unit uDraftProposal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.Bind.Controls, Vcl.Buttons,
  Vcl.Bind.Navigator, Vcl.Grids, Vcl.WinXCtrls, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.WinXPanels, Data.Bind.Components, Data.Bind.DBScope, Data.Bind.EngExt,
  Vcl.Bind.DBEngExt, Vcl.Bind.Grid, System.Rtti, System.Bindings.Outputs,
  Vcl.Bind.Editors, Data.Bind.Grid, Vcl.OleCtrls, SHDocVw, System.NetEncoding,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.StorageBin, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  Vcl.VirtualImage,
  // Il documento della proposta e le sue righe: codice senza niente di VCL,
  // quindi sta in common e lo genera anche la demo FireMonkey.
  uProposalReport
  {$IFDEF VCLSTYLEDCOMPONENTS}, Vcl.StyledComponentsHooks{$ENDIF};

type
  TDraftProposalForm = class(TForm)
    StackPanel1: TStackPanel;
    RelativePanel1: TRelativePanel;
    LineItemsStringGrid: TStringGrid;
    BindNavigator1: TBindNavigator;
    BindSourceDBProposal: TBindSourceDB;
    BindSourceDBLineItems: TBindSourceDB;
    BindingsList1: TBindingsList;
    LinkGridToDataSourceBindSourceDB2: TLinkGridToDataSource;
    Panel1: TPanel;
    PreviewButton: TButton;
    CancelButton: TButton;
    TotalEdit: TEdit;
    Total: TLabel;
    Panel2: TPanel;
    PhoneEdit: TEdit;
    Panel3: TPanel;
    Address2Edit: TEdit;
    Panel4: TPanel;
    Address1Edit: TEdit;
    Panel5: TPanel;
    CompanyEdit: TEdit;
    DraftHeaderPanel: TPanel;
    Label11: TLabel;
    Label1: TLabel;
    DateEdit: TEdit;
    RelativePanel2: TRelativePanel;
    Panel6: TPanel;
    DraftCardPanel: TCardPanel;
    DraftCard: TCard;
    PreviewCard: TCard;
    WebBrowser1: TWebBrowser;
    PreviewHeaderPanel: TPanel;
    Label2: TLabel;
    NavPanel: TPanel;
    SaveProposalButton: TButton;
    BackButton: TButton;
    BindSourceDBDraftProposal: TBindSourceDB;
    LinkControlToField1: TLinkControlToField;
    LinkControlToField2: TLinkControlToField;
    LinkControlToField3: TLinkControlToField;
    LinkControlToField4: TLinkControlToField;
    LinkControlToField5: TLinkControlToField;
    LinkControlToField6: TLinkControlToField;
    ReportMemo: TMemo;
    VirtualImage1: TVirtualImage;
    VirtualImage2: TVirtualImage;
    BindSourceDBProposalQuery: TBindSourceDB;
    procedure PreviewButtonClick(Sender: TObject);
    procedure BackButtonClick(Sender: TObject);
    procedure PreviewCardClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure BindSourceDBLineItemsSubDataSourceDataChange(Sender: TObject;
      Field: TField);
    procedure SaveProposalButtonClick(Sender: TObject);
  private
    { Private declarations }
    /// <summary>Ricalcola il totale dalle righe presenti.</summary>
    procedure UpdateTotal;
  public
    { Public declarations }
    FLeadId: Integer;
    procedure NewDraft(ALeadId: Integer; const ACompanyName: String);
    /// <summary>Prepara una bozza gia' compilata e la mostra. La usa
    /// l'assistente: l'utente controlla, poi preme Preview e Save.</summary>
    procedure PrepareDraft(ALeadId: Integer; const ACompanyName, AAddress1,
      AAddress2, APhone: String; const AItems: TArray<TProposalLineItem>);
  end;

var
  DraftProposalForm: TDraftProposalForm;

implementation

{$R *.dfm}

uses
  uMainForm, uDataMod;

procedure TDraftProposalForm.NewDraft(ALeadId: Integer; const ACompanyName: String);
begin
  DM.LineItemsFDMemTable.EmptyDataSet;
  DM.DraftProposalFDMemTable.EmptyDataSet;
  FLeadId := ALeadId;
  DateEdit.Text := FormatDateTime('ddddd', Now);
  TLinkObservers.ControlChanged(DateEdit);
  CompanyEdit.Text := ACompanyName;
  TLinkObservers.ControlChanged(CompanyEdit);
end;

