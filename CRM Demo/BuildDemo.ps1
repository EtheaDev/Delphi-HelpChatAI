<#
.SYNOPSIS
    Builds the HelpChatAI sample application for one Delphi version.

.DESCRIPTION
    Configures the RAD Studio environment via rsvars.bat and invokes MSBuild on
    "CRM Demo\<Framework>\project\<Framework>_CRMDemo.dproj", or the
    multi-assistant edition <Framework>_CRMDemo_MultiAgent.dproj (the same
    sources with MULTIAGENT defined). Every executable goes to
    "CRM Demo\bin\<Platform>", next to the one WebView2Loader.dll they share;
    the DCUs are kept apart, in "CRM Demo\dcu\<Framework>" and
    "CRM Demo\dcu\<Framework>-MultiAgent", since the same unit compiles
    differently in the two editions.

    The demo compiles the library from source, so no package has to be installed
    first; the resources of the panel are built if they are missing.

.PARAMETER Framework
    VCL or FMX (default: VCL). The FireMonkey demo needs Delphi 12 or later:
    TFmxHelpChatAI does not exist before that.

.PARAMETER Edition
    Single (default): one assistant, the demo to start from. MultiAgent: two
    assistants, an area of the manual each, and an action only one may use.

.PARAMETER DelphiVersion
    Delphi version: D10.4, D11, D12 or D13 (default: D13).

.PARAMETER BDSRoot
    Root folder of RAD Studio installations (default: C:\BDS\Studio).

.PARAMETER Platform
    Target platform: Win32 or Win64 (default: Win32).

.PARAMETER Config
    Build configuration: Debug or Release (default: Release).

.PARAMETER Target
    MSBuild target: Build, Clean or Rebuild (default: Build).

.EXAMPLE
    .\BuildDemo.ps1 -DelphiVersion D12 -Platform Win64
    # Builds every demo with Delphi 12, Win64, Release

.EXAMPLE
    .\BuildDemo.ps1 -Framework FMX -Config Debug

.EXAMPLE
    .\BuildDemo.ps1 -Edition MultiAgent
#>

param(
    [ValidateSet("VCL", "FMX")]
    [string]$Framework = "VCL",

    [ValidateSet("Single", "MultiAgent")]
    [string]$Edition = "Single",

    [ValidateSet("D10.4", "D11", "D12", "D13")]
    [string]$DelphiVersion = "D13",

    [string]$BDSRoot = "C:\BDS\Studio",

    [ValidateSet("Win32", "Win64")]
    [string]$Platform = "Win32",

    [ValidateSet("Debug", "Release")]
    [string]$Config = "Release",

    [ValidateSet("Build", "Clean", "Rebuild")]
    [string]$Target = "Build"
)

$ErrorActionPreference = "Stop"

# Map Delphi version to BDS version subfolder
$bdsVersionMap = @{
    "D10.4" = "21.0"
    "D11"   = "22.0"
    "D12"   = "23.0"
    "D13"   = "37.0"
}

if (($Framework -eq "FMX") -and ($DelphiVersion -in @("D10.4", "D11"))) {
    Write-Error "The FMX demo needs Delphi 12 or later (TFmxHelpChatAI starts there); asked for $DelphiVersion"
    exit 1
}

$ProjectName = "${Framework}_CRMDemo"
if ($Edition -eq "MultiAgent") { $ProjectName += "_MultiAgent" }
$Project = "$Framework\project\$ProjectName.dproj"

$bdsVersion = $bdsVersionMap[$DelphiVersion]
$bdsPath = Join-Path $BDSRoot $bdsVersion
$rsvars = Join-Path $bdsPath "bin\rsvars.bat"

if (-not (Test-Path $rsvars)) {
    Write-Error "rsvars.bat not found at: $rsvars"
    exit 1
}

# The panel page, the assistant icons and the splash are resources the library
# needs to compile: they are versioned, but build them if a checkout lost them.
$repoRoot = Split-Path $PSScriptRoot -Parent
$sourceDir = Join-Path $repoRoot "source"
$panelRes = Join-Path $sourceDir "HelpChatAI.Panel.res"
if (-not (Test-Path $panelRes)) {
    Write-Host "Panel resource missing: running Tools\BuildResources.cmd" -ForegroundColor Yellow
    cmd /c "`"$(Join-Path $repoRoot 'Tools\BuildResources.cmd')`""
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$projectPath = Join-Path $PSScriptRoot $Project
if (-not (Test-Path $projectPath)) {
    Write-Error "Project not found: $projectPath"
    exit 1
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " HelpChatAI CRM Demo Build" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Framework:$Framework" -ForegroundColor White
Write-Host " Edition:  $Edition" -ForegroundColor White
Write-Host " Delphi:   $DelphiVersion (BDS $bdsVersion)" -ForegroundColor White
Write-Host " Platform: $Platform" -ForegroundColor White
Write-Host " Config:   $Config" -ForegroundColor White
Write-Host " Target:   $Target" -ForegroundColor White
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$msbuildArgs = "`"$projectPath`" /t:$Target /p:Config=$Config /p:Platform=$Platform /v:minimal /nologo"
cmd /c "call `"$rsvars`" && msbuild $msbuildArgs"
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "BUILD FAILED (exit code $LASTEXITCODE)" -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host ""
Write-Host "BUILD SUCCEEDED" -ForegroundColor Green
exit 0
