{ *******************************************************************************
  Copyright 2016-2019 Daniele Spinetti

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

  TCloneEventCallback = function(const AObject: TObject): TObject of object;
  TCloneEventMethod = TFunc<TObject, TObject>;

  IEventBus = Interface
    ['{7BDF4536-F2BA-4FBA-B186-09E1EE6C7E35}']
    procedure RegisterSubscriber(ASubscriber: TObject);
    function IsRegistered(ASubscriber: TObject): Boolean;
    procedure Unregister(ASubscriber: TObject);
    procedure Post(AEvent: TObject; const AContext: String = '';
      AEventOwner: Boolean = true);

    procedure SetOnCloneEvent(const aCloneEvent: TCloneEventCallback);
    procedure AddCustomClassCloning(const AQualifiedClassName: String;
      const aCloneEvent: TCloneEventMethod);
    procedure RemoveCustomClassCloning(const AQualifiedClassName: String);

    property OnCloneEvent: TCloneEventCallback write SetOnCloneEvent;
  end;

  SubscribeAttribute = class(TCustomAttribute)
  private
    FContext: String;
    FThreadMode: TThreadMode;
  public
    constructor Create(AThreadMode: TThreadMode = TThreadMode.Posting;
      const AContext: String = '');
    property ThreadMode: TThreadMode read FThreadMode;
    property Context: String read FContext;
  end;

  TDEBEvent<T> = class(TObject)
  private
    FDataOwner: Boolean;
    FData: T;
    procedure SetData(const Value: T);
    procedure SetDataOwner(const Value: Boolean);
  public
    constructor Create; overload;
    constructor Create(AData: T); overload;
    destructor Destroy; override;
    property DataOwner: Boolean read FDataOwner write SetDataOwner;
    property Data: T read FData write SetData;
  end;

function GlobalEventBus: IEventBus;

implementation

uses
  EventBus.Core, RTTIUtilsU, System.Rtti;

var
  FGlobalEventBus: IEventBus;

  { SubscribeAttribute }

constructor SubscribeAttribute.Create(AThreadMode
  : TThreadMode = TThreadMode.Posting; const AContext: String = '');
begin
  inherited Create;
  FContext := AContext;
  FThreadMode := AThreadMode;
end;

{ TDEBSimpleEvent<T> }

constructor TDEBEvent<T>.Create(AData: T);
begin
  inherited Create;
  DataOwner := true;
  Data := AData;
end;

constructor TDEBEvent<T>.Create;
begin
  inherited Create;
end;

destructor TDEBEvent<T>.Destroy;
var
  LValue: TValue;
begin
  LValue := TValue.From<T>(Data);
  if (LValue.IsObject) and DataOwner then
    LValue.AsObject.Free;
  inherited;
end;

procedure TDEBEvent<T>.SetData(const Value: T);
begin
  FData := Value;
end;

procedure TDEBEvent<T>.SetDataOwner(const Value: Boolean);
begin
  FDataOwner := Value;
end;

function GlobalEventBus: IEventBus;
begin
  if not Assigned(FGlobalEventBus) then
    FGlobalEventBus := TEventBus.Create;
  Result := FGlobalEventBus;
end;

initialization

GlobalEventBus;

finalization

end.
