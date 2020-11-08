unit MainFormU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  LogginFormU, Data.Bind.GenData, System.Rtti, System.Bindings.Outputs,
  Data.Bind.EngExt, Vcl.Bind.DBEngExt, Data.Bind.Components,
  Data.Bind.ObjectScope;

type
  TForm6 = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    LabeledEdit1: TLabeledEdit;
    PrototypeBindSource1: TPrototypeBindSource;
    BindingsList1: TBindingsList;
    LinkFillControlToField1: TLinkFillControlToField;
    LinkFillControlToField2: TLinkFillControlToField;
    RadioGroup1: TRadioGroup;
    procedure Button1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Memo1Change(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form6: TForm6;

implementation

uses
  BOU, EventBus, EventBus.Helpers, System.TypInfo;

{$R *.dfm}

function BuildAnalyticsEvent(const What: string): IAnalyticsEvent;
begin
  Result := TAnalyticsEvent.Create(What, Form6.LabeledEdit1.Text, Now);
end;

procedure TForm6.Button1Click(Sender: TObject);
begin
  GlobalEventBus.Post(BuildAnalyticsEvent('Button1 Clicked'), '');
  ShowMessage('You clicked ' + Button1.Name);
end;

procedure TForm6.FormResize(Sender: TObject);
begin
  GlobalEventBus.Post(BuildAnalyticsEvent('Analytics form changed size'), '');
end;

procedure TForm6.FormShow(Sender: TObject);
begin
  FormLogger.Show;
end;

procedure TForm6.Memo1Change(Sender: TObject);
begin
  GlobalEventBus.Post(BuildAnalyticsEvent('Memo1 Changed'), '');
end;

procedure TForm6.RadioGroup1Click(Sender: TObject);
var
  LChoice: string;
begin
  LChoice := RadioGroup1.Items[RadioGroup1.ItemIndex];
  GlobalEventBus.Post(BuildAnalyticsEvent(LChoice + ' is actual favorite food '), '');
end;

end.
