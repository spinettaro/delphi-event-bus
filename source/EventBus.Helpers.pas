unit EventBus.Helpers;

interface

uses System.Rtti, System.TypInfo, System.Generics.Collections, System.SysUtils;

type

  TRTTIUtils = class sealed
  public
    class var ctx: TRttiContext;
    class function HasAttribute<T: class>(ARTTIMember: TRttiType; out AAttribute: T): boolean; overload;
    class function HasAttribute<T: class>(ARTTIMember: TRttiMember; out AAttribute: T): boolean; overload;
  end;

  // this code is taken from Stefan Glienke from https://stackoverflow.com/questions/39584234/how-to-obtain-rtti-from-an-interface-reference-in-delphi
  TInterfaceHelper = record
  strict private
  type
    TInterfaceTypes = TDictionary<TGUID, TRttiInterfaceType>;

    class var FInterfaceTypes: TInterfaceTypes;
    class var Cached: Boolean;
    class var Caching: Boolean;
    class procedure WaitIfCaching; static;
    class procedure CacheIfNotCachedAndWaitFinish; static;
    class constructor Create;
    class destructor Destroy;
  public
    // refresh cached RTTI in a background thread  (eg. when new package is loaded)
    class procedure RefreshCache; static;

    // get RTTI from interface
    class function GetType(AIntf: IInterface): TRttiInterfaceType;
      overload; static;
    class function GetType(AGUID: TGUID): TRttiInterfaceType; overload; static;
    class function GetType(AIntfInTValue: TValue): TRttiInterfaceType;
      overload; static;

    // get type name from interface
    class function GetTypeName(AIntf: IInterface): String; overload; static;
    class function GetTypeName(AGUID: TGUID): String; overload; static;
    class function GetQualifiedName(AIntf: IInterface): String;
      overload; static;
    class function GetQualifiedName(AGUID: TGUID): String; overload; static;

    // get methods
    class function GetMethods(AIntf: IInterface): TArray<TRttiMethod>; static;
    class function GetMethod(AIntf: IInterface; const MethodName: String)
      : TRttiMethod; static;

    // Invoke method
    class function InvokeMethod(AIntf: IInterface; const MethodName: String;
      const Args: array of TValue): TValue; overload; static;
    class function InvokeMethod(AIntfInTValue: TValue; const MethodName: String;
      const Args: array of TValue): TValue; overload; static;
  end;

implementation

uses System.Classes,
  System.SyncObjs, DUnitX.Utils;

{ TInterfaceHelper }

class function TInterfaceHelper.GetType(AIntf: IInterface): TRttiInterfaceType;
var
  ImplObj: TObject;
  LGUID: TGUID;
  LIntfType: TRttiInterfaceType;
  TempIntf: IInterface;
begin
  Result := nil;

  try
    // As far as I know, the cast will fail only when AIntf is obatined from OLE Object
    // Is there any other cases?
    ImplObj := AIntf as TObject;
  except
    // for interfaces obtained from OLE Object
    Result := TRttiContext.Create.GetType(TypeInfo(System.IDispatch))
      as TRttiInterfaceType;
    Exit;
  end;

  // for interfaces obtained from TRawVirtualClass (for exmaple IOS & Android & Mac interfaces)
  if ImplObj.ClassType.InheritsFrom(TRawVirtualClass) then
  begin
    LGUID := ImplObj.GetField('FIIDs').GetValue(ImplObj).AsType < TArray <
      TGUID >> [0];
    Result := GetType(LGUID);
  end
  // for interfaces obtained from TVirtualInterface
  else if ImplObj.ClassType.InheritsFrom(TVirtualInterface) then
  begin
    LGUID := ImplObj.GetField('FIID').GetValue(ImplObj).AsType<TGUID>;
    Result := GetType(LGUID);
  end
  else
  // for interfaces obtained from Delphi object
  // The code is taken from Remy Lebeau's answer at http://stackoverflow.com/questions/39584234/how-to-obtain-rtti-from-an-interface-reference-in-delphi/
  begin
    for LIntfType in (TRttiContext.Create.GetType(ImplObj.ClassType)
      as TRttiInstanceType).GetImplementedInterfaces do
    begin
      if ImplObj.GetInterface(LIntfType.GUID, TempIntf) then
      begin
        if AIntf = TempIntf then
        begin
          Result := LIntfType;
          Exit;
        end;
      end;
    end;
  end;
end;

class constructor TInterfaceHelper.Create;
begin
  FInterfaceTypes := TInterfaceTypes.Create;
  Cached := False;
  Caching := False;
  RefreshCache;
end;

class destructor TInterfaceHelper.Destroy;
begin
  FInterfaceTypes.DisposeOf;
end;

class function TInterfaceHelper.GetQualifiedName(AIntf: IInterface): String;
var
  LType: TRttiInterfaceType;
begin
  Result := string.Empty;
  LType := GetType(AIntf);
  if Assigned(LType) then
    Result := LType.QualifiedName;
end;

class function TInterfaceHelper.GetMethod(AIntf: IInterface;
  const MethodName: String): TRttiMethod;
