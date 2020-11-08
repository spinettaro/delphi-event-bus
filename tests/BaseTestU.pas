unit BaseTestU;

interface

uses
  DUnitX.TestFramework, BOs;

type
  [TestFixture]
  TBaseTest = class(TObject)
  private
    FSubscriber: TSubscriber;
    FChannelSubscriber: TChannelSubscriber;
    procedure Set_Subscriber(const Value: TSubscriber);
  protected
    function SimpleCustomClone(const AObject: TObject): TObject;
  public
    property Subscriber: TSubscriber read FSubscriber write Set_Subscriber;
    property ChannelSubscriber: TChannelSubscriber read FChannelSubscriber write FChannelSubscriber;

    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;
  end;

implementation

uses
  System.SysUtils, EventBus;

procedure TBaseTest.Set_Subscriber(const Value: TSubscriber);
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
  LEvent.OwnsData := (AObject as TDEBEvent<TPerson>).OwnsData;
  LEvent.Data := TPerson.Create;
  LEvent.Data.Firstname := (AObject as TDEBEvent<TPerson>).Data.Firstname + 'Custom';
  LEvent.Data.Lastname := (AObject as TDEBEvent<TPerson>).Data.Lastname + 'Custom';
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
