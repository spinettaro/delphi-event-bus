unit BOsU;

interface

uses

  EventBus;

type

  TLoginDTO = class(TObject)
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

implementation

uses
  System.Classes;

{ TLoginDTO }

constructor TLoginDTO.Create(AUsername, APwd: string);
begin
  FPassword := APwd;
  FUsername := AUsername;
end;

procedure TLoginDTO.SetPassword(const Value: string);
begin
  FPassword := Value;
end;

procedure TLoginDTO.SetUsername(const Value: string);
begin
  FUsername := Value;
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
