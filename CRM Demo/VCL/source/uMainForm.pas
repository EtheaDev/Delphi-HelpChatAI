unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.Bind.Controls, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, Vcl.StdCtrls, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.Buttons, Vcl.Bind.Navigator,
  Vcl.Grids, Vcl.WinXCtrls, Vcl.Imaging.pngimage, Vcl.ExtCtrls, Vcl.ComCtrls,
  Data.Bind.EngExt, Vcl.Bind.DBEngExt, Vcl.Bind.Grid, System.Rtti,
  System.Bindings.Outputs, Vcl.Bind.Editors, Data.Bind.Components,
  Data.Bind.Grid, Data.Bind.DBScope, Vcl.WinXCalendars, FireDAC.Stan.StorageBin,
  FireDAC.Stan.StorageJSON, FireDAC.Stan.StorageXML,
  Vcl.WinXPanels, System.Actions, Vcl.ActnList, Vcl.Themes,
  Vcl.BaseImageCollection, Vcl.ImageCollection, System.ImageList, Vcl.ImgList,
  Vcl.VirtualImageList, Vcl.VirtualImage, System.IOUtils,
  HelpChatAI.Types, HelpChatAI.Log, HelpChatAI.Actions, Vcl.HelpChatAI,
  uDraftProposal
  {$IFDEF VCLSTYLEDCOMPONENTS}, Vcl.StyledComponentsHooks{$ENDIF};

