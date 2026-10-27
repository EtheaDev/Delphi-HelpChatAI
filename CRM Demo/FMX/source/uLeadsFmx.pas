{******************************************************************************}
{                                                                              }
{   HelpChatAI CRM demo - FireMonkey - the lead detail                         }
{                                                                              }
{   The same fields of the VCL window over the same bind sources. Three        }
{   things are not a translation:                                              }
{                                                                              }
{   - the VCL one is a TRelativePanel that moves the documents under the       }
{     fields when the window is narrow, with a resize handler per panel.       }
{     Here the documents are Align = Right and the fields a scroll box:        }
{     FireMonkey has no relative panel, and this needs no handler at all;      }
{   - a TDateTimePicker shows nothing when its date is zero only if the        }
{     format string is blanked by hand, which is why the VCL form has four     }
{     OnAssignedValue handlers. TDateEdit has IsEmpty, so one line does it;    }
{   - MessageDlg is asynchronous in FireMonkey: the answer arrives in a        }
{     callback, so the delete happens there and not after the call.            }
{                                                                              }
{******************************************************************************}

unit uLeadsFmx;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Rtti, System.Bindings.Outputs, Data.DB,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit, FMX.Memo, FMX.Memo.Types,
  FMX.ListBox, FMX.DateTimeCtrls, FMX.ScrollBox, FMX.Grid.Style, FMX.Grid,
  FMX.DialogService,
  Data.Bind.EngExt, Data.Bind.Components, Data.Bind.Grid, Data.Bind.DBScope,
  Fmx.Bind.DBEngExt, Fmx.Bind.Editors, Fmx.Bind.Grid;

const
  /// <summary>What this window is about, for the assistant. The VCL form
  /// says it in HelpType/HelpKeyword; a FireMonkey form has neither, so
  /// the main form reads this when F1 arrives from here.</summary>
  LEADS_HELP_KEYWORD = 'Lead detail';

type
  TLeadsFormFmx = class(TForm)
    HeaderLayout: TLayout;
    HeaderTitle: TLabel;
    ProposalButtons: TLayout;
    CreateProposalButton: TButton;
    ViewProposalButton: TButton;
    CancelProposalButton: TButton;
    CompleteProposalButton: TButton;
    DocsLayout: TLayout;
    DocsTitle: TLabel;
    DocsButtons: TLayout;
    AddDocButton: TButton;
    ViewDocButton: TButton;
    DeleteDocButton: TButton;
    DocsGrid: TStringGrid;
    FieldsScroll: TVertScrollBox;
    LeadIdRow: TLayout;
    LeadIdCaption: TLabel;
    LeadIdLabel: TLabel;
    StatusRow: TLayout;
    StatusCaption: TLabel;
    StatusCombo: TComboBox;
    DatesRow: TLayout;
    DateCreatedBox: TLayout;
    DateCreatedCaption: TLabel;
    DateCreatedEdit: TDateEdit;
    DateContactedBox: TLayout;
    DateContactedCaption: TLabel;
    DateContactedEdit: TDateEdit;
    DateDraftedBox: TLayout;
    DateDraftedCaption: TLabel;
    DateDraftedEdit: TDateEdit;
    DateClosedBox: TLayout;
    DateClosedCaption: TLabel;
    DateClosedEdit: TDateEdit;
    NameRow: TLayout;
    NameCaption: TLabel;
    NameEdit: TEdit;
    AcctRow: TLayout;
    AcctCaption: TLabel;
    AccountNameCombo: TComboBox;
    PhoneRow: TLayout;
    PhoneCaption: TLabel;
    OfficePhoneEdit: TEdit;
    CallButton: TButton;
    EmailRow: TLayout;
    EmailCaption: TLabel;
    EmailEdit: TEdit;
    EmailButton: TButton;
    UserRow: TLayout;
    UserCaption: TLabel;
    UserEdit: TEdit;
    NotesRow: TLayout;
    NotesCaption: TLabel;
    NotesMemo: TMemo;
    OpenDialog: TOpenDialog;
    LeadsBindSourceDB: TBindSourceDB;
    StatusBindSourceDB: TBindSourceDB;
    AcctBindSourceDB: TBindSourceDB;
    DocsBindSourceDB: TBindSourceDB;
    UsersBindSourceDB: TBindSourceDB;
    ProposalBindSourceDB: TBindSourceDB;
    BindingsList: TBindingsList;
    LinkName: TLinkControlToField;
    LinkOfficePhone: TLinkControlToField;
    LinkEmail: TLinkControlToField;
    LinkUser: TLinkControlToField;
    LinkStatus: TLinkFillControlToField;
    LinkAccountName: TLinkFillControlToField;
    LinkDateCreated: TLinkControlToField;
    LinkDateContacted: TLinkControlToField;
    LinkDateDrafted: TLinkControlToField;
    LinkDateClosed: TLinkControlToField;
    LinkNotes: TLinkControlToField;
    LinkLeadId: TLinkPropertyToField;
    LinkGridDocs: TLinkGridToDataSource;
    procedure AddDocButtonClick(Sender: TObject);
    procedure ViewDocButtonClick(Sender: TObject);
    procedure DeleteDocButtonClick(Sender: TObject);
    procedure CreateProposalButtonClick(Sender: TObject);
    procedure ViewProposalButtonClick(Sender: TObject);
    procedure CancelProposalButtonClick(Sender: TObject);
    procedure CompleteProposalButtonClick(Sender: TObject);
    procedure DateAssignedValue(Sender: TObject;
      AssignValueRec: TBindingAssignValueRec; const Value: TValue);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar;
      Shift: TShiftState);
  private
    procedure ShowEmptyDates;
  public
    /// <summary>Moves the detail onto one lead, the way the main form asks
    /// for it when a grid is double clicked or an action creates one.</summary>
    procedure LocateLead(AIndex: Integer);
  end;

