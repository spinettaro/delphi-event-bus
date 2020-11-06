unit ServicesU;

interface

uses
    BOsU;

type

    IRemoteDataContext = interface(IInterface)
        ['{05EC9B06-C552-4718-ACF4-AA584F5F65DB}']
        procedure Login(aLoginDTO: TLoginDTO);
    end;

    IAccessRemoteDataProxy = interface(IInterface)
        ['{A9C0DE85-8FE7-43E0-B9FB-82D1BFE35E4D}']
        procedure DoLogin(aLoginDTO: TLoginDTO);
    end;

function GetAccessRemoteDataProxyInstance: IAccessRemoteDataProxy;
function CreateRemoteDataContext: IRemoteDataContext;

implementation

uses
    EventBus,
    System.Threading,
    System.Classes;

var
    FDefaultInstance: IAccessRemoteDataProxy;

type

    TRemoteDataContext = class(TInterfacedObject, IRemoteDataContext)
    private
    public
        procedure Login(aLoginDTO: TLoginDTO);
    end;

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
      // aLoginDTO.Username
      // aLoginDTO.Password
            TThread.Sleep(3000);
            GlobalEventBus.Post(CreateOnLoginEvent(true, 'Login ok'));
            aLoginDTO.Free;
        end);

end;

{ TRemoteDataContext }

procedure TRemoteDataContext.Login(aLoginDTO: TLoginDTO);
begin
    GetAccessRemoteDataProxyInstance.DoLogin(aLoginDTO);
end;

function GetAccessRemoteDataProxyInstance: IAccessRemoteDataProxy;
begin
    if (not Assigned(FDefaultInstance)) then
        FDefaultInstance := TAccessRemoteDataProxy.Create;
    Result := FDefaultInstance;
end;

function CreateRemoteDataContext: IRemoteDataContext;
begin
    Result:= TRemoteDataContext.Create;
end;

end.
