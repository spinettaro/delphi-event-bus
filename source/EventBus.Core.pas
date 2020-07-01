{ *******************************************************************************
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
  ******************************************************************************** }

unit EventBus.Core;

interface

uses
  System.SyncObjs, EventBus.Subscribers, Generics.Collections,
  System.SysUtils, System.Classes, EventBus;

type

  TEventBus = class(TInterfacedObject, IEventBus)
  var
    FTypesOfGivenSubscriber: TObjectDictionary<TObject, TList<TClass>>;
    FChannelsOfGivenSubscriber: TObjectDictionary<TObject, TList<String>>;
    FSubscriptionsOfGivenEventType
      : TObjectDictionary<TClass, TObjectList<TSubscription>>;
    FSubscriptionsOfGivenChannel
      : TObjectDictionary<String, TObjectList<TSubscription>>;
    FCustomClonerDict: TDictionary<String, TCloneEventMethod>;
    FOnCloneEvent: TCloneEventCallback;
    procedure SubscribeEvent(ASubscriber: TObject;
      ASubscriberMethod: TSubscriberMethod);
    procedure SubscribeChannel(ASubscriber: TObject;
      ASubscriberMethod: TSubscriberMethod);
    procedure UnsubscribeByEventType(ASubscriber: TObject; AEventType: TClass);
    procedure UnsubscribeByChannel(ASubscriber: TObject; AChannel: String);
    procedure InvokeSubscriber(ASubscription: TSubscription;
      AEvent: TObject; AEventMM: TEventMM); overload;
    procedure InvokeSubscriber(ASubscription: TSubscription;
      AMessage: String); overload;
    function GenerateTProc(ASubscription: TSubscription; AEvent: TObject; AEventMM: TEventMM)
      : TProc; overload;
    function GenerateTProc(ASubscription: TSubscription; AMessage: String)
      : TProc; overload;
    function GenerateThreadProc(ASubscription: TSubscription; AEvent: TObject; AEventMM: TEventMM)
      : TThreadProcedure; overload;
    function GenerateThreadProc(ASubscription: TSubscription; AMessage: String)
      : TThreadProcedure; overload;
  protected
    procedure SetOnCloneEvent(const aCloneEvent: TCloneEventCallback);
    function CloneEvent(AEvent: TObject): TObject; virtual;
    procedure PostToSubscription(ASubscription: TSubscription; AEvent: TObject;
      AIsMainThread: Boolean; AEventMM: TEventMM); virtual;
    procedure PostToChannel(ASubscription: TSubscription; AMessage: String;
      AIsMainThread: Boolean); virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure RegisterSubscriberForEvents(ASubscriber: TObject); virtual;
    procedure RegisterSubscriberForChannels(ASubscriber: TObject); virtual;
    function IsRegisteredForEvents(ASubscriber: TObject): Boolean;
    function IsRegisteredForChannels(ASubscriber: TObject): Boolean;
    procedure UnregisterForEvents(ASubscriber: TObject); virtual;
    procedure UnregisterForChannels(ASubscriber: TObject); virtual;
    procedure Post(AEvent: TObject; const AContext: String = '';
      AEventMM: TEventMM = mmManualAndFreeMainEvent); overload; virtual;
    procedure Post(const AChannel: String; const AMessage: String);
      overload; virtual;
    property TypesOfGivenSubscriber: TObjectDictionary < TObject,
      TList < TClass >> read FTypesOfGivenSubscriber;
    property SubscriptionsOfGivenEventType: TObjectDictionary < TClass,
      TObjectList < TSubscription >> read FSubscriptionsOfGivenEventType;
    property OnCloneEvent: TCloneEventCallback write SetOnCloneEvent;
    procedure AddCustomClassCloning(const AQualifiedClassName: String;
      const aCloneEvent: TCloneEventMethod);
    procedure RemoveCustomClassCloning(const AQualifiedClassName: String);
  end;

implementation

uses
  System.Rtti,
{$IF CompilerVersion >= 28.0}
  System.Threading,
{$ENDIF}
  RTTIUtilsU;

var
  FMREWSync: TMultiReadExclusiveWriteSynchronizer;

  { TEventBus }

