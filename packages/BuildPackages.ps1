<#
.SYNOPSIS
    Builds one HelpChatAI package using MSBuild and RAD Studio.

.DESCRIPTION
    Configures the RAD Studio environment via rsvars.bat and invokes MSBuild
    on one project of a package folder (Delphi10.4 ... Delphi13).

    It builds that project alone: the packages it requires must be there
    already (the MarkdownProcessor first, then HelpChatAI, and so on).
    BuildAllPackages.ps1 builds them in the right order.

.PARAMETER DelphiVersion
    Delphi version: D10.4, D11, D12 or D13 (default: D13). The package
    folders of this project are named Delphi10.4 ... Delphi13.

.PARAMETER BDSRoot
    Root folder of RAD Studio installations.
    Default: C:\BDS\Studio
    The script appends the version-specific subfolder (21.0 ... 37.0).

.PARAMETER Platform
    Target platform: Win32 or Win64 (default: Win32). Design-time packages
    for Win64 require D12 or later (64-bit IDE).

.PARAMETER Config
    Build configuration: Debug or Release (default: Release)

.PARAMETER Project
    Project file name without path (default: HelpChatAI.dproj)

.PARAMETER Target
    MSBuild target: Build, Clean, Rebuild (default: Build)

.EXAMPLE
    .\BuildPackages.ps1
    # Builds HelpChatAI with Delphi 13, Win32, Release

.EXAMPLE
    .\BuildPackages.ps1 -DelphiVersion D12 -Platform Win64 -Project HelpChatAIVcl.dproj
    # Builds the VCL runtime package with Delphi 12, Win64, Release
#>

param(
    [ValidateSet("D10.4", "D11", "D12", "D13")]
    [string]$DelphiVersion = "D13",

    [string]$BDSRoot = "C:\BDS\Studio",

    [ValidateSet("Win32", "Win64")]
    [string]$Platform = "Win32",

    [ValidateSet("Debug", "Release")]
    [string]$Config = "Release",

    [string]$Project = "HelpChatAI.dproj",

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

$bdsVersion = $bdsVersionMap[$DelphiVersion]
$bdsPath = Join-Path $BDSRoot $bdsVersion
$rsvars = Join-Path $bdsPath "bin\rsvars.bat"

# Validate paths
if (-not (Test-Path $bdsPath)) {
    Write-Error "RAD Studio not found at: $bdsPath"
    exit 1
}
if (-not (Test-Path $rsvars)) {
    Write-Error "rsvars.bat not found at: $rsvars"
    exit 1
}

$projectDir = Join-Path $PSScriptRoot ("Delphi" + $DelphiVersion.Substring(1))
$projectPath = Join-Path $projectDir $Project

if (-not (Test-Path $projectPath)) {
    Write-Error "Project not found: $projectPath"
    exit 1
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " HelpChatAI Build" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Delphi:   $DelphiVersion (BDS $bdsVersion)" -ForegroundColor White
Write-Host " Project:  $Project" -ForegroundColor White
Write-Host " Platform: $Platform" -ForegroundColor White
Write-Host " Config:   $Config" -ForegroundColor White
Write-Host " Target:   $Target" -ForegroundColor White
Write-Host " BDS Path: $bdsPath" -ForegroundColor White
Write-Host "============================================" -ForegroundColor Cyan

$msbuildArgs = "`"$projectPath`" /t:$Target /p:Config=$Config /p:Platform=$Platform /v:minimal /nologo"

# Win64 needs the DCP folder of its own platform spelled out: the library
# path of an IDE can list ...\Dcp before ...\Dcp\Win64, and the compiler then
# picks the 32-bit HelpChatAI.dcp and stops on "Bad packaged unit format".
# BDSCOMMONDIR is read from rsvars.bat, because cmd expands the variables of
# a line before that line runs rsvars.bat.
if ($Platform -eq "Win64") {
    $commonLine = Select-String -Path $rsvars -Pattern '^@?SET BDSCOMMONDIR=(.+)$' | Select-Object -First 1
    if ($commonLine) {
        $dcp64 = Join-Path $commonLine.Matches[0].Groups[1].Value.Trim() "Dcp\Win64"
        $msbuildArgs += " `"/p:DCC_UnitSearchPath=$dcp64`""
    }
}

$cmd = "call `"$rsvars`" && msbuild $msbuildArgs"

Write-Host ""
Write-Host "Executing: msbuild $Project /t:$Target /p:Config=$Config /p:Platform=$Platform" -ForegroundColor Yellow
Write-Host ""

# Run via cmd /c so rsvars.bat environment is inherited by msbuild
cmd /c $cmd

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "BUILD FAILED (exit code $LASTEXITCODE)" -ForegroundColor Red
    exit $LASTEXITCODE
}
else {
    Write-Host ""
    Write-Host "BUILD SUCCEEDED" -ForegroundColor Green
    exit 0
}
