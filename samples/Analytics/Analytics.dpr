program Analytics;

uses
  Vcl.Forms,
  MainFormU in 'MainFormU.pas' {Form6} ,
  BOU in 'BOU.pas',
  LogginFormU in 'LogginFormU.pas' {FormLogger};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm6, Form6);
  Application.CreateForm(TFormLogger, FormLogger);
  Application.Run;

end.