constructor TEventBus.Create;
begin
  inherited Create;
  FSubscriptionsOfGivenEventType := TObjectDictionary < TClass,
    TObjectList < TSubscription >>.Create([doOwnsValues]);
  FTypesOfGivenSubscriber := TObjectDictionary < TObject,
    TList < TClass >>.Create([doOwnsValues]);
  FSubscriptionsOfGivenChannel := TObjectDictionary < String,
    TObjectList < TSubscription >>.Create([doOwnsValues]);
  FChannelsOfGivenSubscriber := TObjectDictionary < TObject,
    TList < String >>.Create([doOwnsValues]);
  FCustomClonerDict := TDictionary<String, TCloneEventMethod>.Create;
end;

destructor TEventBus.Destroy;
begin
  FreeAndNil(FSubscriptionsOfGivenEventType);
  FreeAndNil(FTypesOfGivenSubscriber);
  FreeAndNil(FSubscriptionsOfGivenChannel);
  FreeAndNil(FChannelsOfGivenSubscriber);
  FreeAndNil(FCustomClonerDict);
  inherited;
end;

procedure TEventBus.AddCustomClassCloning(const AQualifiedClassName: String;
  const aCloneEvent: TCloneEventMethod);
begin
  FCustomClonerDict.Add(AQualifiedClassName, aCloneEvent);
end;

function TEventBus.CloneEvent(AEvent: TObject): TObject;
var
  LCloneEvent: TCloneEventMethod;
begin
  if FCustomClonerDict.TryGetValue(AEvent.QualifiedClassName, LCloneEvent) then
    Result := LCloneEvent(AEvent)
  else if Assigned(FOnCloneEvent) then
    Result := FOnCloneEvent(AEvent)
  else
    Result := TRTTIUtils.Clone(AEvent);
end;

function TEventBus.GenerateThreadProc(ASubscription: TSubscription;
  AEvent: TObject; AEventMM: TEventMM): TThreadProcedure;
begin
  Result := procedure
    begin
      if ASubscription.Active then
      begin
        ASubscription.SubscriberMethod.Method.Invoke(ASubscription.Subscriber,
          [AEvent]);
      end;
      if (AEventMM = TEventMM.mmAutomatic) then
        AEvent.Free;
    end;
end;

function TEventBus.GenerateThreadProc(ASubscription: TSubscription;
  AMessage: String): TThreadProcedure;
begin
  Result := procedure
    begin
      if ASubscription.Active then
      begin
        ASubscription.SubscriberMethod.Method.Invoke(ASubscription.Subscriber,
          [AMessage]);
      end;
    end;
end;

function TEventBus.GenerateTProc(ASubscription: TSubscription;
  AMessage: String): TProc;
begin
  Result := procedure
    begin
      if ASubscription.Active then
      begin
        ASubscription.SubscriberMethod.Method.Invoke(ASubscription.Subscriber,
          [AMessage]);
      end;
    end;
end;

function TEventBus.GenerateTProc(ASubscription: TSubscription;
  AEvent: TObject; AEventMM: TEventMM): TProc;
begin
  Result := procedure
    begin
      if ASubscription.Active then
      begin
        ASubscription.SubscriberMethod.Method.Invoke(ASubscription.Subscriber,
          [AEvent]);
      end;
      if (AEventMM = TEventMM.mmAutomatic) then
          AEvent.Free;
    end;
end;

procedure TEventBus.InvokeSubscriber(ASubscription: TSubscription;
  AEvent: TObject; AEventMM: TEventMM);
begin
  try
    ASubscription.SubscriberMethod.Method.Invoke(ASubscription.Subscriber,
      [AEvent]);
    if (AEventMM = TEventMM.mmAutomatic) then
        AEvent.Free;
  except
    on E: Exception do
    begin
      raise Exception.CreateFmt
        ('Error invoking subscriber method. Subscriber class: %s. Event type: %s. Original exception: %s: %s',
        [ASubscription.Subscriber.ClassName,
        ASubscription.SubscriberMethod.EventType.ClassName, E.ClassName,
        E.Message]);
    end;
  end;
end;

procedure TEventBus.InvokeSubscriber(ASubscription: TSubscription;
  AMessage: String);
begin
  try
    ASubscription.SubscriberMethod.Method.Invoke(ASubscription.Subscriber,
      [AMessage]);
  except
    on E: Exception do
    begin
      raise Exception.CreateFmt
        ('Error invoking subscriber method. Subscriber class: %s. Channel: %s. Original exception: %s: %s',
        [ASubscription.Subscriber.ClassName,
        ASubscription.SubscriberMethod.Context, E.ClassName, E.Message]);
    end;
  end;
end;

