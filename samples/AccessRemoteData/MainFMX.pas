unit MainFMX;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms,
  FMX.Dialogs, FMX.StdCtrls, FMX.Controls.Presentation, FMX.Layouts,
  FMX.Objects, FMX.Edit, FMX.TabControl, BOsU, EventBus;

type
  THeaderFooterForm = class(TForm)
    Header: TToolBar;
    HeaderLabel: TLabel;
    GridPanelLayout1: TGridPanelLayout;
    Edit1: TEdit;
    Edit2: TEdit;
    Button1: TButton;
    AniIndicator1: TAniIndicator;
    TabControl1: TTabControl;
    Text1: TText;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    GridPanelLayout2: TGridPanelLayout;
    Button2: TButton;
    Text2: TText;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    [Subscribe(TThreadMode.Main)]
    procedure OnAfterLogin(AEvent: TOnLoginEvent);
  end;

var
  HeaderFooterForm: THeaderFooterForm;

implementation

uses
  ServicesU;

{$R *.fmx}

procedure THeaderFooterForm.Button1Click(Sender: TObject);
var
  lLoginDTO: TLoginDTO;
begin
  AniIndicator1.Enabled := true;
  Button1.Enabled := false;
  lLoginDTO := TLoginDTO.Create(Edit1.Text, Edit2.Text);
  GetAccessRemoteDataProxyInstance.DoLogin(lLoginDTO);
end;

procedure THeaderFooterForm.Button2Click(Sender: TObject);
begin
  TabControl1.SetActiveTabWithTransition(TabItem1, TTabTransition.None);
end;

procedure THeaderFooterForm.FormCreate(Sender: TObject);
begin
  TabControl1.ActiveTab := TabItem1;
  // register subscribers
  GlobalEventBus.RegisterSubscriberForEvents(Self);
end;

procedure THeaderFooterForm.OnAfterLogin(AEvent: TOnLoginEvent);
begin
  AniIndicator1.Enabled := false;
  Button1.Enabled := true;
  Text2.Text := 'Welcome' + sLineBreak + Edit1.Text;
  TabControl1.SetActiveTabWithTransition(TabItem2, TTabTransition.Slide);
end;

end.
