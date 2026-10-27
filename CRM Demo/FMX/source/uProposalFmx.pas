{******************************************************************************}
{                                                                              }
{   HelpChatAI CRM demo - FireMonkey - the proposal window                     }
{                                                                              }
{   The saved proposal of a lead, shown in a web browser. The VCL one writes   }
{   the document into the DOM of the old TWebBrowser (Document.Write); the     }
{   FireMonkey browser has no DOM to reach, and LoadFromStrings is both the    }
{   way to do it and the better one.                                           }
{                                                                              }
{******************************************************************************}

unit uProposalFmx;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.WebBrowser;

const
  /// <summary>What this window is about, for the assistant. The VCL form
  /// says it in HelpType/HelpKeyword; a FireMonkey form has neither, so
  /// the main form reads this when F1 arrives from here.</summary>
  PROPOSAL_HELP_KEYWORD = 'Sales';

type
  TProposalFormFmx = class(TForm)
    NavLayout: TLayout;
    CloseButton: TButton;
    CompleteButton: TButton;
    Browser: TWebBrowser;
    procedure CloseButtonClick(Sender: TObject);
    procedure CompleteButtonClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar;
      Shift: TShiftState);
  private
    FLeadId: Integer;
  public
    /// <summary>Shows the document of a lead and remembers which lead it is,
    /// so Complete knows what to close.</summary>
    procedure LoadProposal(ALeadId: Integer; const ADocument: string);
  end;

var
  ProposalFormFmx: TProposalFormFmx;

implementation

{$R *.fmx}

uses
  uDataMod, uMainFormFmx;

procedure TProposalFormFmx.LoadProposal(ALeadId: Integer; const ADocument: string);
begin
  FLeadId := ALeadId;
  // No base URL: the document carries its own style and asks for nothing
  // from anywhere else.
  Browser.LoadFromStrings(ADocument, '');
end;

procedure TProposalFormFmx.CompleteButtonClick(Sender: TObject);
begin
  DM.CompleteProposal(FLeadId);
  Close;
end;

procedure TProposalFormFmx.CloseButtonClick(Sender: TObject);
begin
  Close;
end;

procedure TProposalFormFmx.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  // The component lives on the main form and chains that form's handler by
  // itself; every other form asks it, which is what HandleKeyDown is for.
  if Assigned(MainFormFmx) and Assigned(MainFormFmx.HelpChat) then
    MainFormFmx.HelpChat.HandleKeyDown(Key, Shift);
end;

end.