function TEventBus.IsRegisteredForChannels(ASubscriber: TObject): Boolean;
begin
  FMREWSync.BeginRead;
  try
    Result := FChannelsOfGivenSubscriber.ContainsKey(ASubscriber);
  finally
    FMREWSync.EndRead;
  end;
end;

function TEventBus.IsRegisteredForEvents(ASubscriber: TObject): Boolean;
begin
  FMREWSync.BeginRead;
  try
    Result := FTypesOfGivenSubscriber.ContainsKey(ASubscriber);
  finally
    FMREWSync.EndRead;
  end;
end;

procedure TEventBus.Post(AEvent: TObject; const AContext: String = '';
  AEventMM: TEventMM = mmManualAndFreeMainEvent);
var
  LSubscriptions: TObjectList<TSubscription>;
  LSubscription: TSubscription;
  LEvent: TObject;
  LIsMainThread: Boolean;
begin
  Assert(Assigned(AEvent), 'Event cannot be nil');
  FMREWSync.BeginRead;
  try
    try
      LIsMainThread := MainThreadID = TThread.CurrentThread.ThreadID;

      FSubscriptionsOfGivenEventType.TryGetValue(AEvent.ClassType,
        LSubscriptions);

      if (not Assigned(LSubscriptions)) then
        Exit;

      for LSubscription in LSubscriptions do
      begin

        if not LSubscription.Active then
          continue;

        if ((LSubscription.Context <> AContext)) then
          continue;

        LEvent := CloneEvent(AEvent);
        PostToSubscription(LSubscription, LEvent, LIsMainThread, AEventMM);
      end;
    finally
      if (AEventMM in [mmAutomatic, mmManualAndFreeMainEvent]) then
        AEvent.Free;
    end;
  finally
    FMREWSync.EndRead;
  end;
end;

procedure TEventBus.PostToChannel(ASubscription: TSubscription;
  AMessage: String; AIsMainThread: Boolean);
begin
  if not Assigned(ASubscription.Subscriber) then
    Exit;

  case ASubscription.SubscriberMethod.ThreadMode of
    Posting:
      InvokeSubscriber(ASubscription, AMessage);
    Main:
      if (AIsMainThread) then
        InvokeSubscriber(ASubscription, AMessage)
      else
        TThread.Queue(nil, GenerateThreadProc(ASubscription, AMessage));
    Background:
      if (AIsMainThread) then
{$IF CompilerVersion >= 28.0}
        TTask.Run(GenerateTProc(ASubscription, AMessage))
{$ELSE}
        TThread.CreateAnonymousThread(GenerateTProc(ASubscription,
          AMessage)).Start
{$ENDIF}
      else
        InvokeSubscriber(ASubscription, AMessage);
    Async:
{$IF CompilerVersion >= 28.0}
      TTask.Run(GenerateTProc(ASubscription, AMessage));
{$ELSE}
      TThread.CreateAnonymousThread(GenerateTProc(ASubscription,
        AMessage)).Start;
{$ENDIF}
  else
    raise Exception.Create('Unknown thread mode');
  end;
end;

procedure TEventBus.PostToSubscription(ASubscription: TSubscription;
  AEvent: TObject; AIsMainThread: Boolean; AEventMM: TEventMM);
begin

  if not Assigned(ASubscription.Subscriber) then
    Exit;

  case ASubscription.SubscriberMethod.ThreadMode of
    Posting:
      InvokeSubscriber(ASubscription, AEvent, AEventMM);
    Main:
      if (AIsMainThread) then
        InvokeSubscriber(ASubscription, AEvent, AEventMM)
      else
        TThread.Queue(nil, GenerateThreadProc(ASubscription, AEvent, AEventMM));
    Background:
      if (AIsMainThread) then
{$IF CompilerVersion >= 28.0}
        TTask.Run(GenerateTProc(ASubscription, AEvent, AEventMM))
{$ELSE}
        TThread.CreateAnonymousThread(GenerateTProc(ASubscription,
          AEvent, AEventMM)).Start
{$ENDIF}
      else
        InvokeSubscriber(ASubscription, AEvent, AEventMM);
    Async:
{$IF CompilerVersion >= 28.0}
      TTask.Run(GenerateTProc(ASubscription, AEvent, AEventMM));
{$ELSE}
      TThread.CreateAnonymousThread(GenerateTProc(ASubscription, AEvent, AEventMM)).Start;
{$ENDIF}
  else
    raise Exception.Create('Unknown thread mode');
  end;

