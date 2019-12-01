unit MainFormU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TfrmMain = class(TForm)
    Memo1: TMemo;
    Panel1: TPanel;
    CheckBox1: TCheckBox;
    procedure Memo1Change(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses
  EventBus, EventU;

{$R *.dfm}

procedure TfrmMain.CheckBox1Click(Sender: TObject);
var
  Event: TCheckBoxEvent;
begin
  Event := TCheckBoxEvent.Create();
  Event.Checked := CheckBox1.Checked;
  GlobalEventBus.Post(Event);
end;

procedure TfrmMain.Memo1Change(Sender: TObject);
var
  Event: TMemoChangeEvent;
begin
  Event := TMemoChangeEvent.Create();
  Event.Text := Memo1.Lines.Text;
  GlobalEventBus.Post(Event);
end;

end.