var
  LeadsFormFmx: TLeadsFormFmx;

implementation

{$R *.fmx}

uses
  System.IOUtils,
{$IFDEF MSWINDOWS}
  Winapi.Windows, Winapi.ShellAPI,
{$ENDIF}
  uDataMod, uMainFormFmx, uProposalFmx, uDraftProposalFmx;

procedure TLeadsFormFmx.LocateLead(AIndex: Integer);
begin
  LeadsBindSourceDB.DataSet.Locate('LeadId', VarArrayOf([AIndex]), []);
  ShowEmptyDates;
end;

procedure TLeadsFormFmx.ShowEmptyDates;

  procedure Look(ADate: TDateEdit; const AFieldName: string);
  var
    LField: TField;
  begin
    LField := LeadsBindSourceDB.DataSet.FindField(AFieldName);
    ADate.IsEmpty := (LField = nil) or LField.IsNull or (LField.AsDateTime = 0);
  end;

begin
  // A lead that was never contacted has no date, and neither 30/12/1899 nor
  // the date it was created is an answer: the VCL picker needs its format
  // blanked by hand, this one has IsEmpty. The question is asked of the
  // field and not of the control, because a null never reaches the control
  // as a zero - it leaves it as it was.
  if not Assigned(LeadsBindSourceDB.DataSet) then
    Exit;
  Look(DateCreatedEdit, 'DateCreated');
  Look(DateContactedEdit, 'DateContacted');
  Look(DateDraftedEdit, 'DateDrafted');
  Look(DateClosedEdit, 'DateClosed');
end;

procedure TLeadsFormFmx.DateAssignedValue(Sender: TObject;
  AssignValueRec: TBindingAssignValueRec; const Value: TValue);
begin
  // The four links share this one: Sender is not the link that fired it
  // (it is the binding expression), so there is nothing to tell them apart
  // by - and looking at all four costs four field lookups.
  ShowEmptyDates;
end;

procedure TLeadsFormFmx.AddDocButtonClick(Sender: TObject);
begin
  if not OpenDialog.Execute then
    Exit;
  DocsBindSourceDB.DataSet.Append;
  DocsBindSourceDB.DataSet.Edit;
  DocsBindSourceDB.DataSet.FieldByName('LeadId').AsInteger :=
    LeadsBindSourceDB.DataSet.FieldByName('LeadId').AsInteger;
  DocsBindSourceDB.DataSet.FieldByName('DocumentName').AsString :=
    ExtractFileName(OpenDialog.FileName);
  TBlobField(DocsBindSourceDB.DataSet.FieldByName('Document'))
    .LoadFromFile(OpenDialog.FileName);
  DocsBindSourceDB.DataSet.FieldByName('User').AsString :=
    UsersBindSourceDB.DataSet.FieldByName('Username').AsString;
  DocsBindSourceDB.DataSet.Post;
end;

