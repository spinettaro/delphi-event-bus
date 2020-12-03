{*******************************************************************************
  Copyright 2016-2020 Daniele Spinetti

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  ********************************************************************************}

unit EventBus.Core;

interface

uses
  EventBus;

type
  TEventBusFactory = class
  strict private
    class var FGlobalEventBus: IEventBus;
    class constructor Create;
  public
    function CreateEventBus: IEventBus;
    class property GlobalEventBus: IEventBus read FGlobalEventBus;
  end;

implementation

uses
  System.Classes,
  System.Generics.Collections,
  System.Rtti,
  System.SysUtils,
  {$IF CompilerVersion >= 28.0}
  System.Threading,
  {$ENDIF}
  EventBus.Helpers,
  EventBus.Subscribers;

type
  {$REGION 'Type aliases to improve readability'}
  TSubscriptions = TObjectList<TSubscription>;
  TMethodCategory = string;
  TMethodCategories = TList<TMethodCategory>;
  TMethodCategoryToSubscriptionsMap = TObjectDictionary<TMethodCategory, TSubscriptions>;
  TSubscriberToMethodCategoriesMap = TObjectDictionary<TObject, TMethodCategories>;

  TAttributeName = string;
  TMethodCategoryToSubscriptionsByAttributeName = TObjectDictionary<TAttributeName, TMethodCategoryToSubscriptionsMap>;
  TSubscriberToMethodCategoriesByAttributeName = TObjectDictionary<TAttributeName, TSubscriberToMethodCategoriesMap>;
  {$ENDREGION}

  TEventBus = class(TInterfacedObject, IEventBus)
  strict private
    FCategoryToSubscriptionsByAttrName: TMethodCategoryToSubscriptionsByAttributeName;
    FMultiReadExclWriteSync: TMultiReadExclusiveWriteSynchronizer;
    FSubscriberToCategoriesByAttrName: TSubscriberToMethodCategoriesByAttributeName;

    procedure InvokeSubscriber(ASubscription: TSubscription; const Args: array of TValue);
    function IsRegistered<T: TSubscriberMethodAttribute>(ASubscriber: TObject): Boolean;
    procedure RegisterSubscriber<T: TSubscriberMethodAttribute>(ASubscriber: TObject);
    procedure Subscribe<T: TSubscriberMethodAttribute>(ASubscriber: TObject; ASubscriberMethod: TSubscriberMethod);
    procedure UnregisterSubscriber<T: TSubscriberMethodAttribute>(ASubscriber: TObject);
    procedure Unsubscribe<T: TSubscriberMethodAttribute>(ASubscriber: TObject; const AMethodCategory: TMethodCategory);
  protected
    procedure PostToChannel(ASubscription: TSubscription; const AMessage: string; AIsMainThread: Boolean); virtual;
    procedure PostToSubscription(ASubscription: TSubscription; const AEvent: IInterface; AIsMainThread: Boolean); virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    {$REGION'IEventBus interface methods'}
    function IsRegisteredForChannels(ASubscriber: TObject): Boolean;
    function IsRegisteredForEvents(ASubscriber: TObject): Boolean;
    procedure Post(const AChannel: string; const AMessage: string); overload; virtual;
    procedure Post(const AEvent: IInterface; const AContext: string = ''); overload; virtual;
    procedure RegisterSubscriberForChannels(ASubscriber: TObject); virtual;
    procedure RegisterSubscriberForEvents(ASubscriber: TObject); virtual;
    procedure UnregisterForChannels(ASubscriber: TObject); virtual;
    procedure UnregisterForEvents(ASubscriber: TObject); virtual;
    {$ENDREGION}
  end;

constructor TEventBus.Create;
begin
  inherited Create;
  FMultiReadExclWriteSync := TMultiReadExclusiveWriteSynchronizer.Create;
  FCategoryToSubscriptionsByAttrName := TMethodCategoryToSubscriptionsByAttributeName.Create([doOwnsValues]);
  FSubscriberToCategoriesByAttrName := TSubscriberToMethodCategoriesByAttributeName.Create([doOwnsValues]);
end;

destructor TEventBus.Destroy;
begin
  FCategoryToSubscriptionsByAttrName.Free;
  FSubscriberToCategoriesByAttrName.Free;
  FMultiReadExclWriteSync.Free;
  inherited;
