{******************************************************************************}
{                                                                              }
{   HelpChatAI CRM demo - FireMonkey                                           }
{                                                                              }
{   The Windows 10 CRM demo of Embarcadero, ported to FireMonkey to see        }
{   TFmxHelpChatAI at work in a real application. Main form, lead detail,      }
{   proposal and proposal draft, so all three actions of the VCL demo are      }
{   here too - open_screen, create_lead and draft_proposal.                    }
{                                                                              }
{   The data module is the very same one the VCL demo uses (..\..\common):      }
{   same database, same queries, same bind sources - and so are the actions    }
{   of the assistant (uCRMActions).                                            }
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
  HelpChatAI.Types, HelpChatAI.Log, HelpChatAI.Actions, FMX.HelpChatAI,
  Data.Bind.Controls, System.ImageList;

const
  /// <summary>The style the demo wears, relative to the executable.</summary>
  FMX_DEMO_STYLE = '..\..\FMX\Dark.style';
  /// <summary>The side menu open, and narrowed to its icons. The VCL demo
  /// gets the second one from CloseStyle = svcCompact of its TSplitView.</summary>
  MENU_WIDTH_OPEN = 220;
  MENU_WIDTH_COMPACT = 52;

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
    MenuHost: TLayout;
    MultiView: TMultiView;
    MenuList: TListBox;
    MenuImages: TImageList;
    DashboardItem: TListBoxItem;
    DashboardGlyph: TGlyph;
    DashboardText: TLabel;
    AccountsItem: TListBoxItem;
    AccountsGlyph: TGlyph;
    AccountsText: TLabel;
    LeadsItem: TListBoxItem;
    LeadsGlyph: TGlyph;
    LeadsText: TLabel;
    SalesItem: TListBoxItem;
    SalesGlyph: TGlyph;
    SalesText: TLabel;
    MarketingItem: TListBoxItem;
    MarketingGlyph: TGlyph;
    MarketingText: TLabel;
    CalendarItem: TListBoxItem;
    CalendarGlyph: TGlyph;
    CalendarText: TLabel;
    UsersItem: TListBoxItem;
    UsersGlyph: TGlyph;
    UsersText: TLabel;
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
    procedure MenuButtonClick(Sender: TObject);
    procedure HelpChatGetContext(Sender: TObject; var AContext: THelpChatContext);
    procedure HelpChatDecryptSecret(Sender: TObject; const AName, AValue: string;
      var AResult: string; var AHandled: Boolean);
    procedure HelpChatModelChanged(Sender: TObject);
    procedure HelpChatLog(Sender: TObject; const AEntry: THelpChatLogEntry);
    procedure UserComboChange(Sender: TObject);
    procedure LeadsNewGridCellDblClick(const Column: TColumn; const Row: Integer);
    procedure LeadsActiveGridCellDblClick(const Column: TColumn; const Row: Integer);
    procedure LeadsProposalGridCellDblClick(const Column: TColumn; const Row: Integer);
    procedure LeadsClosedGridCellDblClick(const Column: TColumn; const Row: Integer);
  private
    // The activation window is open: another switch of model does not open
    // a second one.
    FAskingKey: Boolean;
    FStarted: Boolean;
    procedure SetMenuCompact(ACompact: Boolean);
    procedure ApplyDarkStyle;
    procedure AppIdle(Sender: TObject; var Done: Boolean);
    procedure StartUp;
    procedure RegisterHelpActions;
    /// <summary>Last resort: the model the assistant is about to use needs a
    /// key and has none, neither in the configuration files nor in the
    /// environment variable of its service. It is asked for that model,
    /// encrypted with the secret of this application and written to the
    /// per-user file, where the next run reads it back encrypted. At startup
    /// and whenever the user switches model in the panel.</summary>
    procedure AskForApiKeyIfMissing;
    function FindTab(const AName: string): TTabItem;
    procedure RefreshTotals;
    /// <summary>Opens the detail on the current record of one of the four
    /// lead boards.</summary>
    procedure ShowLeadDetail(ASource: TBindSourceDB);
  public
    { Public declarations }
  end;

var
  MainFormFmx: TMainFormFmx;

implementation

{$R *.fmx}