type
  TMainForm = class(TForm)
    pnlToolbar: TPanel;
    SplitView: TSplitView;
    NavPanel: TPanel;
    NewLeadsSG: TStringGrid;
    BindNavigator1: TBindNavigator;
    lblTitle: TLabel;
    PageControl: TPageControl;
    LeadsTab: TTabSheet;
    CalendarTab: TTabSheet;
    Panel2: TPanel;
    Label1: TLabel;
    LeadsBindNewSourceDB: TBindSourceDB;
    BindingsList1: TBindingsList;
    Image5: TImage;
    CalendarView1: TCalendarView;
    LeadsSearchBox: TSearchBox;
    Panel4: TPanel;
    Label3: TLabel;
    DashboardTab: TTabSheet;
    Panel5: TPanel;
    Label4: TLabel;
    ImportLeadsDialog: TOpenDialog;
    ExportLeadsDialog: TSaveDialog;
    FlowPanel1: TFlowPanel;
    RelativePanel1: TRelativePanel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    RelativePanel2: TRelativePanel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    RelativePanel3: TRelativePanel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    RelativePanel4: TRelativePanel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    RelativePanel5: TRelativePanel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    RelativePanel6: TRelativePanel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    SalesTab: TTabSheet;
    Panel6: TPanel;
    Label23: TLabel;
    SalesSearchBox: TSearchBox;
    ProposalStringGrid: TStringGrid;
    BindNavigator3: TBindNavigator;
    AccountsTab: TTabSheet;
    Panel7: TPanel;
    Label24: TLabel;
    AcctSearchBox: TSearchBox;
    AccountsSG: TStringGrid;
    BindNavigator4: TBindNavigator;
    UsersTab: TTabSheet;
    Panel8: TPanel;
    Label25: TLabel;
    SearchBox7: TSearchBox;
    UsersSG: TStringGrid;
    UsersBindSourceDB: TBindSourceDB;
    LinkGridToDataSourceUsersBindSourceDB: TLinkGridToDataSource;
    BindNavigator5: TBindNavigator;
    ProposalBindSourceDB: TBindSourceDB;
    LinkGridToDataSourceBindSourceDB5: TLinkGridToDataSource;
    UsernameComboBox: TComboBox;
    LinkListControlToField1: TLinkListControlToField;
    AcctBindSourceDB: TBindSourceDB;
    MarketingTab: TTabSheet;
    Panel3: TPanel;
    Label2: TLabel;
    EmailsSearchBox: TSearchBox;
    StringGrid2: TStringGrid;
    EmailsBindSourceDB: TBindSourceDB;
    LinkGridToDataSourceBindSourceDB4: TLinkGridToDataSource;
    SaveEmailsDialog: TSaveDialog;
    NewLeadsPanel: TPanel;
    Splitter1: TSplitter;
    Label27: TLabel;
    ActiveLeadsSG: TStringGrid;
    ActiveLeadsPanel: TPanel;
    Label28: TLabel;
    Splitter2: TSplitter;
    ProposalSentPanel: TPanel;
    ProposalSentLeadsSG: TStringGrid;
    Label29: TLabel;
    Splitter3: TSplitter;
    ClosedPanel: TPanel;
    ClosedLeadsSG: TStringGrid;
    Label30: TLabel;
    LinkGridToDataSourceLeadsBindSourceDB: TLinkGridToDataSource;
    LeadsBindActiveSourceDB: TBindSourceDB;
    LinkGridToDataSourceLeadsBindActiveSourceDB: TLinkGridToDataSource;
    LeadsBindSourceDB: TBindSourceDB;
    LeadsBindProposalSentSourceDB: TBindSourceDB;
    LeadsBindClosedSourceDB: TBindSourceDB;
    LinkGridToDataSourceLeadsBindClosedSourceDB: TLinkGridToDataSource;
    TopPanel: TPanel;
    VCLStylesCB: TComboBox;
    VirtualImageList1: TVirtualImageList;
    ImageCollection1: TImageCollection;
    ViewLeadButton: TSpeedButton;
    CreateLeadButton: TSpeedButton;
    ExportLeadsButton: TSpeedButton;
    LeadsRelativePanel: TRelativePanel;
    AcctsRelativePanel: TRelativePanel;
    ExportAcctsButton: TSpeedButton;
    RemoveAcctButton: TSpeedButton;
    CreateAcctButton: TSpeedButton;
    ProposalsRelativePanel: TRelativePanel;
    CancelProposalButton: TSpeedButton;
    CompleteProposalButton: TSpeedButton;
    MarketingRelativePanel: TRelativePanel;
    ExportEmailsButton: TSpeedButton;
    UsersRelativePanel: TRelativePanel;
    CreateUserButton: TSpeedButton;
    RemoveUserButton: TSpeedButton;
    DashboardButton: TButton;
    AcctsButton: TButton;
    LeadsButton: TButton;
    SalesButton: TButton;
    MarketingButton: TButton;
    CalendarButton: TButton;
    UsersButton: TButton;
    LinkGridToDataSourceAcctBindSourceDB: TLinkGridToDataSource;
    ExportAcctsDialog: TSaveDialog;
    LinkGridToDataSourceLeadsBindProposalSentSourceDB: TLinkGridToDataSource;
    VirtualImage1: TVirtualImage;
    VirtualImage2: TVirtualImage;
    VirtualImage3: TVirtualImage;
    VirtualImage4: TVirtualImage;
    VirtualImage5: TVirtualImage;
    VirtualImage6: TVirtualImage;
    VirtualImage7: TVirtualImage;
    MenuVirtualImage: TVirtualImage;
    NewTotalBindSourceDB: TBindSourceDB;
    LinkPropertyToFieldCaption: TLinkPropertyToField;
    ActiveTotalBindSourceDB: TBindSourceDB;
    LinkPropertyToFieldCaption2: TLinkPropertyToField;
    ProposalTotalBindSourceDB: TBindSourceDB;
    LinkPropertyToFieldCaption3: TLinkPropertyToField;
    ClosedTotalBindSourceDB: TBindSourceDB;
    LinkPropertyToFieldCaption4: TLinkPropertyToField;
    InactiveTotalBindSourceDB: TBindSourceDB;
    LinkPropertyToFieldCaption5: TLinkPropertyToField;
    AllTotalBindSourceDB: TBindSourceDB;
    LinkPropertyToFieldCaption6: TLinkPropertyToField;
    VirtualImage9: TVirtualImage;
    VirtualImage10: TVirtualImage;
    VirtualImage11: TVirtualImage;
    VirtualImage12: TVirtualImage;
    VirtualImage13: TVirtualImage;
    VirtualImage14: TVirtualImage;
    HelpChat: TVclHelpChatAI;
    procedure CalendarView1DrawDayItem(Sender: TObject;
      DrawParams: TDrawViewInfoParams; CalendarViewViewInfo: TCellItemViewInfo);
    procedure AcctSearchBoxKeyPress(Sender: TObject; var Key: Char);
    procedure LeadsSearchBoxKeyPress(Sender: TObject; var Key: Char);
    procedure SalesSearchBoxKeyPress(Sender: TObject; var Key: Char);
    procedure EmailsSearchBoxKeyPress(Sender: TObject; var Key: Char);
    procedure NewLeadsSGEnter(Sender: TObject);
    procedure ActiveLeadsSGEnter(Sender: TObject);
    procedure ProposalSentLeadsSGEnter(Sender: TObject);
    procedure ClosedLeadsSGEnter(Sender: TObject);
    procedure NewLeadsSGDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure NewLeadsSGDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure NewLeadsSGMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure VCLStylesCBChange(Sender: TObject);
    procedure LeadsRelativePanelResize(Sender: TObject);
    procedure AcctsRelativePanelResize(Sender: TObject);
    procedure ProposalsRelativePanelResize(Sender: TObject);
    procedure MarketingRelativePanelResize(Sender: TObject);
    procedure UsersRelativePanelResize(Sender: TObject);
    procedure CreateLeadButtonClick(Sender: TObject);
    procedure ExportLeadsButtonClick(Sender: TObject);
    procedure ViewLeadButtonClick(Sender: TObject);
    procedure ExportEmailsButtonClick(Sender: TObject);
    procedure SplitViewOpening(Sender: TObject);
    procedure SplitViewClosing(Sender: TObject);
    procedure CreateAcctButtonClick(Sender: TObject);
    procedure DashboardButtonClick(Sender: TObject);
    procedure AccountsTabResize(Sender: TObject);
    procedure RemoveAcctButtonClick(Sender: TObject);
    procedure ExportAcctsButtonClick(Sender: TObject);
    procedure CreateUserButtonClick(Sender: TObject);
    procedure RemoveUserButtonClick(Sender: TObject);
    procedure UsersTabResize(Sender: TObject);
    procedure CancelProposalButtonClick(Sender: TObject);
    procedure CompleteProposalButtonClick(Sender: TObject);
    procedure MenuVirtualImageClick(Sender: TObject);
    procedure PageControlChange(Sender: TObject);
    procedure UsernameComboBoxKeyPress(Sender: TObject; var Key: Char);
    procedure UsernameComboBoxChange(Sender: TObject);
    procedure NewLeadsSGDblClick(Sender: TObject);
    procedure ActiveLeadsSGDblClick(Sender: TObject);
    procedure VCLStylesCBKeyPress(Sender: TObject; var Key: Char);
    procedure FormActivate(Sender: TObject);
    procedure HelpChatGetContext(Sender: TObject; var AContext: THelpChatContext);
    procedure HelpChatActionExecuted(Sender: TObject; const AName: string;
      const AOutcome: THelpChatActionOutcome; const AResult: string);
    procedure HelpChatDecryptSecret(Sender: TObject; const AName, AValue: string;
      var AResult: string; var AHandled: Boolean);
    procedure HelpChatModelChanged(Sender: TObject);
    procedure HelpChatLog(Sender: TObject; const AEntry: THelpChatLogEntry);
  private
    { Private declarations }
    // The activation window is open: another change of model does not open
    // a second one.
    FAskingKey: Boolean;
    FRanOnce: Boolean;
    procedure AppIdle(Sender: TObject; var Done: Boolean);
    procedure UpdateNavButtons;
    /// <summary>What the assistant may do in this application, and nothing
    /// else: each action declares name, description and parameters, and the
    /// handler runs on the main thread. Those that write data ask the user
    /// to confirm before they start.</summary>
    procedure RegisterHelpActions;
    /// <summary>Fallback: the model the assistant is about to use wants a
    /// key and has none (neither in the configuration files nor in the
    /// environment variable of its service). We ask for it for that model,
    /// encrypt it with the secret of this application and write it to the
    /// per-user file, where the next run reads it back encrypted. At startup
    /// and at every change of model from the panel.</summary>
    procedure AskForApiKeyIfMissing;
    /// <summary>The tab the assistant named.</summary>
    function FindTab(const AName: string): TTabSheet;
  public
    { Public declarations }
  end;

