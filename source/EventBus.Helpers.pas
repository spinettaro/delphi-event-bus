unit EventBus.Helpers;

interface

uses
  System.Generics.Collections,
  System.Rtti,
  System.SysUtils,
  System.TypInfo;

type
  TRttiUtils = class sealed
  strict private
    class var FContext: TRttiContext;
  public
    /// <summary>
    ///   Examines an RTTI member object to check if it has the required type of attribute specified.
    /// </summary>
    /// <typeparam name="T">
    ///   The required type of attribute.
    /// </typeparam>
    /// <param name="ARttiMember">
    ///   The RTTI member object to examine.
    /// </param>
    /// <param name="AAttribute">
    ///   The actual instance of the attribute if the attribute is specified for the RTTI object.
    /// </param>
    /// <returns>
    ///   True if the required attribute is specified for the RTTI object; False otherwise.
    /// </returns>
    class function HasAttribute<T: TCustomAttribute>(ARttiMember: TRttiMember; out AAttribute: T): Boolean; overload;

    /// <summary>
    ///   Examines an RTTI type object to check if it has the required type of
    ///   attribute specified.
    /// </summary>
    /// <typeparam name="T">
    ///   The required type of attribute.
    /// </typeparam>
    /// <param name="ARttiType">
    ///   The RTTI type object to examine.
    /// </param>
    /// <param name="AAttribute">
    ///   The actual instance of the attribute if the attribute is specified
    ///   for the RTTI object.
    /// </param>
    /// <returns>
    ///   True if the required attribute is specified for the RTTI object;
    ///   False otherwise.
    /// </returns>
    class function HasAttribute<T: TCustomAttribute>(ARttiType: TRttiType; out AAttribute: T): Boolean; overload;

    /// <summary>
    ///   Rtti context.
    /// </summary>
    class property Context: TRttiContext read FContext;
  end;

  /// <summary>
  ///   Provides interface type helper.
  /// </summary>
  /// <remarks>
  ///   TInterfaceHelper borrows the code from the answer to this StackOverflow question:
  ///   <see href="https://stackoverflow.com/questions/39584234/how-to-obtain-rtti-from-an-interface-reference-in-delphi" />
  /// </remarks>
  TInterfaceHelper = record
  strict private type
    TInterfaceTypes = TDictionary<TGUID, TRttiInterfaceType>;
  strict private
    class var FInterfaceTypes: TInterfaceTypes;
    class var FCached: Boolean;  // Boolean in Delphi is atomic
    class var FCaching: Boolean;
    class constructor Create;
    class destructor Destroy;
    class procedure CacheIfNotCachedAndWaitFinish; static;
    class procedure WaitIfCaching; static;
  public

    /// <summary>
    ///   Refreshes the cached RTTI interface types in a background thread (eg.
    ///   when new package is loaded).
    /// </summary>
    /// <remarks>
    ///   RefreshCache is called at program initialization automatically by the
    ///   class constructor. It may also be called as needed when a package is
    ///   loaded. The purpose of the cache is to speed up querying a given
    ///   interface type inside GetType method.
    /// </remarks>
    class procedure RefreshCache; static;

    /// <summary>
    ///   Obtains the RTTI interface type object of the specified interface.
    /// </summary>
    class function GetType(const AIntf: IInterface): TRttiInterfaceType; overload; static;

    /// <summary>
    ///   Obtains the RTTI interface type object of the specified interface GUID.
    /// </summary>
    class function GetType(const AGuid: TGUID): TRttiInterfaceType; overload; static;

    /// <summary>
    ///   Obtains the RTTI interface type object of the specified TValue-boxed interface.
    /// </summary>
    class function GetType(const AIntfInTValue: TValue): TRttiInterfaceType; overload; static;

    /// <summary>
    ///   Obtains the name of the interface type.
    /// </summary>
    class function GetTypeName(const AIntf: IInterface): string; overload; static;

    /// <summary>
    ///   Obtains the name of the interface type identified by a GUID.
    /// </summary>
    class function GetTypeName(const AGuid: TGUID): string; overload; static;

    /// <summary>
    ///   Obtains the qualified name of the interface type. A qualified name
    ///   includes the unit name separated by dot.
    /// </summary>
    class function GetQualifiedName(const AIntf: IInterface): string; overload; static;

    /// <summary>
    ///   Obtains the qualified name of the interface type identified by a
    ///   GUID. A qualified name includes the unit name separated by dot.
    /// </summary>
    class function GetQualifiedName(const AGuid: TGUID): string; overload; static;

    /// <summary>
    ///   Obtains a list of RTTI objects for all the methods that are members of the specified
    ///   interface.
    /// </summary>
    class function GetMethods(const AIntf: IInterface): TArray<TRttiMethod>; static;

    /// <summary>
    ///   Returns an RTTI object for the interface method with the
    ///   specified name.
    /// </summary>
    class function GetMethod(const AIntf: IInterface; const AMethodName: string): TRttiMethod; static;

    /// <summary>
    ///   Performs a call to the described method.
    /// </summary>
    class function InvokeMethod(const AIntf: IInterface; const AMethodName: string;
      const Args: array of TValue): TValue; overload; static;

    /// <summary>
    ///   Performs a call to the described method.
    /// </summary>
    class function InvokeMethod(const AIntfInTValue: TValue; const AMethodName: string;
      const Args: array of TValue): TValue; overload; static;
  end;

  /// <summary>
  ///   Throws when the method with the specified name is not found.
  /// </summary>
  EMethodNotFound = class(Exception)
  public
    constructor Create(const AMethodName: string);
  end;

