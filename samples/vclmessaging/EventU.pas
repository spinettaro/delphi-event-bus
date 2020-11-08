unit EventU;

interface

type
  IMemoChangeEvent = interface
  ['{DCFE64D2-9BA8-4949-9BB1-F5CD672E51A2}']
    procedure SetText(const Value: string);
    function GetText: String;
    property Text: string read GetText write SetText;
  end;

  ICheckBoxEvent = interface
  ['{2212C465-BD01-4E0E-8468-12FB5DCCA33A}']
    procedure SetChecked(const Value: boolean);
    function GetChecked: Boolean;
    property Checked: boolean read GetChecked write SetChecked;
  end;

  function GetMemoEvent: IMemoChangeEvent;
  function GetCheckBoxEvent: ICheckBoxEvent;

implementation

type
  TMemoChangeEvent = class(TInterfacedObject, IMemoChangeEvent)
  private
    FText: string;
    procedure SetText(const Value: string);
    function GetText: String;
  public
    property Text: string read GetText write SetText;
  end;

  TCheckBoxEvent = class(TInterfacedObject, ICheckBoxEvent)
  private
    FChecked: boolean;
    procedure SetChecked(const Value: boolean);
    function GetChecked: Boolean;
  public
    property Checked: boolean read GetChecked write SetChecked;
  end;

{ TMemoChange }

function TMemoChangeEvent.GetText: String;
begin
  Result:= FText;
end;

procedure TMemoChangeEvent.SetText(const Value: string);
begin
  FText := Value;
end;

{ TCheckBoxEvent }

function TCheckBoxEvent.GetChecked: Boolean;
begin
  Result:= FChecked;
end;

procedure TCheckBoxEvent.SetChecked(const Value: boolean);
begin
  FChecked := Value;
end;

function GetMemoEvent: IMemoChangeEvent;
begin
  Result:= TMemoChangeEvent.Create;
end;

function GetCheckBoxEvent: ICheckBoxEvent;
begin
  Result:= TCheckBoxEvent.Create;
end;

end.
