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
  System.RTTI, EventBus;

type

  TSubscriberMethod = class(TObject)
  private
    FContext: string;
    FEventType: string;
    FMethod: TRttiMethod;
    FThreadMode: TThreadMode;
    procedure SetContext(const Value: string);
    procedure SetEventType(const Value: string);
    procedure SetMethod(const Value: TRttiMethod);
    procedure SetThreadMode(const Value: TThreadMode);
  public
    constructor Create(
      ARttiMethod: TRttiMethod;
      AEventType: string;
      AThreadMode: TThreadMode;
      const AContext: string = '';
      APriority: Integer = 1
    );

    destructor Destroy; override;
    function Equals(Obj: TObject): Boolean; override;

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
    procedure SetActive(const Value: Boolean);
    function GetContext: string;
    procedure SetSubscriber(const Value: TObject);
    procedure SetSubscriberMethod(const Value: TSubscriberMethod);
  public
    constructor Create(ASubscriber: TObject; ASubscriberMethod: TSubscriberMethod);
    destructor Destroy; override;
    function Equals(Obj: TObject): Boolean; override;

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

function TSubscriberMethod.Equals(Obj: TObject): Boolean;
var
  LOtherSubscriberMethod: TSubscriberMethod;
begin
  if (inherited Equals(Obj)) then begin
    Exit(True)
  end else begin
    if (Obj is TSubscriberMethod) then begin
      LOtherSubscriberMethod := TSubscriberMethod(Obj);
      exit(LOtherSubscriberMethod.Method.Tostring = Method.Tostring);
    end else begin
      Exit(False);
    end;
  end;
end;

procedure TSubscriberMethod.SetContext(const Value: string);
begin
  FContext := Value;
end;

procedure TSubscriberMethod.SetEventType(const Value: string);
begin
  FEventType := Value;
end;

procedure TSubscriberMethod.SetMethod(const Value: TRttiMethod);
begin
  FMethod := Value;
end;

procedure TSubscriberMethod.SetThreadMode(const Value: TThreadMode);
begin
  FThreadMode := Value;
end;


class function TSubscribersFinder.FindChannelsSubcriberMethods(ASubscriberClass: TClass;
  ARaiseExcIfEmpty: Boolean): TArray<TSubscriberMethod>;
var
  LChannelAttribute: ChannelAttribute;
  LMethod: TRttiMethod;
  LParamsLength: Integer;
  LRttiMethods: TArray<System.RTTI.TRttiMethod>;
  LRttiType: TRttiType;
  LSubMethod: TSubscriberMethod;
begin
  Result := [];
  LRttiType := TRTTIUtils.Ctx.GetType(ASubscriberClass);
  LRttiMethods := LRttiType.GetMethods;

  for LMethod in LRttiMethods do begin
    if TRTTIUtils.HasAttribute<ChannelAttribute>(LMethod, LChannelAttribute) then begin
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

class function TSubscribersFinder.FindEventsSubscriberMethods(ASubscriberClass: TClass;
  ARaiseExcIfEmpty: Boolean = False): TArray<TSubscriberMethod>;
var
  LEventType: string;
  LMethod: TRttiMethod;
  LParamsLength: Integer;
  LRttiMethods: TArray<System.RTTI.TRttiMethod>;
  LRttiType: TRttiType;
  LSubMethod: TSubscriberMethod;
  LSubscribeAttribute: SubscribeAttribute;
begin
  Result := [];
  LRttiType := TRTTIUtils.Ctx.GetType(ASubscriberClass);
  LRttiMethods := LRttiType.GetMethods;

  for LMethod in LRttiMethods do begin
    if TRTTIUtils.HasAttribute<SubscribeAttribute>(LMethod, LSubscribeAttribute) then begin
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
  if Assigned(FSubscriberMethod) then
    FreeAndNil(FSubscriberMethod);

  inherited;
end;

function TSubscription.Equals(Obj: TObject): Boolean;
var
  LOtherSubscription: TSubscription;
begin
  if (Obj is TSubscription) then begin
    LOtherSubscription := TSubscription(Obj);
    Exit((Subscriber = LOtherSubscription.Subscriber) and (SubscriberMethod.Equals(LOtherSubscription.SubscriberMethod)));
  end else begin
    Exit(False);
  end;
end;

function TSubscription.GetActive: Boolean;
begin
  TMonitor.Enter(self);
  try
    Result := FActive;
  finally
    TMonitor.exit(self);
  end;
end;

procedure TSubscription.SetActive(const Value: Boolean);
begin
  TMonitor.Enter(self);
  try
    FActive := Value;
  finally
    TMonitor.exit(self);
  end;
end;

function TSubscription.GetContext: string;
begin
  Result := SubscriberMethod.Context;
end;

procedure TSubscription.SetSubscriber(const Value: TObject);
begin
  FSubscriber := Value;
end;

procedure TSubscription.SetSubscriberMethod(const Value: TSubscriberMethod);
begin
  FSubscriberMethod := Value;
end;

end.
