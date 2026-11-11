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
  Vcl.VirtualImageList, Vcl.VirtualImage, System.IOUtils, Vcl.TitleBarCtrls,
  HelpChatAI.Types, HelpChatAI.Actions, Vcl.HelpChatAI,
  // per TProposalLineItem e ParseProposalLineItems, che un'azione
  // passa alla bozza
  uProposalReport, uDraftProposal
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
    TitleBarPanel1: TTitleBarPanel;
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
  private
    { Private declarations }
    FRanOnce: Boolean;
    procedure AppIdle(Sender: TObject; var Done: Boolean);
    procedure RefreshGrids;
    procedure UpdateNavButtons;
    /// <summary>Quello che l'assistente puo' fare in questa applicazione, e
    /// nient'altro: ogni azione dichiara nome, descrizione e parametri, e il
    /// gestore gira sul thread principale. Quelle che scrivono dati chiedono
    /// conferma all'utente prima di partire.</summary>
    procedure RegisterHelpActions;
    function ResolveAccountName(const AText: string): string;
    /// <summary>Ripiego: la chiave di Claude non c'e' da nessuna parte (ne'
    /// nei file di configurazione ne' in ANTHROPIC_API_KEY). La chiediamo una
    /// volta sola, la cifriamo con il segreto di questa applicazione e la
    /// scriviamo nel file utente, da dove la prossima esecuzione la rilegge
    /// cifrata.</summary>
    procedure AskForApiKeyIfMissing;
    /// <summary>La scheda che l'assistente ha chiamato per nome.</summary>
    function FindTab(const AName: string): TTabSheet;
    /// <summary>Il lead chiamato per nome, o per azienda se il nome non basta.</summary>
    function LocateLeadByName(const AName: string): Boolean;
  public
    { Public declarations }
  end;

/// <summary>Porta ai pixel dello schermo le larghezze di colonna dei
/// TLinkGridToDataSource di un form: LiveBindings le tiene come sono
/// scritte nel DFM, in pixel di progetto, e le riapplica alla griglia
/// dopo che la VCL l'ha scalata. Senza questo, a 150% o 175% le colonne
/// restano strette e il testo esce troncato.</summary>
procedure ScaleBoundGridColumns(AForm: TCustomForm);

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  uDataMod, uLeads, uProposal,
  HelpChatAI.Settings,
  // La chiave API non sta in chiaro nella configurazione: uAppSecret la
  // cifra e la rilegge, e HelpChatDecryptSecret e' il gancio che il
  // componente chiama. DCPcrypt serve a questa demo, non alla libreria.
  uAppSecret, uLicenseActivation,
  // Un provider esiste solo se la sua unit e' linkata: si registra nella
  // initialization. Senza questa riga Settings.Provider = 'docsearch'
  // trova soltanto lo stub e la chat risponde che il provider non c'e'.
  HelpChatAI.Provider.DocSearch, HelpChatAI.Provider.Claude,
  HelpChatAI.Provider.OpenAI, HelpChatAI.Provider.Gemini;

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
  // Il modello chiama una schermata come la chiamerebbe un utente: prima il
  // nome esatto, poi una corrispondenza parziale.
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

function TMainForm.LocateLeadByName(const AName: string): Boolean;
begin
  Result := DM.LeadsFDTable.Locate('Name', VarArrayOf([AName]), [loCaseInsensitive]);
  if not Result then
    Result := DM.LeadsFDTable.Locate('AccountName', VarArrayOf([AName]), [loCaseInsensitive, loPartialKey]);
end;

/// <summary>The company name as the Accounts list spells it. An exact match
/// (case apart) wins; else a name containing the text, if there is exactly
/// one; else an exception written for the model: no match means "create it
/// with create_account", more than one means "ask the user which one". The
/// lookup walks the table under DisableControls and goes back where it was,
/// so the grids of the application do not move.</summary>
function TMainForm.ResolveAccountName(const AText: string): string;
var
  LTable: TDataSet;
  LBookmark: TBookmark;
  LCandidates: TStringList;
  LName, LError: string;