/// <summary>Brings the column widths of the TLinkGridToDataSource of a form
/// to screen pixels: LiveBindings keeps them as the DFM writes them, in
/// design pixels, and applies them again to the grid after the VCL scaled
/// it. Without this, at 150% or 175% the columns stay narrow and the text
/// is cut.</summary>
procedure ScaleBoundGridColumns(AForm: TCustomForm);

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.Types, System.Math,
  uDataMod, uLeads, uProposal,
  HelpChatAI.Settings,
  // The API key is not in clear text in the configuration: uAppSecret
  // encrypts it and reads it back, and HelpChatDecryptSecret is the hook the
  // component calls. DCPcrypt is for this demo, not for the library.
  uAppSecret, uLicenseActivation,
  // The actions of the assistant, shared with the FireMonkey demo.
  uCRMActions,
  // The log of the assistant to a file, written by Logify.
  uHelpChatLog,
  // A provider exists only if its unit is linked: it registers itself in its
  // initialization. Without this line Settings.Provider = 'docsearch' finds
  // only the stub, and the chat answers that the provider is not there.
  HelpChatAI.Provider.DocSearch, HelpChatAI.Provider.Claude,
  HelpChatAI.Provider.OpenAI, HelpChatAI.Provider.Gemini
  {$IFDEF MULTIAGENT}
  // The edition with several assistants (VCL_CRMDemo_MultiAgent.dproj):
  // everything it adds is in this unit.
  , uMultiAgent
  {$ENDIF};

procedure ScaleBoundGridColumns(AForm: TCustomForm);
var
  I, J: Integer;
  LLink: TLinkGridToDataSource;
  LChanged: Boolean;
begin
  if AForm.ScaleFactor = 1 then
    Exit;
  for I := 0 to AForm.ComponentCount - 1 do
    if AForm.Components[I] is TLinkGridToDataSource then
    begin
      LLink := TLinkGridToDataSource(AForm.Components[I]);
      LChanged := False;
      for J := 0 to LLink.Columns.Count - 1 do
        if LLink.Columns[J].Width > 0 then
        begin
          LLink.Columns[J].Width := Round(LLink.Columns[J].Width * AForm.ScaleFactor);
          LChanged := True;
        end;
      if LChanged and LLink.Active then
      begin
        LLink.Active := False;
        LLink.Active := True;
      end;
    end;
end;

function TMainForm.FindTab(const AName: string): TTabSheet;
var
  I: Integer;
begin
  // The model names a screen as a user would: the exact name first, then a
  // partial match.
  for I := 0 to PageControl.PageCount - 1 do
    if SameText(PageControl.Pages[I].Caption, AName) or
       SameText(PageControl.Pages[I].HelpKeyword, AName) or
       SameText(PageControl.Pages[I].Name, AName) then
      Exit(PageControl.Pages[I]);
  for I := 0 to PageControl.PageCount - 1 do
    if string(PageControl.Pages[I].Caption).ToLower.Contains(AName.ToLower) then
      Exit(PageControl.Pages[I]);
  Result := nil;
end;

procedure TMainForm.RegisterHelpActions;
var
  LHooks: TCRMActionHooks;
  LProposalActions: THelpChatActionBroker;
begin
  // With one assistant, the proposal is an action of its own like the
  // others. With several it is a shared action: registered once for all of
  // them, and who uses it is decided by the configuration (AllowedActions,
  // in uMultiAgent), not by this code.
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
      LTab: TTabSheet;
    begin
      LTab := FindTab(AName);
      if LTab = nil then
        Exit('');
      PageControl.ActivePage := LTab;
      PageControlChange(PageControl);
      Result := LTab.Caption;
    end;
  LHooks.CurrentUser :=
    function: string
    begin
      Result := UsernameComboBox.Text;
    end;
  LHooks.AccountCreated :=
    procedure(AName: string)
    begin
      // The Accounts grid and the combo of the lead window read the
      // companies again.
      LinkGridToDataSourceAcctBindSourceDB.Active := False;
      LinkGridToDataSourceAcctBindSourceDB.Active := True;
      LeadsForm.LinkFillControlToField2.Active := False;
      LeadsForm.LinkFillControlToField2.Active := True;
    end;
  LHooks.LeadCreated :=
    procedure(ALeadId: Integer)
    begin
      PageControl.ActivePage := LeadsTab;
      LeadsForm.LocateLead(ALeadId);
      BindNavigator1.DataSource := LeadsBindNewSourceDB;
      LeadsForm.Show;
    end;
  LHooks.DraftReady :=
    procedure(ADraft: TCRMDraft)
    begin
      DraftProposalForm.PrepareDraft(ADraft.LeadId, ADraft.Company,
        ADraft.Address1, ADraft.Address2, ADraft.Phone, ADraft.Items);
    end;
  RegisterCRMActions(HelpChat.Actions, LProposalActions, LHooks);
