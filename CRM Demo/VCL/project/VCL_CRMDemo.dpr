program VCL_CRMDemo;

uses
  Vcl.Forms,
  // The FireDAC wait cursor is per framework, so it belongs to the project and
  // not to the data module, which the FMX demo shares.
  FireDAC.VCLUI.Wait,
  uDataMod in '..\..\common\uDataMod.pas' {DM: TDataModule},
  uProposalReport in '..\..\common\uProposalReport.pas',
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
