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

unit EventBus.Subscribers;

interface

uses
  System.Rtti, EventBus;

type
  TSubscriberMethod = class(TObject)
  private
    FContext: string;
    FEventType: string;
    FMethod: TRttiMethod;
    FThreadMode: TThreadMode;
    procedure SetContext(const AValue: string);
    procedure SetEventType(const AValue: string);
    procedure SetMethod(const AValue: TRttiMethod);
    procedure SetThreadMode(const AValue: TThreadMode);
  public
    constructor Create(
      ARttiMethod: TRttiMethod;
      AEventType: string;
      AThreadMode: TThreadMode;
      const AContext: string = '';
      APriority: Integer = 1
    );

    destructor Destroy; override;
    function Equals(AObject: TObject): Boolean; override;

    property Context: string read FContext write SetContext;
    property EventType: string read FEventType write SetEventType;
    property Method: TRttiMethod read FMethod write SetMethod;
    property ThreadMode: TThreadMode read FThreadMode write SetThreadMode;
  end;

  TSubscription = class(TObject)
  private
    FActive: Boolean;
    FSubscriber: TObject;
    FSubscriberMethod: TSubscriberMethod;
    function GetActive: Boolean;
    procedure SetActive(const AValue: Boolean);
    function GetContext: string;
    procedure SetSubscriber(const AValue: TObject);
    procedure SetSubscriberMethod(const AValue: TSubscriberMethod);
  public
    constructor Create(ASubscriber: TObject; ASubscriberMethod: TSubscriberMethod);
    destructor Destroy; override;
    function Equals(AObject: TObject): Boolean; override;

    property Active: Boolean read GetActive write SetActive;
    property Context: string read GetContext;
    property Subscriber: TObject read FSubscriber write SetSubscriber;
    property SubscriberMethod: TSubscriberMethod read FSubscriberMethod write SetSubscriberMethod;
  end;

  TSubscribersFinder = class(TObject)
  public
    class function FindEventsSubscriberMethods(
      ASubscriberClass: TClass;
      ARaiseExcIfEmpty: Boolean = False
    ): TArray<TSubscriberMethod>;

    class function FindChannelsSubcriberMethods(
      ASubscriberClass: TClass;
      ARaiseExcIfEmpty: Boolean = False
    ): TArray<TSubscriberMethod>;
  end;

implementation

uses
  System.SysUtils, System.TypInfo, EventBus.Helpers;

constructor TSubscriberMethod.Create(ARttiMethod: TRttiMethod; AEventType: string; AThreadMode: TThreadMode;
  const AContext: string = ''; APriority: Integer = 1);
begin
  FMethod := ARttiMethod;
  FEventType := AEventType;
  FThreadMode := AThreadMode;
  FContext := AContext;
end;

destructor TSubscriberMethod.Destroy;
begin
  inherited;
end;

function TSubscriberMethod.Equals(AObject: TObject): Boolean;
var
  LOtherSubscriberMethod: TSubscriberMethod;
begin
  if (inherited Equals(AObject)) then begin
    Exit(True)
  end else begin
    if (AObject is TSubscriberMethod) then begin
      LOtherSubscriberMethod := TSubscriberMethod(AObject);
      Exit(LOtherSubscriberMethod.Method.Tostring = Method.Tostring);
    end else begin
      Exit(False);
    end;
  end;
end;

procedure TSubscriberMethod.SetContext(const AValue: string);
begin
  FContext := AValue;
end;

procedure TSubscriberMethod.SetEventType(const AValue: string);
begin
  FEventType := AValue;
end;

procedure TSubscriberMethod.SetMethod(const AValue: TRttiMethod);
begin
  FMethod := AValue;
end;

procedure TSubscriberMethod.SetThreadMode(const AValue: TThreadMode);
begin
  FThreadMode := AValue;
end;

class function TSubscribersFinder.FindChannelsSubcriberMethods(ASubscriberClass: TClass; ARaiseExcIfEmpty: Boolean): TArray<TSubscriberMethod>;
var
  LChannelAttribute: ChannelAttribute;
  LMethod: TRttiMethod;
  LParamsLength: Integer;
  LRttiMethods: TArray<System.Rtti.TRttiMethod>;
  LRttiType: TRttiType;
  LSubMethod: TSubscriberMethod;
