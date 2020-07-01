unit PressureFMX;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, ModelU, EventBus;

type
  TPressureForm = class(TForm)
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
  PressureForm: TPressureForm;

implementation

{$R *.fmx}
{ TPressureForm }

procedure TPressureForm.FormCreate(Sender: TObject);
begin
  GlobalEventBus.RegisterSubscriberForEvents(Self);
end;

procedure TPressureForm.OnWeatherInfoEvent(aWeatherInfo: TWeatherInformation);
begin
  Label2.Text := Format(' %d ', [Trunc(aWeatherInfo.Pressure)]);
end;

end.
