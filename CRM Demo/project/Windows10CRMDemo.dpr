program Windows10CRMDemo;

uses
  Vcl.Forms,
  uDataMod in '..\source\uDataMod.pas' {DM: TDataModule},
  uMainForm in '..\source\uMainForm.pas' {MainForm},
  uLeads in '..\source\uLeads.pas' {LeadsForm},
  uDraftProposal in '..\source\uDraftProposal.pas' {DraftProposalForm},
  uProposal in '..\source\uProposal.pas' {ProposalForm},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 SlateGray', False);
  Application.CreateForm(TDM, DM);
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TDraftProposalForm, DraftProposalForm);
  Application.CreateForm(TProposalForm, ProposalForm);
  Application.CreateForm(TLeadsForm, LeadsForm);
  Application.Run;
end.
