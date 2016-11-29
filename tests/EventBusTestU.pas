unit EventBusTestU;

interface

uses
  DUnitX.TestFramework, BaseTestU;

type

  [TestFixture]
  TEventBusTest = class(TBaseTest)
  public
    [Test]
    procedure TestRegisterUnregister;
    [Test]
    procedure TestIsRegisteredTrueAfterRegister;
    [Test]
    procedure TestIsRegisteredFalseAfterUnregister;
    [Test]
    procedure TestRegisterUnregisterMultipleSubscriber;
    [Test]
    procedure TestSimplePost;
    [Test]
    procedure TestSimplePostOnBackgroundThread;
    [Test]
    procedure TestAsyncPost;
    [Test]
    procedure TestPostOnMainThread;
    [Test]
    procedure TestBackgroundPost;
    [Test]
    procedure TestBackgroundsPost;
    [Test]
    procedure TestPostEntityWithChildObject;
    [Test]
    procedure TestRegisterAndFree;

  end;

implementation

uses EventBus, BOs, System.SyncObjs, System.SysUtils, System.Threading,
  System.Classes;

procedure TEventBusTest.TestSimplePost;
var
  LEvent: TEventBusEvent;
  LMsg: string;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  LEvent := TEventBusEvent.Create;
  LMsg := 'TestSimplePost';
  LEvent.Msg := LMsg;
  TEventBus.GetDefault.Post(LEvent);
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Msg);
end;

procedure TEventBusTest.TestSimplePostOnBackgroundThread;
var
  LEvent: TEventBusEvent;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  LEvent := TEventBusEvent.Create;
  TTask.Run(
    procedure
    begin
      TEventBus.GetDefault.Post(LEvent);
    end);
  // attend for max 5 seconds
  Assert.IsTrue(TWaitResult.wrSignaled = Subscriber.Event.WaitFor(5000),
    'Timeout request');
  Assert.AreNotEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestRegisterAndFree;
var
  LRaisedException: Boolean;
begin
  LRaisedException := false;
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  try
    Subscriber.Free;
    Subscriber := nil;
    TEventBus.GetDefault.Post(TEventBusEvent.Create);
  except
    on E: Exception do
      LRaisedException := true;
  end;
  Assert.IsFalse(LRaisedException);
end;

procedure TEventBusTest.TestRegisterUnregister;
var
  LRaisedException: Boolean;
begin
  LRaisedException := false;
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  try
    TEventBus.GetDefault.Unregister(Subscriber);
  except
    on E: Exception do
      LRaisedException := true;
  end;
  Assert.IsFalse(LRaisedException);
end;

procedure TEventBusTest.TestRegisterUnregisterMultipleSubscriber;
var
  LSubscriber: TSubscriberCopy;
  LEvent: TEventBusEvent;
  LMsg: string;
begin
  LSubscriber := TSubscriberCopy.Create;
  try
    TEventBus.GetDefault.RegisterSubscriber(Subscriber);
    TEventBus.GetDefault.RegisterSubscriber(LSubscriber);
    TEventBus.GetDefault.Unregister(Subscriber);
    LEvent := TEventBusEvent.Create;
    LMsg := 'TestSimplePost';
    LEvent.Msg := LMsg;
    TEventBus.GetDefault.Post(LEvent);
    Assert.IsFalse(TEventBus.GetDefault.IsRegistered(Subscriber));
    Assert.IsTrue(TEventBus.GetDefault.IsRegistered(LSubscriber));
    Assert.AreEqual(LMsg, LSubscriber.LastEvent.Msg);
  finally
    LSubscriber.Free;
  end;

end;

procedure TEventBusTest.TestBackgroundPost;
var
  LEvent: TBackgroundEvent;
  LMsg: string;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  LEvent := TBackgroundEvent.Create;
  LMsg := 'TestBackgroundPost';
  LEvent.Msg := LMsg;
  TEventBus.GetDefault.Post(LEvent);
  // attend for max 5 seconds
  Assert.IsTrue(TWaitResult.wrSignaled = Subscriber.Event.WaitFor(5000),
    'Timeout request');
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Msg);
  Assert.AreNotEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestBackgroundsPost;
var
  LEvent: TBackgroundEvent;
  LMsg: string;
  I: Integer;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  for I := 0 to 10 do
  begin
    LEvent := TBackgroundEvent.Create;
    LMsg := 'TestBackgroundPost';
    LEvent.Msg := LMsg;
    LEvent.Count := I;
    TEventBus.GetDefault.Post(LEvent);
  end;
  // attend for max 2 seconds
  for I := 0 to 20 do
    TThread.Sleep(100);

  Assert.AreEqual(10, TBackgroundEvent(Subscriber.LastEvent).Count);
end;

procedure TEventBusTest.TestIsRegisteredFalseAfterUnregister;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  Assert.IsTrue(TEventBus.GetDefault.IsRegistered(Subscriber));
end;

procedure TEventBusTest.TestIsRegisteredTrueAfterRegister;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  TEventBus.GetDefault.Unregister(Subscriber);
  Assert.IsFalse(TEventBus.GetDefault.IsRegistered(Subscriber));
end;

procedure TEventBusTest.TestPostEntityWithChildObject;
var
  LPerson: TPerson;
  LSubscriber: TPersonSubscriber;
begin
  LSubscriber := TPersonSubscriber.Create;
  try
    TEventBus.GetDefault.RegisterSubscriber(LSubscriber);
    LPerson := TPerson.Create;
    LPerson.Firstname := 'Howard';
    LPerson.Lastname := 'Stark';
    // LPerson.Child := LPerson;
    TEventBus.GetDefault.Post(LPerson);
    Assert.AreEqual('Howard', LSubscriber.Person.Firstname);
    // Assert.AreEqual('Tony', LSubscriber.Person.Child.Firstname);
  finally
    LSubscriber.Free;
  end;
end;

procedure TEventBusTest.TestPostOnMainThread;
var
  LEvent: TMainEvent;
  LMsg: string;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  LEvent := TMainEvent.Create;
  LMsg := 'TestPostOnMainThread';
  LEvent.Msg := LMsg;
  TEventBus.GetDefault.Post(LEvent);
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Msg);
  Assert.AreEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestAsyncPost;
var
  LEvent: TAsyncEvent;
  LMsg: string;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  LEvent := TAsyncEvent.Create;
  LMsg := 'TestAsyncPost';
  LEvent.Msg := LMsg;
  TEventBus.GetDefault.Post(LEvent);
  // attend for max 5 seconds
  Assert.IsTrue(TWaitResult.wrSignaled = Subscriber.Event.WaitFor(5000),
    'Timeout request');
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Msg);
  Assert.AreNotEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

initialization

TDUnitX.RegisterTestFixture(TEventBusTest);

end.
