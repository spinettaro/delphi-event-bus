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
  private
    FEvent: TEvent;
    procedure SetEvent(const Value: TEvent);
  public
    property Event: TEvent read FEvent write SetEvent;
  end;

  TBaseSubscriber = class(TObject)
  private
    FLastEvent: TEventBusEvent;
    FLastEventThreadID: cardinal;
    procedure SetLastEvent(const Value: TEventBusEvent);
    procedure SetLastEventThreadID(const Value: cardinal);
  public
    destructor Destroy; override;
    property LastEvent: TEventBusEvent read FLastEvent write SetLastEvent;
    property LastEventThreadID: cardinal read FLastEventThreadID
      write SetLastEventThreadID;
  end;

  TSubscriber = class(TBaseSubscriber)
    [Subscribe]
    procedure OnSimpleEvent(AEvent: TEventBusEvent);
    [Subscribe(TThreadMode.Async)]
    procedure OnSimpleAsyncEvent(AEvent: TAsyncEvent);
    [Subscribe(TThreadMode.Main)]
    procedure OnSimpleMainEvent(AEvent: TMainEvent);
  end;

implementation

uses
  System.Classes, EventBus;

{ TBaseSubscriber }

destructor TBaseSubscriber.Destroy;
begin
  TEventBus.GetDefault.Unregister(Self);
  if Assigned(FLastEvent) then
    FLastEvent.Free;
  inherited;
end;

procedure TBaseSubscriber.SetLastEvent(const Value: TEventBusEvent);
begin
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
  AEvent.Event.SetEvent;
end;

procedure TSubscriber.OnSimpleEvent(AEvent: TEventBusEvent);
begin
  LastEvent := AEvent;
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

{ TAsyncEvent }

procedure TAsyncEvent.SetEvent(const Value: TEvent);
begin
  FEvent := Value;
end;

end.