implementation

uses
  System.Classes, System.SyncObjs, DUnitX.Utils;

class function TInterfaceHelper.GetType(const AIntf: IInterface): TRttiInterfaceType;
var
  LImplObj: TObject;
  LGuid: TGUID;
  LIntfType: TRttiInterfaceType;
  LTempIntf: IInterface;
begin
  Result := nil;

  try
    // As far as I know, the cast will fail only when AIntf is obatined from OLE Object
    // Is there any other cases?
    LImplObj := AIntf as TObject;
  except
    // For interfaces obtained from OLE Object
    Result := TRttiUtils.Context.GetType(TypeInfo(System.IDispatch)) as TRttiInterfaceType;
    Exit;
  end;

  // For interfaces obtained from TRawVirtualClass (e.g. iOS, Android & Mac intf)
  if LImplObj.ClassType.InheritsFrom(TRawVirtualClass) then begin
    LGuid := LImplObj.GetField('FIIDs').GetValue(LImplObj).AsType<TArray<TGUID>>[0];
    Result := GetType(LGuid);
  end else begin
   // For interfaces obtained from TVirtualInterface
    if LImplObj.ClassType.InheritsFrom(TVirtualInterface) then begin
      LGuid := LImplObj.GetField('FIID').GetValue(LImplObj).AsType<TGUID>;
      Result := GetType(LGuid);
    end else begin
      // For interfaces obtained from Delphi object. Code taken from Remy Lebeau's answer
      // http://stackoverflow.com/questions/39584234/how-to-obtain-rtti-from-an-interface-reference-in-delphi/
      for LIntfType in (TRttiUtils.Context.GetType(LImplObj.ClassType) as TRttiInstanceType).GetImplementedInterfaces do begin
        if LImplObj.GetInterface(LIntfType.GUID, LTempIntf) and (AIntf = LTempIntf) then
          Exit(LIntfType);
      end;
    end;
  end;
end;

class constructor TInterfaceHelper.Create;
begin
  FInterfaceTypes := TInterfaceTypes.Create;
  FCached := False;
  FCaching := False;
  RefreshCache;
end;

class destructor TInterfaceHelper.Destroy;
begin
  FInterfaceTypes.DisposeOf;
end;

class function TInterfaceHelper.GetQualifiedName(const AIntf: IInterface): string;
var
  LType: TRttiInterfaceType;
begin
  LType := GetType(AIntf);

  if Assigned(LType) then
    Result := LType.QualifiedName
  else
    Result := EmptyStr;
end;

class function TInterfaceHelper.GetMethod(const AIntf: IInterface; const AMethodName: string): TRttiMethod;
var
  LType: TRttiInterfaceType;
begin
  LType := GetType(AIntf);

  if Assigned(LType) then
    Result := LType.GetMethod(AMethodName)
  else
    Result := nil;
end;

class function TInterfaceHelper.GetMethods(const AIntf: IInterface): TArray<TRttiMethod>;
var
  LType: TRttiInterfaceType;
begin
  LType := GetType(AIntf);

  if Assigned(LType) then
    Result := LType.GetMethods
  else
    Result := nil;
end;

class function TInterfaceHelper.GetQualifiedName(const AGuid: TGUID): string;
var
  LType: TRttiInterfaceType;
