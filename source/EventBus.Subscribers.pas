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
  ///   Encapsulates a subscriber method as an object with relevant properties.
  /// </summary>
  /// <remarks>
  ///   TSubscriberMethod.EventType is represented by the qualified name of the method's
  ///   event argument type. The type of the event argument must be a descendant of
  ///   interface type. EventType can uniquely identify the type of the event.
  /// </remarks>
  TSubscriberMethod = class sealed(TObject)
  strict private
    FContext: string;
    FEventType: string;
    FMethod: TRttiMethod;
    FPriority: Integer;
    FThreadMode: TThreadMode;
    function Get_Category: string;
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
    ///   Encodes Context string and EventType string to a Category string,
    ///   representing the category a subscriber method belongs to.
    /// </summary>
    /// <remarks>
    ///   Named-channel event is a special case of the general event, where the
    ///   channel name is the Context, and System.string is the event type.
    /// </remarks>
    class function EncodeCategory(const AContext: string; const AEventType: string = 'System.string'): string;

    /// <summary>
    ///   Checkes if two subscriber methods are equal. Returns true when
    ///   both method names and argument types are identical.
    /// </summary>
    /// <param name="AObject">
    ///   The object to compare
    /// </param>
    function Equals(AObject: TObject): Boolean; override;

    /// <summary>
    ///   Category of the subscriber method. Internally it takes value of "Context:EventType".
    /// </summary>
    property Category: string read Get_Category;

    /// <summary>
    ///   Context of the subscriber method.
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
    ///   Dispatching priority of the subscriber method. Currently a placeholder
    ///   with no impact on actual event dispatching.
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
    ///   Whether the subject subscription is active.
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
    ///   collected subscriber method must have Subscribe or Channel attribute
    ///   specified.
    /// </summary>
    /// <typeparam name="T">
    ///   An attribute class inherited from TEventBusSubscriberMethodAttribute.
    /// </typeparam>
    /// <param name="ASubscriberClass">
    ///   The subscriber class to collect subscriber methods from.
    /// </param>
    /// <param name="ARaiseExcIfEmpty">
    ///   Whether to raise an EObjectHasNoSubscriberMethods exception when the
    ///   subscriber class does not have any methods with Subscribe or Channel
    ///   attribute specified.
    /// </param>
    /// <exception cref="EInvalidSubscriberMethod">
    ///   Throws whenever a subscriber method of the subscriber class has
    ///   invalid number of arguments or invalid argument type.
    /// </exception>
    /// <exception cref="EObjectHasNoSubscriberMethods">
    ///   Throws when the subscriber class does not have any methods with
    ///   Subscribe or Channel attribute specified, and ARaiseExcIfEmpty is
    ///   True.
    /// </exception>
    class function FindSubscriberMethods<T: TSubscriberMethodAttribute>(ASubscriberClass: TClass;
      ARaiseExcIfEmpty: Boolean = False): TArray<TSubscriberMethod>;
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

class function TSubscriberMethod.EncodeCategory(const AContext: string; const AEventType: string = 'System.string'): string;
begin
  Result := Format('%s:%s', [AContext, AEventType]);
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

function TSubscriberMethod.Get_Category: string;
begin
  Result := EncodeCategory(Context, EventType);
end;

class function TSubscribersFinder.FindSubscriberMethods<T>(ASubscriberClass: TClass;
  ARaiseExcIfEmpty: Boolean = False): TArray<TSubscriberMethod>;
var
  LEventType: string;
  LMethod: TRttiMethod;
  LParamsLength: Integer;
  LRttiMethods: TArray<System.Rtti.TRttiMethod>;
  LRttiType: TRttiType;
  LSubMethod: TSubscriberMethod;
  LAttribute: T;
begin
  {$IF CompilerVersion >= 28.0}
  Result := [];
  {$ELSE}
  SetLength(Result, 0);
  {$ENDIF}

  LRttiType := TRttiUtils.Context.GetType(ASubscriberClass);
  LRttiMethods := LRttiType.GetMethods;

  for LMethod in LRttiMethods do begin
    if TRttiUtils.HasAttribute<T>(LMethod, LAttribute) then begin
      LParamsLength := Length(LMethod.GetParameters);

      if (LParamsLength <> 1) or (LMethod.GetParameters[0].ParamType.TypeKind <> LAttribute.ArgTypeKind) then begin
        raise EInvalidSubscriberMethod.CreateFmt(
          'Method %s.%s has attribute %s with %d argument(s) and argument[0] is of type %s.' +
          'Only 1 argument allowed and that argument must be of %s type.',
          [
            ASubscriberClass.ClassName,
            LAttribute.ClassName,
            LMethod.Name,
            LParamsLength,
            LMethod.GetParameters[0].ParamType.Name,
            TRttiEnumerationType.GetName(LAttribute.ArgTypeKind)
          ]);
      end;

      LEventType := LMethod.GetParameters[0].ParamType.QualifiedName;
      LSubMethod := TSubscriberMethod.Create(LMethod, LEventType, LAttribute.ThreadMode, LAttribute.Context);

      {$IF CompilerVersion >= 28.0}
      Result := Result + [LSubMethod];
      {$ELSE}
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LSubMethod;
      {$ENDIF}
    end;
  end;

  if (Length(Result) < 1) and ARaiseExcIfEmpty then begin
    raise EObjectHasNoSubscriberMethods.CreateFmt(
      'Class %s and its super classes have no public methods with attribute %s defined.',
      [ASubscriberClass.QualifiedClassName, T.ClassName]);
  end;
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