begin
  Result := [];
  LRttiType := TRttiUtils.Ctx.GetType(ASubscriberClass);
  LRttiMethods := LRttiType.GetMethods;

  for LMethod in LRttiMethods do begin
    if TRttiUtils.HasAttribute<ChannelAttribute>(LMethod, LChannelAttribute) then begin
      LParamsLength := Length(LMethod.GetParameters);

      if ((LParamsLength <> 1) or (LMethod.GetParameters[0].ParamType.TypeKind <> tkUstring)) then
        raise Exception.CreateFmt(
          'Method  %s has Channel attribute but requires %d arguments. Methods must require a single argument of string type.',
          [LMethod.Name, LParamsLength]);

      LSubMethod := TSubscriberMethod.Create(LMethod, '',  LChannelAttribute.ThreadMode, LChannelAttribute.Channel);
{$IF CompilerVersion >= 28.0}
      Result := Result + [LSubMethod];
{$ELSE}
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LSubMethod;
{$ENDIF}
    end;
  end;

  if (Length(Result) < 1) and ARaiseExcIfEmpty then
    raise Exception.CreateFmt(
      'Class %s and its super classes have no public methods with the Channel attribute specified.',
      [ASubscriberClass.QualifiedClassName]);
end;

class function TSubscribersFinder.FindEventsSubscriberMethods(ASubscriberClass: TClass; ARaiseExcIfEmpty: Boolean = False): TArray<TSubscriberMethod>;
var
  LEventType: string;
  LMethod: TRttiMethod;
  LParamsLength: Integer;
  LRttiMethods: TArray<System.Rtti.TRttiMethod>;
  LRttiType: TRttiType;
  LSubMethod: TSubscriberMethod;
  LSubscribeAttribute: SubscribeAttribute;
begin
  Result := [];
  LRttiType := TRttiUtils.Ctx.GetType(ASubscriberClass);
  LRttiMethods := LRttiType.GetMethods;

  for LMethod in LRttiMethods do begin
    if TRttiUtils.HasAttribute<SubscribeAttribute>(LMethod, LSubscribeAttribute) then begin
      LParamsLength := Length(LMethod.GetParameters);

      if (LParamsLength <> 1) then
        raise Exception.CreateFmt(
          'Method  %s has Subscribe attribute but requires %d arguments. Only single argument is permitted.',
          [LMethod.Name, LParamsLength]);

      if (LMethod.GetParameters[0].ParamType.TypeKind <> TTypeKind.tkInterface) then
        raise Exception.CreateFmt(
          'Method  %s has Subscribe attribute but the Event argument is NOT of interface type.',
          [LMethod.Name]);

      LEventType := LMethod.GetParameters[0].ParamType.QualifiedName;
      LSubMethod := TSubscriberMethod.Create(LMethod, LEventType, LSubscribeAttribute.ThreadMode, LSubscribeAttribute.Context);
{$IF CompilerVersion >= 28.0}
      Result := Result + [LSubMethod];
{$ELSE}
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LSubMethod;
{$ENDIF}
    end;
  end;

  if (Length(Result) < 1) and ARaiseExcIfEmpty then
    raise Exception.CreateFmt(
      'Class %s and its super classes have no public methods with the Subscribe attribute specified',
      [ASubscriberClass.QualifiedClassName]);
end;

constructor TSubscription.Create(ASubscriber: TObject; ASubscriberMethod: TSubscriberMethod);
begin
  inherited Create;
  FSubscriber := ASubscriber;
  FSubscriberMethod := ASubscriberMethod;
  FActive := True;
end;

destructor TSubscription.Destroy;
begin
  if Assigned(FSubscriberMethod) then FreeAndNil(FSubscriberMethod);
  inherited;
end;

function TSubscription.Equals(AObject: TObject): Boolean;
var
  LOtherSubscription: TSubscription;
begin
  if (AObject is TSubscription) then begin
    LOtherSubscription := TSubscription(AObject);
    Exit((Subscriber = LOtherSubscription.Subscriber) and (SubscriberMethod.Equals(LOtherSubscription.SubscriberMethod)));
  end else begin
    Exit(False);
  end;
end;

function TSubscription.GetActive: Boolean;
begin
  TMonitor.Enter(Self);
  try
    Result := FActive;
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TSubscription.SetActive(const AValue: Boolean);
begin
  TMonitor.Enter(Self);
  try
    FActive := AValue;
  finally
    TMonitor.Exit(Self);
  end;
end;

function TSubscription.GetContext: string;
begin
  Result := SubscriberMethod.Context;
end;

procedure TSubscription.SetSubscriber(const AValue: TObject);
begin
  FSubscriber := AValue;
end;

procedure TSubscription.SetSubscriberMethod(const AValue: TSubscriberMethod);
begin
  FSubscriberMethod := AValue;
end;

end.
