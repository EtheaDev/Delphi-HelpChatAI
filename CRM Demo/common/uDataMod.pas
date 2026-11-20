unit uDataMod;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.StorageBin, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, FireDAC.Stan.StorageJSON, FireDAC.Stan.StorageXML,
  FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteDef, FireDAC.UI.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.SQLite, FireDAC.DApt, System.Variants,
  FireDAC.Phys.SQLiteVDataSet, FireDAC.Comp.BatchMove.Text, System.IOUtils,
  FireDAC.Comp.BatchMove, FireDAC.Comp.BatchMove.DataSet, System.StrUtils,
  // FireDAC.Phys.SQLiteWrapper.FDEStat exists from Delphi 12 (CompilerVersion 36);
  // before that the encryption is inside the plain static wrapper.
  {$IF CompilerVersion >= 36}
  FireDAC.Phys.SQLiteWrapper.FDEStat
  {$ELSE}
  FireDAC.Phys.SQLiteWrapper.Stat
  {$IFEND}
  {$IFDEF VCLSTYLEDCOMPONENTS}, Vcl.StyledComponentsHooks{$ENDIF};

type
  TDM = class(TDataModule)
    LeadsFDMemTable: TFDMemTable;
    FDStanStorageBinLink1: TFDStanStorageBinLink;
    FDStanStorageXMLLink1: TFDStanStorageXMLLink;
    FDStanStorageJSONLink1: TFDStanStorageJSONLink;
    StatusFDMemTable: TFDMemTable;
    AcctFDMemTable: TFDMemTable;
    UsersFDMemTable: TFDMemTable;
    DocsFDMemTable: TFDMemTable;
    ProposalFDMemTable: TFDMemTable;
    ProposalStatusFDMemTable: TFDMemTable;
    FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink;
    FDConnection1: TFDConnection;
    FDLocalSQL1: TFDLocalSQL;
    FDEmailsQuery: TFDQuery;
    FDBatchMove1: TFDBatchMove;
    FDBatchMoveDataSetReader1: TFDBatchMoveDataSetReader;
    FDBatchMoveTextWriter1: TFDBatchMoveTextWriter;
    FDAccountsQuery: TFDQuery;
    FDLeadsQueryNew: TFDQuery;
    FDProposalsQuery: TFDQuery;
    FDLeadsQueryActive: TFDQuery;
    FDLeadsQueryProposalSent: TFDQuery;
    FDLeadsQueryClosed: TFDQuery;
    LineItemsFDMemTable: TFDMemTable;
    DraftProposalFDMemTable: TFDMemTable;
    LineItemsTotalQuery: TFDQuery;
    FDQueryNewTotal: TFDQuery;
    FDQueryActiveTotal: TFDQuery;
    FDQueryProposalTotal: TFDQuery;
    FDQueryClosedTotal: TFDQuery;
    FDQueryTotal: TFDQuery;
    FDQueryInactiveTotal: TFDQuery;
    LeadsFDTable: TFDTable;
    FDSQLiteSecurity1: TFDSQLiteSecurity;
    DocsFDTable: TFDTable;
    UsersFDTable: TFDTable;
    AcctFDTable: TFDTable;
    ProposalsFDTable: TFDTable;
    FDDocsQuery: TFDQuery;
    FDLeadsQueryAll: TFDQuery;
    procedure FDLeadsQueryNewAfterScroll(DataSet: TDataSet);
    procedure LeadsFDTableAfterScroll(DataSet: TDataSet);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure InitializeTable(ATable: TFDTable; AMemTable: TFDMemTable);
    procedure InitializeDatabase;
    procedure CompleteProposal(ALeadId: Integer);
    procedure SetUserQuery(const AUsername: string; AQuery: TFDQuery);
    procedure UpdateProposalStatus(ALeadId: Integer; const AStatus: string);
    procedure ExportEmails(const AFilename: String);
    procedure SearchQuery(const ASQL: String; AQuery: TFDQuery);
    procedure SearchAccounts(const ASearch: String);
    procedure SearchLeadsSubQuery(const ASearch: string; AQuery: TFDQuery);
    procedure SearchLeads(const ASearch: String);
    procedure SearchProposals(const ASearch: string);
    procedure SearchEmails(const ASearch: string);
    procedure SetUser(const AUsername: String);

    // What the actions of the assistant do to the data (uCRMActions): no
    // window and no control here, so both demos share them. An error is an
    // exception whose message is written for the model, which reads it.

    /// <summary>Reads the four lists of leads (new, active, proposal sent,
    /// closed) again.</summary>
    procedure RefreshLeadQueries;
    /// <summary>The company name as the Accounts list spells it. An exact
    /// match (case apart) wins; else a name containing the text, if there is
    /// exactly one; else an exception: no match means "create it with
    /// create_account", more than one means "ask the user which one". The
    /// table is walked under DisableControls and goes back where it was, so
    /// the grids of the application do not move. An empty text stays
    /// empty.</summary>
    function ResolveAccountName(const AText: string): string;
    /// <summary>Moves LeadsFDTable to the lead by name, or by company when
    /// the name is not enough.</summary>
    function LocateLeadByName(const AName: string): Boolean;
    /// <summary>Adds a company to the Accounts list and returns its name.
    /// Idempotent: after a timeout the model may ask again, so a company
    /// that is already there raises instead of being added twice.</summary>
    function CreateAccount(const AName: string): string;
    /// <summary>Adds a lead with status New for AUser, the company resolved
    /// by <see cref="ResolveAccountName" />, and returns its id.</summary>
    function CreateLead(const AName, AAccount, APhone, AEmail, ANotes,
      AUser: string): Integer;
    /// <summary>The lead a new proposal is for: its id and company. Raises
    /// when there is no such lead or it already has a proposal.</summary>
    procedure LeadForProposal(const ALead: string; out ALeadId: Integer;
      out ACompany: string);
 end;
  const
    DB_FILENAME = 'w10crmdemo.sdb';
    DB_PASSWORD = 'SecretPassword';
    DB_ENCRYPTION = 'aes-256';
    DB_LEADSTABLE = 'Leads';
    DB_ACCTSTABLE = 'Accounts';
    DB_USERSTABLE = 'Users';
    DB_DOCSTABLE = 'Docs';
    DB_PROPOSALSTABLE = 'Proposals';

