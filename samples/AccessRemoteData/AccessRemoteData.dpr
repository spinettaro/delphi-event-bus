program AccessRemoteData;

uses
  System.StartUpCopy,
  FMX.Forms,
  MainFMX in 'MainFMX.pas' {HeaderFooterForm} ,
  BOsU in 'BOsU.pas',
  ServicesU in 'ServicesU.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := true;
  Application.Initialize;
  Application.CreateForm(THeaderFooterForm, HeaderFooterForm);
  Application.Run;

end.
