program VCL_CRMDemo_MultiAgent;

// The multi-assistant edition of the CRM demo: the same forms and units as
// VCL_CRMDemo, with MULTIAGENT defined (in the project options) and uMultiAgent in the
// uses. Two assistants, an area of the manual each, and an action only one of
// them may use: see uMultiAgent.
uses
  Vcl.Forms,
  // The FireDAC wait cursor is per framework, so it belongs to the project and
  // not to the data module, which the FMX demo shares.
  FireDAC.VCLUI.Wait,
  uDataMod in '..\..\common\uDataMod.pas' {DM: TDataModule},
  uProposalReport in '..\..\common\uProposalReport.pas',
  uAppSecret in '..\..\common\uAppSecret.pas',
  uLicenseActivation in '..\source\uLicenseActivation.pas' {LicenseActivationForm},
  uMainForm in '..\source\uMainForm.pas' {MainForm},
  uLeads in '..\source\uLeads.pas' {LeadsForm},
  uDraftProposal in '..\source\uDraftProposal.pas' {DraftProposalForm},
  uProposal in '..\source\uProposal.pas' {ProposalForm},
  uMultiAgent in '..\source\uMultiAgent.pas',
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