procedure TLeadsFormFmx.ViewDocButtonClick(Sender: TObject);
var
  LDocStream: TMemoryStream;
  LTempDocument: string;
begin
  LTempDocument := '';
  if (DocsBindSourceDB.DataSet.RecordCount > 0) and
     (DocsBindSourceDB.DataSet.FindField('Document') <> nil) then
  begin
    LDocStream := TMemoryStream.Create;
    try
      TBlobField(DocsBindSourceDB.DataSet.FieldByName('Document')).SaveToStream(LDocStream);
      // TPath here is the one of FMX.Types, the vector path: in a FireMonkey
      // form it wins over System.IOUtils, so it is spelled out.
      LTempDocument := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetTempPath,
        DocsBindSourceDB.DataSet.FieldByName('DocumentName').AsString);
      LDocStream.SaveToFile(LTempDocument);
    finally
      LDocStream.Free;
    end;
  end;

  if LTempDocument = '' then
  begin
    ShowMessage('No document selected.');
    Exit;
  end;
{$IFDEF MSWINDOWS}
  ShellExecute(0, nil, PChar(LTempDocument), nil, nil, SW_SHOWNORMAL);
{$ELSE}
  ShowMessage('Opening a document is only implemented on Windows.');
{$ENDIF}
end;

procedure TLeadsFormFmx.DeleteDocButtonClick(Sender: TObject);
begin
  if DocsBindSourceDB.DataSet.RecordCount = 0 then
    Exit;
  // In FireMonkey the answer comes back in a callback, so the delete lives
  // there: a MessageDlg that returns the button is Windows only.
  TDialogService.MessageDialog('Delete ' +
    DocsBindSourceDB.DataSet.FieldByName('DocumentName').AsString + '?',
    TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbYes, 0,
    procedure(const AResult: TModalResult)
    begin
      if AResult = mrYes then
        DocsBindSourceDB.DataSet.Delete;
    end);
end;

procedure TLeadsFormFmx.CreateProposalButtonClick(Sender: TObject);
var
  LLeadId: Integer;
begin
  LLeadId := LeadsBindSourceDB.DataSet.FieldByName('LeadId').AsInteger;
  if ProposalBindSourceDB.DataSet.Locate('LeadId', VarArrayOf([LLeadId]), []) then
  begin
    ShowMessage('This lead already has a proposal.');
    Exit;
  end;
  DraftProposalFormFmx.NewDraft(LLeadId,
    LeadsBindSourceDB.DataSet.FieldByName('AccountName').AsString);
  DraftProposalFormFmx.Show;
end;

procedure TLeadsFormFmx.ViewProposalButtonClick(Sender: TObject);
var
  LReportStream: TStringStream;
  LReportString: string;
  LCurrentLeadId: Integer;
begin
  LCurrentLeadId := LeadsBindSourceDB.DataSet.FieldByName('LeadId').AsInteger;
  LReportString := '';
  LReportStream := TStringStream.Create;
  try
    if ProposalBindSourceDB.DataSet.Locate('LeadId', VarArrayOf([LCurrentLeadId]), []) and
       (ProposalBindSourceDB.DataSet.FindField('Proposal') <> nil) then
    begin
      TBlobField(ProposalBindSourceDB.DataSet.FieldByName('Proposal')).SaveToStream(LReportStream);
      LReportString := LReportStream.DataString;
    end;
  finally
    LReportStream.Free;
  end;
  if LReportString = '' then
  begin
    ShowMessage('This lead has no proposal yet.');
    Exit;
  end;
  ProposalFormFmx.LoadProposal(LCurrentLeadId, LReportString);
  ProposalFormFmx.Show;
end;

procedure TLeadsFormFmx.CancelProposalButtonClick(Sender: TObject);
begin
  DM.UpdateProposalStatus(LeadsBindSourceDB.DataSet.FieldByName('LeadId').AsInteger, 'Canceled');
end;

procedure TLeadsFormFmx.CompleteProposalButtonClick(Sender: TObject);
begin
  DM.CompleteProposal(LeadsBindSourceDB.DataSet.FieldByName('LeadId').AsInteger);
end;

procedure TLeadsFormFmx.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  // The component lives on the main form and chains that form's handler by
  // itself; every other form asks it, which is what HandleKeyDown is for.
  if Assigned(MainFormFmx) and Assigned(MainFormFmx.HelpChat) then
    MainFormFmx.HelpChat.HandleKeyDown(Key, Shift);
end;

end.
