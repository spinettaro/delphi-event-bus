unit ModelU;

interface

uses
  System.SysUtils;

type

  TWeatherType = (Sunny = 0, Cloudy = 1, Rainy = 2);

  TWeatherInformation = class(TObject)
  private
    FHumidity: Integer;
    FWeatherType: TWeatherType;
    FPressure: Double;
    FTemperature: Integer;
    procedure SetHumidity(const Value: Integer);
    procedure SetPressure(const Value: Double);
    procedure SetTemperature(const Value: Integer);
    procedure SetWeatherType(const Value: TWeatherType);
  public
    property WeatherType: TWeatherType read FWeatherType write SetWeatherType;
    property Temperature: Integer read FTemperature write SetTemperature;
    property Humidity: Integer read FHumidity write SetHumidity;
    property Pressure: Double read FPressure write SetPressure;
  end;

  TWeatherModel = class(TObject)
  public
    class procedure StartPolling;
  end;

implementation

uses
  System.Threading, EventBus, System.Classes;

function GetRandomWeatherInfo: TWeatherInformation;
begin
  Result := TWeatherInformation.Create;
  Result.Temperature := -10 + Random(41);
  Result.WeatherType := TWeatherType(Random(3));
  Result.Humidity := 30 + Random(41);
  Result.Pressure := 20 + Random(11);
end;
{ TWeatherModel }

class procedure TWeatherModel.StartPolling;
var
  LTask: ITask;
begin
  LTask := TTask.Create(
    procedure
    begin
      while True do
      begin
        // simulate a sensor
        GlobalEventBus.Post(GetRandomWeatherInfo);
        TThread.Sleep(3000);
      end
    end);
  LTask.Start;
end;

{ TWeatherInformation }

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
