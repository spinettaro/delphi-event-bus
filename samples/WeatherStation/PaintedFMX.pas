unit PaintedFMX;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  System.ImageList, FMX.ImgList, ModelU, EventBus;

type
  TPaintedForm = class(TForm)
    Image1: TImage;
    ImageList1: TImageList;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    [Subscribe(TThreadMode.Main)]
    procedure OnWeatherInfoEvent(aWeatherInfo: TWeatherInformation);

  end;

var
  PaintedForm: TPaintedForm;

implementation

{$R *.fmx}
{ TPaintedForm }

procedure TPaintedForm.FormCreate(Sender: TObject);
begin
  GlobalEventBus.RegisterSubscriberForEvents(Self);
end;

procedure TPaintedForm.OnWeatherInfoEvent(aWeatherInfo: TWeatherInformation);
begin
  Image1.Bitmap := ImageList1.Bitmap(Image1.Size.Size,
    Integer(aWeatherInfo.WeatherType));
end;

end.
