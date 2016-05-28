program DEBDUnitTests;
{

  Delphi DUnit Test Project
  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options
  to use the console test runner.  Otherwise the GUI test runner will be used by
  default.

}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  DUnit.EventBusTestU in 'DUnit.EventBusTestU.pas',
  EventBus in '..\source\EventBus.pas',
  BOs in 'BOs.pas';

{$R *.RES}

begin
  ReportMemoryLeaksOnShutdown := true;
  DUnitTestRunner.RunRegisteredTests;
end.