procedure TDraftProposalForm.UpdateTotal;
begin
  DM.LineItemsTotalQuery.Open;
  try
    if DM.LineItemsTotalQuery.FindField('Total') <> nil then
    begin
      // Il totale arriva come numero dalla query: CurrToStr lo scrive con le
      // impostazioni dell'utente, che sono le stesse con cui il binding lo
      // rilegge nel campo valuta.
      TotalEdit.Text := CurrToStr(DM.LineItemsTotalQuery.FieldByName('Total').AsCurrency);
      TLinkObservers.ControlChanged(TotalEdit);
    end;
  finally
    DM.LineItemsTotalQuery.Close;
  end;
end;

procedure TDraftProposalForm.PrepareDraft(ALeadId: Integer; const ACompanyName,
  AAddress1, AAddress2, APhone: String; const AItems: TArray<TProposalLineItem>);
var
  LItem: TProposalLineItem;
begin
  NewDraft(ALeadId, ACompanyName);
  Address1Edit.Text := AAddress1;
  TLinkObservers.ControlChanged(Address1Edit);
  Address2Edit.Text := AAddress2;
  TLinkObservers.ControlChanged(Address2Edit);
  PhoneEdit.Text := APhone;
  TLinkObservers.ControlChanged(PhoneEdit);
  for LItem in AItems do
  begin
    DM.LineItemsFDMemTable.Append;
    DM.LineItemsFDMemTable.FieldByName('Title').AsString := LItem.Title;
    DM.LineItemsFDMemTable.FieldByName('Quantity').AsInteger := LItem.Quantity;
    DM.LineItemsFDMemTable.FieldByName('Price').AsCurrency := LItem.Price;
    DM.LineItemsFDMemTable.Post;
  end;
  // Non modale: il gestore di un'azione gira sul thread principale e deve
  // tornare subito, altrimenti il worker che lo ha chiesto va in timeout.
  Show;
  UpdateTotal;
end;

procedure TDraftProposalForm.BindSourceDBLineItemsSubDataSourceDataChange(
  Sender: TObject; Field: TField);
begin
  if DraftProposalForm.Visible then
  begin
    UpdateTotal;
  end;
end;

procedure TDraftProposalForm.PreviewButtonClick(Sender: TObject);
var
  LDoc: Variant;
begin
  DraftCardPanel.NextCard;

  ReportMemo.Lines.Text := GenerateProposalReport(BindSourceDBDraftProposal.DataSet,
    BindSourceDBLineItems.DataSet);

  if not Assigned(WebBrowser1.Document) then
    WebBrowser1.Navigate('about:blank');

  LDoc := WebBrowser1.Document;
  LDoc.Clear;
  LDoc.Write(ReportMemo.Lines.Text);
  LDoc.Close;
end;


procedure TDraftProposalForm.CancelButtonClick(Sender: TObject);
begin
  Close;
end;

procedure TDraftProposalForm.BackButtonClick(Sender: TObject);
begin
  DraftCardPanel.PreviousCard;
end;

procedure TDraftProposalForm.PreviewCardClick(Sender: TObject);
begin
  DraftCardPanel.PreviousCard;
end;

procedure TDraftProposalForm.SaveProposalButtonClick(Sender: TObject);
var
LReportStream: TStringStream;
begin
  BindSourceDBProposal.DataSet.Append;
  BindSourceDBProposal.DataSet.Edit;
  BindSourceDBProposal.DataSet.FieldByName('LeadId').AsInteger := FLeadId;
  BindSourceDBProposal.DataSet.FieldByName('ProposalName').AsString := 'New Proposal';
  BindSourceDBProposal.DataSet.FieldByName('Status').AsString := 'New';
  BindSourceDBProposal.DataSet.FieldByName('Value').AsCurrency := BindSourceDBDraftProposal.DataSet.FieldByName('Total').AsCurrency;
  LReportStream := TStringStream.Create;
  try
    LReportStream.WriteString(ReportMemo.Lines.Text);
    LReportStream.Position := 0;
    TBlobField(BindSourceDBProposal.DataSet.FieldByName('Proposal')).LoadFromStream(LReportStream);
  finally
    LReportStream.Free;
  end;
  BindSourceDBProposal.DataSet.FieldByName('DateCreated').AsDateTime := Now;
  BindSourceDBProposal.DataSet.FieldByName('User').AsString := MainForm.UsernameComboBox.Text;
  BindSourceDBProposal.DataSet.Post;
  BindSourceDBProposalQuery.DataSet.Refresh;
  BindSourceDBProposalQuery.DataSet.Locate('LeadId',VarArrayOf([FLeadId]),[]);
  DraftCardPanel.PreviousCard;
  Close;
end;

end.
