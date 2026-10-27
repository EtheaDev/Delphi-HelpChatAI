{******************************************************************************}
{                                                                              }
{   HelpChatAI CRM demo - FireMonkey                                           }
{                                                                              }
{   The Windows 10 CRM demo of Embarcadero, ported to FireMonkey to see        }
{   TFmxHelpChatAI at work in a real application. Only the main form is        }
{   ported: the lead, proposal and draft windows stay with the VCL demo, so    }
{   this one registers the one action that needs nothing else - open_screen.   }
{                                                                              }
{   The data module is the very same one the VCL demo uses (..\..\common):      }
{   same database, same queries, same bind sources.                            }
{                                                                              }
{******************************************************************************}

unit uMainFormFmx;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.Rtti, System.Bindings.Outputs, Data.DB,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.TabControl,
  FMX.MultiView, FMX.Objects, FMX.Edit, FMX.ListBox, FMX.Calendar,
  FMX.ImgList,
  FMX.ScrollBox, FMX.Grid.Style, FMX.Grid, FMX.Styles,
  Data.Bind.EngExt, Data.Bind.Components, Data.Bind.Grid, Data.Bind.DBScope,
  Fmx.Bind.DBEngExt, Fmx.Bind.Editors, Fmx.Bind.Grid, Fmx.Bind.Navigator,
  HelpChatAI.Types, HelpChatAI.Actions, FMX.HelpChatAI;

const
  /// <summary>The style the demo wears, relative to the executable.</summary>
  FMX_DEMO_STYLE = '..\..\FMX\Dark.style';

