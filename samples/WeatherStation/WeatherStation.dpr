program WeatherStation;

uses
  System.StartUpCopy,
  FMX.Forms,
  TemperatureFMX in 'TemperatureFMX.pas' {TemperatureForm} ,
  PressureFMX in 'PressureFMX.pas' {PressureForm} ,
  HumidityFMX in 'HumidityFMX.pas' {HumidityForm} ,
  PaintedFMX in 'PaintedFMX.pas' {PaintedForm} ,
  ModelU in 'ModelU.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown:= True;
  Application.Initialize;
  Application.CreateForm(TTemperatureForm, TemperatureForm);
  Application.CreateForm(TPressureForm, PressureForm);
  Application.CreateForm(THumidityForm, HumidityForm);
  Application.CreateForm(TPaintedForm, PaintedForm);
  Application.Run;

end.
