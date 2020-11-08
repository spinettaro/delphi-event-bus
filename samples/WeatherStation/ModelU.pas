unit ModelU;

interface

uses
  System.SysUtils;

type
  TWeatherType = (Sunny = 0, Cloudy = 1, Rainy = 2);

  IWeatherInformation = interface
    ['{669F0E41-DE90-470E-A90D-94FE537CB735}']
    procedure SetHumidity(const Value: Integer);
    procedure SetPressure(const Value: Double);
    procedure SetTemperature(const Value: Integer);
    procedure SetWeatherType(const Value: TWeatherType);
    function GetHumidity: Integer;
    function GetPressure: Double;
    function GetTemperature: Integer;
    function GetType: TWeatherType;
    property WeatherType: TWeatherType read GetType write SetWeatherType;
    property Temperature: Integer read GetTemperature write SetTemperature;
    property Humidity: Integer read GetHumidity write SetHumidity;
    property Pressure: Double read GetPressure write SetPressure;
  end;

  TWeatherModel = class(TObject)
  private
    class var FStopped: Boolean;
  public
    class procedure StartPolling;
    class procedure StopPolling;
  end;

implementation

uses
  System.Threading, EventBus, System.Classes;

type
  TWeatherInformation = class(TInterfacedObject, IWeatherInformation)
  private
    FHumidity: Integer;
    FWeatherType: TWeatherType;
    FPressure: Double;
    FTemperature: Integer;
    procedure SetHumidity(const Value: Integer);
    procedure SetPressure(const Value: Double);
    procedure SetTemperature(const Value: Integer);
    procedure SetWeatherType(const Value: TWeatherType);
    function GetHumidity: Integer;
    function GetPressure: Double;
    function GetTemperature: Integer;
    function GetType: TWeatherType;
  public
    property WeatherType: TWeatherType read GetType write SetWeatherType;
    property Temperature: Integer read GetTemperature write SetTemperature;
    property Humidity: Integer read GetHumidity write SetHumidity;
    property Pressure: Double read GetPressure write SetPressure;
  end;

function GetRandomWeatherInfo: IWeatherInformation;
begin
  Result := TWeatherInformation.Create;
  Result.Temperature := -10 + Random(41);
  Result.WeatherType := TWeatherType(Random(3));
  Result.Humidity := 30 + Random(41);
  Result.Pressure := 20 + Random(11);
end;

{ TWeatherModel }

class procedure TWeatherModel.StartPolling;
begin
  FStopped:= False;
  TTask.Create(
    procedure
    begin
      while not FStopped do begin
        // simulate a sensor
        GlobalEventBus.Post(GetRandomWeatherInfo, '');
        TThread.Sleep(3000);
      end
    end
  ).Start;
end;

class procedure TWeatherModel.StopPolling;
begin
  FStopped:= True;
end;

{ TWeatherInformation }

function TWeatherInformation.GetHumidity: Integer;
begin
  Result:= FHumidity;
end;

function TWeatherInformation.GetPressure: Double;
begin
  Result:= FPressure;
end;

function TWeatherInformation.GetTemperature: Integer;
begin
  Result:= FTemperature;
end;

function TWeatherInformation.GetType: TWeatherType;
begin
  Result:= FWeatherType;
end;

procedure TWeatherInformation.SetHumidity(const Value: Integer);
begin
  FHumidity := Value;
end;

procedure TWeatherInformation.SetPressure(const Value: Double);
begin
  FPressure := Value;
end;

procedure TWeatherInformation.SetTemperature(const Value: Integer);
begin
  FTemperature := Value;
end;

procedure TWeatherInformation.SetWeatherType(const Value: TWeatherType);
begin
  FWeatherType := Value;
end;

end.