var
  DM: TDM;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}
{$R *.dfm}

procedure TDM.InitializeTable(ATable: TFDTable; AMemTable: TFDMemTable);
begin
  ATable.FieldDefs.Clear;
  ATable.FieldDefs.Assign(AMemTable.FieldDefs);
  ATable.CreateTable(False);
  ATable.CopyDataSet(AMemTable, [coStructure, coRestart, coAppend]);
end;

procedure TDM.InitializeDatabase;
begin
  FDConnection1.Params.Values['Database'] := TPath.Combine(TPath.GetDocumentsPath, DB_FILENAME);

  LeadsFDTable.TableName := DB_LEADSTABLE;
  AcctFDTable.TableName := DB_ACCTSTABLE;
  UsersFDTable.TableName := DB_USERSTABLE;
  DocsFDTable.TableName := DB_DOCSTABLE;
  ProposalsFDTable.TableName := DB_PROPOSALSTABLE;
  if TFile.Exists(FDConnection1.Params.Values['Database'])=True then
    begin
      FDSQLiteSecurity1.Database := FDConnection1.Params.Values['Database'];
    end
  else
    begin
      FDConnection1.Open;
      try
        InitializeTable(DocsFDTable,DocsFDMemTable);
        InitializeTable(LeadsFDTable,LeadsFDMemTable);
        InitializeTable(AcctFDTable,AcctFDMemTable);
        InitializeTable(UsersFDTable,UsersFDMemTable);
        InitializeTable(ProposalsFDTable,ProposalFDMemTable);
      finally
        FDConnection1.Close;
      end;
      FDSQLiteSecurity1.Database := FDConnection1.Params.Values['Database'];
      FDSQLiteSecurity1.Password := DB_ENCRYPTION + ':' + DB_PASSWORD;
      FDSQLiteSecurity1.SetPassword;
    end;

  FDConnection1.Params.Values['Encrypt'] := DB_ENCRYPTION;
  FDConnection1.Params.Password := DB_PASSWORD;
  FDConnection1.Open;

  DocsFDTable.Open;
  LeadsFDTable.Open;
  AcctFDTable.Open;
  UsersFDTable.Open;
  ProposalsFDTable.Open;

  SetUser(UsersFDMemTable.FieldByName('Username').AsString);

  FDAccountsQuery.Open;

  LeadsFDMemTable.Free;
  AcctFDMemTable.Free;
  UsersFDMemTable.Free;
  DocsFDMemTable.Free;
  ProposalFDMemTable.Free;
end;