begin
  LType := GetType(AGuid);

  if Assigned(LType) then
    Result := LType.QualifiedName
  else
    Result := EmptyStr;
end;

class function TInterfaceHelper.GetType(const AGuid: TGUID): TRttiInterfaceType;
begin
  CacheIfNotCachedAndWaitFinish;
  Result := FInterfaceTypes.Items[AGuid];
end;

class function TInterfaceHelper.GetTypeName(const AGuid: TGUID): string;
var
  LType: TRttiInterfaceType;
begin
  LType := GetType(AGuid);

  if Assigned(LType) then
    Result := LType.Name
  else
    Result := EmptyStr;
end;

class function TInterfaceHelper.InvokeMethod(const AIntfInTValue: TValue; const AMethodName: string; const Args: array of TValue): TValue;
var
  LMethod: TRttiMethod;
  LType: TRttiInterfaceType;
begin
  LType := GetType(AIntfInTValue);

  if Assigned(LType) then
    LMethod := LType.GetMethod(AMethodName)
  else
    LMethod := nil;

  if Assigned(LMethod) then
    Result := LMethod.Invoke(AIntfInTValue, Args)
  else
    raise EMethodNotFound.Create(AMethodName);
end;

class function TInterfaceHelper.InvokeMethod(const AIntf: IInterface; const AMethodName: string; const Args: array of TValue): TValue;
var
  LMethod: TRttiMethod;
begin
  LMethod := GetMethod(AIntf, AMethodName);

  if not Assigned(LMethod) then
    raise EMethodNotFound.Create(AMethodName);

  Result := LMethod.Invoke(AIntf as TObject, Args);
end;

class function TInterfaceHelper.GetTypeName(const AIntf: IInterface): string;
var
  LType: TRttiInterfaceType;
begin
  Result := string.Empty;
  LType := GetType(AIntf);

  if Assigned(LType) then
    Result := LType.Name;
end;

class procedure TInterfaceHelper.RefreshCache;
begin
  WaitIfCaching;
  FCaching := True;
  FCached := False;

  TThread.CreateAnonymousThread(
    procedure
    var
      LType: TRttiType;
      LIntfType: TRttiInterfaceType;
    begin
      FInterfaceTypes.Clear;

      for LType in TRttiUtils.Context.GetTypes do begin
        if LType.IsInterface then begin
          LIntfType := (LType as TRttiInterfaceType);

          if TIntfFlag.ifHasGuid in LIntfType.IntfFlags then
            FInterfaceTypes.AddOrSetValue(LIntfType.GUID, LIntfType);
        end;
      end;

      FCaching := False;
      FCached := True;
    end
  ).Start;
end;

class procedure TInterfaceHelper.WaitIfCaching;
begin
  if FCaching then TSpinWait.SpinUntil(
    function: Boolean
    begin
      Result := FCached;
    end
  );
end;

class procedure TInterfaceHelper.CacheIfNotCachedAndWaitFinish;
begin
  if FCached then
    Exit;

  // Need to be protected because FCaching is changed inside. This will block GetType method.
  TMonitor.Enter(FInterfaceTypes);
  if not FCaching then RefreshCache;
  TMonitor.Exit(FInterfaceTypes);

  WaitIfCaching;
end;

class function TInterfaceHelper.GetType(const AIntfInTValue: TValue): TRttiInterfaceType;
var
  LType: TRttiType;
begin
  LType := AIntfInTValue.RttiType;

  if LType is TRttiInterfaceType then
    Result := LType as TRttiInterfaceType
  else
    Result := nil;
end;

class function TRttiUtils.HasAttribute<T>(ARttiType: TRttiType; out AAttribute: T): Boolean;
var
  LAttr: TCustomAttribute;
begin
  AAttribute := nil;
  Result := False;

  for LAttr in ARttiType.GetAttributes do begin
    if LAttr is T then begin
      AAttribute := T(LAttr);
      Exit(True);
    end;
  end;
end;

class function TRttiUtils.HasAttribute<T>(ARttiMember: TRttiMember; out AAttribute: T): Boolean;
var
  LAttr: TCustomAttribute;
begin
  AAttribute := nil;
  Result := False;

  for LAttr in ARttiMember.GetAttributes do begin
    if LAttr is T then begin
      AAttribute := T(LAttr);
      Exit(True);
    end;
  end;
end;

constructor EMethodNotFound.Create(const AMethodName: string);
begin
  inherited CreateFmt('Method %s not found.', [AMethodName]);
end;

end.