unit MainFMX;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms,
  FMX.Dialogs, FMX.StdCtrls, FMX.Controls.Presentation, FMX.Layouts,
  FMX.Objects, FMX.Edit, FMX.TabControl, BOsU, EventBus, ServicesU;

type
  THeaderFooterForm = class(TForm)
    AniIndicator1: TAniIndicator;
    Button1: TButton;
    Button2: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    GridPanelLayout1: TGridPanelLayout;
    GridPanelLayout2: TGridPanelLayout;
    Header: TToolBar;
    HeaderLabel: TLabel;
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    Text1: TText;
    Text2: TText;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    FRemoteDataContext: IRemoteDataContext;
  public
    { Public declarations }
    [Subscribe(TThreadMode.Main)]
    procedure OnAfterLogin(AEvent: IOnLoginEvent);
  end;

var
  HeaderFooterForm: THeaderFooterForm;

implementation

{$R *.fmx}

procedure THeaderFooterForm.Button1Click(Sender: TObject);
var
  LLoginDTO: TLoginDTO;
begin
  AniIndicator1.Enabled := true;
  Button1.Enabled := false;
  LLoginDTO := TLoginDTO.Create(Edit1.Text, Edit2.Text);
  FRemoteDataContext.Login(LLoginDTO);
end;

procedure THeaderFooterForm.Button2Click(Sender: TObject);
begin
  TabControl1.SetActiveTabWithTransition(TabItem1, TTabTransition.None);
end;

procedure THeaderFooterForm.FormCreate(Sender: TObject);
begin
  TabControl1.ActiveTab := TabItem1;
  FRemoteDataContext:= CreateRemoteDataContext;
  // register subscribers
  GlobalEventBus.RegisterSubscriberForEvents(Self);
end;

procedure THeaderFooterForm.OnAfterLogin(AEvent: IOnLoginEvent);
begin
  AniIndicator1.Enabled := false;
  Button1.Enabled := true;
  Text2.Text := 'Welcome' + sLineBreak + Edit1.Text;
  TabControl1.SetActiveTabWithTransition(TabItem2, TTabTransition.Slide);
end;

end.
