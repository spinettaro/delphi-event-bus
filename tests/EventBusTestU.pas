unit EventBusTestU;

interface

uses
  DUnitX.TestFramework, BaseTestU;

type

  [TestFixture]
  TEventBusTest = class(TBaseTest)
  public
    [Test]
    procedure TestRegisterUnregisterEvents;
    [Test]
    procedure TestIsRegisteredTrueAfterRegisterEvents;
    [Test]
    procedure TestIsRegisteredFalseAfterUnregisterEvents;
    [Test]
    procedure TestRegisterUnregisterMultipleSubscriberEvents;

    [Test]
    procedure TestRegisterUnregisterChannels;
    [Test]
    procedure TestIsRegisteredTrueAfterRegisterChannels;
    [Test]
    procedure TestIsRegisteredFalseAfterUnregisterChannels;
    [Test]
    procedure TestRegisterUnregisterMultipleSubscriberChannels;

    [Test]
    procedure TestSimplePost;
    [Test]
    procedure TestSimplePostOnBackgroundThread;
    [Test]
    procedure TestAsyncPost;
    [Test]
    procedure TestPostOnMainThread;

    [Test]
    procedure TestSimplePostChannel;
    [Test]
    procedure TestSimplePostChannelOnBackgroundThread;
    [Test]
    procedure TestAsyncPostChannel;
    [Test]
    procedure TestPostChannelOnMainThread;
    [Test]
    procedure TestBackgroundPostChannel;
    [Test]
    procedure TestBackgroundsPostChannel;

    [Test]
    procedure TestPostContextOnMainThread;
    [Test]
    procedure TestPostContextKOOnMainThread;
    [Test]
    procedure TestRegisterNewContext;
    [Test]
    procedure TestBackgroundPost;
    [Test]
    procedure TestBackgroundsPost;

    [Test]
    procedure TestPostEntityWithChildObject;
    [Test]
    procedure TestPostEntityWithItsSelfInChildObject;
    [Test]
    procedure TestPostEntityWithObjectList;
    [Test]
    procedure TestRegisterAndFree;

    [Test]
    procedure TestEmptySubscriber;
    [Test]
    procedure TestInvalidArgTypeSubscriber;
    [Test]
    procedure TestInvalidArgNumberSubscriber;
  end;

implementation

uses
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.SysUtils,
  System.Threading,
  BOs,
  EventBus;

procedure TEventBusTest.TestSimplePost;
var
  LEvent: IEventBusEvent;
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  LEvent := TEventBusEvent.Create;
  LMsg := 'TestSimplePost';
  LEvent.Data := LMsg;

  GlobalEventBus.Post(LEvent);
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Data);
end;

procedure TEventBusTest.TestSimplePostChannel;
var
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);
  LMsg := 'TestSimplePost';
  GlobalEventBus.Post('test_channel', 'TestSimplePost');
  Assert.AreEqual(LMsg, ChannelSubscriber.LastChannelMsg);
end;

procedure TEventBusTest.TestSimplePostChannelOnBackgroundThread;
begin
  GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);

  TTask.Run(
    procedure
    begin
      GlobalEventBus.Post('test_channel', 'TestSimplePost');
    end);

  // attend for max 5 seconds
  Assert.IsTrue(TWaitResult.wrSignaled = ChannelSubscriber.Event.WaitFor(5000), 'Timeout request');
  Assert.AreNotEqual(MainThreadID, ChannelSubscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestSimplePostOnBackgroundThread;
var
  LEvent: IEventBusEvent;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  LEvent := TEventBusEvent.Create;

  TTask.Run(
    procedure
    begin
      GlobalEventBus.Post(LEvent);
    end);

  // attend for max 5 seconds
  Assert.IsTrue(TWaitResult.wrSignaled = Subscriber.Event.WaitFor(5000), 'Timeout request');
  Assert.AreNotEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestRegisterAndFree;
var
  LRaisedException: Boolean;
begin
  LRaisedException := False;
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);

  try
    Subscriber.Free;
    Subscriber := nil;
    GlobalEventBus.Post(TEventBusEvent.Create);
  except
    on E: Exception do LRaisedException := True;
  end;

  Assert.IsFalse(LRaisedException);
end;

