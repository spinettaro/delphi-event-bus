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
    procedure OnMemoChange(AEvent: IMemoChangeEvent);
    [Subscribe]
    procedure OnCheckBoxChange(AEvent: ICheckBoxEvent);
  end;

var
  FrmSecond: TfrmSecond;

implementation

{$R *.dfm}

procedure TfrmSecond.CheckBox2Click(Sender: TObject);
begin
  if (CheckBox2.Checked) then
    GlobalEventBus.RegisterSubscriberForEvents(Self)
  else
    GlobalEventBus.UnregisterForEvents(Self);
end;

procedure TfrmSecond.OnCheckBoxChange(AEvent: ICheckBoxEvent);
begin
  CheckBox1.Checked := AEvent.Checked;
end;

procedure TfrmSecond.OnMemoChange(AEvent: IMemoChangeEvent);
begin
  MemoObserver.Lines.Text := AEvent.Text;
end;

end.