var
  LType: TRttiInterfaceType;
begin
  Result := nil;
  LType := GetType(AIntf);
  if Assigned(LType) then
    Result := LType.GetMethod(MethodName);
end;

class function TInterfaceHelper.GetMethods(AIntf: IInterface)
  : TArray<TRttiMethod>;
var
  LType: TRttiInterfaceType;
begin
  Result := [];
  LType := GetType(AIntf);
  if Assigned(LType) then
    Result := LType.GetMethods;
end;

class function TInterfaceHelper.GetQualifiedName(AGUID: TGUID): String;
var
  LType: TRttiInterfaceType;
begin
  Result := string.Empty;
  LType := GetType(AGUID);
  if Assigned(LType) then
    Result := LType.QualifiedName;
end;

class function TInterfaceHelper.GetType(AGUID: TGUID): TRttiInterfaceType;
begin
  CacheIfNotCachedAndWaitFinish;
  Result := FInterfaceTypes.Items[AGUID];
end;

class function TInterfaceHelper.GetTypeName(AGUID: TGUID): String;
var
  LType: TRttiInterfaceType;
begin
  Result := string.Empty;
  LType := GetType(AGUID);
  if Assigned(LType) then
    Result := LType.Name;
end;

class function TInterfaceHelper.InvokeMethod(AIntfInTValue: TValue;
  const MethodName: String; const Args: array of TValue): TValue;
var
  LMethod: TRttiMethod;
  LType: TRttiInterfaceType;
begin
  LMethod:= nil;
  LType := GetType(AIntfInTValue);
  if Assigned(LType) then
    LMethod := LType.GetMethod(MethodName);
  if not Assigned(LMethod) then
    raise Exception.Create('Method not found');
  Result := LMethod.Invoke(AIntfInTValue, Args);
end;

class function TInterfaceHelper.InvokeMethod(AIntf: IInterface;
  const MethodName: String; const Args: array of TValue): TValue;
var
  LMethod: TRttiMethod;
begin
  LMethod := GetMethod(AIntf, MethodName);
  if not Assigned(LMethod) then
    raise Exception.Create('Method not found');
  Result := LMethod.Invoke(TValue.From<IInterface>(AIntf), Args);
end;

class function TInterfaceHelper.GetTypeName(AIntf: IInterface): String;
var
  LType: TRttiInterfaceType;
begin
  Result := string.Empty;
  LType := GetType(AIntf);
  if Assigned(LType) then
    Result := LType.Name;
end;

class procedure TInterfaceHelper.RefreshCache;
var
  LTypes: TArray<TRttiType>;
begin
  WaitIfCaching;

  FInterfaceTypes.Clear;
  Cached := False;
  Caching := True;
  TThread.CreateAnonymousThread(
    procedure
    var
      LType: TRttiType;
      LIntfType: TRttiInterfaceType;
    begin
      LTypes := TRttiContext.Create.GetTypes;

      for LType in LTypes do
      begin
        if LType.TypeKind = TTypeKind.tkInterface then
        begin
          LIntfType := (LType as TRttiInterfaceType);
          if TIntfFlag.ifHasGuid in LIntfType.IntfFlags then
          begin
            FInterfaceTypes.AddOrSetValue(LIntfType.GUID, LIntfType);
          end;
        end;
      end;

      Caching := False;
      Cached := True;
    end).Start;
end;

class procedure TInterfaceHelper.WaitIfCaching;
begin
  if Caching then
    TSpinWait.SpinUntil(
      function: Boolean
      begin
        Result := Cached;
      end);
end;

class procedure TInterfaceHelper.CacheIfNotCachedAndWaitFinish;
begin
  if Cached then
    Exit
  else if not Caching then
  begin
    RefreshCache;
    WaitIfCaching;
  end
  else
    WaitIfCaching;
end;

class function TInterfaceHelper.GetType(AIntfInTValue: TValue)
  : TRttiInterfaceType;
var
  LType: TRttiType;
begin
  Result := nil;
  LType := AIntfInTValue.RttiType;
  if LType is TRttiInterfaceType then
    Result := LType as TRttiInterfaceType;
end;

{ TRTTIUtils }

class function TRTTIUtils.HasAttribute<T>(ARTTIMember: TRttiType;
  out AAttribute: T): boolean;
var
  attrs: TArray<TCustomAttribute>;
  Attr: TCustomAttribute;
begin
  AAttribute := nil;
  Result := False;
  attrs := ARTTIMember.GetAttributes;
  for Attr in attrs do
    if Attr is T then
    begin
      AAttribute := T(Attr);
      Exit(true);
    end;
end;

class function TRTTIUtils.HasAttribute<T>(ARTTIMember: TRttiMember;
  out AAttribute: T): boolean;
var
  attrs: TArray<TCustomAttribute>;
  Attr: TCustomAttribute;
begin
  AAttribute := nil;
  Result := False;
  attrs := ARTTIMember.GetAttributes;
  for Attr in attrs do
    if Attr is T then
    begin
      AAttribute := T(Attr);
      Exit(true);
    end;
end;

end.