end;

procedure TEventBus.Post(const AChannel, AMessage: String);
var
  LSubscriptions: TObjectList<TSubscription>;
  LSubscription: TSubscription;
  LIsMainThread: Boolean;
begin
  FMREWSync.BeginRead;
  try
    LIsMainThread := MainThreadID = TThread.CurrentThread.ThreadID;

    FSubscriptionsOfGivenChannel.TryGetValue(AChannel, LSubscriptions);

    if (not Assigned(LSubscriptions)) then
      Exit;

    for LSubscription in LSubscriptions do
    begin

      if not LSubscription.Active then
        continue;

      if (LSubscription.Context <> AChannel) then
        continue;

      PostToChannel(LSubscription, AMessage, LIsMainThread);
    end;
  finally
    FMREWSync.EndRead;
  end;
end;

procedure TEventBus.RegisterSubscriberForChannels(ASubscriber: TObject);
var
  LSubscriberClass: TClass;
  LSubscriberMethods: TArray<TSubscriberMethod>;
  LSubscriberMethod: TSubscriberMethod;
begin
  FMREWSync.BeginWrite;
  try
    LSubscriberClass := ASubscriber.ClassType;

    LSubscriberMethods := TSubscribersFinder.FindChannelsSubcriberMethods
      (LSubscriberClass, true);
    for LSubscriberMethod in LSubscriberMethods do
      SubscribeChannel(ASubscriber, LSubscriberMethod);
  finally
    FMREWSync.EndWrite;
  end;
end;

procedure TEventBus.RegisterSubscriberForEvents(ASubscriber: TObject);
var
  LSubscriberClass: TClass;
  LSubscriberMethods: TArray<TSubscriberMethod>;
  LSubscriberMethod: TSubscriberMethod;
begin
  FMREWSync.BeginWrite;
  try
    LSubscriberClass := ASubscriber.ClassType;

    LSubscriberMethods := TSubscribersFinder.FindEventsSubscriberMethods
      (LSubscriberClass, true);
    for LSubscriberMethod in LSubscriberMethods do
      SubscribeEvent(ASubscriber, LSubscriberMethod);

  finally
    FMREWSync.EndWrite;
  end;
end;

procedure TEventBus.RemoveCustomClassCloning(const AQualifiedClassName: String);
begin
  // No exception is thrown if the key is not in the dictionary
  FCustomClonerDict.Remove(AQualifiedClassName);
end;

procedure TEventBus.SetOnCloneEvent(const aCloneEvent: TCloneEventCallback);
begin
  FOnCloneEvent := aCloneEvent;
end;

procedure TEventBus.SubscribeEvent(ASubscriber: TObject;
  ASubscriberMethod: TSubscriberMethod);
var
  LEventType: TClass;
  LNewSubscription: TSubscription;
  LSubscriptions: TObjectList<TSubscription>;
  LSubscribedEvents: TList<TClass>;
begin
  LEventType := ASubscriberMethod.EventType;
  LNewSubscription := TSubscription.Create(ASubscriber, ASubscriberMethod);
  if (not FSubscriptionsOfGivenEventType.ContainsKey(LEventType)) then
  begin
    LSubscriptions := TObjectList<TSubscription>.Create();
    FSubscriptionsOfGivenEventType.Add(LEventType, LSubscriptions);
  end
  else
  begin
    LSubscriptions := FSubscriptionsOfGivenEventType.Items[LEventType];
    if (LSubscriptions.Contains(LNewSubscription)) then
      raise Exception.CreateFmt('Subscriber %s already registered to event %s ',
        [ASubscriber.ClassName, LEventType.ClassName]);
  end;

  LSubscriptions.Add(LNewSubscription);

  if (not FTypesOfGivenSubscriber.TryGetValue(ASubscriber, LSubscribedEvents))
  then
  begin
    LSubscribedEvents := TList<TClass>.Create;
    FTypesOfGivenSubscriber.Add(ASubscriber, LSubscribedEvents);
  end;
  LSubscribedEvents.Add(LEventType);
end;

procedure TEventBus.SubscribeChannel(ASubscriber: TObject;
  ASubscriberMethod: TSubscriberMethod);
var
  LNewSubscription: TSubscription;
  LSubscriptions: TObjectList<TSubscription>;
  LSubscribedChannels: TList<String>;
  LChannel: string;