end;

procedure TEventBus.InvokeSubscriber(ASubscription: TSubscription; const Args: array of TValue);
begin
  try
    if not ASubscription.Active then
      Exit;

    ASubscription.SubscriberMethod.Method.Invoke(ASubscription.Subscriber, Args);
  except
    on E: Exception do begin
      raise EInvokeSubscriberError.CreateFmt(
        'Error invoking subscriber method. Subscriber class: %s. Event type: %s. Original exception %s: %s.',
        [
          ASubscription.Subscriber.ClassName,
          ASubscription.SubscriberMethod.EventType,
          E.ClassName,
          E.Message
        ]);
    end;
  end;
end;

function TEventBus.IsRegistered<T>(ASubscriber: TObject): Boolean;
var
  LSubscriberToCategoriesMap: TSubscriberToMethodCategoriesMap;
  LAttrName: TAttributeName;
begin
  FMultiReadExclWriteSync.BeginRead;

  try
    LAttrName := T.ClassName;
    if not FSubscriberToCategoriesByAttrName.TryGetValue(LAttrName, LSubscriberToCategoriesMap) then
      Exit(False);

    Result := LSubscriberToCategoriesMap.ContainsKey(ASubscriber);
  finally
    FMultiReadExclWriteSync.EndRead;
  end;
end;

function TEventBus.IsRegisteredForChannels(ASubscriber: TObject): Boolean;
begin
  Result := IsRegistered<ChannelAttribute>(ASubscriber);
end;

function TEventBus.IsRegisteredForEvents(ASubscriber: TObject): Boolean;
begin
  Result := IsRegistered<SubscribeAttribute>(ASubscriber);
end;

procedure TEventBus.Post(const AChannel, AMessage: string);
var
  LSubscriptions: TSubscriptions;
  LSubscription: TSubscription;
  LIsMainThread: Boolean;
  LCategoryToSubscriptionsMap: TMethodCategoryToSubscriptionsMap;
  LAttrName: TAttributeName;
begin
  FMultiReadExclWriteSync.BeginRead;

  try
    LAttrName := ChannelAttribute.ClassName;
    if not FCategoryToSubscriptionsByAttrName.TryGetValue(LAttrName, LCategoryToSubscriptionsMap) then
      Exit;

    if not LCategoryToSubscriptionsMap.TryGetValue(TSubscriberMethod.EncodeCategory(AChannel), LSubscriptions) then
      Exit;

    LIsMainThread := MainThreadID = TThread.CurrentThread.ThreadID;

    for LSubscription in LSubscriptions do begin
      if (LSubscription.Context <> AChannel) or (not LSubscription.Active) then Continue;
      PostToChannel(LSubscription, AMessage, LIsMainThread);
    end;
  finally
    FMultiReadExclWriteSync.EndRead;
  end;
end;

procedure TEventBus.Post(const AEvent: IInterface; const AContext: string = '');
var
  LIsMainThread: Boolean;
  LSubscription: TSubscription;
  LSubscriptions: TSubscriptions;
  LCategoryToSubscriptionsMap: TMethodCategoryToSubscriptionsMap;
  LEventType: string;
  LAttrName: TAttributeName;
begin
  FMultiReadExclWriteSync.BeginRead;

  try
    LAttrName := SubscribeAttribute.ClassName;
    if not FCategoryToSubscriptionsByAttrName.TryGetValue(LAttrName, LCategoryToSubscriptionsMap) then
      Exit;

    LEventType:= TInterfaceHelper.GetQualifiedName(AEvent);
    if not LCategoryToSubscriptionsMap.TryGetValue(TSubscriberMethod.EncodeCategory(AContext, LEventType), LSubscriptions) then
      Exit;

    LIsMainThread := MainThreadID = TThread.CurrentThread.ThreadID;

    for LSubscription in LSubscriptions do begin
      if not LSubscription.Active then Continue;
      PostToSubscription(LSubscription, AEvent, LIsMainThread);
    end;
  finally
    FMultiReadExclWriteSync.EndRead;
  end;
end;

procedure TEventBus.PostToChannel(ASubscription: TSubscription; const AMessage: string; AIsMainThread: Boolean);
var
  LProc: TProc;