end;

procedure TMainForm.HelpChatActionExecuted(Sender: TObject; const AName: string;
  const AOutcome: THelpChatActionOutcome; const AResult: string);
begin
  // No status bar in this application: the outcome matters to the model,
  // which gets it anyway, and to the user, who sees the window open.
  if AOutcome = aoFailed then
    Beep;
end;

procedure TMainForm.HelpChatDecryptSecret(Sender: TObject; const AName, AValue: string;
  var AResult: string; var AHandled: Boolean);
begin
  // This runs on the worker thread that is about to call the service:
  // compute and return, no window and no waiting. AName would say which
  // secret it is (Claude.ApiKey, Remote.AppKey...); here every value
  // carrying the prefix is answered for, whoever asked.
  AHandled := AppSecretIsProtected(AValue);
  if AHandled then
    AResult := AppSecretReveal(AValue);
end;

procedure TMainForm.HelpChatLog(Sender: TObject; const AEntry: THelpChatLogEntry);
begin
  // The log of the assistant to a file, with Logify (uHelpChatLog): in
  // %APPDATA%\HelpChatAI\Logs\VCL_CRMDemo.log, rotated. It runs on the
  // thread that writes the entry (often a worker), one call at a time, and
  // Logify queues it and returns at once. The level is Settings.LogLevel,
  // "info" unless changed: "LogLevel": "debug" in helpchatai.json shows
  // everything, question, reply and HTTP calls included.
  HelpChatLogWrite(AEntry);
end;

procedure TMainForm.AskForApiKeyIfMissing;
var
  LRequest: TAppSecretKeyRequest;
  LRequests: TArray<TAppSecretKeyRequest>;
  LKeys: TArray<string>;
  LInfo: THelpChatModelInfo;
  I: Integer;
begin
  // RunSettings are the settings of the running engine, with the model
  // picked in the panel already applied: its provider says whether the key
  // is missing (the property, the three helpchatai.json already loaded, the
  // environment variable, the handler above). docsearch or a local Ollama
  // want none, and the window does not open.
  if FAskingKey or not AppSecretMissingKey(HelpChat.RunSettings, LRequest) then
    Exit;
  FAskingKey := True;
  try
    // One row per service (Claude, Gemini, OpenAI), the one of the model in
    // use in bold: while at it, the user registers the others too.
    LRequests := AppSecretKeyRequests(HelpChat.RunSettings);
    if not TLicenseActivationForm.Execute(LRequests,
      THelpChatSettings.UserConfigFile, LKeys) then
      Exit;
    // Encrypted, into the section of the provider or into the model of the
    // catalogue when it has an endpoint of its own, and applied at once:
    // what stays in memory is the encrypted one.
    AppSecretActivate(HelpChat.RunSettings, LRequests, LKeys);
    for I := 0 to High(LKeys) do
      LKeys[I] := '';
    // The model in use still has no key, but the user registered another
    // one: switch to the first that can answer. Models offers only those
    // (plus the one in use), and the switch reaches the panel too.
    if AppSecretMissingKey(HelpChat.RunSettings, LRequest) then
      for LInfo in HelpChat.Models do
        if not LInfo.Active then
        begin
          HelpChat.SelectModel(LInfo.Name);
          Break;
        end;
  finally
    FAskingKey := False;
  end;
end;

procedure TMainForm.HelpChatModelChanged(Sender: TObject);
begin
  // The user picked another model in the panel: if it has no key, we ask
  // for it now instead of leaving it to the first question.
  AskForApiKeyIfMissing;
end;

procedure TMainForm.HelpChatGetContext(Sender: TObject; var AContext: THelpChatContext);
begin
  // The component finds the screen walking up from the focused control:
  // inside a page it reaches the TTabSheet and takes its keyword, but the
  // side menu is outside the PageControl, and from there F1 would describe
  // the window instead of the page the user is looking at. For this
  // application the active page is always the right answer - but only on
  // this window: when the user is working on the lead or on the proposal,
  // the component already chose that one (ScreenType), even with the chat
  // in front.
  if (AContext.ScreenType = ClassName) and (PageControl.ActivePage <> nil) then
  begin
    AContext.ScreenName := PageControl.ActivePage.Name;
    AContext.ScreenLabel := PageControl.ActivePage.Caption;
    if PageControl.ActivePage.HelpKeyword <> '' then
      AContext.HelpKeyword := PageControl.ActivePage.HelpKeyword;
  end;
end;

procedure TMainForm.RemoveAcctButtonClick(Sender: TObject);
begin
  AcctBindSourceDB.DataSet.Delete;
end;

procedure TMainForm.RemoveUserButtonClick(Sender: TObject);
begin
  UsersBindSourceDB.DataSet.Delete;
end;

procedure TMainForm.AcctSearchBoxKeyPress(Sender: TObject; var Key: Char);
begin
  DM.SearchAccounts(AcctSearchBox.Text);
end;

procedure TMainForm.CalendarView1DrawDayItem(Sender: TObject;
  DrawParams: TDrawViewInfoParams; CalendarViewViewInfo: TCellItemViewInfo);
begin
  if DayOfWeek(CalendarViewViewInfo.Date) in [1, 7] then
  begin
    DrawParams.Font.Style := [fsBold];
  end;
end;

procedure TMainForm.CancelProposalButtonClick(Sender: TObject);
begin
  if ProposalBindSourceDB.DataSet.RecordCount>0 then
  begin
    DM.UpdateProposalStatus(ProposalBindSourceDB.DataSet.FieldByName('LeadId').AsInteger,'Canceled');
  end;
end;