procedure TDM.CompleteProposal(ALeadId: Integer);
begin
    DM.UpdateProposalStatus(ALeadId,'Accepted');
end;

procedure TDM.UpdateProposalStatus(ALeadId: Integer; const AStatus: string);
begin
  if ProposalsFDTable.Locate('LeadId',VarArrayOf([ALeadId]),[]) then
  begin
    ProposalsFDTable.Edit;
    ProposalsFDTable.FieldByName('Status').AsString := AStatus;
    if AStatus = 'Accepted' then ProposalsFDTable.FieldByName('DateCompleted').AsDateTime := Now;
    ProposalsFDTable.Post;
    FDProposalsQuery.Close;
    FDProposalsQuery.Open;
    FDProposalsQuery.Locate('ProposalId',VarArrayOf([ProposalsFDTable.FieldByName('ProposalId').AsInteger]),[]);
  end;
end;

procedure TDM.SetUserQuery(const AUsername: string; AQuery: TFDQuery);
begin
  AQuery.Close;
  AQuery.ParamByName('Username').AsString := AUsername;
  AQuery.Open;
end;


procedure TDM.SetUser(const AUsername: String);
begin
  SetUserQuery(AUsername, FDEmailsQuery);
  SetUserQuery(AUsername, FDLeadsQueryAll);
  SetUserQuery(AUsername, FDLeadsQueryNew);
  SetUserQuery(AUsername, FDProposalsQuery);
  SetUserQuery(AUsername, FDDocsQuery);
  SetUserQuery(AUsername, FDLeadsQueryActive);
  SetUserQuery(AUsername, FDLeadsQueryProposalSent);
  SetUserQuery(AUsername, FDLeadsQueryClosed);
  SetUserQuery(AUsername, FDQueryNewTotal);
  SetUserQuery(AUsername, FDQueryActiveTotal);
  SetUserQuery(AUsername, FDQueryProposalTotal);
  SetUserQuery(AUsername, FDQueryClosedTotal);
  SetUserQuery(AUsername, FDQueryTotal);
  SetUserQuery(AUsername, FDQueryInactiveTotal);
end;

procedure TDM.LeadsFDTableAfterScroll(DataSet: TDataSet);
begin
  FDDocsQuery.Close;
  FDDocsQuery.ParamByName('LeadId').AsInteger := LeadsFDTable.FieldByName('LeadId').AsInteger;
  FDDocsQuery.Open;
end;


procedure TDM.ExportEmails(const AFilename: string);
begin
  FDBatchMoveTextWriter1.FileName := AFilename;
  FDBatchMove1.Execute;
end;

procedure TDM.SearchQuery(const ASQL: string; AQuery: TFDQuery);
begin
  AQuery.Close;
  AQuery.MacroByName('Where').AsRaw := ASQL;
  AQuery.Open;
end;

procedure TDM.FDLeadsQueryNewAfterScroll(DataSet: TDataSet);
begin
  LeadsFDTable.Locate('LeadId',VarArrayOf([DataSet.FieldByName('LeadId').AsInteger]),[]);
end;

procedure TDM.SearchAccounts(const ASearch: string);
begin
  SearchQuery(IfThen(ASearch <> '', 'UPPER(AccountName) LIKE ''%' +
    UpperCase(ASearch) + '%''', ''), FDAccountsQuery);
end;

procedure TDM.SearchLeadsSubQuery(const ASearch: string; AQuery: TFDQuery);
begin
  SearchQuery(IfThen(ASearch <> '', 'AND UPPER(Name) LIKE ''%' + UpperCase(ASearch)
    + '%'' OR UPPER(AccountName) LIKE ''%' + UpperCase(ASearch) +
    '%'' OR UPPER(OfficePhone) LIKE ''%' + UpperCase(ASearch) +
    '%'' OR UPPER(Email) LIKE ''%' + UpperCase(ASearch) + '%''', ''),
     AQuery);
end;

procedure TDM.SearchLeads(const ASearch: string);
begin
  SearchLeadsSubQuery(ASearch,FDLeadsQueryNew);
  SearchLeadsSubQuery(ASearch,FDLeadsQueryActive);
  SearchLeadsSubQuery(ASearch,FDLeadsQueryProposalSent);
  SearchLeadsSubQuery(ASearch,FDLeadsQueryClosed);
end;

procedure TDM.SearchProposals(const ASearch: string);
begin
  SearchQuery(IfThen(ASearch <> '', 'AND UPPER(ProposalName) LIKE ''%' +
    UpperCase(ASearch) + '%''', ''), FDProposalsQuery);
