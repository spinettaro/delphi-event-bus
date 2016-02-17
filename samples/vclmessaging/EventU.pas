unit EventU;

interface

type

  TMemoChangeEvent = class(TObject)
  private
    FText: string;
    procedure SetText(const Value: string);
  public
    property Text: string read FText write SetText;
  end;

  TCheckBoxEvent = class(TObject)
  private
    FChecked: boolean;
    procedure SetChecked(const Value: boolean);
  public
    property Checked: boolean read FChecked write SetChecked;
  end;

implementation

{ TMemoChange }

procedure TMemoChangeEvent.SetText(const Value: string);
begin
  FText := Value;
end;

{ TCheckBoxEvent }

procedure TCheckBoxEvent.SetChecked(const Value: boolean);
begin
  FChecked := Value;
end;

end.
