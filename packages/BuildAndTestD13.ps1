<#
.SYNOPSIS
    Builds everything with Delphi 13 and runs the test suite.

.DESCRIPTION
    The check to run before a commit, in this order, stopping at the first
    failure:
    - the packages (BuildAllPackages.ps1 -DelphiVersion D13: MarkdownProcessor,
      runtime and design-time) in Release;
    - the DUnitX tests (Test\Delphi13) in the requested configuration;
    - the two CRM demos, VCL and FMX ("CRM Demo\BuildDemo.ps1"), with the
      WebView2Loader.dll they share copied next to them;
    - the console server (Server\Delphi13) and the HelpIndexBuilder tool in
      Release;
    - Test\Bin\<Platform>\HelpChatAITests.exe, whose exit code is the exit
      code of this script.

    Only Delphi 13 has a project for the tests and the server. For the
    packages of every version use BuildAllPackages.ps1, for the demos
    "CRM Demo\BuildAllDemos.ps1".

.PARAMETER BDSRoot
    Root folder of RAD Studio installations (default: C:\BDS\Studio).

.PARAMETER Platform
    Target platform: Win32 or Win64 (default: Win32).

.PARAMETER Config
    Configuration of the tests and the demos: Debug or Release (default:
    Debug). The packages, the server and the tool are always Release.

.EXAMPLE
    .\BuildAndTestD13.ps1
    # Win32 Debug: what was Tools\Build_Delphi13.cmd with no arguments.

.EXAMPLE
    .\BuildAndTestD13.ps1 -Platform Win64 -Config Release
#>
param(
    [string]$BDSRoot = "C:\BDS\Studio",

    [ValidateSet("Win32", "Win64")]
    [string]$Platform = "Win32",

    [ValidateSet("Debug", "Release")]
    [string]$Config = "Debug"
)

$ErrorActionPreference = "Stop"

$Root = Split-Path $PSScriptRoot -Parent
$rsvars = Join-Path $BDSRoot "37.0\bin\rsvars.bat"
if (-not (Test-Path $rsvars)) {
    Write-Error "Delphi 13 not found: $rsvars"
    exit 1
}

function Invoke-MSBuild([string]$Title, [string]$Project, [string]$Cfg) {
    Write-Host ""
    Write-Host "=== $Title ($Platform $Cfg) ===" -ForegroundColor Cyan
    $path = Join-Path $Root $Project
    cmd /c "call `"$rsvars`" && msbuild `"$path`" /t:Build /p:Config=$Cfg /p:Platform=$Platform /v:minimal /nologo"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "BUILD FAILED: $Project" -ForegroundColor Red
        exit 1
    }
}

# Packages: incremental, only the platform asked for.
& (Join-Path $PSScriptRoot "BuildAllPackages.ps1") -DelphiVersion D13 -BDSRoot $BDSRoot -Platform $Platform -Config Release -Target Build
if ($LASTEXITCODE -ne 0) { exit 1 }

Invoke-MSBuild "Tests" "Test\Delphi13\HelpChatAITests.dproj" $Config

foreach ($fw in @("VCL", "FMX")) {
    & (Join-Path $Root "CRM Demo\BuildDemo.ps1") -Framework $fw -DelphiVersion D13 -BDSRoot $BDSRoot -Platform $Platform -Config $Config -Target Build
    if ($LASTEXITCODE -ne 0) { exit 1 }
}
if ($Platform -eq "Win64") { $arch = "x64" } else { $arch = "x86" }
Copy-Item (Join-Path $Root "Redist\WebView2\$arch\WebView2Loader.dll") (Join-Path $Root "CRM Demo\bin\$Platform\") -Force

Invoke-MSBuild "HelpChatAI server" "Server\Delphi13\HelpChatAIServerApp.dproj" "Release"
Invoke-MSBuild "HelpIndexBuilder tool" "Tools\HelpIndexBuilder\HelpIndexBuilder.dproj" "Release"

Write-Host ""
Write-Host "=== Running tests ===" -ForegroundColor Cyan
& (Join-Path $Root "Test\Bin\$Platform\HelpChatAITests.exe") --exitbehavior:Continue
exit $LASTEXITCODE