end;

procedure TDM.SearchEmails(const ASearch: string);
begin
  SearchQuery(IfThen(ASearch <> '', 'AND UPPER(Email) LIKE ''%' +
    UpperCase(ASearch) + '%''', ''), FDEmailsQuery);
end;

procedure TDM.RefreshLeadQueries;
begin
  FDLeadsQueryNew.Refresh;
  FDLeadsQueryActive.Refresh;
  FDLeadsQueryProposalSent.Refresh;
  FDLeadsQueryClosed.Refresh;
end;

function TDM.ResolveAccountName(const AText: string): string;
var
  LBookmark: TBookmark;
  LCandidates: TStringList;
  LName, LError: string;
begin
  Result := Trim(AText);
  if Result = '' then
    Exit;
  LCandidates := TStringList.Create;
  try
    AcctFDTable.DisableControls;
    try
      LBookmark := AcctFDTable.GetBookmark;
      try
        AcctFDTable.First;
        while not AcctFDTable.Eof do
        begin
          LName := AcctFDTable.FieldByName('AccountName').AsString;
          if SameText(LName, Result) then
            Exit(LName);
          if LName.ToLower.Contains(Result.ToLower) then
            LCandidates.Add(LName);
          AcctFDTable.Next;
        end;
      finally
        if AcctFDTable.BookmarkValid(LBookmark) then
          AcctFDTable.GotoBookmark(LBookmark);
        AcctFDTable.FreeBookmark(LBookmark);
      end;
    finally
      AcctFDTable.EnableControls;
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

function TDM.LocateLeadByName(const AName: string): Boolean;
begin
  Result := LeadsFDTable.Locate('Name', VarArrayOf([AName]), [loCaseInsensitive]);
  if not Result then
    Result := LeadsFDTable.Locate('AccountName', VarArrayOf([AName]),
      [loCaseInsensitive, loPartialKey]);
end;

function TDM.CreateAccount(const AName: string): string;
begin
  Result := Trim(AName);
  if Result = '' then
    raise Exception.Create('The company name is required.');
  if AcctFDTable.Locate('AccountName', VarArrayOf([Result]), [loCaseInsensitive]) then
    raise Exception.CreateFmt('The account "%s" already exists.',
      [AcctFDTable.FieldByName('AccountName').AsString]);
  FDAccountsQuery.DisableControls;
  try
    FDAccountsQuery.AppendRecord([nil, Result]);
  finally
    FDAccountsQuery.EnableControls;
  end;
  // The query is what the Accounts grid shows, the table what the combo of
  // the lead window reads: the table has to see the new row too.
  AcctFDTable.Refresh;
end;

function TDM.CreateLead(const AName, AAccount, APhone, AEmail, ANotes,
  AUser: string): Integer;
var
  LAccount: string;
begin
  // The company as the Accounts list spells it, or the exception that says
  // "create it first" or "ask the user which one".
  LAccount := ResolveAccountName(AAccount);
  FDLeadsQueryNew.Append;
  FDLeadsQueryNew.FieldByName('Status').AsString := 'New';
  FDLeadsQueryNew.FieldByName('Name').AsString := AName;
  FDLeadsQueryNew.FieldByName('AccountName').AsString := LAccount;
  FDLeadsQueryNew.FieldByName('OfficePhone').AsString := APhone;
  FDLeadsQueryNew.FieldByName('Email').AsString := AEmail;
  FDLeadsQueryNew.FieldByName('Notes').AsString := ANotes;
  FDLeadsQueryNew.FieldByName('User').AsString := AUser;
  FDLeadsQueryNew.FieldByName('DateCreated').AsDateTime := Now;
  FDLeadsQueryNew.Post;
  Result := FDLeadsQueryNew.FieldByName('LeadId').AsInteger;
  RefreshLeadQueries;
end;

procedure TDM.LeadForProposal(const ALead: string; out ALeadId: Integer;
  out ACompany: string);
begin
  if not LocateLeadByName(ALead) then
    raise Exception.CreateFmt('There is no lead called "%s".', [ALead]);
  ALeadId := LeadsFDTable.FieldByName('LeadId').AsInteger;
  ACompany := LeadsFDTable.FieldByName('AccountName').AsString;
  if ProposalsFDTable.Locate('LeadId', VarArrayOf([ALeadId]), []) then
    raise Exception.Create('This lead already has a proposal.');
end;

end.
