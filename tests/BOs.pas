unit BOs;

interface

uses
  System.Generics.Collections, System.SyncObjs, EventBus;

type
  TPerson = class(TObject)
  private
    FChild: TPerson;
    FFirstname: string;
    FLastname: string;
    procedure Set_Child(const AValue: TPerson);
    procedure Set_Firstname(const AValue: string);
    procedure Set_Lastname(const AValue: string);
  public
    destructor Destroy; override;
    property Child: TPerson read FChild write Set_Child;
    property Firstname: string read FFirstname write Set_Firstname;
    property Lastname: string read FLastname write Set_Lastname;
  end;

  IEventBusEvent = IDEBEvent<string>;

  TEventBusEvent = class(TDEBEvent<string>);

  IMainEvent = interface(IEventBusEvent)
  ['{68F192C1-1F0F-41CE-85FD-0146C2301A4E}']
  end;

  TMainEvent = class(TDEBEvent<string>, IMainEvent);

  IAsyncEvent = Interface(IEventBusEvent)
  ['{68F192C1-1F0F-41CE-85FD-0146C2301A4E}']
  end;

  TAsyncEvent = class(TDEBEvent<string>, IAsyncEvent);

  IBackgroundEvent = Interface(IEventBusEvent)
  ['{E70B43F0-7F68-47B9-AFF3-5878A0B1A88D}']
    procedure Set_SequenceID(const AValue: Integer);
    function Get_SequenceID: Integer;
    property SequenceID: Integer read Get_SequenceID write Set_SequenceID;
  end;

  TBackgroundEvent = class(TDEBEvent<string>, IBackgroundEvent)
  private
    FSequenceID: Integer;
    function Get_SequenceID: Integer;
    procedure Set_SequenceID(const AValue: Integer);
  public
    property SequenceID: Integer read Get_SequenceID write Set_SequenceID;
  public
  end;

  TBaseSubscriber = class(TObject)
  private
    FChannelMsg: string;
    FEvent: TEvent; // Wrapper of Win32 Set_Event with automic Set_/Reset, no need for thread protection.
    FCount: Integer;
    FEventMsg: string;
    FLastEvent: IEventBusEvent;
    FLastEventThreadID: Cardinal;
    procedure Set_LastChannelMsg(const AValue: string);
    procedure Set_LastEvent(const AValue: IEventBusEvent);
    procedure Set_LastEventMsg(const AValue: string);
    procedure Set_LastEventThreadID(const AValue: Cardinal);
  public
    constructor Create;
    destructor Destroy; override;

    procedure IncrementCount;

    property Event: TEvent read FEvent; // Readonly is good enough
    property Count: Integer read FCount;
    property LastEvent: IEventBusEvent read FLastEvent write Set_LastEvent;
    property LastChannelMsg: string read FChannelMsg write Set_LastChannelMsg;
    property LastEventMsg: string read FEventMsg write Set_LastEventMsg;
    property LastEventThreadID: Cardinal read FLastEventThreadID write Set_LastEventThreadID;
  end;

  TSubscriber = class(TBaseSubscriber)
    [Subscribe]
    procedure OnSimpleEvent(AEvent: IEventBusEvent);

    [Subscribe(TThreadMode.Async)]
    procedure OnSimpleAsyncEvent(AEvent: IAsyncEvent);

    [Subscribe(TThreadMode.Main)]
    procedure OnSimpleMainEvent(AEvent: IMainEvent);

    [Subscribe(TThreadMode.Background)]
    procedure OnSimpleBackgroundEvent(AEvent: IBackgroundEvent);

    [Subscribe(TThreadMode.Main, 'TestCtx')]
    procedure OnSimpleContextEvent(AEvent: IMainEvent);
  end;

  TChannelSubscriber = class(TBaseSubscriber)
    [Channel('test_channel')]
    procedure OnSimpleChannel(AMsg: string);

    [Channel('test_channel_async', TThreadMode.Async)]
    procedure OnSimpleAsyncChannel(AMsg: string);

    [Channel('test_channel_main', TThreadMode.Main)]
    procedure OnSimpleMainChannel(AMsg: string);

    [Channel('test_channel_bkg', TThreadMode.Background)]
    procedure OnSimpleBackgroundChannel(AMsg: string);
  end;

  TSubscriberCopy = class(TBaseSubscriber)
    [Subscribe]
    procedure OnSimpleEvent(AEvent: IEventBusEvent);
  end;

  TPersonSubscriber = class(TBaseSubscriber)
  private
    FPerson: TPerson;
    FOwnsObject: Boolean;
    procedure Set_OwnsObject(const AValue: Boolean);
    procedure Set_Person(const AValue: TPerson);
  public
    constructor Create;
    destructor Destroy; override;

    [Subscribe]
    procedure OnPersonEvent(AEvent: IDEBEvent<TPerson>);

    property OwnsObject: Boolean read FOwnsObject write Set_OwnsObject;
    property Person: TPerson read FPerson write Set_Person;
  end;

  TPersonListSubscriber = class(TBaseSubscriber)
  private
    FPersonList: TObjectList<TPerson>;
    procedure Set_PersonList(const AValue: TObjectList<TPerson>);
  public
    [Subscribe]
    procedure OnPersonListEvent(AEvent: IDEBEvent<TObjectList<TPerson>>);

    property PersonList: TObjectList<TPerson> read FPersonList write Set_PersonList;
  end;

  TEmptySubscriber = class

  end;


  TInvalidArgNumSubscriber = class
  public
    [Subscribe]
    procedure OnEvent(AEvent: IEventBusEvent; AExtraArg: Integer);

    [Channel('Test')]
    procedure OnChannelMessage(const AMesage: string; AExtraArg: Integer);
  end;

  TInvalidArgTypeSubscriber = class
  public
    [Subscribe]
    procedure OnEvent(AEvent: Integer);

    [Channel('Test')]
    procedure OnChannelMessage(const AMesage: Integer);
  end;

