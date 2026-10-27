{******************************************************************************}
{                                                                              }
{   HelpChatAI CRM demo - FireMonkey - the proposal draft                      }
{                                                                              }
{   The window the draft_proposal action opens: the assistant fills it in,     }
{   the user checks it and presses Preview and Save. The document itself is    }
{   built by uProposalReport, which both demos share.                          }
{                                                                              }
{   Two cards in the VCL (TCardPanel), two tabs of a TTabControl with          }
{   TabPosition = None here: FireMonkey has no card panel, and a tab control   }
{   without tabs is exactly the same thing.                                    }
{                                                                              }
{******************************************************************************}

unit uDraftProposalFmx;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Rtti, System.Bindings.Outputs, Data.DB,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit, FMX.TabControl,
  FMX.ScrollBox, FMX.Grid.Style, FMX.Grid, FMX.WebBrowser,
  Data.Bind.EngExt, Data.Bind.Components, Data.Bind.Grid, Data.Bind.DBScope,
  Fmx.Bind.DBEngExt, Fmx.Bind.Editors, Fmx.Bind.Grid, Fmx.Bind.Navigator,
  uProposalReport;

const
  /// <summary>What this window is about, for the assistant. The VCL form
  /// says it in HelpType/HelpKeyword; a FireMonkey form has neither, so
  /// the main form reads this when F1 arrives from here.</summary>
  DRAFT_HELP_KEYWORD = 'Draft a proposal';

type
  TDraftProposalFormFmx = class(TForm)
    Cards: TTabControl;
    DraftCard: TTabItem;
    PreviewCard: TTabItem;
    DraftHeader: TLayout;
    DraftTitle: TLabel;
    FieldsLayout: TLayout;
    CompanyRow: TLayout;
    CompanyEdit: TEdit;
    InvoiceLabel: TLabel;
    Address1Row: TLayout;
    Address1Edit: TEdit;
    DateEdit: TEdit;
    Address2Row: TLayout;
    Address2Edit: TEdit;
    PhoneRow: TLayout;
    PhoneEdit: TEdit;
    TotalLayout: TLayout;
    TotalLabel: TLabel;
    TotalEdit: TEdit;
    NavLayout: TLayout;
    CancelButton: TButton;
    PreviewButton: TButton;
    GridLayout: TLayout;
    LineItemsGrid: TStringGrid;
    LineItemsNav: TBindNavigator;
    PreviewHeader: TLayout;
    PreviewTitle: TLabel;
    PreviewNav: TLayout;
    BackButton: TButton;
    SaveProposalButton: TButton;
    Browser: TWebBrowser;
    BindSourceDBDraftProposal: TBindSourceDB;
    BindSourceDBLineItems: TBindSourceDB;
    BindSourceDBProposal: TBindSourceDB;
    BindSourceDBProposalQuery: TBindSourceDB;
    BindingsList: TBindingsList;
    LinkGridLineItems: TLinkGridToDataSource;
    LinkCompany: TLinkControlToField;
    LinkAddress1: TLinkControlToField;
    LinkAddress2: TLinkControlToField;
    LinkDate: TLinkControlToField;
    LinkPhone: TLinkControlToField;
    LinkTotal: TLinkControlToField;
    procedure PreviewButtonClick(Sender: TObject);
    procedure BackButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure SaveProposalButtonClick(Sender: TObject);
    procedure LineItemsDataChange(Sender: TObject; Field: TField);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar;
      Shift: TShiftState);
  private
    FLeadId: Integer;
    /// <summary>What Preview built and Save stores: the VCL demo keeps it in
    /// a hidden TMemo on the form, which is a field with a window around it.</summary>
    FReportHtml: string;
    procedure UpdateTotal;
  public
    /// <summary>An empty draft for a lead, the way the Create Proposal button
    /// of the lead window opens it.</summary>
    procedure NewDraft(ALeadId: Integer; const ACompanyName: string);
    /// <summary>A draft already filled in, shown for the user to check. This
    /// is what the assistant calls: it must not block, so Show and not
    /// ShowModal - the worker waiting for the action would time out.</summary>
    procedure PrepareDraft(ALeadId: Integer; const ACompanyName, AAddress1,
      AAddress2, APhone: string; const AItems: TArray<TProposalLineItem>);
  end;

var
  DraftProposalFormFmx: TDraftProposalFormFmx;

implementation

{$R *.fmx}

uses
  uDataMod, uMainFormFmx;