procedure TEventBusTest.TestRegisterNewContext;
var
  LEvent: IMainEvent;
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  LEvent := TMainEvent.Create;
  LMsg := 'TestPostOnMainThread';
  LEvent.Data := LMsg;
  GlobalEventBus.RegisterNewContext( Subscriber, LEvent, 'TestCtx', 'MyNewContext');

  GlobalEventBus.Post(LEvent, 'TestCtx');
  Assert.IsNull( Subscriber.LastEvent);

  GlobalEventBus.Post(LEvent, 'MyNewContext');
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Data);
  Assert.AreEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestRegisterUnregisterChannels;
var
  LRaisedException: Boolean;
begin
  LRaisedException := False;
  GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);

  try
    GlobalEventBus.UnregisterForChannels(ChannelSubscriber);
  except
    on E: Exception do LRaisedException := True;
  end;

  Assert.IsFalse(LRaisedException);
end;

procedure TEventBusTest.TestRegisterUnregisterEvents;
var
  LRaisedException: Boolean;
begin
  LRaisedException := False;
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);

  try
    GlobalEventBus.UnregisterForEvents(Subscriber);
  except
    on E: Exception do LRaisedException := True;
  end;

  Assert.IsFalse(LRaisedException);
end;

procedure TEventBusTest.TestRegisterUnregisterMultipleSubscriberChannels;
var
  LChannelSubscriber: TChannelSubscriber;
  LMsg: string;
begin
  LChannelSubscriber := TChannelSubscriber.Create;
  try
    GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);
    GlobalEventBus.RegisterSubscriberForChannels(LChannelSubscriber);
    GlobalEventBus.UnregisterForChannels(ChannelSubscriber);
    LMsg := 'TestSimplePost';
    GlobalEventBus.Post('test_channel', LMsg);
    Assert.IsFalse(GlobalEventBus.IsRegisteredForChannels(ChannelSubscriber));
    Assert.IsTrue(GlobalEventBus.IsRegisteredForChannels(LChannelSubscriber));
    Assert.AreEqual(LMsg, LChannelSubscriber.LastChannelMsg);
  finally
    LChannelSubscriber.Free;
  end;
end;

procedure TEventBusTest.TestRegisterUnregisterMultipleSubscriberEvents;
var
  LSubscriber: TSubscriberCopy;
  LEvent: IEventBusEvent;
  LMsg: string;
begin
  LSubscriber := TSubscriberCopy.Create;
  try
    GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
    GlobalEventBus.RegisterSubscriberForEvents(LSubscriber);
    GlobalEventBus.UnregisterForEvents(Subscriber);
    LEvent := TEventBusEvent.Create;
    LMsg := 'TestSimplePost';
    LEvent.Data := LMsg;
    GlobalEventBus.Post(LEvent);
    Assert.IsFalse(GlobalEventBus.IsRegisteredForEvents(Subscriber));
    Assert.IsTrue(GlobalEventBus.IsRegisteredForEvents(LSubscriber));
    Assert.AreEqual(LMsg, LSubscriber.LastEvent.Data);
  finally
    LSubscriber.Free;
  end;
end;

procedure TEventBusTest.TestAsyncPostChannel;
var
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);
  LMsg := 'TestAsyncPost';
  GlobalEventBus.Post('test_channel_async', LMsg);
  // attend for max 5 seconds
  Assert.IsTrue(TWaitResult.wrSignaled = ChannelSubscriber.Event.WaitFor(5000), 'Timeout request');
  Assert.AreEqual(LMsg, ChannelSubscriber.LastChannelMsg);
  Assert.AreNotEqual(MainThreadID, ChannelSubscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestBackgroundPost;
var
  LEvent: IBackgroundEvent;
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  LEvent := TBackgroundEvent.Create;
  LMsg := 'TestBackgroundPost';
  LEvent.Data := LMsg;
  GlobalEventBus.Post(LEvent);
  // attend for max 5 seconds
  Assert.IsTrue(TWaitResult.wrSignaled = Subscriber.Event.WaitFor(5000), 'Timeout request');
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Data);
  Assert.AreNotEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestBackgroundPostChannel;
var
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);
  LMsg := 'TestBackgroundPost';
  GlobalEventBus.Post('test_channel_bkg', LMSG);
  // attend for max 5 seconds
  Assert.IsTrue(TWaitResult.wrSignaled = ChannelSubscriber.Event.WaitFor(5000), 'Timeout request');
  Assert.AreEqual(LMsg, ChannelSubscriber.LastChannelMsg);
  Assert.AreNotEqual(MainThreadID, ChannelSubscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestBackgroundsPost;
var
  LEvent: IBackgroundEvent;
  LMsg: string;
  I: Integer;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);

  for I := 1 to 10 do begin
    LEvent := TBackgroundEvent.Create;
    LMsg := 'TestBackgroundPost';
    LEvent.Data := LMsg;
    LEvent.SequenceID := I;
    GlobalEventBus.Post(LEvent);
  end;

  for I := 0 to 50 do TThread.Sleep(10);
  Assert.AreEqual(10, Subscriber.Count);
