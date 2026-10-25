<#
.SYNOPSIS
    Builds the HelpChatAI sample application for one Delphi version.

.DESCRIPTION
    Configures the RAD Studio environment via rsvars.bat and invokes MSBuild on
    "CRM Demo\project\Windows10CRMDemo.dproj". The executable goes to
    "CRM Demo\bin\<Platform>".

    The demo compiles the library from source, so no package has to be installed
    first; the resources of the panel are built if they are missing.

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
    .\BuildDemo.ps1 -Project Vcl -Config Debug
#>

param(
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

$Project = "project\Windows10CRMDemo.dproj"

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
