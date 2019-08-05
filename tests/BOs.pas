unit BOs;

interface

uses
  EventBus.Commons, System.SyncObjs, System.Generics.Collections;

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

  TEventBusEvent = class(TDEBEvent<string>)
    // private
    // FMsg: string;
    // procedure SetMsg(const Value: string);
    // public
    // property Msg: string read FMsg write SetMsg;
  end;

  TMainEvent = class(TEventBusEvent)

  end;

  TAsyncEvent = class(TEventBusEvent)

  end;

  TBackgroundEvent = class(TEventBusEvent)
  private
    FCount: integer;
    procedure SetCount(const Value: integer);
  public
    property Count: integer read FCount write SetCount;
  end;

  TBaseSubscriber = class(TObject)
  private
    FLastEvent: TEventBusEvent;
    FLastEventThreadID: cardinal;
    FEvent: TEvent;
    procedure SetLastEvent(const Value: TEventBusEvent);
    procedure SetLastEventThreadID(const Value: cardinal);
    procedure SetEvent(const Value: TEvent);
  public
    constructor Create;
    destructor Destroy; override;
    property LastEvent: TEventBusEvent read FLastEvent write SetLastEvent;
    property LastEventThreadID: cardinal read FLastEventThreadID
      write SetLastEventThreadID;
    property Event: TEvent read FEvent write SetEvent;
  end;

  TSubscriber = class(TBaseSubscriber)
    [Subscribe]
    procedure OnSimpleEvent(AEvent: TEventBusEvent);
    [Subscribe(TThreadMode.Async)]
    procedure OnSimpleAsyncEvent(AEvent: TAsyncEvent);
    [Subscribe(TThreadMode.Main)]
    procedure OnSimpleMainEvent(AEvent: TMainEvent);
    [Subscribe(TThreadMode.Background)]
    procedure OnSimpleBackgroundEvent(AEvent: TBackgroundEvent);
    [Subscribe(TThreadMode.Main, 'TestCtx')]
    procedure OnSimpleContextEvent(AEvent: TMainEvent);
  end;

  TSubscriberCopy = class(TBaseSubscriber)
    [Subscribe]
    procedure OnSimpleEvent(AEvent: TEventBusEvent);
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
    procedure OnPersonEvent(AEvent: TDEBEvent<TPerson>);
  end;

  TPersonListSubscriber = class(TBaseSubscriber)
  private
    FPersonList: TObjectList<TPerson>;
    procedure SetPersonList(const Value: TObjectList<TPerson>);
  public
    property PersonList: TObjectList<TPerson> read FPersonList
      write SetPersonList;
    [Subscribe]
    procedure OnPersonListEvent(AEvent: TDEBEvent < TObjectList < TPerson >> );
  end;

implementation

uses
  System.Classes, EventBus;

{ TBaseSubscriber }

constructor TBaseSubscriber.Create;
begin
  inherited Create;
  FEvent := TEvent.Create;
end;

destructor TBaseSubscriber.Destroy;
begin
  TEventBus.GetDefault.Unregister(Self);
  if Assigned(FLastEvent) then
    FLastEvent.Free;
  if Assigned(FEvent) then
    FEvent.Free;
  inherited;
end;

procedure TBaseSubscriber.SetEvent(const Value: TEvent);
begin
  FEvent := Value;
end;

procedure TBaseSubscriber.SetLastEvent(const Value: TEventBusEvent);
begin
  if Assigned(FLastEvent) then
    FLastEvent.Free;
  FLastEvent := Value;
end;

procedure TBaseSubscriber.SetLastEventThreadID(const Value: cardinal);
begin
  FLastEventThreadID := Value;
end;

{ TSubscriber }

procedure TSubscriber.OnSimpleAsyncEvent(AEvent: TAsyncEvent);
begin
  LastEvent := AEvent;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TSubscriber.OnSimpleBackgroundEvent(AEvent: TBackgroundEvent);
begin
  LastEvent := AEvent;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TSubscriber.OnSimpleContextEvent(AEvent: TMainEvent);
begin
  LastEvent := AEvent;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
end;

procedure TSubscriber.OnSimpleEvent(AEvent: TEventBusEvent);
begin
  LastEvent := AEvent;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

procedure TSubscriber.OnSimpleMainEvent(AEvent: TMainEvent);
begin
  LastEvent := AEvent;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
end;

{ TEvent }

// procedure TEventBusEvent.SetMsg(const Value: string);
// begin
// FMsg := Value;
// end;

{ TBackgroundEvent }

procedure TBackgroundEvent.SetCount(const Value: integer);
begin
  FCount := Value;
end;

{ TSubscriberCopy }

procedure TSubscriberCopy.OnSimpleEvent(AEvent: TEventBusEvent);
begin
  LastEvent := AEvent;
  LastEventThreadID := TThread.CurrentThread.ThreadID;
  Event.SetEvent;
end;

{ TPerson }

destructor TPerson.Destroy;
begin
  if Assigned(Child) then
    if integer(self) <> integer(Child) then
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

procedure TPersonSubscriber.OnPersonEvent(AEvent: TDEBEvent<TPerson>);
begin
  try
    AEvent.DataOwner := false;
    Person := AEvent.Data;
    LastEventThreadID := TThread.CurrentThread.ThreadID;
    Event.SetEvent;
  finally
    AEvent.Free;
  end;
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
  (AEvent: TDEBEvent < TObjectList < TPerson >> );
begin
  try
    PersonList := AEvent.Data;
    AEvent.DataOwner := false;
    LastEventThreadID := TThread.CurrentThread.ThreadID;
    Event.SetEvent;
  finally
    AEvent.Free;
  end;
end;

procedure TPersonListSubscriber.SetPersonList(const Value
  : TObjectList<TPerson>);
begin
  FPersonList := Value;
end;

end.