end;

procedure TEventBusTest.TestBackgroundsPostChannel;
var
  LMsg: string;
  I: Integer;
begin
  GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);

  for I := 1 to 10 do begin
    LMsg := Format('TestBackgroundPost%d',[I]);
    GlobalEventBus.Post('test_channel_bkg', LMsg);
  end;

  for I := 0 to 50 do TThread.Sleep(10);
  Assert.AreEqual(10, ChannelSubscriber.Count);
end;

procedure TEventBusTest.TestIsRegisteredFalseAfterUnregisterChannels;
begin
  GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);
  Assert.IsTrue(GlobalEventBus.IsRegisteredForChannels(ChannelSubscriber));
end;

procedure TEventBusTest.TestIsRegisteredFalseAfterUnregisterEvents;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  Assert.IsTrue(GlobalEventBus.IsRegisteredForEvents(Subscriber));
end;

procedure TEventBusTest.TestIsRegisteredTrueAfterRegisterChannels;
begin
  GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);
  GlobalEventBus.UnregisterForChannels(ChannelSubscriber);
  Assert.IsFalse(GlobalEventBus.IsRegisteredForChannels(ChannelSubscriber));
end;

procedure TEventBusTest.TestIsRegisteredTrueAfterRegisterEvents;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  GlobalEventBus.UnregisterForEvents(Subscriber);
  Assert.IsFalse(GlobalEventBus.IsRegisteredForEvents(Subscriber));
end;

