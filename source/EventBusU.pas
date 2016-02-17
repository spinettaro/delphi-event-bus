{ *******************************************************************************
  Copyright 2016 Daniele Spinetti

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

unit EventBusU;

interface

uses
  System.SyncObjs, SubscribersU, Generics.Collections;

type

  TPostingThreadState = class(TObject)
  private
    FIsMainThread: Boolean;
    FCanceled: Boolean;
    FSubscription: TSubscription;
    FEvent: TObject;
    FIsPosting: Boolean;
    procedure SetCanceled(const Value: Boolean);
    procedure SetEvent(const Value: TObject);
    procedure SetIsMainThread(const Value: Boolean);
    procedure SetIsPosting(const Value: Boolean);
    procedure SetSubscription(const Value: TSubscription);
  public
    property IsPosting: Boolean read FIsPosting write SetIsPosting;
    property IsMainThread: Boolean read FIsMainThread write SetIsMainThread;
    property Subscription: TSubscription read FSubscription
      write SetSubscription;
    property Event: TObject read FEvent write SetEvent;
    property Canceled: Boolean read FCanceled write SetCanceled;
  end;

  TEventBus = class(TObject)
  private
  class var
    FDefaultInstance: TEventBus;
    FCS: TCriticalSection;
    FSubscriptionsByEventType
      : TObjectDictionary<TClass, TObjectList<TSubscription>>;
    FTypesBySubscriber: TObjectDictionary<TObject, TList<TClass>>;
    procedure Subscribe(ASubscriber: TObject;
      ASubscriberMethod: TSubscriberMethod);
    procedure UnsubscribeByEventType(ASubscriber: TObject; AEventType: TClass);
    procedure PostSingleEvent(APostingState: TPostingThreadState);
    procedure PostToSubscription(ASubscription: TSubscription; AEvent: TObject;
      AIsMainThread: Boolean);
    procedure InvokeSubscriber(ASubscription: TSubscription; AEvent: TObject);
  public
    constructor Create();
    destructor Destroy; override;
    procedure RegisterSubscriber(ASubscriber: TObject);
    function IsRegistered(ASubscriber: TObject): Boolean;
    procedure Unregister(ASubscriber: TObject);
    procedure Post(AEvent: TObject);
    class function GetDefault: TEventBus;
  end;

implementation

uses
  System.Rtti, System.Messaging, AttributesU, System.SysUtils, System.Classes,
  CommonsU, RttiUtilsU;

{ TEventBus }

constructor TEventBus.Create;
begin
  inherited Create;
  FCS := TCriticalSection.Create;
  FSubscriptionsByEventType := TObjectDictionary < TClass,
    TObjectList < TSubscription >>.Create([doOwnsValues]);
  FTypesBySubscriber := TObjectDictionary < TObject,
    TList < TClass >>.Create([doOwnsKeys]);
end;

destructor TEventBus.Destroy;
begin
  FreeAndNil(FCS);
  FreeAndNil(FSubscriptionsByEventType);
  FreeAndNil(FTypesBySubscriber);
  inherited;
end;

class function TEventBus.GetDefault: TEventBus;
var
  LCS: TCriticalSection;
begin
  LCS := TCriticalSection.Create;
  try
    if (not Assigned(FDefaultInstance)) then
    begin
      LCS.Acquire;
      if (not Assigned(FDefaultInstance)) then
        FDefaultInstance := TEventBus.Create;
    end;
    Result := FDefaultInstance;
  finally
    LCS.Free;
  end;
end;

procedure TEventBus.InvokeSubscriber(ASubscription: TSubscription;
  AEvent: TObject);
begin
  ASubscription.SubscriberMethod.Method.Invoke(ASubscription.Subscriber,
    [AEvent]);
end;

function TEventBus.IsRegistered(ASubscriber: TObject): Boolean;
begin
  FCS.Acquire;
  try
    Result := FTypesBySubscriber.ContainsKey(ASubscriber);
  finally
    FCS.Release;
  end;
end;

procedure TEventBus.Post(AEvent: TObject);
var
  LPostingState: TPostingThreadState;
  LElement: TObject;
begin
  LPostingState := TPostingThreadState.Create;
  try
    LPostingState.IsMainThread := TThread.CurrentThread.ThreadID = MainThreadID;
    LPostingState.IsPosting := true;
    LPostingState.Event := AEvent;
    try
      PostSingleEvent(LPostingState);
    finally
      LPostingState.IsPosting := false;
      LPostingState.IsMainThread := false;
    end;
  finally
    LPostingState.Free;
  end;
end;

procedure TEventBus.PostSingleEvent(APostingState: TPostingThreadState);
var
  LSubscriptions: TObjectList<TSubscription>;
  LSubscription: TSubscription;
  LAborted: Boolean;
  LEvent: TObject;
begin
  LEvent := APostingState.Event;
  TMonitor.Enter(FSubscriptionsByEventType);
  try
    FSubscriptionsByEventType.TryGetValue(LEvent.ClassType, LSubscriptions);
  finally
    TMonitor.Exit(FSubscriptionsByEventType);
  end;

  if (not Assigned(LSubscriptions)) then
    Exit;

  for LSubscription in LSubscriptions do
  begin
    APostingState.Subscription := LSubscription;
    LAborted := false;
    try
      PostToSubscription(LSubscription, LEvent, APostingState.IsMainThread);
      LAborted := APostingState.Canceled;
    finally
      APostingState.Event := nil;
      APostingState.Subscription := nil;
      APostingState.Canceled := false;
    end;
    if (LAborted) then
      break;
  end;
end;

procedure TEventBus.PostToSubscription(ASubscription: TSubscription;
  AEvent: TObject; AIsMainThread: Boolean);
begin
  case ASubscription.SubscriberMethod.ThreadMode of
    Posting:
      InvokeSubscriber(ASubscription, AEvent);
    Main:
      if (AIsMainThread) then
        InvokeSubscriber(ASubscription, AEvent);
    // else
    // mainThreadPoster.enqueue(Subscription, Event);
    Background:
      if (AIsMainThread) then // backgroundPoster.enqueue(subscription, event);
      else
        InvokeSubscriber(ASubscription, AEvent);
    Async:
      ;
  else
    raise Exception.Create('Unknown thread mode ');
  end;

end;

procedure TEventBus.RegisterSubscriber(ASubscriber: TObject);
var
  LSubscriberClass: TClass;
  LSubscriberMethods: TArray<TSubscriberMethod>;
  LSubscriberMethod: TSubscriberMethod;
begin
  LSubscriberClass := ASubscriber.ClassType;
  LSubscriberMethods := TSubscribersFinder.FindSubscriberMethods
    (LSubscriberClass, true);
  FCS.Acquire;
  try
    for LSubscriberMethod in LSubscriberMethods do
      Subscribe(ASubscriber, LSubscriberMethod);
  finally
    FCS.Release;
  end;
end;

procedure TEventBus.Subscribe(ASubscriber: TObject;
  ASubscriberMethod: TSubscriberMethod);
var
  LEventType: TClass;
  LNewSubscription: TSubscription;
  LSubscriptions: TObjectList<TSubscription>;
  LSubscribedEvents: TList<TClass>;
begin
  LEventType := ASubscriberMethod.EventType;
  LNewSubscription := TSubscription.Create(ASubscriber, ASubscriberMethod);

  if (not FSubscriptionsByEventType.ContainsKey(LEventType)) then
  begin
    LSubscriptions := TObjectList<TSubscription>.Create();
    FSubscriptionsByEventType.Add(LEventType, LSubscriptions);
  end
  else
  begin
    LSubscriptions := FSubscriptionsByEventType.Items[LEventType];
    if (LSubscriptions.Contains(LNewSubscription)) then
      raise Exception.CreateFmt('Subscriber %s already registered to event %s ',
        [ASubscriber.ClassName, LEventType.ClassName]);
  end;

  LSubscriptions.Add(LNewSubscription);

  if (not FTypesBySubscriber.ContainsKey(ASubscriber)) then
  begin
    LSubscribedEvents := TList<TClass>.Create;
    FTypesBySubscriber.Add(ASubscriber, LSubscribedEvents);
  end;
  LSubscribedEvents.Add(LEventType);

end;

procedure TEventBus.Unregister(ASubscriber: TObject);
var
  LSubscribedTypes: TList<TClass>;
  LEventType: TClass;
begin
  FCS.Acquire;
  try
    LSubscribedTypes := FTypesBySubscriber.Items[ASubscriber];
    if (Assigned(LSubscribedTypes)) then
    begin
      for LEventType in LSubscribedTypes do
        UnsubscribeByEventType(ASubscriber, LEventType);
      FTypesBySubscriber.Remove(ASubscriber);
    end;
    // else {
    // Log.w(TAG, "Subscriber to unregister was not registered before: " + subscriber.getClass());
    // }
  finally
    FCS.Release;
  end;
end;

procedure TEventBus.UnsubscribeByEventType(ASubscriber: TObject;
  AEventType: TClass);
var
  LSubscriptions: TObjectList<TSubscription>;
  LSize, I: Integer;
  LSubscription: TSubscription;
begin
  LSubscriptions := FSubscriptionsByEventType.Items[AEventType];
  if (Assigned(LSubscriptions)) then
  begin
    LSize := LSubscriptions.Count;
    for I := LSize - 1 downto 0 do
    begin
      LSubscription := LSubscriptions[I];
      if (LSubscription.Subscriber.Equals(ASubscriber)) then
        LSubscription.Active := false;
      LSubscriptions.Delete(I);
    end;
  end;
end;

{ TPostingThreadState }

procedure TPostingThreadState.SetCanceled(const Value: Boolean);
begin
  FCanceled := Value;
end;

procedure TPostingThreadState.SetEvent(const Value: TObject);
begin
  FEvent := Value;
end;

procedure TPostingThreadState.SetIsMainThread(const Value: Boolean);
begin
  FIsMainThread := Value;
end;

procedure TPostingThreadState.SetIsPosting(const Value: Boolean);
begin
  FIsPosting := Value;
end;

procedure TPostingThreadState.SetSubscription(const Value: TSubscription);
begin
  FSubscription := Value;
end;

initialization

finalization

TEventBus.GetDefault.Free;

end.