procedure TDraftProposalFormFmx.FormCreate(Sender: TObject);
begin
  Cards.TabPosition := TTabPosition.None;
  Cards.ActiveTab := DraftCard;
end;

procedure TDraftProposalFormFmx.NewDraft(ALeadId: Integer; const ACompanyName: string);
begin
  DM.LineItemsFDMemTable.EmptyDataSet;
  DM.DraftProposalFDMemTable.EmptyDataSet;
  FLeadId := ALeadId;
  FReportHtml := '';
  Cards.ActiveTab := DraftCard;
  DateEdit.Text := FormatDateTime('ddddd', Now);
  TLinkObservers.ControlChanged(DateEdit);
  CompanyEdit.Text := ACompanyName;
  TLinkObservers.ControlChanged(CompanyEdit);
end;

procedure TDraftProposalFormFmx.PrepareDraft(ALeadId: Integer; const ACompanyName,
  AAddress1, AAddress2, APhone: string; const AItems: TArray<TProposalLineItem>);
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
  // Not modal: the handler of an action runs on the main thread and has to
  // return at once, or the worker that asked for it times out.
  Show;
  UpdateTotal;
end;

procedure TDraftProposalFormFmx.UpdateTotal;
begin
  DM.LineItemsTotalQuery.Open;
  try
    if DM.LineItemsTotalQuery.FindField('Total') <> nil then
    begin
      // The total arrives as a number from the query: CurrToStr writes it
      // with the settings of the user, the same ones the binding reads it
      // back with into the currency field.
      TotalEdit.Text := CurrToStr(DM.LineItemsTotalQuery.FieldByName('Total').AsCurrency);
      TLinkObservers.ControlChanged(TotalEdit);
    end;
  finally
    DM.LineItemsTotalQuery.Close;
  end;
end;

procedure TDraftProposalFormFmx.LineItemsDataChange(Sender: TObject; Field: TField);
begin
  if Visible then
    UpdateTotal;
end;

procedure TDraftProposalFormFmx.PreviewButtonClick(Sender: TObject);
begin
  FReportHtml := GenerateProposalReport(BindSourceDBDraftProposal.DataSet,
    BindSourceDBLineItems.DataSet);
  Cards.ActiveTab := PreviewCard;
  Browser.LoadFromStrings(FReportHtml, '');
end;

procedure TDraftProposalFormFmx.BackButtonClick(Sender: TObject);
begin
  Cards.ActiveTab := DraftCard;
end;

procedure TDraftProposalFormFmx.CancelButtonClick(Sender: TObject);
begin
  Close;
end;

procedure TDraftProposalFormFmx.SaveProposalButtonClick(Sender: TObject);
var
  LReportStream: TStringStream;
begin
  BindSourceDBProposal.DataSet.Append;
  BindSourceDBProposal.DataSet.Edit;
  BindSourceDBProposal.DataSet.FieldByName('LeadId').AsInteger := FLeadId;
  BindSourceDBProposal.DataSet.FieldByName('ProposalName').AsString := 'New Proposal';
  BindSourceDBProposal.DataSet.FieldByName('Status').AsString := 'New';
  BindSourceDBProposal.DataSet.FieldByName('Value').AsCurrency :=
    BindSourceDBDraftProposal.DataSet.FieldByName('Total').AsCurrency;
  LReportStream := TStringStream.Create;
  try
    LReportStream.WriteString(FReportHtml);
    LReportStream.Position := 0;
    TBlobField(BindSourceDBProposal.DataSet.FieldByName('Proposal')).LoadFromStream(LReportStream);
  finally
    LReportStream.Free;
  end;
  BindSourceDBProposal.DataSet.FieldByName('DateCreated').AsDateTime := Now;
  BindSourceDBProposal.DataSet.FieldByName('User').AsString := MainFormFmx.UserCombo.Text;
  BindSourceDBProposal.DataSet.Post;
  BindSourceDBProposalQuery.DataSet.Refresh;
  BindSourceDBProposalQuery.DataSet.Locate('LeadId', VarArrayOf([FLeadId]), []);
  Cards.ActiveTab := DraftCard;
  Close;
end;

procedure TDraftProposalFormFmx.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  // The component lives on the main form and chains that form's handler by
  // itself; every other form asks it, which is what HandleKeyDown is for.
  if Assigned(MainFormFmx) and Assigned(MainFormFmx.HelpChat) then
    MainFormFmx.HelpChat.HandleKeyDown(Key, Shift);
end;

end.