begin
  Result := Trim(AText);
  if Result = '' then
    Exit;
  LTable := DM.AcctFDTable;
  LCandidates := TStringList.Create;
  try
    LTable.DisableControls;
    try
      LBookmark := LTable.GetBookmark;
      try
        LTable.First;
        while not LTable.Eof do
        begin
          LName := LTable.FieldByName('AccountName').AsString;
          if SameText(LName, Result) then
            Exit(LName);
          if LName.ToLower.Contains(Result.ToLower) then
            LCandidates.Add(LName);
          LTable.Next;
        end;
      finally
        if LTable.BookmarkValid(LBookmark) then
          LTable.GotoBookmark(LBookmark);
        LTable.FreeBookmark(LBookmark);
      end;
    finally
      LTable.EnableControls;
    end;
    if LCandidates.Count = 1 then
      Exit(LCandidates[0]);
    if LCandidates.Count > 1 then
      LError := Format('More than one account matches "%s": %s. Ask the user which one.',
        [Result, string.Join(', ', LCandidates.ToStringArray)])
    else
      LError := Format('There is no account called "%s". Create it with create_account, ' +
        'then call create_lead again.', [Result]);
  finally
    LCandidates.Free;
  end;
  raise Exception.Create(LError);
end;

procedure TMainForm.RegisterHelpActions;
begin
  HelpChat.Actions.Add('open_screen',
    'Brings one of the application screens to the front. Only when the user asks to ' +
    'go to a screen: never to show where something is while answering a question.',
    [THelpChatActionParam.Create('name',
      'Screen name: Dashboard, Accounts, Leads, Sales, Marketing, Calendar or Users.')],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LTab: TTabSheet;
    begin
      LTab := FindTab(AArgs.AsString('name'));
      if LTab = nil then
        raise Exception.CreateFmt('There is no "%s" screen.', [AArgs.AsString('name')]);
      PageControl.ActivePage := LTab;
      PageControlChange(PageControl);
      AResult := 'Opened the ' + LTab.Caption + ' screen.';
    end, False); // changes nothing: no confirmation

  // Scrive un record: chiede conferma (il default), e l'utente vede nome e
  // valori. L'azienda deve esistere: l'handler la cerca e, se manca o se il
  // nome e' ambiguo, lo dice al modello con un'eccezione che spiega cosa
  // fare - creare l'azienda con create_account, o chiedere all'utente.
  HelpChat.Actions.Add('create_account',
    'Creates a company in the Accounts list. Use it before create_lead when the ' +
    'company of the lead is not there yet.',
    [THelpChatActionParam.Create('name', 'Company name')],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LName: string;
    begin
      LName := Trim(AArgs.AsString('name'));
      if LName = '' then
        raise Exception.Create('The company name is required.');
      // Idempotent: after a timeout the model may call it again, and the
      // second call must not create a second company.
      if DM.AcctFDTable.Locate('AccountName', VarArrayOf([LName]), [loCaseInsensitive]) then
        raise Exception.CreateFmt('The account "%s" already exists.',
          [DM.AcctFDTable.FieldByName('AccountName').AsString]);
      AcctBindSourceDB.DataSet.DisableControls;
      try
        AcctBindSourceDB.DataSet.AppendRecord([nil, LName]);
      finally
        AcctBindSourceDB.DataSet.EnableControls;
      end;
      // The Accounts grid reads the query, the combo of the lead window reads
      // the table: both have to see the new row.
      LinkGridToDataSourceAcctBindSourceDB.Active := False;
      LinkGridToDataSourceAcctBindSourceDB.Active := True;
      DM.AcctFDTable.Refresh;
      LeadsForm.LinkFillControlToField2.Active := False;
      LeadsForm.LinkFillControlToField2.Active := True;
      AResult := Format('Account "%s" created.', [LName]);
    end);

  HelpChat.Actions.Add('create_lead',
    'Creates a new lead for the active user and opens its detail window so the ' +
    'user can check it. Does not send anything to anybody. The company must ' +
    'exist in the Accounts list: if it does not, create it with create_account first.',
    [THelpChatActionParam.Create('name', 'Name of the person'),
     THelpChatActionParam.Create('account',
       'Company name, as in the Accounts list (it must exist)', apkString, False),
     THelpChatActionParam.Create('phone', 'Office phone', apkString, False),
     THelpChatActionParam.Create('email', 'E-mail address', apkString, False),
     THelpChatActionParam.Create('notes', 'Anything worth remembering', apkString, False)],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LDataSet: TDataSet;
      LAccount: string;
    begin
      // The company as it is spelled in the Accounts list, or an exception
      // the model reads: "create it first" or "ask the user which one".
      LAccount := ResolveAccountName(AArgs.AsString('account'));
      PageControl.ActivePage := LeadsTab;
      LDataSet := LeadsBindNewSourceDB.DataSet;
      LDataSet.Append;
      LDataSet.FieldByName('Status').AsString := 'New';
      LDataSet.FieldByName('Name').AsString := AArgs.AsString('name');
      LDataSet.FieldByName('AccountName').AsString := LAccount;
      LDataSet.FieldByName('OfficePhone').AsString := AArgs.AsString('phone');
      LDataSet.FieldByName('Email').AsString := AArgs.AsString('email');
      LDataSet.FieldByName('Notes').AsString := AArgs.AsString('notes');
      LDataSet.FieldByName('User').AsString := UsernameComboBox.Text;
      LDataSet.FieldByName('DateCreated').AsDateTime := Now;
      LDataSet.Post;
      RefreshGrids;
      LeadsForm.LocateLead(LDataSet.FieldByName('LeadId').AsInteger);
      BindNavigator1.DataSource := LeadsBindNewSourceDB;
      LeadsForm.Show;
      AResult := Format('Lead "%s" created with status New (id %d).',
        [AArgs.AsString('name'), LDataSet.FieldByName('LeadId').AsInteger]);
    end, True);

  HelpChat.Actions.Add('draft_proposal',
    'Opens the proposal draft for a lead with the address and the line items ' +
    'already filled in. It does not save it: the user presses Preview and Save Proposal.',
    [THelpChatActionParam.Create('lead', 'Name of the lead, or of its company'),
     THelpChatActionParam.Create('items',
       'The line items, one per line, written as "title x quantity @ price", ' +
       'for example "Consulting x 12 @ 150". The price uses a dot as decimal separator.'),
     THelpChatActionParam.Create('address1', 'Street address of the customer', apkString, False),
     THelpChatActionParam.Create('address2', 'City, state and postal code', apkString, False),
     THelpChatActionParam.Create('phone', 'Phone of the customer', apkString, False)],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LItems: TArray<TProposalLineItem>;
      LLeadId: Integer;
      LCompany: string;
    begin
      LItems := ParseProposalLineItems(AArgs.AsString('items'));
      if not LocateLeadByName(AArgs.AsString('lead')) then
        raise Exception.CreateFmt('There is no lead called "%s".', [AArgs.AsString('lead')]);
      LLeadId := DM.LeadsFDTable.FieldByName('LeadId').AsInteger;
      LCompany := DM.LeadsFDTable.FieldByName('AccountName').AsString;
      if DM.ProposalsFDTable.Locate('LeadId', VarArrayOf([LLeadId]), []) then
        raise Exception.Create('This lead already has a proposal.');
      DraftProposalForm.PrepareDraft(LLeadId, LCompany,
        AArgs.AsString('address1'), AArgs.AsString('address2'), AArgs.AsString('phone'), LItems);
      AResult := Format('Draft ready for %s with %d line item(s): check it and press Preview.',
        [LCompany, Length(LItems)]);
    end, True);
