program FMX_CRMDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  // The FireDAC wait cursor is per framework, so it belongs to the project and
  // not to the data module, which the VCL demo shares.
  FireDAC.FMXUI.Wait,
  uDataMod in '..\..\common\uDataMod.pas' {DM: TDataModule},
  uMainFormFmx in '..\source\uMainFormFmx.pas' {MainFormFmx};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDM, DM);
  Application.CreateForm(TMainFormFmx, MainFormFmx);
  Application.Run;
end.
