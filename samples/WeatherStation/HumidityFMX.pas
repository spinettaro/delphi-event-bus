unit HumidityFMX;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, ModelU, EventBus;

type
  THumidityForm = class(TForm)
    Label2: TLabel;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    [Subscribe(TThreadMode.Main)]
    procedure OnWeatherInfoEvent(aWeatherInfo: TWeatherInformation);
  end;

var
  HumidityForm: THumidityForm;

implementation

{$R *.fmx}
{ THumidityForm }

procedure THumidityForm.FormCreate(Sender: TObject);
begin
  GlobalEventBus.RegisterSubscriberForEvents(Self);
end;

procedure THumidityForm.OnWeatherInfoEvent(aWeatherInfo: TWeatherInformation);
begin
  Label2.Text := Format('%d %', [aWeatherInfo.Humidity]);
end;

end.