type
  TMainFormFmx = class(TForm)
    ToolBar: TToolBar;
    MenuButton: TSpeedButton;
    TitleLabel: TLabel;
    UserGroup: TLayout;
    UserLabel: TLabel;
    UserCombo: TComboBox;
    ThemeGroup: TLayout;
    ThemeLabel: TLabel;
    ThemeCombo: TComboBox;
    MultiView: TMultiView;
    MenuList: TListBox;
    DashboardItem: TListBoxItem;
    AccountsItem: TListBoxItem;
    LeadsItem: TListBoxItem;
    SalesItem: TListBoxItem;
    MarketingItem: TListBoxItem;
    CalendarItem: TListBoxItem;
    UsersItem: TListBoxItem;
    Tabs: TTabControl;
    DashboardTab: TTabItem;
    AccountsTab: TTabItem;
    LeadsTab: TTabItem;
    SalesTab: TTabItem;
    MarketingTab: TTabItem;
    CalendarTab: TTabItem;
    UsersTab: TTabItem;
    DashboardHeader: TLayout;
    DashboardTitle: TLabel;
    DashboardFlow: TFlowLayout;
    TileImages: TImageList;
    TileNew: TPanel;
    TileNewCaption: TLabel;
    TileNewValue: TLabel;
    TileNewUnit: TLabel;
    TileNewGlyph: TGlyph;
    TileActive: TPanel;
    TileActiveCaption: TLabel;
    TileActiveValue: TLabel;
    TileActiveUnit: TLabel;
    TileActiveGlyph: TGlyph;
    TileProposal: TPanel;
    TileProposalCaption: TLabel;
    TileProposalValue: TLabel;
    TileProposalUnit: TLabel;
    TileProposalGlyph: TGlyph;
    TileClosed: TPanel;
    TileClosedCaption: TLabel;
    TileClosedValue: TLabel;
    TileClosedUnit: TLabel;
    TileClosedGlyph: TGlyph;
    TileInactive: TPanel;
    TileInactiveCaption: TLabel;
    TileInactiveValue: TLabel;
    TileInactiveUnit: TLabel;
    TileInactiveGlyph: TGlyph;
    TileTotal: TPanel;
    TileTotalCaption: TLabel;
    TileTotalValue: TLabel;
    TileTotalUnit: TLabel;
    TileTotalGlyph: TGlyph;
    AccountsHeader: TLayout;
    AccountsTitle: TLabel;
    AccountsBar: TLayout;
    AccountsSearch: TEdit;
    AccountsGrid: TStringGrid;
    AccountsNav: TBindNavigator;
    SalesHeader: TLayout;
    SalesTitle: TLabel;
    SalesBar: TLayout;
    SalesSearch: TEdit;
    SalesGrid: TStringGrid;
    SalesNav: TBindNavigator;
    MarketingHeader: TLayout;
    MarketingTitle: TLabel;
    MarketingBar: TLayout;
    MarketingSearch: TEdit;
    MarketingGrid: TStringGrid;
    UsersHeader: TLayout;
    UsersTitle: TLabel;
    UsersBar: TLayout;
    UsersSearch: TEdit;
    UsersGrid: TStringGrid;
    UsersNav: TBindNavigator;
    LeadsHeader: TLayout;
    LeadsTitle: TLabel;
    LeadsBar: TLayout;
    LeadsSearch: TEdit;
    LeadsBoards: TLayout;
    LeadsNewPanel: TPanel;
    LeadsNewTitle: TLabel;
    LeadsNewGrid: TStringGrid;
    LeadsSplitter1: TSplitter;
    LeadsActivePanel: TPanel;
    LeadsActiveTitle: TLabel;
    LeadsActiveGrid: TStringGrid;
    LeadsSplitter2: TSplitter;
    LeadsProposalPanel: TPanel;
    LeadsProposalTitle: TLabel;
    LeadsProposalGrid: TStringGrid;
    LeadsSplitter3: TSplitter;
    LeadsClosedPanel: TPanel;
    LeadsClosedTitle: TLabel;
    LeadsClosedGrid: TStringGrid;
    CalendarHeader: TLayout;
    CalendarTitle: TLabel;
    Calendar: TCalendar;
    AcctBindSourceDB: TBindSourceDB;
    ProposalBindSourceDB: TBindSourceDB;
    EmailsBindSourceDB: TBindSourceDB;
    UsersBindSourceDB: TBindSourceDB;
    LeadsBindNewSourceDB: TBindSourceDB;
    LeadsBindActiveSourceDB: TBindSourceDB;
    LeadsBindProposalSentSourceDB: TBindSourceDB;
    LeadsBindClosedSourceDB: TBindSourceDB;
    NewTotalBindSourceDB: TBindSourceDB;
    ActiveTotalBindSourceDB: TBindSourceDB;
    ProposalTotalBindSourceDB: TBindSourceDB;
    ClosedTotalBindSourceDB: TBindSourceDB;
    InactiveTotalBindSourceDB: TBindSourceDB;
    AllTotalBindSourceDB: TBindSourceDB;
    BindingsList: TBindingsList;
    LinkGridAccounts: TLinkGridToDataSource;
    LinkGridSales: TLinkGridToDataSource;
    LinkGridMarketing: TLinkGridToDataSource;
    LinkGridUsers: TLinkGridToDataSource;
    LinkGridLeadsNew: TLinkGridToDataSource;
    LinkGridLeadsActive: TLinkGridToDataSource;
    LinkGridLeadsProposal: TLinkGridToDataSource;
    LinkGridLeadsClosed: TLinkGridToDataSource;
    LinkTileNew: TLinkPropertyToField;
    LinkTileActive: TLinkPropertyToField;
    LinkTileProposal: TLinkPropertyToField;
    LinkTileClosed: TLinkPropertyToField;
    LinkTileInactive: TLinkPropertyToField;
    LinkTileTotal: TLinkPropertyToField;
    HelpChat: TFmxHelpChatAI;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar;
      Shift: TShiftState);
    procedure MenuListItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
    procedure TabsChange(Sender: TObject);
    procedure SearchTyping(Sender: TObject);
    procedure ThemeComboChange(Sender: TObject);
    procedure HelpChatGetContext(Sender: TObject; var AContext: THelpChatContext);
  private
    FStarted: Boolean;
    procedure ApplyDarkStyle;
    procedure AppIdle(Sender: TObject; var Done: Boolean);
    procedure StartUp;
    procedure RegisterHelpActions;
    function FindTab(const AName: string): TTabItem;
    procedure RefreshTotals;
  public
    { Public declarations }
  end;