procedure TEventBusTest.TestPostChannelOnMainThread;
var
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForChannels(ChannelSubscriber);
  LMsg := 'TestPostOnMainThread';
  GlobalEventBus.Post('test_channel', LMsg);
  Assert.AreEqual(LMsg, ChannelSubscriber.LastChannelMsg);
  Assert.AreEqual(MainThreadID, ChannelSubscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestPostContextKOOnMainThread;
var
  LEvent: IMainEvent;
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  LEvent := TMainEvent.Create;
  LMsg := 'TestPostOnMainThread';
  LEvent.Data := LMsg;
  GlobalEventBus.Post(LEvent, 'TestFoo');
  Assert.IsNull(Subscriber.LastEvent);
end;

procedure TEventBusTest.TestPostContextOnMainThread;
var
  LEvent: IMainEvent;
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
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
  LEvent: IDEBEvent<TPerson>;
begin
  LSubscriber := TPersonSubscriber.Create;
  try
    LSubscriber.OwnsObject:= True;
    GlobalEventBus.RegisterSubscriberForEvents(LSubscriber);
    LPerson := TPerson.Create;
    LPerson.Firstname := 'Howard';
    LPerson.Lastname := 'Stark';
    LPerson.Child := TPerson.Create;
    LPerson.Child.Firstname := 'Tony';
    LPerson.Child.Lastname := 'Stark';
    LEvent:= TDEBEvent<TPerson>.Create(LPerson);
    GlobalEventBus.Post( LEvent);
    Assert.AreEqual('Howard', LSubscriber.Person.Firstname);
    Assert.AreEqual('Tony', LSubscriber.Person.Child.Firstname);
  finally
    LSubscriber.Free;
  end;
end;

procedure TEventBusTest.TestPostEntityWithItsSelfInChildObject;
var
  LPerson: TPerson;
  LSubscriber: TPersonSubscriber;
  LEvent: IDEBEvent<TPerson>;
begin
  LSubscriber := TPersonSubscriber.Create;
  try
    LSubscriber.OwnsObject := True;
    GlobalEventBus.RegisterSubscriberForEvents(LSubscriber);
    LPerson := TPerson.Create;
    LPerson.Firstname := 'Howard';
    LPerson.Lastname := 'Stark';
    LPerson.Child := LPerson;
    LEvent:= TDEBEvent<TPerson>.Create(LPerson);
    GlobalEventBus.Post(LEvent);
    Assert.AreEqual('Howard', LSubscriber.Person.Firstname);
    Assert.AreEqual('Howard', LSubscriber.Person.Child.Firstname);
  finally
    LSubscriber.Free;
  end;
end;

procedure TEventBusTest.TestPostEntityWithObjectList;
var
  LPerson: TPerson;
  LSubscriber: TPersonListSubscriber;
  LList: TObjectList<TPerson>;
  LEvent: IDEBEvent < TObjectList < TPerson >>;
begin
  LSubscriber := TPersonListSubscriber.Create;
  try
    GlobalEventBus.RegisterSubscriberForEvents(LSubscriber);
    LList := TObjectList<TPerson>.Create;
    LPerson := TPerson.Create;
    LPerson.Firstname := 'Howard';
    LPerson.Lastname := 'Stark';
    LList.Add(LPerson);
    LPerson := TPerson.Create;
    LPerson.Firstname := 'Tony';
    LPerson.Lastname := 'Stark';
    LList.Add(LPerson);
    LEvent:= TDEBEvent < TObjectList < TPerson >> .Create(LList);
    GlobalEventBus.Post(LEvent);
    Assert.AreEqual(2, LSubscriber.PersonList.Count);
    LSubscriber.PersonList.Free;
  finally
    LSubscriber.Free;
  end;
end;

procedure TEventBusTest.TestPostOnMainThread;
var
  LEvent: IMainEvent;
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  LEvent := TMainEvent.Create;
  LMsg := 'TestPostOnMainThread';
  LEvent.Data := LMsg;
  GlobalEventBus.Post(LEvent);
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Data);
  Assert.AreEqual(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TEventBusTest.TestAsyncPost;
var
  LEvent: IAsyncEvent;
  LMsg: string;
begin
  GlobalEventBus.RegisterSubscriberForEvents(Subscriber);
  LEvent := TAsyncEvent.Create;
  LMsg := 'TestAsyncPost';
  LEvent.Data := LMsg;
  GlobalEventBus.Post(LEvent);
  // attend for max 5 seconds
  Assert.IsTrue(TWaitResult.wrSignaled = Subscriber.Event.WaitFor(5000), 'Timeout request');
  Assert.AreEqual(LMsg, Subscriber.LastEvent.Data);
  Assert.AreNotEqual(MainThreadID, Subscriber.LastEventThreadID);
end;


procedure TEventBusTest.TestEmptySubscriber;
var
  LSubscriber: TEmptySubscriber;
begin
  LSubscriber := TEmptySubscriber.Create;

  Assert.WillRaise(
    procedure begin
      GlobalEventBus.RegisterSubscriberForEvents(LSubscriber);
    end
    ,
    EObjectHasNoSubscriberMethods
    ,
    'Empty subscriber methods for Events');

  Assert.WillRaise(
    procedure begin
      GlobalEventBus.RegisterSubscriberForChannels(LSubscriber);
    end
    ,
    EObjectHasNoSubscriberMethods
    ,
    'Empty subscriber methods for Channels');

  LSubscriber.Free;
end;

procedure TEventBusTest.TestInvalidArgNumberSubscriber;
var
  LSubscriber: TInvalidArgNumSubscriber;
begin
  LSubscriber := TInvalidArgNumSubscriber.Create;

  Assert.WillRaise(
    procedure begin
      GlobalEventBus.RegisterSubscriberForEvents(LSubscriber);
    end
    ,
    EInvalidSubscriberMethod
    ,
    'Invalid subscriber method argument number');

  Assert.WillRaise(
    procedure begin
      GlobalEventBus.RegisterSubscriberForChannels(LSubscriber);
    end
    ,
    EInvalidSubscriberMethod
    ,
    'Invalid subscriber method argument number');

  LSubscriber.Free;
end;

procedure TEventBusTest.TestInvalidArgTypeSubscriber;
var
  LSubscriber: TInvalidArgTypeSubscriber;
begin
  LSubscriber := TInvalidArgTypeSubscriber.Create;

  Assert.WillRaise(
    procedure begin
      GlobalEventBus.RegisterSubscriberForEvents(LSubscriber);
    end
    ,
    EInvalidSubscriberMethod
    ,
    'Invalid subscriber method argument type');

  Assert.WillRaise(
    procedure begin
      GlobalEventBus.RegisterSubscriberForChannels(LSubscriber);
    end
    ,
    EInvalidSubscriberMethod
    ,
    'Invalid subscriber method argument type');

  LSubscriber.Free;
end;

initialization
  TDUnitX.RegisterTestFixture(TEventBusTest);

end.