uses
  uDataMod, uLeadsFmx, uProposalFmx, uDraftProposalFmx,
  // The log of the assistant to a file, written by Logify.
  uHelpChatLog,
  HelpChatAI.Settings,
  // The API key is not in clear in the configuration: uAppSecret encrypts it
  // and reads it back, and HelpChatDecryptSecret is the hook the component
  // calls. DCPcrypt belongs to this demo, not to the library.
  uAppSecret, uLicenseActivationFmx,
  // The actions of the assistant, shared with the VCL demo.
  uCRMActions,
  // A provider exists only if its unit is linked: it registers itself in
  // the initialization. Same rule as in the VCL demo.
  HelpChatAI.Provider.DocSearch, HelpChatAI.Provider.Claude,
  HelpChatAI.Provider.OpenAI, HelpChatAI.Provider.Gemini
  {$IFDEF MULTIAGENT}
  // The multi-assistant edition (FMX_CRMDemo_MultiAgent.dproj): everything it
  // adds is in this unit.
  , uMultiAgentFmx
  {$ENDIF};

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

  // Open, like the side menu of the VCL demo.
  SetMenuCompact(False);

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
  HelpChatLogOpen('FMX_CRMDemo');
  // What happens, never what the user writes: "LogLevel" in a
  // helpchatai.json raises it (detail, debug) with no rebuild.
  HelpChat.Settings.LogLevel := llInfo;
  HelpChat.OnLogEvent := HelpChatLog;
  {$IFDEF MULTIAGENT}
  ConfigureGeneralAssistant(HelpChat);
  {$ENDIF}
  HelpChat.Active := True;
  {$IFDEF MULTIAGENT}
  // The second assistant, on the lead window: after the first, whose
  // provider, models, manual and key handler it copies.
  CreateSalesAssistant(HelpChat, LeadsFormFmx);
  {$ENDIF}
  AskForApiKeyIfMissing;
end;

procedure TMainFormFmx.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  // The component chains this handler by itself (it keeps the previous
  // one and calls it first), so there is nothing to do here: the method
  // exists because the form needs one for the chain to hook onto.
end;

procedure TMainFormFmx.SetMenuCompact(ACompact: Boolean);
var
  I, J: Integer;
  LItem: TListBoxItem;
begin
  // The labels go away rather than being cut off: they start right after
  // the icon, so any width that shows the whole icon shows half a letter
  // too. The icon is a child of the item, so it is the label that hides.
  for I := 0 to MenuList.Count - 1 do
  begin
    LItem := MenuList.ListItems[I];
    for J := 0 to LItem.ChildrenCount - 1 do
      if LItem.Children[J] is TLabel then
        TLabel(LItem.Children[J]).Visible := not ACompact;
  end;
  if ACompact then
    MenuHost.Width := MENU_WIDTH_COMPACT
  else
    MenuHost.Width := MENU_WIDTH_OPEN;
end;

procedure TMainFormFmx.MenuButtonClick(Sender: TObject);
begin
  // None of the three modes of TMultiView behaves like the side menu of the
  // VCL demo, which is open until the user says otherwise: Panel is
  // permanent and hides the button it is given, Drawer and NavigationPane
  // slide over the content and close again at the first click outside.
  // So the pane stays a Panel - docked, with the content beside it and not
  // under it - and the button narrows the layout around it, which is what
  // the VCL TSplitView does with CloseStyle = svcCompact. Narrow, only the
  // icons are left, and they are the icons of the VCL menu.
  SetMenuCompact(MenuHost.Width > MENU_WIDTH_COMPACT);
end;

procedure TMainFormFmx.MenuListItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
begin
  Tabs.TabIndex := Item.Tag;
  TabsChange(Tabs);
  // The menu stays where it is. As a Drawer it closed after every choice,
  // which the VCL side menu never does: there it is a TSplitView with
  // CloseStyle = svcCompact, open until the user presses the button and
  // then narrowed to its icons. NavigationPane is that, and MasterButton
  // is what opens and closes it.
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

procedure TMainFormFmx.ShowLeadDetail(ASource: TBindSourceDB);
begin
  if not Assigned(ASource.DataSet) or (ASource.DataSet.RecordCount = 0) then
    Exit;
  LeadsFormFmx.LocateLead(ASource.DataSet.FieldByName('LeadId').AsInteger);
  LeadsFormFmx.Show;
