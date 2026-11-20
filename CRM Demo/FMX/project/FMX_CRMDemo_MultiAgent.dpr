program FMX_CRMDemo_MultiAgent;

// The multi-assistant edition of the CRM demo: the same forms and units as
// FMX_CRMDemo, with MULTIAGENT defined (in the project options) and uMultiAgentFmx in the
// uses. Two assistants, an area of the manual each, and an action only one of
// them may use: see uMultiAgentFmx.
uses
  System.StartUpCopy,
  FMX.Forms,
  // The FireDAC wait cursor is per framework, so it belongs to the project and
  // not to the data module, which the VCL demo shares.
  FireDAC.FMXUI.Wait,
  uDataMod in '..\..\common\uDataMod.pas' {DM: TDataModule},
  uProposalReport in '..\..\common\uProposalReport.pas',
  uCRMActions in '..\..\common\uCRMActions.pas',
  uAppSecret in '..\..\common\uAppSecret.pas',
  uLicenseActivationFmx in '..\source\uLicenseActivationFmx.pas' {LicenseActivationFormFmx},
  uMainFormFmx in '..\source\uMainFormFmx.pas' {MainFormFmx},
  uLeadsFmx in '..\source\uLeadsFmx.pas' {LeadsFormFmx},
  uProposalFmx in '..\source\uProposalFmx.pas' {ProposalFormFmx},
  uDraftProposalFmx in '..\source\uDraftProposalFmx.pas' {DraftProposalFormFmx},
  uMultiAgentFmx in '..\source\uMultiAgentFmx.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDM, DM);
  Application.CreateForm(TMainFormFmx, MainFormFmx);
  Application.CreateForm(TLeadsFormFmx, LeadsFormFmx);
  Application.CreateForm(TProposalFormFmx, ProposalFormFmx);
  Application.CreateForm(TDraftProposalFormFmx, DraftProposalFormFmx);
  Application.Run;
end.
