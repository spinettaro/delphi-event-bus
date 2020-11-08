program VCLMessaging;

uses
  Vcl.Forms,
  MainFormU in 'MainFormU.pas' {frmMain} ,
  SecondFormU in 'SecondFormU.pas' {frmSecond} ,
  ThirdFormU in 'ThirdFormU.pas' {frmThird} ,
  EventU in 'EventU.pas';

{$R *.res}

begin

  ReportMemoryLeaksOnShutdown := true;

  Application.Initialize;
  Application.MainFormOnTaskbar := true;
  Application.CreateForm(TfrmMain, FrmMain);
  Application.CreateForm(TfrmSecond, FrmSecond);
  Application.CreateForm(TfrmThird, FrmThird);
  Application.Run;

end.
