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
    procedure TestPostContextOnMainThread;
    [Test]
    procedure TestPostContextKOOnMainThread;
    [Test]
    procedure TestBackgroundPost;
    [Test]
    procedure TestBackgroundsPost;
    [Test]
    procedure TestPostEntityWithChildObject;
    [Test]
    procedure TestPostEntityWithItsSelfInChildObjectKO;
    [Test]
    procedure TestPostEntityWithItsSelfInChildObjectOkCustomCloningClass;
    [Test]
    procedure TestPostEntityWithCustomCloneEvent;
    [Test]
    procedure TestPostEntityWithObjectList;
    [Test]
    procedure TestRegisterAndFree;

  end;

implementation

uses EventBus, BOs, System.SyncObjs, System.SysUtils, System.Threading,
  System.Classes, System.Generics.Collections;

procedure TEventBusTest.TestSimplePost;
var
  LEvent: TEventBusEvent;
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriber(Subscriber);
  LEvent := TEventBusEvent.Create;
  LMsg := 'TestSimplePost';
  LEvent.Data := LMsg;
  GlobalEventBus.Post(LEvent);
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Data);
end;

procedure TEventBusTest.TestSimplePostOnBackgroundThread;
var
  LEvent: TEventBusEvent;
begin
  GlobalEventBus.RegisterSubscriber(Subscriber);
  LEvent := TEventBusEvent.Create;
  TTask.Run(
    procedure
    begin
      GlobalEventBus.Post(LEvent);
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
  GlobalEventBus.RegisterSubscriber(Subscriber);
  try
    Subscriber.Free;
    Subscriber := nil;
    GlobalEventBus.Post(TEventBusEvent.Create);
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
  GlobalEventBus.RegisterSubscriber(Subscriber);
  try
    GlobalEventBus.Unregister(Subscriber);
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
    GlobalEventBus.RegisterSubscriber(Subscriber);
    GlobalEventBus.RegisterSubscriber(LSubscriber);
    GlobalEventBus.Unregister(Subscriber);
    LEvent := TEventBusEvent.Create;
    LMsg := 'TestSimplePost';
    LEvent.Data := LMsg;
    GlobalEventBus.Post(LEvent);
    Assert.IsFalse(GlobalEventBus.IsRegistered(Subscriber));
    Assert.IsTrue(GlobalEventBus.IsRegistered(LSubscriber));
    Assert.AreEqual(LMsg, LSubscriber.LastEvent.Data);
  finally
    LSubscriber.Free;
  end;

end;

procedure TEventBusTest.TestBackgroundPost;
var
  LEvent: TBackgroundEvent;
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriber(Subscriber);
  LEvent := TBackgroundEvent.Create;
  LMsg := 'TestBackgroundPost';
  LEvent.Data := LMsg;
  GlobalEventBus.Post(LEvent);
  // attend for max 5 seconds
  Assert.IsTrue(TWaitResult.wrSignaled = Subscriber.Event.WaitFor(5000),
    'Timeout request');
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Data);
  Assert.AreNotEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestBackgroundsPost;
var
  LEvent: TBackgroundEvent;
  LMsg: string;
  I: Integer;
begin
  GlobalEventBus.RegisterSubscriber(Subscriber);
  for I := 0 to 10 do
  begin
    LEvent := TBackgroundEvent.Create;
    LMsg := 'TestBackgroundPost';
    LEvent.Data := LMsg;
    LEvent.Count := I;
    GlobalEventBus.Post(LEvent);
  end;
  // attend for max 2 seconds
  for I := 0 to 20 do
    TThread.Sleep(100);

  Assert.AreEqual(10, TBackgroundEvent(Subscriber.LastEvent).Count);
end;

procedure TEventBusTest.TestIsRegisteredFalseAfterUnregister;
begin
  GlobalEventBus.RegisterSubscriber(Subscriber);
  Assert.IsTrue(GlobalEventBus.IsRegistered(Subscriber));
end;

