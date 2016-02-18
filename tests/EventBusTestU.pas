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
    procedure TestSimplePost;
    [Test]
    procedure TestAsyncPost;
    [Test]
    procedure TestPostOnMainThread;
  end;

implementation

uses EventBus, BOs, System.SyncObjs, System.SysUtils;

procedure TEventBusTest.TestSimplePost;
var
  LEvent: TEventBusEvent;
  LMsg: string;
begin
  Subscriber := TSubscriber.Create;
  try
    TEventBus.GetDefault.RegisterSubscriber(Subscriber);
    LEvent := TEventBusEvent.Create;
    try
      LMsg := 'TestSimplePost';
      LEvent.Msg := LMsg;
      TEventBus.GetDefault.Post(LEvent);
      Assert.AreEqual(LMsg, Subscriber.LastEvent.Msg);
    finally
      LEvent.Free;
    end;
  finally
    // Subscriber.Free;
  end;
end;

procedure TEventBusTest.TestAsyncPost;
var
  LEvent: TAsyncEvent;
  LMsg: string;
  LEvt: TEvent;
begin
  Subscriber := TSubscriber.Create;
  try
    TEventBus.GetDefault.RegisterSubscriber(Subscriber);
    LEvent := TAsyncEvent.Create;
    try
      LMsg := 'TestAsyncPost';
      LEvent.Msg := LMsg;
      LEvt := TEvent.Create;
      try
        LEvent.Event := LEvt;
        TEventBus.GetDefault.Post(LEvent);
        // attend for max 5 seconds
        Assert.IsTrue(TWaitResult.wrSignaled = LEvt.WaitFor(5000),
          'Timeout request');
        Assert.AreEqual(LMsg, Subscriber.LastEvent.Msg);
        Assert.AreNotEqual(MainThreadID, Subscriber.LastEventThreadID);
      finally
        LEvt.Free;
      end;
    finally
      LEvent.Free;
    end;
  finally
    // Subscriber.Free;
  end;
end;

procedure TEventBusTest.TestPostOnMainThread;
var
  LEvent: TMainEvent;
  LMsg: string;
begin
  Subscriber := TSubscriber.Create;
  try
    TEventBus.GetDefault.RegisterSubscriber(Subscriber);
    LEvent := TMainEvent.Create;
    try
      LMsg := 'TestPostOnMainThread';
      LEvent.Msg := LMsg;
      TEventBus.GetDefault.Post(LEvent);
      Assert.AreEqual(LMsg, Subscriber.LastEvent.Msg);
      Assert.AreEqual(MainThreadID, Subscriber.LastEventThreadID);
    finally
      LEvent.Free;
    end;
  finally
    // Subscriber.Free;
  end;
end;

procedure TEventBusTest.TestRegisterUnregister;
var
  LRaisedException: Boolean;
begin
  LRaisedException := false;
  Subscriber := TSubscriber.Create;
  try
    TEventBus.GetDefault.RegisterSubscriber(Subscriber);
    try
      TEventBus.GetDefault.Unregister(Subscriber);
    except
      on E: Exception do
        LRaisedException := true;
    end;
    Assert.IsFalse(LRaisedException);
  finally
    // Subscriber.Free;
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TEventBusTest);

end.