end;

procedure TMainForm.HelpChatActionExecuted(Sender: TObject; const AName: string;
  const AOutcome: THelpChatActionOutcome; const AResult: string);
begin
  // Niente barra di stato in questa applicazione: l'esito interessa al modello,
  // che lo riceve comunque, e all'utente, che vede la finestra aprirsi.
  if AOutcome = aoFailed then
    Beep;
end;

procedure TMainForm.HelpChatDecryptSecret(Sender: TObject; const AName, AValue: string;
  var AResult: string; var AHandled: Boolean);
begin
  // Gira sul thread del worker che sta per chiamare il servizio: solo
  // calcolo, nessuna finestra e nessuna attesa. AName direbbe di quale
  // segreto si tratta (Claude.ApiKey, Remote.AppKey...): qui rispondiamo per
  // tutti quelli che portano il prefisso, chiunque li abbia chiesti.
  AHandled := AppSecretIsProtected(AValue);
  if AHandled then
    AResult := AppSecretReveal(AValue);
end;

procedure TMainForm.AskForApiKeyIfMissing;
var
  LKey, LProtected: string;
begin
  // ResolveApiKey guarda la property, i tre helpchatai.json gia' caricati e
  // la variabile d'ambiente, e passa dal gestore qui sopra: se risponde
  // qualcosa, la chiave c'e' ed e' leggibile.
  if HelpChat.Settings.Claude.ResolveApiKey <> '' then
    Exit;
  if not TLicenseActivationForm.Execute(THelpChatSettings.UserConfigFile, LKey) then
    Exit;
  LProtected := AppSecretProtect(LKey);
  AppSecretStoreApiKey('Claude', LProtected);
  // Quella che resta in memoria e' la cifrata, come se fosse appena stata
  // letta dal file: la chiave in chiaro vive quanto la richiesta.
  HelpChat.Settings.Claude.ApiKeyEncrypted := LProtected;
