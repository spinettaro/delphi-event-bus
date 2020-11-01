unit BOs;

interface

uses
  EventBus, System.SyncObjs, System.Generics.Collections;

type

  TPerson = class(TObject)
  private
    FLastname: string;
    FFirstname: string;
    FChild: TPerson;
    procedure SetChild(const Value: TPerson);
    procedure SetFirstname(const Value: string);
    procedure SetLastname(const Value: string);
  public
    destructor Destroy; override;
    property Firstname: string read FFirstname write SetFirstname;
    property Lastname: string read FLastname write SetLastname;
    property Child: TPerson read FChild write SetChild;
  end;



  IEventBusEvent = IDEBEvent<String>;
  TEventBusEvent = class(TDEBEvent<String>);

  IMainEvent = Interface(IEventBusEvent)
     ['{68F192C1-1F0F-41CE-85FD-0146C2301A4E}']
  end;
  TMainEvent = class(TDEBEvent<String>, IMainEvent);

  IAsyncEvent = Interface(IEventBusEvent)
     ['{68F192C1-1F0F-41CE-85FD-0146C2301A4E}']
  end;
  TAsyncEvent = class(TDEBEvent<String>, IAsyncEvent);

  IBackgroundEvent = Interface(IEventBusEvent)
  ['{E70B43F0-7F68-47B9-AFF3-5878A0B1A88D}']
     procedure SetCount(const Value: integer);
    function GetCount: Integer;
    property Count: integer read GetCount write SetCount;
  end;

  TBackgroundEvent = class(TDEBEvent<String>, IBackgroundEvent)
  private
    FCount: integer;
    procedure SetCount(const Value: integer);
    function GetCount: Integer;
  public
    property Count: integer read GetCount write SetCount;
  end;

  TBaseSubscriber = class(TObject)
  private
    FLastEvent: IEventBusEvent;
    FLastEventThreadID: cardinal;
    FEvent: TEvent;
    FChannelMsg: String;
    FEventMsg: String;
    procedure SetLastEvent(const Value: IEventBusEvent);
    procedure SetLastEventThreadID(const Value: cardinal);
    procedure SetEvent(const Value: TEvent);
  public
    constructor Create;
    destructor Destroy; override;
    property LastEvent: IEventBusEvent read FLastEvent write SetLastEvent;
    property LastEventThreadID: cardinal read FLastEventThreadID
      write SetLastEventThreadID;
    property Event: TEvent read FEvent write SetEvent;
    property LastChannelMsg: String read FChannelMsg write FChannelMsg;
    property LastEventMsg: String read FEventMsg write FEventMsg;
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
    procedure OnSimpleChannel(AMsg: String);
    [Channel('test_channel_async', TThreadMode.Async)]
    procedure OnSimpleAsyncChannel(AMsg: String);
    [Channel('test_channel_main', TThreadMode.Main)]
    procedure OnSimpleMainChannel(AMsg: String);
    [Channel('test_channel_bkg', TThreadMode.Background)]
    procedure OnSimpleBackgroundChannel(AMsg: String);
  end;

  TSubscriberCopy = class(TBaseSubscriber)
    [Subscribe]
    procedure OnSimpleEvent(AEvent: IEventBusEvent);
  end;

  TPersonSubscriber = class(TBaseSubscriber)
  private
    FPerson: TPerson;
    FObjOwner: boolean;
    procedure SetPerson(const Value: TPerson);
    procedure SetObjOwner(const Value: boolean);
  public
    constructor Create;
    destructor Destroy; override;
    property ObjOwner: boolean read FObjOwner write SetObjOwner;
    property Person: TPerson read FPerson write SetPerson;
    [Subscribe]
    procedure OnPersonEvent(AEvent: IDEBEvent<TPerson>);
  end;

  TPersonListSubscriber = class(TBaseSubscriber)
  private
    FPersonList: TObjectList<TPerson>;
    procedure SetPersonList(const Value: TObjectList<TPerson>);
  public
    property PersonList: TObjectList<TPerson> read FPersonList
      write SetPersonList;
    [Subscribe]
    procedure OnPersonListEvent(AEvent: IDEBEvent < TObjectList < TPerson >> );
  end;

implementation

uses
  System.Classes;

{ TBaseSubscriber }

constructor TBaseSubscriber.Create;
begin
  inherited Create;
  FEvent := TEvent.Create;
end;

destructor TBaseSubscriber.Destroy;
begin
  GlobalEventBus.UnregisterForEvents(Self);
  GlobalEventBus.UnregisterForChannels(Self);
  if Assigned(FEvent) then
    FEvent.Free;
  inherited;
end;

procedure TBaseSubscriber.SetEvent(const Value: TEvent);
begin
  FEvent := Value;
end;

procedure TBaseSubscriber.SetLastEvent(const Value: IEventBusEvent);
begin
  FLastEvent := Value;
end;

procedure TBaseSubscriber.SetLastEventThreadID(const Value: cardinal);
begin
  FLastEventThreadID := Value;
end;

{ TSubscriber }

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

{ TEvent }

// procedure TEventBusEvent.SetMsg(const Value: string);
// begin
// FMsg := Value;
// end;

{ TBackgroundEvent }

function TBackgroundEvent.GetCount: Integer;
begin
  Result:= FCount;
end;

procedure TBackgroundEvent.SetCount(const Value: integer);
begin
  FCount := Value;
end;

{ TSubscriberCopy }

procedure TSubscriberCopy.OnSimpleEvent(AEvent: IEventBusEvent);
begin
  LastEvent := AEvent;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

{ TPerson }

destructor TPerson.Destroy;
begin
  if Assigned(Child) then
    if integer(Self) <> integer(Child) then
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

{ TPersonSubscriber }

constructor TPersonSubscriber.Create;
begin
  inherited Create;
  FObjOwner := true;
end;

destructor TPersonSubscriber.Destroy;
begin
  if ObjOwner and Assigned(Person) then
    Person.Free;
  inherited;
end;

procedure TPersonSubscriber.OnPersonEvent(AEvent: IDEBEvent<TPerson>);
begin
  AEvent.DataOwner := false;
  Person := AEvent.Data;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TPersonSubscriber.SetObjOwner(const Value: boolean);
begin
  FObjOwner := Value;
end;

procedure TPersonSubscriber.SetPerson(const Value: TPerson);
begin
  FPerson := Value;
end;

{ TPersonListSubscriber }

procedure TPersonListSubscriber.OnPersonListEvent
  (AEvent: IDEBEvent < TObjectList < TPerson >> );
begin
  PersonList := AEvent.Data;
  AEvent.DataOwner := false;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TPersonListSubscriber.SetPersonList(const Value
  : TObjectList<TPerson>);
begin
  FPersonList := Value;
end;

{ TChannelSubscriber }

procedure TChannelSubscriber.OnSimpleAsyncChannel(AMsg: String);
begin
  LastChannelMsg := AMsg;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TChannelSubscriber.OnSimpleBackgroundChannel(AMsg: String);
begin
  LastChannelMsg := AMsg;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TChannelSubscriber.OnSimpleChannel(AMsg: String);
begin
  LastChannelMsg := AMsg;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TChannelSubscriber.OnSimpleMainChannel(AMsg: String);
begin
  LastChannelMsg := AMsg;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

end.