begin
  LChannel := ASubscriberMethod.Context;
  LNewSubscription := TSubscription.Create(ASubscriber, ASubscriberMethod);
  if (not FSubscriptionsOfGivenChannel.ContainsKey(LChannel)) then
  begin
    LSubscriptions := TObjectList<TSubscription>.Create();
    FSubscriptionsOfGivenChannel.Add(LChannel, LSubscriptions);
  end
  else
  begin
    LSubscriptions := FSubscriptionsOfGivenChannel.Items[LChannel];
    if (LSubscriptions.Contains(LNewSubscription)) then
      raise Exception.CreateFmt
        ('Subscriber %s already registered to channel %s ',
        [ASubscriber.ClassName, LChannel]);
  end;

  LSubscriptions.Add(LNewSubscription);

  if (not FChannelsOfGivenSubscriber.TryGetValue(ASubscriber,
    LSubscribedChannels)) then
  begin
    LSubscribedChannels := TList<String>.Create;
    FChannelsOfGivenSubscriber.Add(ASubscriber, LSubscribedChannels);
  end;
  LSubscribedChannels.Add(LChannel);
end;

procedure TEventBus.UnregisterForChannels(ASubscriber: TObject);
var
  LSubscribedChannelTypes: TList<string>;
  LChannel: String;
begin
  FMREWSync.BeginWrite;
  try
    if FChannelsOfGivenSubscriber.TryGetValue(ASubscriber,
      LSubscribedChannelTypes) then
    begin
      for LChannel in LSubscribedChannelTypes do
        UnsubscribeByChannel(ASubscriber, LChannel);
      FChannelsOfGivenSubscriber.Remove(ASubscriber);
    end;
    // else {
    // Log.w(TAG, "Subscriber to unregister was not registered before: " + subscriber.getClass());
    // }
  finally
    FMREWSync.EndWrite;
  end;
end;

procedure TEventBus.UnregisterForEvents(ASubscriber: TObject);
var
  LSubscribedTypes: TList<TClass>;
  LEventType: TClass;
begin
  FMREWSync.BeginWrite;
  try
    if FTypesOfGivenSubscriber.TryGetValue(ASubscriber, LSubscribedTypes) then
    begin
      for LEventType in LSubscribedTypes do
        UnsubscribeByEventType(ASubscriber, LEventType);
      FTypesOfGivenSubscriber.Remove(ASubscriber);
    end;

    // else {
    // Log.w(TAG, "Subscriber to unregister was not registered before: " + subscriber.getClass());
    // }
  finally
    FMREWSync.EndWrite;
  end;
end;

procedure TEventBus.UnsubscribeByChannel(ASubscriber: TObject;
  AChannel: String);
var
  LSubscriptions: TObjectList<TSubscription>;
  LSize, I: Integer;
  LSubscription: TSubscription;
begin
  LSubscriptions := FSubscriptionsOfGivenChannel.Items[AChannel];
  if (not Assigned(LSubscriptions)) or (LSubscriptions.Count < 1) then
    Exit;
  LSize := LSubscriptions.Count;
  for I := LSize - 1 downto 0 do
  begin
    LSubscription := LSubscriptions[I];
    // Notes: In case the subscriber has been freed but it didn't unregister itself, calling
    // LSubscription.Subscriber.Equals() will cause Access Violation, so we use '=' instead.
    if LSubscription.Subscriber = ASubscriber then
    begin
      LSubscription.Active := false;
      LSubscriptions.Delete(I);
    end;
  end;
end;

procedure TEventBus.UnsubscribeByEventType(ASubscriber: TObject;
  AEventType: TClass);
var
  LSubscriptions: TObjectList<TSubscription>;
  LSize, I: Integer;
  LSubscription: TSubscription;
begin
  LSubscriptions := FSubscriptionsOfGivenEventType.Items[AEventType];
  if (not Assigned(LSubscriptions)) or (LSubscriptions.Count < 1) then
    Exit;
  LSize := LSubscriptions.Count;
  for I := LSize - 1 downto 0 do
  begin
    LSubscription := LSubscriptions[I];
    // Notes: In case the subscriber has been freed but it didn't unregister itself, calling
    // LSubscription.Subscriber.Equals() will cause Access Violation, so we use '=' instead.
    if LSubscription.Subscriber = ASubscriber then
    begin
      LSubscription.Active := false;
      LSubscriptions.Delete(I);
    end;
  end;
end;

initialization

FMREWSync := TMultiReadExclusiveWriteSynchronizer.Create;

finalization

FMREWSync.Free;

end.