end;

procedure TMainForm.HelpChatGetContext(Sender: TObject; var AContext: THelpChatContext);
begin
  // Il componente ricava la schermata salendo dal controllo che ha il fuoco:
  // dentro una pagina arriva alla TTabSheet e prende la sua parola chiave, ma
  // il menu laterale sta fuori dal PageControl, e da li' F1 descriverebbe la
  // finestra invece della pagina che l'utente sta guardando. Per questa
  // applicazione la pagina attiva e' sempre la risposta giusta.
  if PageControl.ActivePage <> nil then
  begin
    AContext.ScreenName := PageControl.ActivePage.Name;
    AContext.ScreenLabel := PageControl.ActivePage.Caption;
    if PageControl.ActivePage.HelpKeyword <> '' then
      AContext.HelpKeyword := PageControl.ActivePage.HelpKeyword;
  end;
end;

procedure TMainForm.RefreshGrids;
begin
  LeadsBindClosedSourceDB.DataSet.Refresh;
  LeadsBindActiveSourceDB.DataSet.Refresh;
  LeadsBindNewSourceDB.DataSet.Refresh;
  LeadsBindProposalSentSourceDB.DataSet.Refresh;
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
  // La larghezza della griglia e della colonna sono gia' in pixel dello
  // schermo (ScaleBoundGridColumns ha scalato le colonne all'avvio):
  // moltiplicare la differenza per ScaleFactor dava una colonna piu' larga
  // della griglia, con la barra di scorrimento orizzontale sempre accesa.
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

    RefreshGrids;

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

    // L'assistente: l'indice del manuale sta in Help\help-index.json, il
    // percorso nel DFM e' relativo all'eseguibile. Da qui in poi F1 apre la
    // chat sulla pagina della schermata attiva (HelpKeyword delle schede e
    // delle finestre) e la bolla in basso a destra la apre senza contesto.
    RegisterHelpActions;
    HelpChat.Active := True;
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
begin
  Application.OnIdle := AppIdle;

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
