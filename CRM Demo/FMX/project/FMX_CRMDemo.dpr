program FMX_CRMDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  // The FireDAC wait cursor is per framework, so it belongs to the project and
  // not to the data module, which the VCL demo shares.
  FireDAC.FMXUI.Wait,
  uDataMod in '..\..\common\uDataMod.pas' {DM: TDataModule},
  uProposalReport in '..\..\common\uProposalReport.pas',
  uMainFormFmx in '..\source\uMainFormFmx.pas' {MainFormFmx},
  uLeadsFmx in '..\source\uLeadsFmx.pas' {LeadsFormFmx},
  uProposalFmx in '..\source\uProposalFmx.pas' {ProposalFormFmx},
  uDraftProposalFmx in '..\source\uDraftProposalFmx.pas' {DraftProposalFormFmx};

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
