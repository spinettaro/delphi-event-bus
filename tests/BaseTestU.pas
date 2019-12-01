unit BaseTestU;

interface

uses
    DUnitX.TestFramework,
    BOs;

type

    [TestFixture]
    TBaseTest = class(TObject)
    private
        FSubscriber: TSubscriber;
        procedure SetSubscriber(const Value: TSubscriber);
    protected
        function SimpleCustomClone(const AObject: TObject): TObject;
    public
        property Subscriber: TSubscriber read FSubscriber write SetSubscriber;
        [Setup]
        procedure Setup;
        [TearDown]
        procedure TearDown;
    end;

implementation

uses
    System.SysUtils,
    EventBus.Commons,
    EventBus;

{ TBaseTest }

procedure TBaseTest.SetSubscriber(const Value: TSubscriber);
begin
    FSubscriber := Value;
end;

procedure TBaseTest.Setup;
begin
    FSubscriber := TSubscriber.Create;
end;

function TBaseTest.SimpleCustomClone(const AObject: TObject): TObject;
var
    LEvent: TDEBEvent<TPerson>;
begin
    LEvent := TDEBEvent<TPerson>.Create;
    LEvent.DataOwner := (AObject as TDEBEvent<TPerson>).DataOwner;
    LEvent.Data := TPerson.Create;
    LEvent.Data.Firstname := (AObject as TDEBEvent<TPerson>).Data.Firstname
        + 'Custom';
    LEvent.Data.Lastname := (AObject as TDEBEvent<TPerson>).Data.Lastname
        + 'Custom';
    Result := LEvent;
end;

procedure TBaseTest.TearDown;
begin
    if Assigned(FSubscriber) then
        FreeAndNil(FSubscriber);
end;

end.
