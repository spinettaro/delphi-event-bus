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
  /// <summary>
  ///   Encapsulates subscriber method as an object with relevant properties.
  /// </summary>
  /// <remarks>
  ///   TSubscriberMethod.EventType is represented by the qualified name of type of the method's
  ///   event argument. The type of the event argument must be a descendant of interface type. EventType
  ///   can uniquely identify the type of the event.
  /// </remarks>
  TSubscriberMethod = class sealed(TObject)
  strict private
    FContext: string;
    FEventType: string;
    FMethod: TRttiMethod;
    FPriority: Integer;
    FThreadMode: TThreadMode;
  public
    /// <param name="ARttiMethod">
    ///   Rtti information about the subject method.
    /// </param>
    /// <param name="AEventType">
    ///   Event type of the method.
    /// </param>
    /// <param name="AThreadMode">
    ///   Designated thread mode.
    /// </param>
    /// <param name="AContext">
    ///   Context of the method.
    /// </param>
    /// <param name="APriority">
    ///   Dispatching priority of the method.
    /// </param>
    constructor Create(ARttiMethod: TRttiMethod; const AEventType: string; AThreadMode: TThreadMode;
      const AContext: string = ''; APriority: Integer = 1);

    /// <summary>
    ///   Checkes if two subscriber methods are equal. Returns true if an only
    ///   if when both method names and argument types are identical.
    /// </summary>
    /// <param name="AObject">
    ///   The object to compare
    /// </param>
    function Equals(AObject: TObject): Boolean; override;

    /// <summary>
    ///   Context of the subscriber method
    /// </summary>
    property Context: string read FContext;
    /// <summary>
    ///   Event type of the subscriber method. It is actually the fully
    ///   qualified name of the event type.
    /// </summary>
    property EventType: string read FEventType;
    /// <summary>
    ///   Rtti information of the subscriber method.
    /// </summary>
    property Method: TRttiMethod read FMethod;
    /// <summary>
    ///   Dispatching priority of the subscriber method. Currently just a place
    ///   holder with no impact on actual event dispatching.
    /// </summary>
    property Priority: Integer read FPriority;
    /// <summary>
    ///   Thread mode of the subscriber method.
    /// </summary>
    property ThreadMode: TThreadMode read FThreadMode;
  end;

  /// <summary>
  ///   Encapsulates the subscriber method and its owner subscriber object.
  /// </summary>
  TSubscription = class sealed(TObject)
  private
    FActive: Boolean;
    FSubscriber: TObject;
    FSubscriberMethod: TSubscriberMethod;
    {$REGION 'Property Gettors and Settors'}
    /// <summary>
    ///   Encapsulates the subscriber method and its defining subscriber
    ///   object.
    /// </summary>
    procedure Set_Active(const AValue: Boolean);
    function Get_Context: string;
    {$ENDREGION}
  public
    constructor Create(ASubscriber: TObject; ASubscriberMethod: TSubscriberMethod);
    destructor Destroy; override;

    /// <summary>
    ///   Checks if two subscriptions are equal. Returns True when both
    ///   having the same subscriber object and the same subscriber method.
    /// </summary>
    function Equals(AObject: TObject): Boolean; override;

    /// <summary>
    ///   Whether the subject subscription is active
    /// </summary>
    property Active: Boolean read FActive write Set_Active;
    /// <summary>
    ///   Context of the subscriber method.
    /// </summary>
    property Context: string read Get_Context;
    /// <summary>
    ///   The subscriber object.
    /// </summary>
    property Subscriber: TObject read FSubscriber;
    /// <summary>
    ///   The subscriber method.
    /// </summary>
    property SubscriberMethod: TSubscriberMethod read FSubscriberMethod;
  end;

  TSubscribersFinder = class(TObject)
  public
    /// <summary>
    ///   Collects all subscriber methods from a given subscriber class. Each
    ///   collected subscriber method must have Subscribe attribute specified.
    /// </summary>
    /// <param name="ASubscriberClass">
    ///   The subscriber class to collect subscriber methods from.
    /// </param>
    /// <param name="ARaiseExcIfEmpty">
    ///   Whether to raise an EObjectHasNoSubscriberMethods when none of the
    ///   methods of the subscriber class has Subscribe attribute specified.
    /// </param>
    /// <exception cref="EInvalidSubscriberMethod">
    ///   When any subscriber method of the subscriber class has invalid number of arguments or invalid
    ///   argument type.
    /// </exception>
    /// <exception cref="EObjectHasNoSubscriberMethods">
    ///   When the subscriber class contains no subscriber methods, and
    ///   ARaiseExcIfEmpty is True.
    /// </exception>
    class function FindEventsSubscriberMethods(ASubscriberClass: TClass; ARaiseExcIfEmpty: Boolean = False): TArray<TSubscriberMethod>;

    /// <summary>
    ///   Collects all subscriber methods from a given subscriber class. Each
    ///   collected subscriber method must have Channel attribute specified.
    /// </summary>
    /// <param name="ASubscriberClass">
    ///   The subscriber class to collect subscriber methods from.
    /// </param>
    /// <param name="ARaiseExcIfEmpty">
    ///   Whether to raise an EObjectHasNoSubscriberMethods when none of the methods of the
    ///   subscriber class has Channel attribute specified.
    /// </param>
    /// <exception cref="EInvalidSubscriberMethod">
    ///   When any subscriber method of the subscriber class has invalid number of arguments or invalid
    ///   argument type.
    /// </exception>
    /// <exception cref="EObjectHasNoSubscriberMethods">
    ///   When the subscriber class contains no subscriber methods, and ARaiseExcIfEmpty is True.
    /// </exception>
    class function FindChannelsSubcriberMethods(ASubscriberClass: TClass; ARaiseExcIfEmpty: Boolean = False): TArray<TSubscriberMethod>;
  end;

