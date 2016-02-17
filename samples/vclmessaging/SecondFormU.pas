unit SecondFormU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, EventBus.Attributes, EventU;

type
  TfrmSecond = class(TForm)
    MemoObserver: TMemo;
    Panel1: TPanel;
    Label1: TLabel;
    CheckBox1: TCheckBox;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    [Subscribe]
    procedure OnMemoChange(AEvent: TMemoChangeEvent);
    [Subscribe]
    procedure OnCheckBoxChange(AEvent: TCheckBoxEvent);
  end;

var
  frmSecond: TfrmSecond;

implementation

uses
  EventBus, RttiUtilsU, System.Rtti;

{$R *.dfm}

procedure TfrmSecond.FormCreate(Sender: TObject);
begin
  TEventBus.GetDefault.RegisterSubscriber(self);
end;

procedure TfrmSecond.OnCheckBoxChange(AEvent: TCheckBoxEvent);
begin
  CheckBox1.Checked := AEvent.Checked;
end;

procedure TfrmSecond.OnMemoChange(AEvent: TMemoChangeEvent);
begin
  MemoObserver.Lines.Text := AEvent.Text;
end;

end.
