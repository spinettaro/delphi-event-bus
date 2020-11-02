unit EventBus.Helpers;

interface

uses
  System.Generics.Collections,
  System.Rtti,
  System.SysUtils,
  System.TypInfo;

type

  TRttiUtils = class sealed
  public
    class var Ctx: TRttiContext;
    class function HasAttribute<T: class>(ARTTIMember: TRttiMember; out AAttribute: T): Boolean; overload;
    class function HasAttribute<T: class>(ARTTIMember: TRttiType; out AAttribute: T): Boolean; overload;
  end;

  // This code is taken from Stefan Glienke from
  // https://stackoverflow.com/questions/39584234/how-to-obtain-rtti-from-an-interface-reference-in-delphi
  TInterfaceHelper = record
  strict private
  type
    TInterfaceTypes = TDictionary<TGUID, TRttiInterfaceType>;

    class var FInterfaceTypes: TInterfaceTypes;
    class var FCached: Boolean;
    class var FCaching: Boolean;
    class procedure WaitIfCaching; static;
    class procedure CacheIfNotCachedAndWaitFinish; static;
    class constructor Create;
    class destructor Destroy;
  public
    // Refresh cached RTTI in a background thread  (eg. when new package is loaded)
    class procedure RefreshCache; static;

    // Get RTTI from interface
    class function GetType(AIntf: IInterface): TRttiInterfaceType; overload; static;
    class function GetType(AGUID: TGUID): TRttiInterfaceType; overload; static;
    class function GetType(AIntfInTValue: TValue): TRttiInterfaceType; overload; static;

    // Get type name from interface
    class function GetTypeName(AIntf: IInterface): string; overload; static;
    class function GetTypeName(AGUID: TGUID): string; overload; static;
    class function GetQualifiedName(AIntf: IInterface): string; overload; static;
    class function GetQualifiedName(AGUID: TGUID): string; overload; static;

    // Get methods
    class function GetMethods(AIntf: IInterface): TArray<TRttiMethod>; static;
    class function GetMethod(AIntf: IInterface; const MethodName: string): TRttiMethod; static;

    // Invoke method
    class function InvokeMethod(AIntf: IInterface; const MethodName: string; const Args: array of TValue): TValue; overload; static;
    class function InvokeMethod(AIntfInTValue: TValue; const MethodName: string; const Args: array of TValue): TValue; overload; static;
  end;

implementation

uses
  System.Classes,
  System.SyncObjs,
  DUnitX.Utils; // For TObjectHelper.GetField

{ TInterfaceHelper }

class function TInterfaceHelper.GetType(AIntf: IInterface): TRttiInterfaceType;
var
  LImplObj: TObject;
  LGUID: TGUID;
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
    Result := TRttiContext.Create.GetType(TypeInfo(System.IDispatch)) as TRttiInterfaceType;
    Exit;
  end;

  // For interfaces obtained from TRawVirtualClass (e.g. iOS, Android & Mac intf)
  if LImplObj.ClassType.InheritsFrom(TRawVirtualClass) then begin
    LGUID := LImplObj.GetField('FIIDs').GetValue(LImplObj).AsType<TArray<TGUID>>[0];
    Result := GetType(LGUID);
  end else begin
     // For interfaces obtained from TVirtualInterface
    if LImplObj.ClassType.InheritsFrom(TVirtualInterface) then begin
      LGUID := LImplObj.GetField('FIID').GetValue(LImplObj).AsType<TGUID>;
      Result := GetType(LGUID);
    end else begin
      // For interfaces obtained from Delphi object. Code taken from Remy Lebeau's answer
      // http://stackoverflow.com/questions/39584234/how-to-obtain-rtti-from-an-interface-reference-in-delphi/
      for LIntfType in (TRttiContext.Create.GetType(LImplObj.ClassType) as TRttiInstanceType).GetImplementedInterfaces do begin
        if LImplObj.GetInterface(LIntfType.GUID, LTempIntf) then begin
          if AIntf = LTempIntf then begin
            Result := LIntfType;
            Exit;
          end;
        end;
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