implementation

uses
  System.SysUtils, System.TypInfo, EventBus.Helpers;

constructor TSubscriberMethod.Create(ARttiMethod: TRttiMethod; const AEventType: string; AThreadMode: TThreadMode;
  const AContext: string = ''; APriority: Integer = 1);
begin
  FMethod := ARttiMethod;
  FEventType := AEventType;
  FThreadMode := AThreadMode;
  FContext := AContext;
  FPriority := APriority;
end;

function TSubscriberMethod.Equals(AObject: TObject): Boolean;
var
  LOtherSubscriberMethod: TSubscriberMethod;
begin
  if not (AObject is TSubscriberMethod) then
    Exit(False);

  if (inherited Equals(AObject)) then
    Exit(True);

  LOtherSubscriberMethod := TSubscriberMethod(AObject);
  Result := (LOtherSubscriberMethod.Method.Tostring = Method.Tostring) and (LOtherSubscriberMethod.EventType = EventType);
end;

class function TSubscribersFinder.FindChannelsSubcriberMethods(ASubscriberClass: TClass;
  ARaiseExcIfEmpty: Boolean = False): TArray<TSubscriberMethod>;
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
        raise EInvalidSubscriberMethod.CreateFmt(
          'Method %s.%s has Channel attribute with %d argument(s) and argument[0] is of type %s.' +
          'Only one argument allowed and that argument must be of string type.',
          [ASubscriberClass.ClassName, LMethod.Name, LParamsLength, LMethod.GetParameters[0].ParamType.Name]);

      LSubMethod := TSubscriberMethod.Create(LMethod, '', LChannelAttribute.ThreadMode, LChannelAttribute.Channel);
{$IF CompilerVersion >= 28.0}
      Result := Result + [LSubMethod];
{$ELSE}
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LSubMethod;
{$ENDIF}
    end;
  end;

  if (Length(Result) < 1) and ARaiseExcIfEmpty then
    raise EObjectHasNoSubscriberMethods.CreateFmt(
      'Class %s and its super classes have no public methods with Channel attribute.',
      [ASubscriberClass.QualifiedClassName]);
end;

class function TSubscribersFinder.FindEventsSubscriberMethods(ASubscriberClass: TClass;
  ARaiseExcIfEmpty: Boolean = False): TArray<TSubscriberMethod>;
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

      if (LParamsLength <> 1) or (LMethod.GetParameters[0].ParamType.TypeKind <> TTypeKind.tkInterface) then
        raise EInvalidSubscriberMethod.CreateFmt(
          'Method %s.%s has Subscribe attribute with %d argument(s) and argument[0] is of type %s.' +
          'Only 1 argument allowed and that argument must be of interface type.',
          [ASubscriberClass.ClassName, LMethod.Name, LParamsLength, LMethod.GetParameters[0].ParamType.Name]);

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
    raise EObjectHasNoSubscriberMethods.CreateFmt(
      'Class %s and its super classes have no public methods with Subscribe attribute.',
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
  if not (AObject is TSubscription) then
    Exit(False);

  LOtherSubscription := TSubscription(AObject);
  Result := (Subscriber = LOtherSubscription.Subscriber) and (SubscriberMethod.Equals(LOtherSubscription.SubscriberMethod));
end;

procedure TSubscription.Set_Active(const AValue: Boolean);
begin
  TMonitor.Enter(Self);
  try
    FActive := AValue;
  finally
    TMonitor.Exit(Self);
  end;
end;

function TSubscription.Get_Context: string;
begin
  Result := SubscriberMethod.Context;
end;

end.

