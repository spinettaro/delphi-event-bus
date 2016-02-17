program VCLMessaging;

uses
  Vcl.Forms,
  MainFormU in 'MainFormU.pas' {frmMain},
  SecondFormU in 'SecondFormU.pas' {frmSecond},
  ThirdFormU in 'ThirdFormU.pas' {frmThird};

{$R *.res}

begin

  ReportMemoryLeaksOnShutdown := true;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmSecond, frmSecond);
  Application.CreateForm(TfrmThird, frmThird);
  Application.Run;
end.