class function TInterfaceHelper.GetQualifiedName(AIntf: IInterface): string;
var
  LType: TRttiInterfaceType;
begin
  Result := string.Empty;
  LType := GetType(AIntf);

  if Assigned(LType) then
    Result := LType.QualifiedName;
end;

class function TInterfaceHelper.GetMethod(AIntf: IInterface; const MethodName: string): TRttiMethod;
var
  LType: TRttiInterfaceType;
begin
  Result := nil;
  LType := GetType(AIntf);

  if Assigned(LType) then
    Result := LType.GetMethod(MethodName);
end;

class function TInterfaceHelper.GetMethods(AIntf: IInterface): TArray<TRttiMethod>;
var
  LType: TRttiInterfaceType;
begin
  Result := [];
  LType := GetType(AIntf);

  if Assigned(LType) then
    Result := LType.GetMethods;
end;

class function TInterfaceHelper.GetQualifiedName(AGUID: TGUID): string;
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

class function TInterfaceHelper.GetTypeName(AGUID: TGUID): string;
var
  LType: TRttiInterfaceType;
begin
  Result := string.Empty;
  LType := GetType(AGUID);

  if Assigned(LType) then
    Result := LType.Name;
end;

class function TInterfaceHelper.InvokeMethod(AIntfInTValue: TValue; const MethodName: string; const Args: array of TValue): TValue;
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

class function TInterfaceHelper.InvokeMethod(AIntf: IInterface; const MethodName: string; const Args: array of TValue): TValue;
var
  LMethod: TRttiMethod;
begin
  LMethod := GetMethod(AIntf, MethodName);

  if not Assigned(LMethod) then
    raise Exception.Create('Method not found');

  Result := LMethod.Invoke(TValue.From<IInterface>(AIntf), Args);
end;

class function TInterfaceHelper.GetTypeName(AIntf: IInterface): string;
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
  FCached := False;
  FCaching := True;

  TThread.CreateAnonymousThread(
    procedure
    var
      LType: TRttiType;
      LIntfType: TRttiInterfaceType;
    begin
      LTypes := TRttiContext.Create.GetTypes;

      for LType in LTypes do begin
        if LType.TypeKind = TTypeKind.tkInterface then begin
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
  if FCaching then
    TSpinWait.SpinUntil(
      function: Boolean
      begin
        Result := FCached;
      end
    );
end;

class procedure TInterfaceHelper.CacheIfNotCachedAndWaitFinish;
begin
  if FCached then begin
    Exit
  end else begin
    if not FCaching then begin
      RefreshCache;
      WaitIfCaching;
    end else begin
      WaitIfCaching;
    end;
  end;
end;

class function TInterfaceHelper.GetType(AIntfInTValue: TValue): TRttiInterfaceType;
var
  LType: TRttiType;
begin
  Result := nil;
  LType := AIntfInTValue.RttiType;

  if LType is TRttiInterfaceType then
    Result := LType as TRttiInterfaceType;
end;

class function TRttiUtils.HasAttribute<T>(ARTTIMember: TRttiType; out AAttribute: T): Boolean;
var
  LAttrs: TArray<TCustomAttribute>;
  LAttr: TCustomAttribute;
begin
  AAttribute := nil;
  Result := False;
  LAttrs := ARTTIMember.GetAttributes;

  for LAttr in LAttrs do begin
    if LAttr is T then begin
      AAttribute := T(LAttr);
      Exit(True);
    end;
  end;
end;

class function TRttiUtils.HasAttribute<T>(ARTTIMember: TRttiMember; out AAttribute: T): Boolean;
var
  LAttrs: TArray<TCustomAttribute>;
  LAttr: TCustomAttribute;
begin
  AAttribute := nil;
  Result := False;
  LAttrs := ARTTIMember.GetAttributes;

  for LAttr in LAttrs do begin
    if LAttr is T then begin
      AAttribute := T(LAttr);
      Exit(True);
    end;
  end;
end;

end.