procedure TMainForm.PageControlChange(Sender: TObject);
begin
  if PageControl.ActivePageIndex=0 then
    begin
      DM.FDQueryNewTotal.Refresh;
      DM.FDQueryActiveTotal.Refresh;
      DM.FDQueryProposalTotal.Refresh;
      DM.FDQueryInactiveTotal.Refresh;
      DM.FDQueryClosedTotal.Refresh;
      DM.FDQueryTotal.Refresh;
    end;
  case PageControl.ActivePageIndex of
    0: DashboardButton.SetFocus;
    1: AcctsButton.SetFocus;
    2: LeadsButton.SetFocus;
    3: SalesButton.SetFocus;
    4: begin
      MarketingButton.SetFocus;
      EmailsBindSourceDB.DataSet.Refresh;
    end;
    5: CalendarButton.SetFocus;
    6: UsersButton.SetFocus;
  end;

end;

procedure TMainForm.SalesSearchBoxKeyPress(Sender: TObject; var Key: Char);
begin
  DM.SearchProposals(SalesSearchBox.Text);
end;

procedure TMainForm.SplitViewClosing(Sender: TObject);
begin
  DashboardButton.Caption := '';
  AcctsButton.Caption := '';
  LeadsButton.Caption := '';
  SalesButton.Caption := '';
  MarketingButton.Caption := '';
  CalendarButton.Caption := '';
  UsersButton.Caption := '';
end;

procedure TMainForm.SplitViewOpening(Sender: TObject);
begin
  DashboardButton.Caption := '          '+DashboardButton.Hint;
  AcctsButton.Caption := '          '+AcctsButton.Hint;
  LeadsButton.Caption := '          '+LeadsButton.Hint;
  SalesButton.Caption := '          '+SalesButton.Hint;
  MarketingButton.Caption := '          '+MarketingButton.Hint;
  CalendarButton.Caption := '          '+CalendarButton.Hint;
  UsersButton.Caption := '          '+UsersButton.Hint;
end;

procedure TMainForm.AccountsTabResize(Sender: TObject);
begin
  // The widths of the grid and of the column are already screen pixels
  // (ScaleBoundGridColumns scaled the columns at startup): multiplying the
  // difference by ScaleFactor gave a column wider than the grid, with the
  // horizontal scroll bar always on.
  LinkGridToDataSourceAcctBindSourceDB.Columns[1].Width :=
    AccountsSG.ClientWidth - LinkGridToDataSourceAcctBindSourceDB.Columns[0].Width -
    Round(4 * ScaleFactor);
end;

procedure TMainForm.UsersTabResize(Sender: TObject);
begin
  LinkGridToDataSourceUsersBindSourceDB.Columns[1].Width :=
    UsersSG.ClientWidth - LinkGridToDataSourceUsersBindSourceDB.Columns[0].Width -
    Round(4 * ScaleFactor);
end;

procedure TMainForm.UsernameComboBoxChange(Sender: TObject);
begin
  LeadsForm.Close;
  DraftProposalForm.Close;
  ProposalForm.Close;
  DM.SetUser(UsernameComboBox.Text);
end;

procedure TMainForm.UsernameComboBoxKeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TMainForm.UsersRelativePanelResize(Sender: TObject);
begin
  if UsersRelativePanel.Width<=Round(436 * ScaleFactor) then
  begin
    CreateUserButton.Caption := '';
    CreateUserButton.Width := Round(40 * ScaleFactor);
    RemoveUserButton.Caption := '';
    RemoveUserButton.Width := Round(40 * ScaleFactor);
  end
  else
  begin
    CreateUserButton.Caption := CreateUserButton.Hint;
    CreateUserButton.Width := Round(121 * ScaleFactor);
    RemoveUserButton.Caption := RemoveUserButton.Hint;
    RemoveUserButton.Width := Round(121 * ScaleFactor);
  end;
end;

procedure TMainForm.VCLStylesCBChange(Sender: TObject);
begin
  MainForm.WindowState := TWindowState.wsMaximized;
  TStyleManager.TrySetStyle(VCLStylesCB.Text);
  UpdateNavButtons;
end;

procedure TMainForm.VCLStylesCBKeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TMainForm.ViewLeadButtonClick(Sender: TObject);
begin
  LeadsForm.Show;
end;

procedure TMainForm.MenuVirtualImageClick(Sender: TObject);
begin
  SplitView.Opened := not SplitView.Opened;
end;

procedure TMainForm.AcctsRelativePanelResize(Sender: TObject);
begin
  if AcctsRelativePanel.Width<=Round(634*ScaleFactor) then
  begin

    ExportAcctsButton.Caption := '';
    ExportAcctsButton.Width := Round(40*ScaleFactor);
    CreateAcctButton.Caption := '';
    CreateAcctButton.Width := Round(40*ScaleFactor);
    RemoveAcctButton.Caption := '';
    RemoveAcctButton.Width := Round(40*ScaleFactor);
  end
  else
  begin
    ExportAcctsButton.Caption := ExportAcctsButton.Hint;
    ExportAcctsButton.Width := Round(112*ScaleFactor);
    CreateAcctButton.Caption := CreateAcctButton.Hint;
    CreateAcctButton.Width := Round(112*ScaleFactor);
    RemoveAcctButton.Caption := RemoveAcctButton.Hint;
    RemoveAcctButton.Width := Round(112*ScaleFactor);
  end;
end;

procedure TMainForm.ActiveLeadsSGDblClick(Sender: TObject);
begin
  ViewLeadButtonClick(Sender);
end;

procedure TMainForm.ActiveLeadsSGEnter(Sender: TObject);
begin
  LeadsForm.LocateLead(LeadsBindActiveSourceDB.DataSet.FieldByName('LeadId').AsInteger);
  BindNavigator1.DataSource := LeadsBindActiveSourceDB;
end;

