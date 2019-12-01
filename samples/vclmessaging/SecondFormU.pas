unit SecondFormU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, EventU, EventBus;

type
  TfrmSecond = class(TForm)
    MemoObserver: TMemo;
    Panel1: TPanel;
    Label1: TLabel;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    procedure CheckBox2Click(Sender: TObject);
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
  RttiUtilsU, System.Rtti;

{$R *.dfm}

procedure TfrmSecond.CheckBox2Click(Sender: TObject);
begin
  if (CheckBox2.Checked) then
    GlobalEventBus.RegisterSubscriber(self)
  else
    GlobalEventBus.Unregister(self);
end;

procedure TfrmSecond.OnCheckBoxChange(AEvent: TCheckBoxEvent);
begin
  CheckBox1.Checked := AEvent.Checked;
  AEvent.Free;
end;

procedure TfrmSecond.OnMemoChange(AEvent: TMemoChangeEvent);
begin
  MemoObserver.Lines.Text := AEvent.Text;
  AEvent.Free;
end;

end.