implementation

uses
  System.Classes;

constructor TBaseSubscriber.Create;
begin
  inherited Create;
  FEvent := TEvent.Create;
  FCount := 0;
end;

destructor TBaseSubscriber.Destroy;
begin
  GlobalEventBus.UnregisterForEvents(Self);
  GlobalEventBus.UnregisterForChannels(Self);
  FEvent.Free;
  inherited;
end;

procedure TBaseSubscriber.IncrementCount;
begin
  AtomicIncrement(FCount);
end;

procedure TBaseSubscriber.Set_LastEvent(const AValue: IEventBusEvent);
begin
  TMonitor.Enter(Self); // Need to protect from multithread write (for the Background/Async events testing)
  FLastEvent := AValue;
  TMonitor.Exit(Self);
end;

procedure TBaseSubscriber.Set_LastEventThreadID(const AValue: Cardinal);
begin
  TMonitor.Enter(Self); // Need to protect from multithread write (for the Background/Async events testing)
  FLastEventThreadID := AValue;
  TMonitor.Exit(Self);
end;

procedure TBaseSubscriber.Set_LastChannelMsg(const AValue: string);
begin
  TMonitor.Enter(Self);
  FChannelMsg := AValue;
  TMonitor.Exit(Self);
end;

procedure TBaseSubscriber.Set_LastEventMsg(const AValue: string);
begin
  TMonitor.Enter(Self);
  FEventMsg := AValue;
  TMonitor.Exit(Self);
end;

procedure TSubscriber.OnSimpleAsyncEvent(AEvent: IAsyncEvent);
begin
  LastEvent := AEvent;
  LastEventMsg:= AEvent.Data;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TSubscriber.OnSimpleBackgroundEvent(AEvent: IBackgroundEvent);
begin
  LastEvent := AEvent;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  IncrementCount;
  Event.SetEvent;
end;

procedure TSubscriber.OnSimpleContextEvent(AEvent: IMainEvent);
begin
  LastEvent := AEvent;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
end;

procedure TSubscriber.OnSimpleEvent(AEvent: IEventBusEvent);
begin
  LastEvent := AEvent;
  LastEventMsg:= AEvent.Data;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TSubscriber.OnSimpleMainEvent(AEvent: IMainEvent);
begin
  LastEvent := AEvent;
  LastEventMsg:= AEvent.Data;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
end;

function TBackgroundEvent.Get_SequenceID: Integer;
begin
  Result:= FSequenceID;
end;

procedure TBackgroundEvent.Set_SequenceID(const AValue: Integer);
begin
  FSequenceID := AValue;
end;

procedure TSubscriberCopy.OnSimpleEvent(AEvent: IEventBusEvent);
begin
  LastEvent := AEvent;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

destructor TPerson.Destroy;
begin
  if Assigned(Child) then
    if Integer(Self) <> Integer(Child) then Child.Free;
  inherited;
end;

procedure TPerson.Set_Child(const AValue: TPerson);
begin
  FChild := AValue;
end;

procedure TPerson.Set_Firstname(const AValue: string);
begin
  FFirstname := AValue;
end;

procedure TPerson.Set_Lastname(const AValue: string);
begin
  FLastname := AValue;
end;

constructor TPersonSubscriber.Create;
begin
  inherited Create;
  FOwnsObject := True;
end;

destructor TPersonSubscriber.Destroy;
begin
  if OwnsObject and Assigned(Person) then
    Person.Free;

  inherited;
end;

procedure TPersonSubscriber.OnPersonEvent(AEvent: IDEBEvent<TPerson>);
begin
  AEvent.OwnsData:= False;
  Person := AEvent.Data;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TPersonSubscriber.Set_OwnsObject(const AValue: Boolean);
begin
  FOwnsObject := AValue;
end;

procedure TPersonSubscriber.Set_Person(const AValue: TPerson);
begin
  FPerson := AValue;
end;

procedure TPersonListSubscriber.OnPersonListEvent(AEvent: IDEBEvent<TObjectList<TPerson>>);
begin
  PersonList := AEvent.Data;
  AEvent.OwnsData := False;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TPersonListSubscriber.Set_PersonList(const AValue: TObjectList<TPerson>);
begin
  FPersonList := AValue;
end;

procedure TChannelSubscriber.OnSimpleAsyncChannel(AMsg: string);
begin
  LastChannelMsg := AMsg;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TChannelSubscriber.OnSimpleBackgroundChannel(AMsg: string);
begin
  LastChannelMsg := AMsg;
  IncrementCount;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TChannelSubscriber.OnSimpleChannel(AMsg: string);
begin
  LastChannelMsg := AMsg;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TChannelSubscriber.OnSimpleMainChannel(AMsg: string);
begin
  LastChannelMsg := AMsg;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TInvalidArgNumSubscriber.OnChannelMessage(const AMesage: string; AExtraArg: Integer);
begin
  // No-Op
end;

procedure TInvalidArgNumSubscriber.OnEvent(AEvent: IEventBusEvent; AExtraArg: Integer);
begin
  // No-Op
end;

procedure TInvalidArgTypeSubscriber.OnChannelMessage(const AMesage: Integer);
begin
  // No-Op
end;

procedure TInvalidArgTypeSubscriber.OnEvent(AEvent: Integer);
begin
  // No-Op
end;

end.

