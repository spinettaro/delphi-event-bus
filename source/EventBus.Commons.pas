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

unit EventBus.Commons;

interface

uses
  System.Classes;

type

  TThreadMode = (Posting, Main, Async, Background);

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
    FDataOwner: boolean;
    FData: T;
    procedure SetData(const Value: T);
    procedure SetDataOwner(const Value: boolean);
  public
    constructor Create; overload;
    constructor Create(AData: T); overload;
    destructor Destroy; override;
    property DataOwner: boolean read FDataOwner write SetDataOwner;
    property Data: T read FData write SetData;
  end;

implementation

uses
  RTTIUtilsU, System.Rtti;

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

procedure TDEBEvent<T>.SetDataOwner(const Value: boolean);
begin
  FDataOwner := Value;
end;

end.

