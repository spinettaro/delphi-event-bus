unit LogginFormU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, EventBus,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, BOU;

type
  TFormLogger = class(TForm)
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    function GetFormattedAnalyticsEvent(AAnalyticsEvent
      : TAnalyticsEvent): string;
  public
    { Public declarations }
    [Subscribe]
    procedure OnAnalyticsEvent(AAnalyticsEvent: TAnalyticsEvent);
  end;

var
  FormLogger: TFormLogger;

implementation

{$R *.dfm}

procedure TFormLogger.FormCreate(Sender: TObject);
begin
  Memo1.Lines.Clear;
  GlobalEventBus.RegisterSubscriberForEvents(self);
end;

function TFormLogger.GetFormattedAnalyticsEvent(AAnalyticsEvent
  : TAnalyticsEvent): string;
begin
  Result := Format('User %s - %s - at %s ',
    [AAnalyticsEvent.Who, AAnalyticsEvent.What,
    DateTimeToStr(AAnalyticsEvent.When)]);
end;

procedure TFormLogger.OnAnalyticsEvent(AAnalyticsEvent: TAnalyticsEvent);
begin
  Memo1.Lines.Add(GetFormattedAnalyticsEvent(AAnalyticsEvent));
end;

end.
