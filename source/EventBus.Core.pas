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
    FTypesOfGivenSubscriber: TObjectDictionary<TObject, TList<String>>;
    FChannelsOfGivenSubscriber: TObjectDictionary<TObject, TList<String>>;
    FSubscriptionsOfGivenEventType
      : TObjectDictionary<String, TObjectList<TSubscription>>;
    FSubscriptionsOfGivenChannel
      : TObjectDictionary<String, TObjectList<TSubscription>>;
    procedure SubscribeEvent(ASubscriber: TObject;
      ASubscriberMethod: TSubscriberMethod);
    procedure SubscribeChannel(ASubscriber: TObject;
      ASubscriberMethod: TSubscriberMethod);
    procedure UnsubscribeByEventType(ASubscriber: TObject; AEventType: String);
    procedure UnsubscribeByChannel(ASubscriber: TObject; AChannel: String);
    procedure InvokeSubscriber(ASubscription: TSubscription;
      AEvent: IInterface); overload;
    procedure InvokeSubscriber(ASubscription: TSubscription;
      AMessage: String); overload;
    function GenerateTProc(ASubscription: TSubscription; AEvent: IInterface)
      : TProc; overload;
    function GenerateTProc(ASubscription: TSubscription; AMessage: String)
      : TProc; overload;
    function GenerateThreadProc(ASubscription: TSubscription; AEvent: IInterface)
      : TThreadProcedure; overload;
    function GenerateThreadProc(ASubscription: TSubscription; AMessage: String)
      : TThreadProcedure; overload;
  protected
    procedure PostToSubscription(ASubscription: TSubscription; AEvent: IInterface;
      AIsMainThread: Boolean); virtual;
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
    procedure Post(AEvent: IInterface; const AContext: String = ''); overload; virtual;
    procedure Post(const AChannel: String; const AMessage: String);
      overload; virtual;
    property TypesOfGivenSubscriber: TObjectDictionary < TObject,
      TList < String >> read FTypesOfGivenSubscriber;
    property SubscriptionsOfGivenEventType: TObjectDictionary < String,
      TObjectList < TSubscription >> read FSubscriptionsOfGivenEventType;
  end;

implementation

uses
  System.Rtti,
{$IF CompilerVersion >= 28.0}
  System.Threading,
{$ENDIF}
  EventBus.Helpers;

var
  FMREWSync: TMultiReadExclusiveWriteSynchronizer;

  { TEventBus }

constructor TEventBus.Create;
begin
  inherited Create;
  FSubscriptionsOfGivenEventType := TObjectDictionary < String,
    TObjectList < TSubscription >>.Create([doOwnsValues]);
  FTypesOfGivenSubscriber := TObjectDictionary < TObject,
    TList < String >>.Create([doOwnsValues]);
  FSubscriptionsOfGivenChannel := TObjectDictionary < String,
    TObjectList < TSubscription >>.Create([doOwnsValues]);
  FChannelsOfGivenSubscriber := TObjectDictionary < TObject,
    TList < String >>.Create([doOwnsValues]);
end;

destructor TEventBus.Destroy;
begin
  FreeAndNil(FSubscriptionsOfGivenEventType);
  FreeAndNil(FTypesOfGivenSubscriber);
  FreeAndNil(FSubscriptionsOfGivenChannel);
  FreeAndNil(FChannelsOfGivenSubscriber);
  inherited;
end;

function TEventBus.GenerateThreadProc(ASubscription: TSubscription;
  AEvent: IInterface): TThreadProcedure;
begin
  Result := procedure
    begin
      InvokeSubscriber(ASubscription, AEvent);
    end;
end;

function TEventBus.GenerateThreadProc(ASubscription: TSubscription;
  AMessage: String): TThreadProcedure;
begin
  Result := procedure
    begin
      InvokeSubscriber(ASubscription, AMessage);
    end;
end;

function TEventBus.GenerateTProc(ASubscription: TSubscription;
  AMessage: String): TProc;
begin
  Result := procedure
    begin
      InvokeSubscriber(ASubscription, AMessage);
    end;
end;

function TEventBus.GenerateTProc(ASubscription: TSubscription;
  AEvent: IInterface): TProc;
begin
  Result := procedure
    begin
        InvokeSubscriber(ASubscription, AEvent);
    end;
end;

procedure TEventBus.InvokeSubscriber(ASubscription: TSubscription;
  AEvent: IInterface);
begin
  try
    if not ASubscription.Active then
        exit;
    ASubscription.SubscriberMethod.Method.Invoke(ASubscription.Subscriber,
      [ AEvent as TObject  ]);
  except
    on E: Exception do
    begin
      raise Exception.CreateFmt
        ('Error invoking subscriber method. Subscriber class: %s. Event type: %s. Original exception: %s: %s',
        [ASubscription.Subscriber.ClassName,
        ASubscription.SubscriberMethod.EventType, E.ClassName,
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

procedure TEventBus.Post(AEvent: IInterface; const AContext: String = '');
var
  LSubscriptions: TObjectList<TSubscription>;
  LSubscription: TSubscription;
  LIsMainThread: Boolean;
  lType: String;
begin
  Assert(Assigned(AEvent), 'Event cannot be nil');
  FMREWSync.BeginRead;
  try
      LIsMainThread := MainThreadID = TThread.CurrentThread.ThreadID;
      lType:= TInterfaceHelper.GetQualifiedName( AEvent);

      FSubscriptionsOfGivenEventType.TryGetValue( lType, LSubscriptions);

      if (not Assigned(LSubscriptions)) then
        Exit;

      for LSubscription in LSubscriptions do
      begin

        if not LSubscription.Active then
          continue;

        if ((LSubscription.Context <> AContext)) then
          continue;

        PostToSubscription(LSubscription, AEvent, LIsMainThread);
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
  AEvent: IInterface; AIsMainThread: Boolean);
begin

  if not Assigned(ASubscription.Subscriber) then
    Exit;

  case ASubscription.SubscriberMethod.ThreadMode of
    Posting:
      InvokeSubscriber(ASubscription, AEvent);
    Main:
      if (AIsMainThread) then
        InvokeSubscriber(ASubscription, AEvent)
      else
        TThread.Queue(nil, GenerateThreadProc(ASubscription, AEvent));
    Background:
      if (AIsMainThread) then
{$IF CompilerVersion >= 28.0}
        TTask.Run(GenerateTProc(ASubscription, AEvent))
{$ELSE}
        TThread.CreateAnonymousThread(GenerateTProc(ASubscription,
          AEvent)).Start
{$ENDIF}
      else
        InvokeSubscriber(ASubscription, AEvent);
    Async:
{$IF CompilerVersion >= 28.0}
      TTask.Run(GenerateTProc(ASubscription, AEvent));
{$ELSE}
      TThread.CreateAnonymousThread(GenerateTProc(ASubscription, AEvent)).Start;
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

procedure TEventBus.SubscribeEvent(ASubscriber: TObject;
  ASubscriberMethod: TSubscriberMethod);
var
  LEventType: String;
  LNewSubscription: TSubscription;
  LSubscriptions: TObjectList<TSubscription>;
  LSubscribedEvents: TList<String>;
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
        [ASubscriber.ClassName, LEventType]);
  end;

  LSubscriptions.Add(LNewSubscription);

  if (not FTypesOfGivenSubscriber.TryGetValue(ASubscriber, LSubscribedEvents))
  then
  begin
    LSubscribedEvents := TList<String>.Create;
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
  LSubscribedTypes: TList<String>;
  LEventType: String;
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
  AEventType: String);
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
