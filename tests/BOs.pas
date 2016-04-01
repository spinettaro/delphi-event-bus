unit BOs;

interface

uses
  EventBus.Attributes, EventBus.Commons, System.SyncObjs;

type

  TEventBusEvent = class(TObject)
  private
    FMsg: string;
    procedure SetMsg(const Value: string);
  public
    property Msg: string read FMsg write SetMsg;
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

procedure TEventBusEvent.SetMsg(const Value: string);
begin
  FMsg := Value;
end;

{ TBackgroundEvent }

procedure TBackgroundEvent.SetCount(const Value: integer);
begin
  FCount := Value;
end;

end.
