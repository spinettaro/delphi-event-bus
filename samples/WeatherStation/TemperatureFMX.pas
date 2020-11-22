unit TemperatureFMX;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics,
  FMX.Dialogs, FMX.Controls.Presentation, FMX.StdCtrls, ModelU,
  EventBus;

type
  TTemperatureForm = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  public
    [Subscribe(TThreadMode.Main)]
    procedure OnWeatherInfoEvent(AWeatherInfo: IWeatherInformation);
  end;

var
  TemperatureForm: TTemperatureForm;

implementation

{$R *.fmx}
{ TTemperatureForm }

procedure TTemperatureForm.FormCreate(Sender: TObject);
begin
  GlobalEventBus.RegisterSubscriberForEvents(Self);
  TWeatherModel.StartPolling;
end;

procedure TTemperatureForm.FormDestroy(Sender: TObject);
begin
  TWeatherModel.StopPolling;
end;

procedure TTemperatureForm.OnWeatherInfoEvent(AWeatherInfo: IWeatherInformation);
begin
  Label2.Text := Format('%d °C', [AWeatherInfo.Temperature]);
end;

end.