var
  MainFormFmx: TMainFormFmx;

implementation

{$R *.fmx}

uses
  uDataMod,
  // A provider exists only if its unit is linked: it registers itself in
  // the initialization. Same rule as in the VCL demo.
  HelpChatAI.Provider.DocSearch, HelpChatAI.Provider.Claude;

procedure TMainFormFmx.ApplyDarkStyle;
var
  LFile: string;
begin
  // The VCL demo links Windows10 SlateGray into the executable with the
  // Custom_Styles option of the project; FireMonkey has no such option,
  // a style is a file. The one that ships with the demo is the stock
  // Dark of Delphi, next to the project, and the path is relative to
  // the executable like every other path of this demo.
  // TPath is not usable here: FMX.Types has one of its own, the vector
  // path, and it wins over System.IOUtils in the uses of a FireMonkey form.
  LFile := ExpandFileName(ExtractFilePath(ParamStr(0)) + FMX_DEMO_STYLE);
  if not FileExists(LFile) then
    Exit;                  // no style file: the default one, and it still runs
  try
    TStyleManager.SetStyle(TStyleStreaming.LoadFromFile(LFile));
  except
    // A style is decoration: a broken file must not stop the demo.
  end;
end;

procedure TMainFormFmx.FormCreate(Sender: TObject);
begin
  ApplyDarkStyle;
  Tabs.TabPosition := TTabPosition.None;
  Tabs.ActiveTab := DashboardTab;
  // The chat follows the application, which is dark: in FireMonkey the
  // component cannot read the style, so the host says which it is.
  ThemeCombo.ItemIndex := 2;
  ThemeComboChange(ThemeCombo);
  // The database is created on first use, so the application has to be
  // running before any of this works - same as the VCL demo.
  Application.OnIdle := AppIdle;
end;

procedure TMainFormFmx.AppIdle(Sender: TObject; var Done: Boolean);
begin
  StartUp;
end;

procedure TMainFormFmx.StartUp;
var
  LDataSet: TDataSet;
begin
  if FStarted then
    Exit;
  FStarted := True;

  DM.InitializeDatabase;

  // One handler for every search box: each one carries the bind source
  // it filters and, in Hint, the field to match.
  AccountsSearch.TagObject := AcctBindSourceDB;
  SalesSearch.TagObject := ProposalBindSourceDB;
  MarketingSearch.TagObject := EmailsBindSourceDB;
  UsersSearch.TagObject := UsersBindSourceDB;
  LeadsSearch.TagObject := LeadsBindNewSourceDB;

  // The users of the CRM, for the combo in the toolbar. Bound by hand:
  // one list, read once, is clearer here than a LiveBindings link.
  LDataSet := UsersBindSourceDB.DataSet;
  if Assigned(LDataSet) and LDataSet.Active then
  begin
    LDataSet.First;
    while not LDataSet.Eof do
    begin
      UserCombo.Items.Add(LDataSet.FieldByName('Username').AsString);
      LDataSet.Next;
    end;
    LDataSet.First;
  end;
  if UserCombo.Items.Count > 0 then
    UserCombo.ItemIndex := 0;

  // The assistant. The index of the manual is the same one the VCL demo
  // reads: both executables live in CRM Demo\bin\<Platform>, and the
  // path in the form is relative to the executable.
  RegisterHelpActions;
  HelpChat.Active := True;
end;

procedure TMainFormFmx.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  // The component chains this handler by itself (it keeps the previous
  // one and calls it first), so there is nothing to do here: the method
  // exists because the form needs one for the chain to hook onto.
end;

procedure TMainFormFmx.MenuListItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
begin
  Tabs.TabIndex := Item.Tag;
  TabsChange(Tabs);
  // A drawer stays open until somebody closes it, and after a choice
  // nobody wants it open.
  MultiView.HideMaster;
end;

