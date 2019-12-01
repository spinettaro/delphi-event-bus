unit ServicesU;

interface

uses
  BOsU;

type

  IAccessRemoteDataProxy = interface(IInterface)
    ['{A9C0DE85-8FE7-43E0-B9FB-82D1BFE35E4D}']
    procedure DoLogin(aLoginDTO: TLoginDTO);
  end;

function GetAccessRemoteDataProxyInstance: IAccessRemoteDataProxy;

implementation

uses
  EventBus, System.Threading, System.Classes;

var
  FDefaultInstance: IAccessRemoteDataProxy;

type

  TAccessRemoteDataProxy = class(TInterfacedObject, IAccessRemoteDataProxy)
  private
  public
    procedure DoLogin(aLoginDTO: TLoginDTO);
  end;

procedure TAccessRemoteDataProxy.DoLogin(aLoginDTO: TLoginDTO);
begin
  TTask.Run(
    procedure
    begin
      // simulate an http request for 5 seconds
      TThread.Sleep(3000);
      GlobalEventBus.Post(TOnLoginEvent.Create(true, 'Login ok'));
      aLoginDTO.Free;
    end);

end;

function GetAccessRemoteDataProxyInstance: IAccessRemoteDataProxy;
begin
  if (not Assigned(FDefaultInstance)) then
    FDefaultInstance := TAccessRemoteDataProxy.Create;
  Result := FDefaultInstance;
end;

end.
