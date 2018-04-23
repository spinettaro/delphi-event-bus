unit BOsU;

interface

uses
  EventBus.Subscribers, EventBus.Commons;

type

  TDoLoginEvent = class(TObject)
  private
    FPassword: string;
    FUsername: string;
    procedure SetPassword(const Value: string);
    procedure SetUsername(const Value: string);
  public
    constructor Create(AUsername: string; APwd: string);
    property Username: string read FUsername write SetUsername;
    property Password: string read FPassword write SetPassword;
  end;

  TOnLoginEvent = class(TObject)
  private
    FSuccess: boolean;
    FMsg: string;
    procedure SetMsg(const Value: string);
    procedure SetSuccess(const Value: boolean);
  public
    constructor Create(ASuccess: boolean; AMsg: string);
    property Success: boolean read FSuccess write SetSuccess;
    property Msg: string read FMsg write SetMsg;
  end;

  TRemoteProxy = class(TObject)
  private
    class var FDefaultInstance: TRemoteProxy;
  public
    class function GetDefault: TRemoteProxy;
    [Subscribe(TThreadMode.Async)]
    procedure DoLogin(ADoLoginEvent: TDoLoginEvent);
  end;

implementation

uses
  System.Classes, EventBus;

{ TDoLoginEvent }

constructor TDoLoginEvent.Create(AUsername, APwd: string);
begin
  FPassword := APwd;
  FUsername := AUsername;
end;

procedure TDoLoginEvent.SetPassword(const Value: string);
begin
  FPassword := Value;
end;

procedure TDoLoginEvent.SetUsername(const Value: string);
begin
  FUsername := Value;
end;

{ TRemoteProxy }

procedure TRemoteProxy.DoLogin(ADoLoginEvent: TDoLoginEvent);
begin
  // simulate an http request for 5 seconds
  TThread.Sleep(3000);
  TEventBus.GetDefault.Post(TOnLoginEvent.Create(true, 'Login ok'));
  ADoLoginEvent.Free;
end;

class function TRemoteProxy.GetDefault: TRemoteProxy;
begin
  if (not Assigned(FDefaultInstance)) then
    FDefaultInstance := TRemoteProxy.Create;
  Result := FDefaultInstance;
end;

{ TOnLoginEvent }

constructor TOnLoginEvent.Create(ASuccess: boolean; AMsg: string);
begin
  inherited Create;
  FSuccess := ASuccess;
  FMsg := AMsg;
end;

procedure TOnLoginEvent.SetMsg(const Value: string);
begin
  FMsg := Value;
end;

procedure TOnLoginEvent.SetSuccess(const Value: boolean);
begin
  FSuccess := Value;
end;

end.
