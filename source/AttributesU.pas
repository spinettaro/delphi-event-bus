unit AttributesU;

interface

uses CommonsU;

type

  SubscribeAttribute = class(TCustomAttribute)
  private
    FThreadMode: TThreadMode;
  public
    constructor Create(AThreadMode: TThreadMode = TThreadMode.Posting);
    property ThreadMode: TThreadMode read FThreadMode;
  end;

implementation

{ SubscribeAttribute }

constructor SubscribeAttribute.Create(AThreadMode: TThreadMode);
begin
  FThreadMode := AThreadMode;
end;

end.
