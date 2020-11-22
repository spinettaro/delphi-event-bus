unit BOU;

interface

type
  IAnalyticsEvent = interface(IInvokable)
  ['{50DABFB6-62D3-42C9-91BC-4D6357D75DF3}']
    procedure SetWhat(const AValue: string);
    procedure SetWhen(const AValue: TDateTime);
    procedure SetWho(const AValue: string);

    function GetWhat: String;
    function GetWhen: TDateTime;
    function GetWho: String;

    property What: string read GetWhat write SetWhat;
    property When: TDateTime read GetWhen write SetWhen;
    property Who: string read GetWho write SetWho;
  end;

  TAnalyticsEvent = class(TInterfacedObject, IAnalyticsEvent)
  private
    FWho:  string;
    FWhat: string;
    FWhen: TDateTime;
    procedure SetWhat(const AValue: string);
    procedure SetWhen(const AValue: TDateTime);
    procedure SetWho(const AValue: string);
    function GetWhat: String;
    function GetWhen: TDateTime;
    function GetWho: String;
  public
    constructor Create(const What, Who: string; const When: TDateTime);
    property What: string read FWhat write SetWhat;
    property When: TDateTime read FWhen write SetWhen;
    property Who: string read FWho write SetWho;
  end;

implementation

{ TAnalyticsEvent }

constructor TAnalyticsEvent.Create(const What, Who: string; const When: TDateTime);
begin
 FWhat := What;
 FWho := Who;
 FWhen := When;
end;

function TAnalyticsEvent.GetWhat: String;
begin
  Result:= FWhat;
end;

function TAnalyticsEvent.GetWhen: TDateTime;
begin
  Result:= FWhen;
end;

function TAnalyticsEvent.GetWho: String;
begin
  Result:= FWho;
end;

procedure TAnalyticsEvent.SetWhat(const AValue: string);
begin
  FWhat := AValue;
end;

procedure TAnalyticsEvent.SetWhen(const AValue: TDateTime);
begin
  FWhen := AValue;
end;

procedure TAnalyticsEvent.SetWho(const AValue: string);
begin
  FWho := AValue;
end;

end.
