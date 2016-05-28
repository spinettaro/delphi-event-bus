{ *******************************************************************************
  Copyright 2016 Daniele Spinetti

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  ******************************************************************************** }

unit EventBus.Poster;

interface

uses EventBus.Interfaces, System.SysUtils, System.Generics.Collections,
  System.SyncObjs;

type

  TBackgroundPoster = class(TObject)
  private
    FisRunning: boolean;
    FCS: TCriticalSection;
    procedure SetisRunning(const Value: boolean);
  protected
    FQueue: TThreadedQueue<TProc>;
    procedure Run;
    property isRunning: boolean read FisRunning write SetisRunning;
  public
    constructor Create();
    destructor Destroy; override;
    procedure Enqueue(AProc: TProc);
  end;

  {
    TAsyncPoster = class(TInterfacedObject, IRunnable)
    end;


    TMainThreadPoster = class(TInterfacedObject, IRunnable)
    end; }

implementation

uses
  {$IF CompilerVersion >= 28.0}
  System.Threading,
  {$ENDIF}
  System.Classes;

{ TBackgroundPoster }

constructor TBackgroundPoster.Create();
begin
  inherited Create;
  FQueue := TThreadedQueue<TProc>.Create(20, 10, 10);
  FCS := TCriticalSection.Create;
end;

destructor TBackgroundPoster.Destroy;
begin
  if Assigned(FQueue) then
    FQueue.Free;
  if Assigned(FCS) then
    FCS.Free;
  inherited;
end;

{$IF CompilerVersion >= 28.0}
procedure TBackgroundPoster.Enqueue(AProc: TProc);
var
  LTask: ITask;
begin
  FQueue.PushItem(AProc);
  if not isRunning then
  begin
    isRunning := true;
    LTask := TTask.Run(self.Run);
  end;
end;
{$ELSE}
procedure TBackgroundPoster.Enqueue(AProc: TProc);
var
  LThread: TThread;
begin
  FQueue.PushItem(AProc);
  if not isRunning then
  begin
    isRunning := true;
    LThread := TThread.CreateAnonymousThread(self.Run);
    LThread.Start;
  end;
end;
{$ENDIF}

procedure TBackgroundPoster.Run;
var
  LItem: TProc;
  LWaitResult: TWaitResult;
begin
  try
    try
      while true do
      begin
        LWaitResult := FQueue.PopItem(LItem);
        if LWaitResult <> TWaitResult.wrSignaled then
          exit;
        if Assigned(LItem) then
          LItem();
      end;
    except
      on E: Exception do
        { TODO -ospinettaro : Implement Logger }
    end;
  finally
    isRunning := false;
  end;
end;

procedure TBackgroundPoster.SetisRunning(const Value: boolean);
begin
  FCS.Acquire;
  try
    FisRunning := Value;
  finally
    FCS.Release;
  end;
end;

end.