end;

procedure TMainFormFmx.LeadsNewGridCellDblClick(const Column: TColumn;
  const Row: Integer);
begin
  ShowLeadDetail(LeadsBindNewSourceDB);
end;

procedure TMainFormFmx.LeadsActiveGridCellDblClick(const Column: TColumn;
  const Row: Integer);
begin
  ShowLeadDetail(LeadsBindActiveSourceDB);
end;

procedure TMainFormFmx.LeadsProposalGridCellDblClick(const Column: TColumn;
  const Row: Integer);
begin
  ShowLeadDetail(LeadsBindProposalSentSourceDB);
end;

procedure TMainFormFmx.LeadsClosedGridCellDblClick(const Column: TColumn;
  const Row: Integer);
begin
  ShowLeadDetail(LeadsBindClosedSourceDB);
end;

procedure TMainFormFmx.UserComboChange(Sender: TObject);
begin
  // The three windows show the data of one user: when the user changes they
  // are looking at somebody else's records, so they close.
  LeadsFormFmx.Close;
  DraftProposalFormFmx.Close;
  ProposalFormFmx.Close;
  DM.SetUser(UserCombo.Text);
end;

procedure TMainFormFmx.RegisterHelpActions;
var
  LHooks: TCRMActionHooks;
  LProposalActions: THelpChatActionBroker;
begin
  // With one assistant the proposal is one of its actions like the others.
  // With several it is a shared action: registered once for all of them, and
  // who uses it is the configuration's to decide (AllowedActions, in
  // uMultiAgentFmx), not this code's.
  {$IFDEF MULTIAGENT}
  LProposalActions := HelpChatSharedActions;
  {$ELSE}
  LProposalActions := HelpChat.Actions;
  {$ENDIF}

  // The actions are declared in uCRMActions and change the data through the
  // data module, the same for both demos: here is only what a window does.
  LHooks.OpenScreen :=
    function(AName: string): string
    var
      LTab: TTabItem;
    begin
      LTab := FindTab(AName);
      if LTab = nil then
        Exit('');
      Tabs.ActiveTab := LTab;
      TabsChange(Tabs);
      Result := LTab.Text;
    end;
  LHooks.CurrentUser :=
    function: string
    begin
      Result := UserCombo.Text;
    end;
  LHooks.AccountCreated :=
    procedure(AName: string)
    begin
      // The Accounts grid and the combo of the lead window read the
      // companies again.
      LinkGridAccounts.Active := False;
      LinkGridAccounts.Active := True;
      LeadsFormFmx.LinkAccountName.Active := False;
      LeadsFormFmx.LinkAccountName.Active := True;
    end;
  LHooks.LeadCreated :=
    procedure(ALeadId: Integer)
    begin
      Tabs.ActiveTab := LeadsTab;
      LeadsFormFmx.LocateLead(ALeadId);
      LeadsFormFmx.Show;
    end;
  LHooks.DraftReady :=
    procedure(ADraft: TCRMDraft)
    begin
      DraftProposalFormFmx.PrepareDraft(ADraft.LeadId, ADraft.Company,
        ADraft.Address1, ADraft.Address2, ADraft.Phone, ADraft.Items);
    end;
  RegisterCRMActions(HelpChat.Actions, LProposalActions, LHooks);
end;

procedure TMainFormFmx.HelpChatGetContext(Sender: TObject;
  var AContext: THelpChatContext);