procedure TMainForm.ProposalSentLeadsSGEnter(Sender: TObject);
begin
  LeadsForm.LocateLead(LeadsBindProposalSentSourceDB.DataSet.FieldByName('LeadId').AsInteger);
  BindNavigator1.DataSource := LeadsBindProposalSentSourceDB;
end;

procedure TMainForm.ProposalsRelativePanelResize(Sender: TObject);
begin
  if ProposalsRelativePanel.Width<=Round(436*ScaleFactor) then
  begin
    CompleteProposalButton.Caption := '';
    CompleteProposalButton.Width := Round(40*ScaleFactor);
    CancelProposalButton.Caption := '';
    CancelProposalButton.Width := Round(40*ScaleFactor);
  end
  else
  begin
    CompleteProposalButton.Caption := CompleteProposalButton.Hint;
    CompleteProposalButton.Width := Round(121*ScaleFactor);
    CancelProposalButton.Caption := CancelProposalButton.Hint;
    CancelProposalButton.Width := Round(121*ScaleFactor);
  end;
end;

procedure TMainForm.ClosedLeadsSGEnter(Sender: TObject);
begin
  LeadsForm.LocateLead(LeadsBindClosedSourceDB.DataSet.FieldByName('LeadId').AsInteger);
  BindNavigator1.DataSource := LeadsBindClosedSourceDB;
end;

procedure TMainForm.CompleteProposalButtonClick(Sender: TObject);
begin
  if ProposalBindSourceDB.DataSet.RecordCount>0 then
  begin
    DM.UpdateProposalStatus(ProposalBindSourceDB.DataSet.FieldByName('LeadId').AsInteger,'Accepted');
    ProposalBindSourceDB.DataSet.Refresh;
  end;
end;

procedure TMainForm.CreateAcctButtonClick(Sender: TObject);
var
LNewAccount: String;
begin
  LNewAccount := InputBox('Create New Account', 'Account Name', 'New Account');
  AcctBindSourceDB.DataSet.DisableControls;
  AcctBindSourceDB.DataSet.AppendRecord([nil,LNewAccount]);
  AcctBindSourceDB.DataSet.EnableControls;
  LinkGridToDataSourceAcctBindSourceDB.Active := False;
  LinkGridToDataSourceAcctBindSourceDB.Active := True;

end;

procedure TMainForm.CreateLeadButtonClick(Sender: TObject);
begin
  LeadsBindNewSourceDB.DataSet.Append;
  LeadsBindNewSourceDB.DataSet.FieldByName('LeadId').AsString := '';
  LeadsBindNewSourceDB.DataSet.FieldByName('Status').AsString := 'New';
  LeadsBindNewSourceDB.DataSet.FieldByName('Name').AsString := 'First Last';
  LeadsBindNewSourceDB.DataSet.FieldByName('User').AsString := UsernameCombobox.Text;
  LeadsBindNewSourceDB.DataSet.FieldByName('DateCreated').AsDateTime := Now;
  LeadsBindNewSourceDB.DataSet.Post;
  LeadsBindSourceDB.DataSet.Locate('LeadId',VarArrayOf([LeadsBindNewSourceDB.DataSet.FieldByName('LeadId').AsInteger]),[]);
  BindNavigator1.DataSource := LeadsBindNewSourceDB;
  LeadsForm.Show;
end;

procedure TMainForm.CreateUserButtonClick(Sender: TObject);
var
LNewUser: String;
begin
  LNewUser := InputBox('Create New User', 'User Name', 'user');
  if UsersBindSourceDB.DataSet.Lookup('Username', VarArrayOf([LNewUser]),'Username')<>LNewUser then
  begin
    UsersBindSourceDB.DataSet.Append;
    UsersBindSourceDB.DataSet.FieldByName('UserId').AsInteger := 0;
    UsersBindSourceDB.DataSet.FieldByName('Username').AsString := LNewUser;
    UsersBindSourceDB.DataSet.Post;
    DM.UsersFDTable.Refresh;
  end
  else
  begin
    ShowMessage('A user with that username already exists.');
  end;
end;

procedure TMainForm.DashboardButtonClick(Sender: TObject);
begin
  PageControl.ActivePageIndex := TButton(Sender).Tag;
end;

procedure TMainForm.LeadsRelativePanelResize(Sender: TObject);
begin
  if LeadsRelativePanel.Width<=Round(781*ScaleFactor) then
  begin

    ExportLeadsButton.Caption := '';
    ExportLeadsButton.Width := Round(40*ScaleFactor);
    CreateLeadButton.Caption := '';
    CreateLeadButton.Width := Round(40*ScaleFactor);
    ViewLeadButton.Caption := '';
    ViewLeadButton.Width := Round(40*ScaleFactor);
  end
  else
  begin
    ExportLeadsButton.Caption := ExportLeadsButton.Hint;
    ExportLeadsButton.Width := Round(153*ScaleFactor);
    CreateLeadButton.Caption := CreateLeadButton.Hint;
    CreateLeadButton.Width := Round(153*ScaleFactor);
    ViewLeadButton.Caption := ViewLeadButton.Hint;
    ViewLeadButton.Width := Round(153*ScaleFactor);
  end;
end;

procedure TMainForm.LeadsSearchBoxKeyPress(Sender: TObject; var Key: Char);
begin
  DM.SearchLeads(LeadsSearchBox.Text);
end;

procedure TMainForm.MarketingRelativePanelResize(Sender: TObject);
begin
  if MarketingRelativePanel.Width<=Round(320*ScaleFactor) then
  begin
    ExportEmailsButton.Caption := '';
    ExportEmailsButton.Width := Round(40*ScaleFactor);
  end
  else
  begin
    ExportEmailsButton.Caption := ExportEmailsButton.Hint;
    ExportEmailsButton.Width := Round(121*ScaleFactor);;
  end;