procedure TMainFormFmx.RefreshTotals;
begin
  DM.FDQueryNewTotal.Refresh;
  DM.FDQueryActiveTotal.Refresh;
  DM.FDQueryProposalTotal.Refresh;
  DM.FDQueryClosedTotal.Refresh;
  DM.FDQueryInactiveTotal.Refresh;
  DM.FDQueryTotal.Refresh;
end;

procedure TMainFormFmx.TabsChange(Sender: TObject);
begin
  if Tabs.ActiveTab = DashboardTab then
    RefreshTotals
  else if Tabs.ActiveTab = MarketingTab then
    EmailsBindSourceDB.DataSet.Refresh;
end;

procedure TMainFormFmx.ThemeComboChange(Sender: TObject);
begin
  // What the chat looks like is a property of the component in FMX:
  // there are no VCL styles to follow, so the host says light or dark.
  case ThemeCombo.ItemIndex of
    1: HelpChat.ThemeMode := tmLight;
    2: HelpChat.ThemeMode := tmDark;
  else
    HelpChat.ThemeMode := tmAuto;
  end;
end;

procedure TMainFormFmx.SearchTyping(Sender: TObject);
var
  LSource: TBindSourceDB;
  LText: string;
begin
  // Tag carries the bind source to filter, so one handler serves them all.
  LSource := TBindSourceDB(TEdit(Sender).TagObject);
  if (LSource = nil) or not Assigned(LSource.DataSet) then
    Exit;
  LText := TEdit(Sender).Text.Trim;
  LSource.DataSet.Filtered := False;
  if LText = '' then
    Exit;
  LSource.DataSet.Filter := TEdit(Sender).Hint + ' LIKE ''%' +
    LText.Replace('''', '''''') + '%''';
  LSource.DataSet.Filtered := True;
end;

function TMainFormFmx.FindTab(const AName: string): TTabItem;
var
  I: Integer;
begin
  // The model names a screen the way a user would: the exact name first,
  // then a partial match.
  for I := 0 to Tabs.TabCount - 1 do
    if SameText(Tabs.Tabs[I].Text, AName) or
       SameText(Tabs.Tabs[I].HelpKeyword, AName) or
       SameText(Tabs.Tabs[I].Name, AName) then
      Exit(Tabs.Tabs[I]);
  for I := 0 to Tabs.TabCount - 1 do
    if Tabs.Tabs[I].Text.ToLower.Contains(AName.ToLower) then
      Exit(Tabs.Tabs[I]);
  Result := nil;
end;

procedure TMainFormFmx.RegisterHelpActions;
begin
  // Only this one: the windows the other two actions of the VCL demo need
  // (the lead detail and the proposal draft) are not ported yet.
  HelpChat.Actions.Add('open_screen',
    'Brings one of the application screens to the front.',
    [THelpChatActionParam.Create('name',
      'Screen name: Dashboard, Accounts, Leads, Sales, Marketing, Calendar or Users.')],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LTab: TTabItem;
    begin
      LTab := FindTab(AArgs.AsString('name'));
      if LTab = nil then
        raise Exception.CreateFmt('There is no "%s" screen.', [AArgs.AsString('name')]);
      Tabs.ActiveTab := LTab;
      TabsChange(Tabs);
      AResult := 'Opened the ' + LTab.Text + ' screen.';
    end);
end;

procedure TMainFormFmx.HelpChatGetContext(Sender: TObject;
  var AContext: THelpChatContext);
begin
  // Same reason as in the VCL demo: the side menu lives outside the tab
  // control, and from there the component would describe the window
  // instead of the page the user is looking at. Here the active page is
  // always the right answer.
  if Assigned(Tabs.ActiveTab) then
  begin
    AContext.ScreenName := Tabs.ActiveTab.Name;
    AContext.ScreenLabel := Tabs.ActiveTab.Text;
    if Tabs.ActiveTab.HelpKeyword <> '' then
      AContext.HelpKeyword := Tabs.ActiveTab.HelpKeyword;
  end;
end;

initialization

end.
