unit BOsU;

interface

uses
  EventBus;

type
  TLoginDTO = class(TObject)
  private
    FPassword: string;
    FUsername: string;
    procedure SetPassword(const AValue: string);
    procedure SetUsername(const AValue: string);
  public
    constructor Create(AUsername: string; APwd: string);
    property Username: string read FUsername write SetUsername;
    property Password: string read FPassword write SetPassword;
  end;

  IOnLoginEvent = interface
  ['{E3C9633D-86CA-488F-A452-29DAB206C92A}']
    procedure SetMsg(const AValue: string);
    procedure SetSuccess(const AValue: Boolean);
    function GetMsg: string;
    function GetSuccess: Boolean;
    property Success: Boolean read GetSuccess write SetSuccess;
    property Msg: string read GetMsg write SetMsg;
  end;

  function CreateOnLoginEvent(ASuccess: Boolean; AMsg: string): IOnLoginEvent;

implementation

uses
  System.Classes;

type
  TOnLoginEvent = class(TInterfacedObject, IOnLoginEvent)
  private
    FSuccess: Boolean;
    FMsg: string;
    procedure SetMsg(const AValue: string);
    procedure SetSuccess(const AValue: Boolean);
    function GetMsg: string;
    function GetSuccess: Boolean;
  public
    constructor Create(ASuccess: Boolean; AMsg: string);
    property Success: Boolean read GetSuccess write SetSuccess;
    property Msg: string read GetMsg write SetMsg;
  end;

{ TLoginDTO }

constructor TLoginDTO.Create(AUsername, APwd: string);
begin
  FPassword := APwd;
  FUsername := AUsername;
end;

procedure TLoginDTO.SetPassword(const AValue: string);
begin
  FPassword := AValue;
end;

procedure TLoginDTO.SetUsername(const AValue: string);
begin
  FUsername := AValue;
end;

{ TOnLoginEvent }

constructor TOnLoginEvent.Create(ASuccess: Boolean; AMsg: string);
begin
  inherited Create;
  FSuccess := ASuccess;
  FMsg := AMsg;
end;

function TOnLoginEvent.GetMsg: string;
begin
  Result:= FMsg;
end;

function TOnLoginEvent.GetSuccess: Boolean;
begin
  Result:= FSuccess;
end;

procedure TOnLoginEvent.SetMsg(const AValue: string);
begin
  FMsg := AValue;
end;

procedure TOnLoginEvent.SetSuccess(const AValue: Boolean);
begin
  FSuccess := AValue;
end;

function CreateOnLoginEvent(ASuccess: Boolean; AMsg: string): IOnLoginEvent;
begin
  Result:= TOnLoginEvent.Create(ASuccess, AMsg);
end;

end.
