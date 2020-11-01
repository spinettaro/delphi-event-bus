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

  IOnLoginEvent = interface
      ['{E3C9633D-86CA-488F-A452-29DAB206C92A}']
    procedure SetMsg(const Value: string);
    procedure SetSuccess(const Value: boolean);
    function GetMsg: String;
    function GetSuccess: Boolean;
    property Success: boolean read GetSuccess write SetSuccess;
    property Msg: string read GetMsg write SetMsg;
  end;

  function CreateOnLoginEvent(ASuccess: boolean; AMsg: string): IOnLoginEvent;

implementation

uses
  System.Classes;


type

    TOnLoginEvent = class(TInterfacedObject, IOnLoginEvent)
  private
    FSuccess: boolean;
    FMsg: string;
    procedure SetMsg(const Value: string);
    procedure SetSuccess(const Value: boolean);
    function GetMsg: String;
    function GetSuccess: Boolean;
  public
    constructor Create(ASuccess: boolean; AMsg: string);
    property Success: boolean read GetSuccess write SetSuccess;
    property Msg: string read GetMsg write SetMsg;
  end;

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

function TOnLoginEvent.GetMsg: String;
begin
  Result:= FMsg;
end;

function TOnLoginEvent.GetSuccess: Boolean;
begin
  Result:= FSuccess;
end;

procedure TOnLoginEvent.SetMsg(const Value: string);
begin
  FMsg := Value;
end;

procedure TOnLoginEvent.SetSuccess(const Value: boolean);
begin
  FSuccess := Value;
end;

function CreateOnLoginEvent(ASuccess: boolean; AMsg: string): IOnLoginEvent;
begin
  Result:= TOnLoginEvent.Create( ASuccess, AMsg);
end;

end.