procedure TEventBusTest.TestIsRegisteredTrueAfterRegister;
begin
  GlobalEventBus.RegisterSubscriber(Subscriber);
  GlobalEventBus.Unregister(Subscriber);
  Assert.IsFalse(GlobalEventBus.IsRegistered(Subscriber));
end;

procedure TEventBusTest.TestPostContextKOOnMainThread;
var
  LEvent: TMainEvent;
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriber(Subscriber);
  LEvent := TMainEvent.Create;
  LMsg := 'TestPostOnMainThread';
  LEvent.Data := LMsg;
  GlobalEventBus.Post(LEvent, 'TestFoo');
  Assert.IsNull(Subscriber.LastEvent);
end;

procedure TEventBusTest.TestPostContextOnMainThread;
var
  LEvent: TMainEvent;
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriber(Subscriber);
  LEvent := TMainEvent.Create;
  LMsg := 'TestPostOnMainThread';
  LEvent.Data := LMsg;
  GlobalEventBus.Post(LEvent, 'TestCtx');
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Data);
  Assert.AreEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestPostEntityWithChildObject;
var
  LPerson: TPerson;
  LSubscriber: TPersonSubscriber;
begin
  LSubscriber := TPersonSubscriber.Create;
  try
    LSubscriber.ObjOwner := true;
    GlobalEventBus.RegisterSubscriber(LSubscriber);
    LPerson := TPerson.Create;
    LPerson.Firstname := 'Howard';
    LPerson.Lastname := 'Stark';
    LPerson.Child := TPerson.Create;
    LPerson.Child.Firstname := 'Tony';
    LPerson.Child.Lastname := 'Stark';
    GlobalEventBus.Post(TDEBEvent<TPerson>.Create(LPerson));
    Assert.AreEqual('Howard', LSubscriber.Person.Firstname);
    Assert.AreEqual('Tony', LSubscriber.Person.Child.Firstname);
  finally
    LSubscriber.Free;
  end;
end;

procedure TEventBusTest.TestPostEntityWithCustomCloneEvent;
var
  LPerson: TPerson;
  LSubscriber: TPersonSubscriber;
begin
  LSubscriber := TPersonSubscriber.Create;
  try
    LSubscriber.ObjOwner := true;
    GlobalEventBus.RegisterSubscriber(LSubscriber);
    LPerson := TPerson.Create;
    LPerson.Firstname := 'Howard';
    LPerson.Lastname := 'Stark';

    GlobalEventBus.OnCloneEvent := SimpleCustomClone;

    GlobalEventBus.Post(TDEBEvent<TPerson>.Create(LPerson));
    Assert.AreEqual('HowardCustom', LSubscriber.Person.Firstname);
    Assert.AreEqual('StarkCustom', LSubscriber.Person.Lastname);
  finally
    LSubscriber.Free;
    GlobalEventBus.OnCloneEvent := nil;
  end;
end;

procedure TEventBusTest.TestPostEntityWithItsSelfInChildObjectKO;
var
  LPerson: TPerson;
  LSubscriber: TPersonSubscriber;
begin
  LSubscriber := TPersonSubscriber.Create;
  try
    LSubscriber.ObjOwner := true;
    GlobalEventBus.RegisterSubscriber(LSubscriber);
    LPerson := TPerson.Create;
    LPerson.Firstname := 'Howard';
    LPerson.Lastname := 'Stark';
    Assert.WillRaiseWithMessage(
      procedure
      begin
        // simulate the stackoverflow exception, that should be generate by next codes
        raise Exception.Create('stackoverflow exception');
        // stackoverflow by TRTTIUtils.clone
        LPerson.Child := LPerson;
        GlobalEventBus.Post(TDEBEvent<TPerson>.Create(LPerson));
        Assert.AreEqual('Howard', LSubscriber.Person.Firstname);
        Assert.AreEqual('Tony', LSubscriber.Person.Child.Firstname);
      end, nil, 'stackoverflow exception');

  finally
    LSubscriber.Free;
    LPerson.Free;
  end;