end;

procedure TMainForm.NewLeadsSGDblClick(Sender: TObject);
begin
  ViewLeadButtonClick(Sender);
end;

procedure TMainForm.NewLeadsSGDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  LStatus: String;
  LIndex: Integer;
  LDataSet: TDataSet;
  LDateField: String;
begin
  LIndex := -1;

  if Source = Sender then
  begin

  end
  else
  begin

    case TStringGrid(Sender).Parent.Tag of
      1:
        begin
          LStatus := 'New';
          LDateField := 'DateCreated';
          LDataSet := LeadsBindNewSourceDB.DataSet;
        end;
      2:
        begin
          LStatus := 'Active';
          LDateField := 'DateContacted';
          LDataSet := LeadsBindActiveSourceDB.DataSet;
        end;
      3:
        begin
          LStatus := 'Proposal Sent';
          LDateField := 'DateDrafted';
          LDataSet := LeadsBindProposalSentSourceDB.DataSet;
        end;
      4:
        begin
          LStatus := 'Closed';
          LDateField := 'DateClosed';
          LDataSet := LeadsBindClosedSourceDB.DataSet;
        end;
      else
       LDataSet := LeadsBindNewSourceDB.DataSet;
    end;

    case TStringGrid(Source).Parent.Tag of
      1:
        begin
          if LeadsBindNewSourceDB.DataSet.RecordCount > 0 then
          begin
            LIndex := LeadsBindNewSourceDB.DataSet.FieldByName('LeadId').AsInteger;
            if LeadsBindSourceDB.DataSet.Locate('LeadId',VarArrayOf([LIndex]),[]) then
            begin
              LeadsBindSourceDB.DataSet.Edit;
              LeadsBindSourceDB.DataSet.FieldByName('Status').AsString := LStatus;
              if LeadsBindSourceDB.DataSet.FieldByName(LDateField).AsDateTime=0 then LeadsBindSourceDB.DataSet.FieldByName(LDateField).AsDateTime := Now;
              LeadsBindSourceDB.DataSet.Post;
            end;
            LDataSet.Locate('LeadId',VarArrayOf([LIndex]),[]);
          end;
        end;
      2:
        begin
          if LeadsBindActiveSourceDB.DataSet.RecordCount > 0 then
          begin
            LIndex := LeadsBindActiveSourceDB.DataSet.FieldByName('LeadId').AsInteger;
            if LeadsBindSourceDB.DataSet.Locate('LeadId',VarArrayOf([LIndex]),[]) then
            begin
              LeadsBindSourceDB.DataSet.Edit;
              LeadsBindSourceDB.DataSet.FieldByName('Status').AsString := LStatus;
              if LeadsBindSourceDB.DataSet.FieldByName(LDateField).AsDateTime=0 then LeadsBindSourceDB.DataSet.FieldByName(LDateField).AsDateTime := Now;
              LeadsBindSourceDB.DataSet.Post;
            end;
            LDataSet.Locate('LeadId',VarArrayOf([LIndex]),[]);
          end;
        end;
      3:
        begin
          if LeadsBindProposalSentSourceDB.DataSet.RecordCount > 0 then
          begin
            LIndex := LeadsBindProposalSentSourceDB.DataSet.FieldByName('LeadId').AsInteger;
            if LeadsBindSourceDB.DataSet.Locate('LeadId',VarArrayOf([LIndex]),[]) then
            begin
              LeadsBindSourceDB.DataSet.Edit;
              LeadsBindSourceDB.DataSet.FieldByName('Status').AsString := LStatus;
              if LeadsBindSourceDB.DataSet.FieldByName(LDateField).AsDateTime=0 then LeadsBindSourceDB.DataSet.FieldByName(LDateField).AsDateTime := Now;
              LeadsBindSourceDB.DataSet.Post;
            end;
            LDataSet.Locate('LeadId',VarArrayOf([LIndex]),[]);
          end;
        end;
      4:
        begin
          if LeadsBindClosedSourceDB.DataSet.RecordCount > 0 then
          begin
            LIndex := LeadsBindClosedSourceDB.DataSet.FieldByName('LeadId').AsInteger;
            if LeadsBindSourceDB.DataSet.Locate('LeadId',VarArrayOf([LIndex]),[]) then
            begin
              LeadsBindSourceDB.DataSet.Edit;
              LeadsBindSourceDB.DataSet.FieldByName('Status').AsString := LStatus;
              if LeadsBindSourceDB.DataSet.FieldByName(LDateField).AsDateTime=0 then LeadsBindSourceDB.DataSet.FieldByName(LDateField).AsDateTime := Now;
              LeadsBindSourceDB.DataSet.Post;
            end;
            LDataSet.Locate('LeadId',VarArrayOf([LIndex]),[]);
          end;
        end;
    end;

    DM.RefreshLeadQueries;

    LDataSet.Locate('LeadId',VarArrayOf([LIndex]),[]);
  end;
end;

procedure TMainForm.NewLeadsSGDragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  Accept := Source is TStringGrid;
end;

procedure TMainForm.NewLeadsSGEnter(Sender: TObject);
begin
  LeadsForm.LocateLead(LeadsBindNewSourceDB.DataSet.FieldByName('LeadId').AsInteger);
  BindNavigator1.DataSource := LeadsBindNewSourceDB;
end;

procedure TMainForm.NewLeadsSGMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
     TStringGrid(Sender).BeginDrag(False,4);
end;

procedure TMainForm.EmailsSearchBoxKeyPress(Sender: TObject; var Key: Char);
begin
  DM.SearchEmails(EmailsSearchBox.Text);
end;

