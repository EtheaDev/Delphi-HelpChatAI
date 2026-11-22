<#
.SYNOPSIS
    Rebuilds the HelpChatAI packages of Delphi 10.2 Tokyo: the engine and the server.

.DESCRIPTION
    Calls BuildAllPackages.ps1 -DelphiVersion D10.2: the MarkdownProcessor
    package first, then the runtime and the design-time packages of HelpChatAI.
    The IDE is 32-bit: the design-time packages are built for Win32 only.

.PARAMETER BDSRoot
    Root folder of RAD Studio installations (default: C:\BDS\Studio).

.PARAMETER Platform
    Target platform: Win32, Win64 or Both (default: Both).

.PARAMETER Config
    Build configuration: Debug or Release (default: Release).

.PARAMETER Target
    MSBuild target: Build, Clean or Rebuild (default: Rebuild).

.EXAMPLE
    .\BuildAllPackagesD10.2.ps1
    # Rebuilds the packages for D10.2 on Win32 + Win64 in Release.

.EXAMPLE
    .\BuildAllPackagesD10.2.ps1 -Platform Win32 -Target Build -Config Debug
    # Incremental Debug build for D10.2, only Win32.
#>
param(
    [string]$BDSRoot = "C:\BDS\Studio",

    [ValidateSet("Win32", "Win64", "Both")]
    [string]$Platform = "Both",

    [ValidateSet("Debug", "Release")]
    [string]$Config = "Release",

    [ValidateSet("Build", "Clean", "Rebuild")]
    [string]$Target = "Rebuild"
)

# --- Explorer pause: when started from Explorer the window stays open at the end, so the errors can be read ---
if (-not $global:ExplorerPauseRegistered) {
    $global:ExplorerPauseRegistered = $true
    try {
        $ppid = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId
        if ((Get-Process -Id $ppid -ErrorAction Stop).ProcessName -eq 'explorer') {
            Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
                Write-Host ''
                Write-Host 'Press Enter to close...'
                [void](Read-Host)
            } | Out-Null
        }
    } catch { }
}


$BuildAll = Join-Path $PSScriptRoot "BuildAllPackages.ps1"
& $BuildAll -DelphiVersion "D10.2" -BDSRoot $BDSRoot -Platform $Platform -Config $Config -Target $Target
exit $LASTEXITCODE
