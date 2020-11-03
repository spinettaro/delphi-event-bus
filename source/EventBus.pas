{ *******************************************************************************
  Copyright 2016-2020 Daniele Spinetti

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

unit EventBus;

interface

uses
  System.Classes, System.SysUtils;

type

  TThreadMode = (Posting, Main, Async, Background);

  IEventBus = Interface
    ['{7BDF4536-F2BA-4FBA-B186-09E1EE6C7E35}']
    function IsRegisteredForChannels(ASubscriber: TObject): Boolean;
    function IsRegisteredForEvents(ASubscriber: TObject): Boolean;

    procedure Post(const AChannel: string; const AMessage: string); overload;
    procedure Post(AEvent: IInterface; const AContext: string = ''); overload;

    procedure RegisterSubscriberForChannels(ASubscriber: TObject);
    procedure UnregisterForChannels(ASubscriber: TObject);

    procedure RegisterSubscriberForEvents(ASubscriber: TObject);
    procedure UnregisterForEvents(ASubscriber: TObject);
  end;

  SubscribeAttribute = class(TCustomAttribute)
  private
    FContext: string;
    FThreadMode: TThreadMode;
  public
    constructor Create(AThreadMode: TThreadMode = TThreadMode.Posting; const AContext: string = '');
    property ThreadMode: TThreadMode read FThreadMode;
    property Context: string read FContext;
  end;

  ChannelAttribute = class(TCustomAttribute)
  private
    FChannel: string;
    FThreadMode: TThreadMode;
  public
    constructor Create(const AChannel: string; AThreadMode: TThreadMode = TThreadMode.Posting);
    property ThreadMode: TThreadMode read FThreadMode;
    property Channel: string read FChannel;
  end;

  IDEBEvent<T> = interface(IInterface)
  ['{AFDFF9C9-46D8-4663-9535-2BBB1396587C}']
    function GetData: T;
    procedure SetData(const Value: T);
    function GetOwnsData: Boolean;
    procedure SetOwnsData(const Value: Boolean);

    property Data: T read GetData write SetData;
    property OwnsData: Boolean read GetOwnsData write SetOwnsData;
  end;

  TDEBEvent<T> = class(TInterfacedObject, IDEBEvent<T>)
  private
    FData: T;
    FOwnsData: Boolean;
    function GetData: T;
    procedure SetData(const Value: T);
    function GetOwnsData: Boolean;
    procedure SetOwnsData(const Value: Boolean);
  public
    constructor Create; overload;
    constructor Create(AData: T); overload;
    destructor Destroy; override;

    property Data: T read FData write SetData;
    property OwnsData: Boolean read GetOwnsData write SetOwnsData;
  end;

function GlobalEventBus: IEventBus;

implementation

uses
  System.Rtti, EventBus.Core;

var
  FGlobalEventBus: IEventBus;

constructor SubscribeAttribute.Create(AThreadMode: TThreadMode = TThreadMode.Posting; const AContext: string = '');
begin
  inherited Create;
  FContext := AContext;
  FThreadMode := AThreadMode;
end;

constructor TDEBEvent<T>.Create;
begin
  inherited Create;
end;

constructor TDEBEvent<T>.Create(AData: T);
begin
  inherited Create;
  OwnsData := True;
  Data := AData;
end;

destructor TDEBEvent<T>.Destroy;
var
  LValue: TValue;
begin
  LValue := TValue.From<T>(Data);

  if (LValue.IsObject) and OwnsData then
    LValue.AsObject.Free;

  inherited;
end;

function TDEBEvent<T>.GetData: T;
begin
  Result:= FData;
end;

procedure TDEBEvent<T>.SetData(const Value: T);
begin
  FData := Value;
end;

function TDEBEvent<T>.GetOwnsData: Boolean;
begin
  Result:= FOwnsData;
end;

procedure TDEBEvent<T>.SetOwnsData(const Value: Boolean);
begin
  FOwnsData := Value;
end;

function GlobalEventBus: IEventBus;
begin
  if not Assigned(FGlobalEventBus) then
    FGlobalEventBus := TEventBus.Create;

  Result := FGlobalEventBus;
end;

constructor ChannelAttribute.Create(const AChannel: string; AThreadMode: TThreadMode = TThreadMode.Posting);
begin
  FThreadMode := AThreadMode;
  FChannel := AChannel;
end;

initialization
  GlobalEventBus;

finalization

end.
