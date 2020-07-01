unit ThirdFormU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, EventU, EventBus,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls;

type
  TfrmThird = class(TForm)
    PaintBox1: TPaintBox;
    procedure PaintBox1Paint(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FMessage: string;
    { Private declarations }
  public
    { Public declarations }
    [Subscribe]
    procedure OnMemoChange(AEvent: TMemoChangeEvent);
  end;

var
  frmThird: TfrmThird;

implementation

uses
  Vcl.GraphUtil;

{$R *.dfm}

procedure TfrmThird.FormCreate(Sender: TObject);
begin
  GlobalEventBus.RegisterSubscriberForEvents(self);
end;

procedure TfrmThird.OnMemoChange(AEvent: TMemoChangeEvent);
begin
  FMessage := AEvent.Text;
  PaintBox1.Repaint;
  AEvent.Free;
end;

procedure TfrmThird.PaintBox1Paint(Sender: TObject);
var
  R: TRect;
begin
  R := ClientRect;
  GradientFillCanvas(PaintBox1.Canvas, clRed, clWhite, R,
    TGradientDirection.gdVertical);
  InflateRect(R, -5, -5);
  PaintBox1.Canvas.Brush.Style := bsClear;
  PaintBox1.Canvas.Font.Size := 18;
  PaintBox1.Canvas.TextRect(R, FMessage, [TTextFormats.tfWordBreak,
    TTextFormats.tfCenter]);
end;

end.
