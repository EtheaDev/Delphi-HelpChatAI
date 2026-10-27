<#
.SYNOPSIS
    Builds the HelpChatAI sample application for one or more Delphi versions.

.DESCRIPTION
    Wrapper around BuildDemo.ps1 that builds the CRM demos for each requested
    framework, Delphi version and platform, and prints a summary table. A Delphi
    version that is not installed under BDSRoot is reported as SKIP; the FMX
    demo on Delphi 10.4 and 11 is reported as N/A, because TFmxHelpChatAI starts
    at Delphi 12.

.PARAMETER Framework
    VCL, FMX or Both (default: Both).

.PARAMETER DelphiVersion
    One or more versions (D10.4, D11, D12, D13), or "All" (default) for all of
    them.

.PARAMETER BDSRoot
    Root folder of RAD Studio installations (default: C:\BDS\Studio).

.PARAMETER Platform
    Target platform: Win32, Win64 or Both (default: Both).

.PARAMETER Config
    Build configuration: Debug or Release (default: Release).

.PARAMETER Target
    MSBuild target: Build, Clean or Rebuild (default: Rebuild).

.EXAMPLE
    .\BuildAllDemos.ps1
    # Rebuilds both demos with every installed Delphi, Win32 + Win64, Release.

.EXAMPLE
    .\BuildAllDemos.ps1 -Framework FMX -DelphiVersion D13 -Platform Win64 -Target Build
#>
param(
    [ValidateSet("VCL", "FMX", "Both")]
    [string]$Framework = "Both",

    [string[]]$DelphiVersion = @("All"),

    [string]$BDSRoot = "C:\BDS\Studio",

    [ValidateSet("Win32", "Win64", "Both")]
    [string]$Platform = "Both",

    [ValidateSet("Debug", "Release")]
    [string]$Config = "Release",

    [ValidateSet("Build", "Clean", "Rebuild")]
    [string]$Target = "Rebuild"
)

$ErrorActionPreference = "Stop"

$AllVersions = @("D10.4", "D11", "D12", "D13")
$bdsVersionMap = @{
    "D10.4" = "21.0"
    "D11"   = "22.0"
    "D12"   = "23.0"
    "D13"   = "37.0"
}

# accepts both -DelphiVersion D12,D13 and "D12,D13" (when launched with powershell -File)
$DelphiVersion = @($DelphiVersion | ForEach-Object { $_ -split "," } | Where-Object { $_ })
if ($DelphiVersion -contains "All") { $Versions = $AllVersions } else { $Versions = $DelphiVersion }
if ($Platform -eq "Both") { $Platforms = @("Win32", "Win64") } else { $Platforms = @($Platform) }
if ($Framework -eq "Both") { $Frameworks = @("VCL", "FMX") } else { $Frameworks = @($Framework) }

# The FireMonkey component of the library starts at Delphi 12.
$FmxVersions = @("D12", "D13")

$BuildScript = Join-Path $PSScriptRoot "BuildDemo.ps1"
$Results = @()
$Failed = 0
$StartTime = Get-Date

foreach ($fw in $Frameworks) {
    foreach ($ver in $Versions) {
        foreach ($plat in $Platforms) {
            if (($fw -eq "FMX") -and ($ver -notin $FmxVersions)) {
                $Results += [pscustomobject]@{ Framework = $fw; Delphi = $ver; Platform = $plat; Status = "N/A"; Seconds = 0 }
                continue
            }
            $installed = Test-Path (Join-Path (Join-Path $BDSRoot $bdsVersionMap[$ver]) "bin\rsvars.bat")
            if (-not $installed) {
                $Results += [pscustomobject]@{ Framework = $fw; Delphi = $ver; Platform = $plat; Status = "SKIP"; Seconds = 0 }
                continue
            }

            Write-Host ""
            Write-Host "############################################" -ForegroundColor Magenta
            Write-Host "  CRM Demo / $fw / $ver / $plat / $Config" -ForegroundColor Magenta
            Write-Host "############################################" -ForegroundColor Magenta

            $stepStart = Get-Date
            & $BuildScript -Framework $fw -DelphiVersion $ver -BDSRoot $BDSRoot -Platform $plat -Config $Config -Target $Target
            $exitCode = $LASTEXITCODE
            $Results += [pscustomobject]@{
                Framework = $fw
                Delphi    = $ver
                Platform  = $plat
                Status    = if ($exitCode -eq 0) { "OK" } else { "FAIL" }
                Seconds   = [math]::Round(((Get-Date) - $stepStart).TotalSeconds, 1)
            }
            if ($exitCode -ne 0) { $Failed++ }
        }
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " SUMMARY (CRM demos)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
$Results | Format-Table -AutoSize | Out-String | Write-Host
Write-Host ("Total elapsed: {0:N1} s" -f ((Get-Date) - $StartTime).TotalSeconds) -ForegroundColor White

$built = @($Results | Where-Object { $_.Status -notin @("SKIP", "N/A") }).Count
if ($Failed -gt 0) {
    Write-Host "$Failed of $built builds FAILED" -ForegroundColor Red
    exit 1
}
else {
    Write-Host "All $built builds SUCCEEDED" -ForegroundColor Green
    exit 0
}