procedure TMainForm.ExportAcctsButtonClick(Sender: TObject);
begin
  if ExportAcctsDialog.Execute then
  begin
    DM.AcctFDTable.SaveToFile(ExportAcctsDialog.FileName);
  end;
end;

procedure TMainForm.ExportEmailsButtonClick(Sender: TObject);
begin
  if SaveEmailsDialog.Execute then
  begin
    DM.ExportEmails(SaveEmailsDialog.FileName);
  end;
end;

procedure TMainForm.ExportLeadsButtonClick(Sender: TObject);
begin
  if ExportLeadsDialog.Execute then
  begin
    DM.LeadsFDTable.SaveToFile(ExportLeadsDialog.FileName);
  end;
end;

procedure TMainForm.AppIdle(Sender: TObject; var Done: Boolean);
begin
  if not FRanOnce then
  begin
    FRanOnce := True;

    DM.InitializeDatabase;

    ScaleBoundGridColumns(Self);
    ScaleBoundGridColumns(LeadsForm);

    // The assistant: the index of the manual is in Help\help-index.json, the
    // path in the DFM is relative to the executable. From here on F1 opens
    // the chat on the page of the active screen (HelpKeyword of the tabs and
    // of the windows) and the bubble at the bottom right opens it with the
    // context of the window the user is on.
    RegisterHelpActions;
    HelpChatLogOpen('VCL_CRMDemo');
    // What happens, never what the user writes: "LogLevel" in a
    // helpchatai.json raises it (detail, debug) without recompiling.
    HelpChat.Settings.LogLevel := llInfo;
    HelpChat.OnLogEvent := HelpChatLog;
    {$IFDEF MULTIAGENT}
    ConfigureGeneralAssistant(HelpChat);
    {$ENDIF}
    HelpChat.Active := True;
    {$IFDEF MULTIAGENT}
    // The second assistant, on the lead window: after the first, whose
    // provider, models, manual and key handler it copies.
    CreateSalesAssistant(HelpChat, LeadsForm);
    {$ENDIF}
    AskForApiKeyIfMissing;

    DashboardButton.SetFocus;
  end;
end;

procedure TMainForm.FormActivate(Sender: TObject);
begin
  if FRanOnce then
  begin
    if LeadsBindSourceDB.DataSet.State = TDataSetState.dsEdit then
      LeadsBindSourceDB.DataSet.Post;
    TBindSourceDB(BindNavigator1.DataSource).DataSet.Refresh;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  StyleName: string;
  LWork: TRect;
  LWidth, LHeight: Integer;
begin
  Application.OnIdle := AppIdle;
  // Maximized here, after the restored bounds are centred on the work area:
  // the default position cascades, so after a few starts "Restore" put the
  // window past the right edge, and poScreenCenter does nothing to a form
  // that starts maximized.
  LWork := Monitor.WorkareaRect;
  LWidth := Min(Width, LWork.Width);
  LHeight := Min(Height, LWork.Height);
  SetBounds(LWork.Left + (LWork.Width - LWidth) div 2,
    LWork.Top + (LWork.Height - LHeight) div 2, LWidth, LHeight);
  WindowState := TWindowState.wsMaximized;

  for StyleName in TStyleManager.StyleNames do
    VCLStylesCB.Items.Add(StyleName);

  VCLStylesCB.ItemIndex := VCLStylesCB.Items.IndexOf(TStyleManager.ActiveStyle.Name);

  UpdateNavButtons;
end;

procedure TMainForm.UpdateNavButtons;
{$IFNDEF VCLSTYLEDCOMPONENTS}
var
  LStyle: Dword;
{$ENDIF}
begin
  {$IFDEF VCLSTYLEDCOMPONENTS}
  DashboardButton.CaptionAlignment := TAlignment.taLeftJustify;
  AcctsButton.CaptionAlignment := TAlignment.taLeftJustify;
  LeadsButton.CaptionAlignment := TAlignment.taLeftJustify;
  SalesButton.CaptionAlignment := TAlignment.taLeftJustify;
  MarketingButton.CaptionAlignment := TAlignment.taLeftJustify;
  CalendarButton.CaptionAlignment := TAlignment.taLeftJustify;
  UsersButton.CaptionAlignment := TAlignment.taLeftJustify;
  {$ELSE}
  LStyle := GetWindowLong(DashboardButton.Handle, GWL_STYLE);
  SetWindowLong(DashboardButton.Handle, GWL_STYLE, LStyle or BS_LEFT);
  DashboardButton.Caption := '          '+DashboardButton.Hint;
  SetWindowLong(AcctsButton.Handle, GWL_STYLE, LStyle or BS_LEFT);
  AcctsButton.Caption := '          '+AcctsButton.Hint;
  SetWindowLong(LeadsButton.Handle, GWL_STYLE, LStyle or BS_LEFT);
  LeadsButton.Caption := '          '+LeadsButton.Hint;
  SetWindowLong(SalesButton.Handle, GWL_STYLE, LStyle or BS_LEFT);
  SalesButton.Caption := '          '+SalesButton.Hint;
  SetWindowLong(MarketingButton.Handle, GWL_STYLE, LStyle or BS_LEFT);
  MarketingButton.Caption := '          '+MarketingButton.Hint;
  SetWindowLong(CalendarButton.Handle, GWL_STYLE, LStyle or BS_LEFT);
  CalendarButton.Caption := '          '+CalendarButton.Hint;
  SetWindowLong(UsersButton.Handle, GWL_STYLE, LStyle or BS_LEFT);
  UsersButton.Caption := '          '+UsersButton.Hint;
  {$ENDIF};
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  if MainForm.Width <= Round(640 * ScaleFactor) then
  begin
    if SplitView.Opened=True then SplitView.Opened := False;
  end
  else
  begin
    if SplitView.Opened=False then SplitView.Opened := True;
  end;
end;

end.
