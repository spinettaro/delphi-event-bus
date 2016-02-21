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

unit EventBus;

interface

uses
  System.SyncObjs, EventBus.Subscribers, Generics.Collections;

type

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
    procedure PostToSubscription(ASubscription: TSubscription; AEvent: TObject;
      AIsMainThread: Boolean);
    procedure InvokeSubscriber(ASubscription: TSubscription; AEvent: TObject);
  public
    constructor Create();
    destructor Destroy; override;
    procedure RegisterSubscriber(ASubscriber: TObject);
    function IsRegistered(ASubscriber: TObject): Boolean;
    procedure Unregister(ASubscriber: TObject);
    procedure Post(AEvent: TObject; AEventOwner: Boolean = true);
    class function GetDefault: TEventBus;
  end;

implementation

uses
  System.Rtti, System.Messaging, EventBus.Attributes, System.SysUtils,
  System.Classes, EventBus.Commons, RttiUtilsU, System.Threading;

{ TEventBus }

constructor TEventBus.Create;
begin
  inherited Create;
  FCS := TCriticalSection.Create;
  FSubscriptionsByEventType := TObjectDictionary < TClass,
    TObjectList < TSubscription >>.Create([doOwnsValues]);
  FTypesBySubscriber := TObjectDictionary < TObject,
    TList < TClass >>.Create([doOwnsValues]);
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

procedure TEventBus.Post(AEvent: TObject; AEventOwner: Boolean = true);
var
  LSubscriptions: TObjectList<TSubscription>;
  LSubscription: TSubscription;
  LEvent: TObject;
  LIsMainThread: Boolean;
begin
  try
    LIsMainThread := MainThreadID = TThread.CurrentThread.ThreadID;
    LEvent := TRTTIUtils.Clone(AEvent);

    TMonitor.Enter(FSubscriptionsByEventType);
    try
      FSubscriptionsByEventType.TryGetValue(LEvent.ClassType, LSubscriptions);
    finally
      TMonitor.Exit(FSubscriptionsByEventType);
    end;

    if (not Assigned(LSubscriptions)) then
      Exit;

    for LSubscription in LSubscriptions do
      PostToSubscription(LSubscription, LEvent, LIsMainThread);
  finally
    if (AEventOwner and Assigned(AEvent)) then
      AEvent.Free;
  end;
end;

procedure TEventBus.PostToSubscription(ASubscription: TSubscription;
  AEvent: TObject; AIsMainThread: Boolean);
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
        TThread.Queue(nil,
          procedure
          begin
            ASubscription.SubscriberMethod.Method.Invoke
              (ASubscription.Subscriber, [AEvent]);
          end);
    Background:
      if (AIsMainThread) then // backgroundPoster.enqueue(subscription, event);
      else
        InvokeSubscriber(ASubscription, AEvent);
    Async:
      TTask.Run(
        procedure
        begin
          ASubscription.SubscriberMethod.Method.Invoke(ASubscription.Subscriber,
            [AEvent]);
        end);
  else
    raise Exception.Create('Unknown thread mode');
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

  if (not FTypesBySubscriber.TryGetValue(ASubscriber, LSubscribedEvents)) then
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
  if (not Assigned(LSubscriptions)) or (LSubscriptions.Count < 1) then
    Exit;
  LSize := LSubscriptions.Count;
  for I := LSize - 1 downto 0 do
  begin
    LSubscription := LSubscriptions[I];
    if (LSubscription.Subscriber.Equals(ASubscriber)) then
      LSubscription.Active := false;
    LSubscriptions.Delete(I);
  end;
end;

initialization

finalization

TEventBus.GetDefault.Free;

end.
