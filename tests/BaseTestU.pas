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
    FChannelSubscriber: TChannelSubscriber;
    procedure SetSubscriber(const Value: TSubscriber);
  protected
    function SimpleCustomClone(const AObject: TObject): TObject;
  public
    property Subscriber: TSubscriber read FSubscriber write SetSubscriber;
    property ChannelSubscriber: TChannelSubscriber read FChannelSubscriber
      write FChannelSubscriber;
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
  end;

implementation

uses
  System.SysUtils,
  EventBus;

{ TBaseTest }

procedure TBaseTest.SetSubscriber(const Value: TSubscriber);
begin
  FSubscriber := Value;
end;

procedure TBaseTest.Setup;
begin
  FSubscriber := TSubscriber.Create;
  FChannelSubscriber := TChannelSubscriber.Create;
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
  GlobalEventBus.UnregisterForChannels(ChannelSubscriber);
  GlobalEventBus.UnregisterForEvents(Subscriber);
  if Assigned(FSubscriber) then
    FreeAndNil(FSubscriber);
  if Assigned(FChannelSubscriber) then
    FreeAndNil(FChannelSubscriber);

end;

end.
