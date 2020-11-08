program DEBDUnitXTests;

{$IFNDEF TESTINSIGHT}
{$IFNDEF GUI_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}{$ENDIF}{$STRONGLINKTYPES ON}

uses
  SysUtils,
  {$IFDEF GUI_TESTRUNNER}
  Vcl.Forms,
  DUnitX.Loggers.GUI.Vcl,
  {$ENDIF }
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF }
  {$IFDEF CONSOLE_TESTRUNNER}
  DUnitX.Loggers.Console,
  {$ENDIF }
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  EventBusTestU in 'EventBusTestU.pas',
  BOs in 'BOs.pas',
  BaseTestU in 'BaseTestU.pas',
  EventBus in '..\source\EventBus.pas',
  EventBus.Helpers in '..\source\EventBus.Helpers.pas',
  EventBus.Subscribers in '..\source\EventBus.Subscribers.pas',
  EventBus.Core in '..\source\EventBus.Core.pas';

{$IFDEF TESTINSIGHT}
TestInsight.DUnitX.RunRegisteredTests;
Exit;
{$ENDIF}

{$IFDEF CONSOLE_TESTRUNNER}
procedure MainConsole();
var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  nunitLogger: ITestLogger;
try
  // Check command line options, will exit if invalid
  TDUnitX.CheckCommandLine;
  // Create the test runner
  runner := TDUnitX.CreateRunner;
  // Tell the runner to use RTTI to find Fixtures
  runner.UseRTTI := true;
  // tell the runner how we will log things
  // Log to the console window
  logger := TDUnitXConsoleLogger.Create(true);
  runner.AddLogger(logger);
  // Generate an NUnit compatible XML File
  nunitLogger := TDUnitXXMLNUnitFileLogger.Create
    (TDUnitX.Options.XMLOutputFile);
  runner.AddLogger(nunitLogger);
  runner.FailsOnNoAsserts := False;
  // When true, Assertions must be made during tests;

  // Run tests
  results := runner.Execute;
  if not results.AllPassed then
    System.ExitCode := EXIT_ERRORS;

{$IFNDEF CI}
  // We don't want this happening when running under CI.
  if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
  begin
    System.Write('Done.. press <Enter> key to quit.');
    System.Readln;
  end;
{$ENDIF}
except
  on E: Exception do
    System.Writeln(E.ClassName, ': ', E.Message);
end;
{$ENDIF}
{$IFDEF GUI_TESTRUNNER}

procedure MainGUI;
begin
  Application.Initialize;
  Application.CreateForm(TGUIVCLTestRunner, GUIVCLTestRunner);
  Application.Run;
end;
{$ENDIF}

begin
  ReportMemoryLeaksOnShutdown := true;
{$IFDEF CONSOLE_TESTRUNNER}
  MainConsole();
{$ENDIF}
{$IFDEF GUI_TESTRUNNER}
  MainGUI();
{$ENDIF}

end.
