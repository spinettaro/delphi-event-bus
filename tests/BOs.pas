unit BOs;

interface

uses
  System.SyncObjs, System.Generics.Collections, EventBus;

type
  TPerson = class(TObject)
  private
    FChild: TPerson;
    FFirstname: string;
    FLastname: string;
    procedure SetChild(const Value: TPerson);
    procedure SetFirstname(const Value: string);
    procedure SetLastname(const Value: string);
  public
    destructor Destroy; override;
    property Child: TPerson read FChild write SetChild;
    property Firstname: string read FFirstname write SetFirstname;
    property Lastname: string read FLastname write SetLastname;
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
    procedure SetSequenceID(const Value: Integer);
    function GetSequenceID: Integer;
    property SequenceID: Integer read GetSequenceID write SetSequenceID;
  end;

  TBackgroundEvent = class(TDEBEvent<string>, IBackgroundEvent)
  private
    FSequenceID: Integer;
    function GetSequenceID: Integer;
    procedure SetSequenceID(const Value: Integer);
  public
    property SequenceID: Integer read GetSequenceID write SetSequenceID;
  public
  end;

  TBaseSubscriber = class(TObject)
  private
    FChannelMsg: string;
    FEvent: TEvent; // Wrapper of Win32 SetEvent with automic Set/Reset, no need for thread protection.
    FCount: Integer;
    FEventMsg: string;
    FLastEvent: IEventBusEvent;
    FLastEventThreadID: Cardinal;
    procedure SetLastChannelMsg(const Value: string);
    procedure SetLastEvent(const Value: IEventBusEvent);
    procedure SetLastEventMsg(const Value: string);
    procedure SetLastEventThreadID(const Value: Cardinal);
  public
    constructor Create;
    destructor Destroy; override;

    procedure IncrementCount;

    property Event: TEvent read FEvent; // Readonly is good enough
    property Count: Integer read FCount;
    property LastEvent: IEventBusEvent read FLastEvent write SetLastEvent;
    property LastChannelMsg: string read FChannelMsg write SetLastChannelMsg;
    property LastEventMsg: string read FEventMsg write SetLastEventMsg;
    property LastEventThreadID: Cardinal read FLastEventThreadID write SetLastEventThreadID;
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
    procedure SetOwnsObject(const Value: Boolean);
    procedure SetPerson(const Value: TPerson);
  public
    constructor Create;
    destructor Destroy; override;

    [Subscribe]
    procedure OnPersonEvent(AEvent: IDEBEvent<TPerson>);

    property OwnsObject: Boolean read FOwnsObject write SetOwnsObject;
    property Person: TPerson read FPerson write SetPerson;
  end;

  TPersonListSubscriber = class(TBaseSubscriber)
  private
    FPersonList: TObjectList<TPerson>;
    procedure SetPersonList(const Value: TObjectList<TPerson>);
  public
    [Subscribe]
    procedure OnPersonListEvent(AEvent: IDEBEvent<TObjectList<TPerson>>);

    property PersonList: TObjectList<TPerson> read FPersonList write SetPersonList;
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

procedure TBaseSubscriber.SetLastEvent(const Value: IEventBusEvent);
begin
  TMonitor.Enter(Self); // Need to protect from multithread write (for the Background/Async events testing)
  FLastEvent := Value;
  TMonitor.Exit(Self);
end;

procedure TBaseSubscriber.SetLastEventThreadID(const Value: Cardinal);
begin
  TMonitor.Enter(Self); // Need to protect from multithread write (for the Background/Async events testing)
  FLastEventThreadID := Value;
  TMonitor.Exit(Self);
end;

procedure TBaseSubscriber.SetLastChannelMsg(const Value: string);
begin
  TMonitor.Enter(Self);
  FChannelMsg := Value;
  TMonitor.Exit(Self);
end;

procedure TBaseSubscriber.SetLastEventMsg(const Value: string);
begin
  TMonitor.Enter(Self);
  FEventMsg := Value;
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

function TBackgroundEvent.GetSequenceID: Integer;
begin
  Result:= FSequenceID;
end;

procedure TBackgroundEvent.SetSequenceID(const Value: Integer);
begin
  FSequenceID := Value;
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
    if Integer(Self) <> Integer(Child) then
      Child.Free;

  inherited;
end;

procedure TPerson.SetChild(const Value: TPerson);
begin
  FChild := Value;
end;

procedure TPerson.SetFirstname(const Value: string);
begin
  FFirstname := Value;
end;

procedure TPerson.SetLastname(const Value: string);
begin
  FLastname := Value;
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

procedure TPersonSubscriber.SetOwnsObject(const Value: Boolean);
begin
  FOwnsObject := Value;
end;

procedure TPersonSubscriber.SetPerson(const Value: TPerson);
begin
  FPerson := Value;
end;

procedure TPersonListSubscriber.OnPersonListEvent(AEvent: IDEBEvent<TObjectList<TPerson>>);
begin
  PersonList := AEvent.Data;
  AEvent.OwnsData := False;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TPersonListSubscriber.SetPersonList(const Value: TObjectList<TPerson>);
begin
  FPersonList := Value;
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

end.