end;

procedure TEventBusTest.
  TestPostEntityWithItsSelfInChildObjectOkCustomCloningClass;
var
  LPerson: TPerson;
  LSubscriber: TPersonSubscriber;
begin
  LSubscriber := TPersonSubscriber.Create;
  try
    GlobalEventBus.AddCustomClassCloning
      ('EventBus.Commons.TDEBEvent<BOs.TPerson>',
      function(AObject: TObject): TObject
      var
        LEvent: TDEBEvent<TPerson>;
      begin
        LEvent := TDEBEvent<TPerson>.Create;
        LEvent.DataOwner := (AObject as TDEBEvent<TPerson>).DataOwner;
        LEvent.Data := TPerson.Create;
        LEvent.Data.Firstname := (AObject as TDEBEvent<TPerson>).Data.Firstname;
        LEvent.Data.Lastname := (AObject as TDEBEvent<TPerson>).Data.Lastname;
        LEvent.Data.Child := TPerson.Create;
        LEvent.Data.Child.Firstname := (AObject as TDEBEvent<TPerson>)
          .Data.Child.Firstname;
        LEvent.Data.Child.Lastname := (AObject as TDEBEvent<TPerson>)
          .Data.Child.Lastname;
        Result := LEvent;
      end);
    LSubscriber.ObjOwner := true;
    GlobalEventBus.RegisterSubscriber(LSubscriber);
    LPerson := TPerson.Create;
    LPerson.Firstname := 'Howard';
    LPerson.Lastname := 'Stark';
    LPerson.Child := LPerson;
    GlobalEventBus.Post(TDEBEvent<TPerson>.Create(LPerson));
    Assert.AreEqual('Howard', LSubscriber.Person.Firstname);
    Assert.AreEqual('Howard', LSubscriber.Person.Child.Firstname);

  finally
    GlobalEventBus.RemoveCustomClassCloning
      ('EventBus.Commons.TDEBEvent<BOs.TPerson>');
    LSubscriber.Free;
  end;
end;

procedure TEventBusTest.TestPostEntityWithObjectList;
var
  LPerson: TPerson;
  LSubscriber: TPersonListSubscriber;
  LList: TObjectList<TPerson>;
begin
  LSubscriber := TPersonListSubscriber.Create;
  try
    GlobalEventBus.RegisterSubscriber(LSubscriber);
    LList := TObjectList<TPerson>.Create;
    LPerson := TPerson.Create;
    LPerson.Firstname := 'Howard';
    LPerson.Lastname := 'Stark';
    LList.Add(LPerson);
    LPerson := TPerson.Create;
    LPerson.Firstname := 'Tony';
    LPerson.Lastname := 'Stark';
    LList.Add(LPerson);
    // stackoverflow by TRTTIUtils.clone
    // LPerson.Child := LPerson;
    GlobalEventBus.Post(TDEBEvent < TObjectList < TPerson >> .Create(LList));
    Assert.AreEqual(2, LSubscriber.PersonList.Count);
    LSubscriber.PersonList.Free;
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
  GlobalEventBus.RegisterSubscriber(Subscriber);
  LEvent := TMainEvent.Create;
  LMsg := 'TestPostOnMainThread';
  LEvent.Data := LMsg;
  GlobalEventBus.Post(LEvent);
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Data);
  Assert.AreEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestAsyncPost;
var
  LEvent: TAsyncEvent;
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriber(Subscriber);
  LEvent := TAsyncEvent.Create;
  LMsg := 'TestAsyncPost';
  LEvent.Data := LMsg;
  GlobalEventBus.Post(LEvent);
  // attend for max 5 seconds
  Assert.IsTrue(TWaitResult.wrSignaled = Subscriber.Event.WaitFor(5000),
    'Timeout request');
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Data);
  Assert.AreNotEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

initialization

TDUnitX.RegisterTestFixture(TEventBusTest);

end.