begin
  if not Assigned(ASubscription.Subscriber) then
    Exit;

  LProc := procedure begin
    InvokeSubscriber(ASubscription, [AMessage]);
  end;

  case ASubscription.SubscriberMethod.ThreadMode of
    Posting:
      LProc();
    Main:
      if (AIsMainThread) then
        LProc()
      else
        TThread.Queue(nil, TThreadProcedure(LProc));
    Background:
      if (AIsMainThread) then
        {$IF CompilerVersion >= 28.0}
        TTask.Run(LProc)
        {$ELSE}
        TThread.CreateAnonymousThread(LProc).Start
        {$ENDIF}
      else
        LProc();
    Async:
      {$IF CompilerVersion >= 28.0}
      TTask.Run(LProc);
      {$ELSE}
      TThread.CreateAnonymousThread(LProc).Start;
      {$ENDIF}
  else
    raise EUnknownThreadMode.CreateFmt('Unknown thread mode: %s.', [Ord(ASubscription.SubscriberMethod.ThreadMode)]);
  end;
end;

procedure TEventBus.PostToSubscription(ASubscription: TSubscription; const AEvent: IInterface; AIsMainThread: Boolean);
var
  LProc: TProc;
begin
  if not Assigned(ASubscription.Subscriber) then
    Exit;

  LProc := procedure begin
     InvokeSubscriber(ASubscription, [AEvent as TObject]);
  end;

  case ASubscription.SubscriberMethod.ThreadMode of
    Posting:
      LProc();
    Main:
      if (AIsMainThread) then
        LProc()
      else
        TThread.Queue(nil, TThreadProcedure(LProc));
    Background:
      if (AIsMainThread) then
        {$IF CompilerVersion >= 28.0}
        TTask.Run(LProc)
        {$ELSE}
        TThread.CreateAnonymousThread(LProc).Start
        {$ENDIF}
      else
        LProc();
    Async:
      {$IF CompilerVersion >= 28.0}
      TTask.Run(LProc);
      {$ELSE}
      TThread.CreateAnonymousThread(LProc)).Start;
      {$ENDIF}
  else
    raise Exception.Create('Unknown thread mode');
  end;
end;

procedure TEventBus.RegisterSubscriber<T>(ASubscriber: TObject);
var
  LSubscriberClass: TClass;
  LSubscriberMethods: TArray<TSubscriberMethod>;
  LSubscriberMethod: TSubscriberMethod;
begin
  FMultiReadExclWriteSync.BeginWrite;

  try
    LSubscriberClass := ASubscriber.ClassType;
    LSubscriberMethods := TSubscribersFinder.FindSubscriberMethods<T>(LSubscriberClass, True);
    for LSubscriberMethod in LSubscriberMethods do Subscribe<T>(ASubscriber, LSubscriberMethod);
  finally
    FMultiReadExclWriteSync.EndWrite;
  end;
end;

procedure TEventBus.RegisterSubscriberForChannels(ASubscriber: TObject);
begin
  RegisterSubscriber<ChannelAttribute>(ASubscriber);
end;

procedure TEventBus.RegisterSubscriberForEvents(ASubscriber: TObject);
begin
  RegisterSubscriber<SubscribeAttribute>(ASubscriber);
end;

procedure TEventBus.Subscribe<T>(ASubscriber: TObject; ASubscriberMethod: TSubscriberMethod);
var
  LNewSubscription: TSubscription;
  LSubscriptions: TSubscriptions;
  LCategories: TMethodCategories;
  LCategory: TMethodCategory;
  LCategoryToSubscriptionsMap: TMethodCategoryToSubscriptionsMap;
  LSubscriberToCategoriesMap: TSubscriberToMethodCategoriesMap;
  LAttrName: TAttributeName;