begin
  // F1 pressed in one of the three other windows: what the user is looking
  // at is that window, not the page behind it. The VCL forms declare it in
  // HelpType/HelpKeyword, which a FireMonkey form does not have, so each
  // unit carries the keyword as a constant and this is where it is read.
  // The form is the one the component chose (ScreenType), not
  // Screen.ActiveForm: with the chat in front, that is the chat's window.
  if AContext.ScreenType = TLeadsFormFmx.ClassName then
  begin
    AContext.ScreenName := 'LeadDetail';
    AContext.ScreenLabel := 'Lead Detail';
    AContext.HelpKeyword := LEADS_HELP_KEYWORD;
    Exit;
  end;
  if AContext.ScreenType = TProposalFormFmx.ClassName then
  begin
    AContext.ScreenName := 'Proposal';
    AContext.ScreenLabel := 'Proposal';
    AContext.HelpKeyword := PROPOSAL_HELP_KEYWORD;
    Exit;
  end;
  if AContext.ScreenType = TDraftProposalFormFmx.ClassName then
  begin
    AContext.ScreenName := 'DraftProposal';
    AContext.ScreenLabel := 'Draft Proposal';
    AContext.HelpKeyword := DRAFT_HELP_KEYWORD;
    Exit;
  end;
  // Same reason as in the VCL demo: the side menu lives outside the tab
  // control, and from there the component would describe the window
  // instead of the page the user is looking at. Here the active page is
  // always the right answer - on this form, not on a window of the
  // application that has no assistant of its own.
  if (AContext.ScreenType = ClassName) and Assigned(Tabs.ActiveTab) then
  begin
    AContext.ScreenName := Tabs.ActiveTab.Name;
    AContext.ScreenLabel := Tabs.ActiveTab.Text;
    if Tabs.ActiveTab.HelpKeyword <> '' then
      AContext.HelpKeyword := Tabs.ActiveTab.HelpKeyword;
  end;
end;

procedure TMainFormFmx.HelpChatDecryptSecret(Sender: TObject;
  const AName, AValue: string; var AResult: string; var AHandled: Boolean);
begin
  // This runs on the worker thread that is about to call the service:
  // compute and return, no window and no waiting. AName would say which
  // secret it is (Claude.ApiKey, Remote.AppKey...); here every value
  // carrying the prefix is answered for, whoever asked.
  AHandled := AppSecretIsProtected(AValue);
  if AHandled then
    AResult := AppSecretReveal(AValue);
end;

procedure TMainFormFmx.HelpChatLog(Sender: TObject; const AEntry: THelpChatLogEntry);
begin
  // The log of the assistant to a file, by Logify (uHelpChatLog): in
  // %APPDATA%\HelpChatAI\Logs\FMX_CRMDemo.log, rotated. It runs on the thread
  // that writes the entry (often a worker), one call at a time, and Logify
  // queues it and returns. The level is Settings.LogLevel, "info" unless
  // changed: "LogLevel": "debug" in helpchatai.json shows everything,
  // question, reply and HTTP calls included.
  HelpChatLogWrite(AEntry);
end;

procedure TMainFormFmx.AskForApiKeyIfMissing;
var
  LRequest: TAppSecretKeyRequest;
  LRequests: TArray<TAppSecretKeyRequest>;
begin
  // RunSettings are the settings of the running engine, with the model the
  // user picked in the panel applied: its provider says whether the key is
  // missing (the property, the configuration files already loaded, the
  // environment variable, the handler above). docsearch or a local Ollama
  // want none, and the window does not open.
  if FAskingKey or not AppSecretMissingKey(HelpChat.RunSettings, LRequest) then
    Exit;
  FAskingKey := True;
  // One row per service (Claude, Gemini, OpenAI), the one of the model in
  // use in bold: while at it, the user registers the others too.
  LRequests := AppSecretKeyRequests(HelpChat.RunSettings);
  TLicenseActivationFormFmx.Execute(LRequests, THelpChatSettings.UserConfigFile,
    procedure(AKeys: TArray<string>)
    var
      LRequest: TAppSecretKeyRequest;
      LInfo: THelpChatModelInfo;
    begin
      // Encrypted, into the section of the provider or the model of the
      // catalogue with an endpoint of its own, and applied at once: what
      // stays in memory is the encrypted one.
      AppSecretActivate(HelpChat.RunSettings, LRequests, AKeys);
      // The model in use still has no key, but the user registered another:
      // switch to the first that can answer. Models offers only those (plus
      // the one in use), and the switch reaches the panel too.
      if AppSecretMissingKey(HelpChat.RunSettings, LRequest) then
        for LInfo in HelpChat.Models do
          if not LInfo.Active then
          begin
            HelpChat.SelectModel(LInfo.Name);
            Break;
          end;
    end,
    procedure
    begin
      FAskingKey := False;
    end);
end;

procedure TMainFormFmx.HelpChatModelChanged(Sender: TObject);
begin
  // The user picked another model in the panel: if that one has no key, it
  // is asked for now rather than left to the first question.
  AskForApiKeyIfMissing;
end;

initialization

end.
