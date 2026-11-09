<#
.SYNOPSIS
    Rebuilds all HelpChatAI packages for one or more Delphi versions.

.DESCRIPTION
    For each version and each requested platform, in this order:
    - the MarkdownProcessor runtime package, through the BuildPackages.ps1 of
      that project (Ext\MarkdownProcessor\Packages, an svn:external): the
      engine requires it;
    - the runtime packages HelpChatAI, HelpChatAIServer, HelpChatAIVcl and
      HelpChatAIFmx (FMX from D12 on), through BuildPackages.ps1;
    - the design-time packages dclHelpChatAIVcl and dclHelpChatAIFmx, which
      require the runtime ones.
    At the end prints a summary table with the result of each
    (version, package, platform) combination, and stops at nothing: a
    failure is reported in the table, not by skipping the rest.

    The resources of the panel (source\HelpChatAI.Panel.res) are built first
    if they are missing: nothing compiles without them.

    A version that is not installed under BDSRoot is reported as SKIP.
    Design-time packages are built for Win64 only on D12 and later: before
    D12 the IDE is 32-bit and loads only Win32 design-time BPLs, so those
    combinations are reported as SKIP too. A package that does not exist in
    a version (FMX before D12) is not listed at all.

    The BuildAllPackages<Version>.ps1 scripts call this one with their
    version.

.PARAMETER DelphiVersion
    One or more versions (D10.4, D11, D12, D13), or "All" (default) for every
    one of them.

.PARAMETER BDSRoot
    Root folder of RAD Studio installations (default: C:\BDS\Studio).

.PARAMETER Platform
    Target platform: Win32, Win64 or Both (default: Both).

.PARAMETER Config
    Build configuration: Debug or Release (default: Release).

.PARAMETER Target
    MSBuild target: Build, Clean or Rebuild (default: Rebuild).

.EXAMPLE
    .\BuildAllPackages.ps1
    # Rebuilds every package of every installed version, Win32 + Win64, Release.

.EXAMPLE
    .\BuildAllPackages.ps1 -DelphiVersion D13 -Platform Win32 -Target Build
    # Builds (incremental) the D13 packages, only Win32.
#>
param(
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

$ScriptDir = $PSScriptRoot
$Root = Split-Path $ScriptDir -Parent
$BuildScript = Join-Path $ScriptDir "BuildPackages.ps1"
$MdpBuildScript = Join-Path $Root "Ext\MarkdownProcessor\Packages\BuildPackages.ps1"
foreach ($s in @($BuildScript, $MdpBuildScript)) {
    if (-not (Test-Path $s)) {
        Write-Error "Build script not found: $s"
        exit 1
    }
}

$AllVersions = @("D10.4", "D11", "D12", "D13")
$bdsVersionMap = @{ "D10.4" = "21.0"; "D11" = "22.0"; "D12" = "23.0"; "D13" = "37.0" }
# "D12,D13" arrives as one string through powershell -File: split it here
$DelphiVersion = @($DelphiVersion | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($DelphiVersion -contains "All") { $Versions = $AllVersions } else { $Versions = $DelphiVersion }
foreach ($ver in $Versions) {
    if ($AllVersions -notcontains $ver) {
        Write-Error "Unknown Delphi version '$ver'. Use D10.4, D11, D12, D13 or All."
        exit 1
    }
}
if ($Platform -eq "Both") { $Platforms = @("Win32", "Win64") } else { $Platforms = @($Platform) }

# runtime first, in the order they require each other; design-time last
$Runtime = @("HelpChatAI.dproj", "HelpChatAIServer.dproj", "HelpChatAIVcl.dproj", "HelpChatAIFmx.dproj")
$Design = @("dclHelpChatAIVcl.dproj", "dclHelpChatAIFmx.dproj")

# The panel page is a resource the library needs to compile.
if (-not (Test-Path (Join-Path $Root "source\HelpChatAI.Panel.res"))) {
    Write-Host "Building the resources of the panel..." -ForegroundColor Yellow
    cmd /c "`"$(Join-Path $Root 'Tools\BuildResources.cmd')`""
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Tools\BuildResources.cmd failed"
        exit 1
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " BuildAllPackages $($Versions -join ', ')" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Platforms: $($Platforms -join ', ')" -ForegroundColor White
Write-Host " Config:    $Config" -ForegroundColor White
Write-Host " Target:    $Target" -ForegroundColor White
Write-Host "============================================" -ForegroundColor Cyan

$Results = @()
$Failed = 0
$StartTime = Get-Date

function Add-Result($ver, $pkg, $plat, $status, $seconds) {
    $script:Results += [pscustomobject]@{
        Delphi   = $ver
        Package  = $pkg
        Platform = $plat
        Status   = $status
        Seconds  = $seconds
    }
}

function Invoke-Step($ver, $pkg, $plat, [scriptblock]$Build) {
    Write-Host ""
    Write-Host "############################################" -ForegroundColor Magenta
    Write-Host "  $ver / $pkg / $plat / $Config" -ForegroundColor Magenta
    Write-Host "############################################" -ForegroundColor Magenta
    $stepStart = Get-Date
    & $Build
    $exitCode = $LASTEXITCODE
    $seconds = [math]::Round(((Get-Date) - $stepStart).TotalSeconds, 1)
    if ($exitCode -eq 0) { $status = "OK" } else { $status = "FAIL"; $script:Failed++ }
    Add-Result $ver $pkg $plat $status $seconds
}

foreach ($ver in $Versions) {
    if (-not (Test-Path (Join-Path $BDSRoot "$($bdsVersionMap[$ver])\bin\rsvars.bat"))) {
        Add-Result $ver "(all)" "-" "SKIP" 0
        continue
    }
    $folder = Join-Path $ScriptDir ("Delphi" + $ver.Substring(1))
    # 64-bit IDE (and Win64 design-time packages) from D12 on
    $win64DesignTime = @("D12", "D13") -contains $ver

    foreach ($plat in $Platforms) {
        # The MarkdownProcessor names its folders D10.4 ... D13, like $ver.
        Invoke-Step $ver "MarkdownProcessor.dproj" $plat {
            & $MdpBuildScript -DelphiVersion $ver -BDSRoot $BDSRoot -Platform $plat -Config $Config -Project "MarkdownProcessor.dproj" -Target $Target
        }
        foreach ($pkg in $Runtime + $Design) {
            if (-not (Test-Path (Join-Path $folder $pkg))) { continue }
            if (($pkg -like "dcl*") -and ($plat -eq "Win64") -and -not $win64DesignTime) {
                Add-Result $ver $pkg $plat "SKIP" 0
                continue
            }
            Invoke-Step $ver $pkg $plat {
                & $BuildScript -DelphiVersion $ver -BDSRoot $BDSRoot -Platform $plat -Config $Config -Project $pkg -Target $Target
            }
        }
    }
}

$totalDuration = (Get-Date) - $StartTime
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " SUMMARY [$($Versions -join ', ')]" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
$Results | Format-Table -AutoSize | Out-String | Write-Host
Write-Host ("Total elapsed: {0:N1} s" -f $totalDuration.TotalSeconds) -ForegroundColor White

$built = @($Results | Where-Object { $_.Status -ne "SKIP" }).Count
if ($Failed -gt 0) {
    Write-Host "$Failed of $built builds FAILED" -ForegroundColor Red
    exit 1
}
else {
    Write-Host "All $built builds SUCCEEDED" -ForegroundColor Green
    exit 0
}