begin
  LAttrName := T.ClassName;
  if not FCategoryToSubscriptionsByAttrName.ContainsKey(LAttrName) then begin
    LCategoryToSubscriptionsMap := TMethodCategoryToSubscriptionsMap.Create([doOwnsValues]);
    FCategoryToSubscriptionsByAttrName.Add(LAttrName, LCategoryToSubscriptionsMap);
  end else begin
    LCategoryToSubscriptionsMap := FCategoryToSubscriptionsByAttrName[LAttrName];
  end;

  LCategory := ASubscriberMethod.Category;
  LNewSubscription := TSubscription.Create(ASubscriber, ASubscriberMethod);

  if (not LCategoryToSubscriptionsMap.ContainsKey(LCategory)) then begin
    LSubscriptions := TSubscriptions.Create;
    LCategoryToSubscriptionsMap.Add(LCategory, LSubscriptions);
  end else begin
    LSubscriptions := LCategoryToSubscriptionsMap[LCategory];
    if (LSubscriptions.Contains(LNewSubscription)) then begin
      LNewSubscription.Free;
      raise ESubscriberMethodAlreadyRegistered.CreateFmt('Subscriber %s already registered to %s.', [ASubscriber.ClassName, LCategory]);
    end;
  end;

  LSubscriptions.Add(LNewSubscription);

  if not FSubscriberToCategoriesByAttrName.ContainsKey(LAttrName) then begin
    LSubscriberToCategoriesMap := TSubscriberToMethodCategoriesMap.Create([doOwnsValues]);
    FSubscriberToCategoriesByAttrName.Add(LAttrName, LSubscriberToCategoriesMap);
  end else begin
    LSubscriberToCategoriesMap := FSubscriberToCategoriesByAttrName[LAttrName];
  end;

  if (not LSubscriberToCategoriesMap.TryGetValue(ASubscriber, LCategories)) then begin
    LCategories := TMethodCategories.Create;
    LSubscriberToCategoriesMap.Add(ASubscriber, LCategories);
  end;

  LCategories.Add(LCategory);
end;

procedure TEventBus.UnregisterSubscriber<T>(ASubscriber: TObject);
var
  LCategories: TMethodCategories;
  LCategory: TMethodCategory;
  LSubscriberToCategoriesMap: TSubscriberToMethodCategoriesMap;
  LAttrName: TAttributeName;
begin
  FMultiReadExclWriteSync.BeginWrite;

  try
    LAttrName := T.ClassName;
    if not FSubscriberToCategoriesByAttrName.TryGetValue(LAttrName, LSubscriberToCategoriesMap) then
      Exit;

    if LSubscriberToCategoriesMap.TryGetValue(ASubscriber, LCategories) then begin
      for LCategory in LCategories do Unsubscribe<T>(ASubscriber, LCategory);
      LSubscriberToCategoriesMap.Remove(ASubscriber);
    end;
  finally
    FMultiReadExclWriteSync.EndWrite;
  end;
end;

procedure TEventBus.UnregisterForChannels(ASubscriber: TObject);
begin
  UnregisterSubscriber<ChannelAttribute>(ASubscriber);
end;

procedure TEventBus.UnregisterForEvents(ASubscriber: TObject);
begin
  UnregisterSubscriber<SubscribeAttribute>(ASubscriber);
end;

procedure TEventBus.Unsubscribe<T>(ASubscriber: TObject; const AMethodCategory: TMethodCategory);
var
  LSubscriptions: TObjectList<TSubscription>;
  LSize, I: Integer;
  LSubscription: TSubscription;
  LCategoryToSubscriptionsMap: TMethodCategoryToSubscriptionsMap;
  LAttrName: TAttributeName;
begin
  LAttrName := T.ClassName;
  if not FCategoryToSubscriptionsByAttrName.TryGetValue(LAttrName, LCategoryToSubscriptionsMap) then
    Exit;

  if not LCategoryToSubscriptionsMap.TryGetValue(AMethodCategory, LSubscriptions) then
    Exit;

  if (LSubscriptions.Count < 1) then
    Exit;

  LSize := LSubscriptions.Count;

  for I := LSize - 1 downto 0 do begin
    LSubscription := LSubscriptions[I];
    // Note - If the subscriber has been freed without unregistering itself, calling
    // LSubscription.Subscriber.Equals() will cause Access Violation, hence use '=' instead.
    if LSubscription.Subscriber = ASubscriber then begin
      LSubscription.Active := False;
      LSubscriptions.Delete(I);
    end;
  end;
end;

class constructor TEventBusFactory.Create;
begin
  FGlobalEventBus := TEventBus.Create;
end;

function TEventBusFactory.CreateEventBus: IEventBus;
begin
  Result := TEventBus.Create;
end;

end.
