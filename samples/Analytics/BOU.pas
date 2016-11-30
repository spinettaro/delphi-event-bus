unit BOU;

interface

type

  TAnalyticsEvent = class(TObject)
  private
    FWho: string;
    FWhat: string;
    FWhen: TDateTime;
    procedure SetWhat(const Value: string);
    procedure SetWhen(const Value: TDateTime);
    procedure SetWho(const Value: string);
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

procedure TAnalyticsEvent.SetWhat(const Value: string);
begin
  FWhat := Value;
end;

procedure TAnalyticsEvent.SetWhen(const Value: TDateTime);
begin
  FWhen := Value;
end;

procedure TAnalyticsEvent.SetWho(const Value: string);
begin
  FWho := Value;
end;

end.
