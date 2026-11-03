<#
.SYNOPSIS
    Puts the CRM demo back to "no API key anywhere", so that the License
    activation window shows up again.

.DESCRIPTION
    The demo asks for a key only when it cannot find one. ResolveApiKey looks,
    in this order, at Settings.Claude.ApiKey, at the three helpchatai.json
    files (the shared one in %APPDATA%\HelpChatAI, the one next to the
    executable, the per-application one in %APPDATA%\<exe>) and at the
    ANTHROPIC_API_KEY environment variable - so showing the activation window
    means taking all of them out of the way.

    This script does two things and warns about the rest:

      - deletes the per-application file(s) %APPDATA%\VCL_CRMDemo\helpchatai.json
        and %APPDATA%\FMX_CRMDemo\helpchatai.json, which is where the demo
        writes the encrypted key;
      - moves the shared %APPDATA%\HelpChatAI\helpchatai.json aside, to
        helpchatai.json.bak. It is never deleted: it is the file that holds
        your key in clear, and -Restore brings it back.

    It warns when ANTHROPIC_API_KEY is set in this session, or when a
    helpchatai.json next to one of the executables carries an ApiKey: either
    would answer before the window ever appears.

.PARAMETER Framework
    Which demo to reset: VCL, FMX or Both (default: Both).

.PARAMETER KeepShared
    Leave %APPDATA%\HelpChatAI\helpchatai.json where it is. Use it when that
    file holds no key, or when you want the demo to find one.

.PARAMETER Restore
    Undo: brings helpchatai.json.bak back to helpchatai.json. The encrypted
    per-application files stay deleted - they are written again at the next
    activation.

.EXAMPLE
    .\ResetDemoKey.ps1
    # Before the demo: the activation window will show up

.EXAMPLE
    .\ResetDemoKey.ps1 -Restore
    # After the demo: your own key is back where it was

.EXAMPLE
    .\ResetDemoKey.ps1 -Framework FMX -KeepShared
#>

param(
    [ValidateSet("VCL", "FMX", "Both")]
    [string]$Framework = "Both",

    [switch]$KeepShared,

    [switch]$Restore
)

$ErrorActionPreference = "Stop"

$sharedFile = Join-Path $env:APPDATA "HelpChatAI\helpchatai.json"
$sharedBak = "$sharedFile.bak"

$userFiles = @()
if ($Framework -in @("VCL", "Both")) {
    $userFiles += Join-Path $env:APPDATA "VCL_CRMDemo\helpchatai.json"
}
if ($Framework -in @("FMX", "Both")) {
    $userFiles += Join-Path $env:APPDATA "FMX_CRMDemo\helpchatai.json"
}

if ($Restore) {
    if (Test-Path $sharedBak) {
        if (Test-Path $sharedFile) {
            Write-Error "Both files are there: $sharedFile and $sharedBak. Sort them out by hand, one of the two holds your key."
            exit 1
        }
        Move-Item $sharedBak $sharedFile
        Write-Host "Restored $sharedFile" -ForegroundColor Green
    }
    else {
        Write-Host "Nothing to restore: $sharedBak is not there" -ForegroundColor Yellow
    }
    exit 0
}

# ---- the encrypted key the demo wrote
foreach ($file in $userFiles) {
    if (Test-Path $file) {
        Remove-Item $file
        Write-Host "Deleted  $file" -ForegroundColor Green
    }
    else {
        Write-Host "Already gone: $file" -ForegroundColor DarkGray
    }
}

# ---- the shared file: moved aside, never deleted
if (-not $KeepShared) {
    if (Test-Path $sharedFile) {
        if (Test-Path $sharedBak) {
            Write-Error "$sharedBak is already there: a previous run was never restored. Sort it out by hand - one of the two holds your key."
            exit 1
        }
        Move-Item $sharedFile $sharedBak
        Write-Host "Moved    $sharedFile -> $sharedBak" -ForegroundColor Green
        Write-Host "         (.\ResetDemoKey.ps1 -Restore brings it back)" -ForegroundColor DarkGray
    }
    else {
        Write-Host "Already gone: $sharedFile" -ForegroundColor DarkGray
    }
}

# ---- what this script cannot take away
if ($env:ANTHROPIC_API_KEY) {
    Write-Host "WARNING: ANTHROPIC_API_KEY is set in this session - the demo will find that one and never ask." -ForegroundColor Yellow
    Write-Host "         Start the demo from a prompt where it is not set, or clear it first." -ForegroundColor Yellow
}

$binRoot = Join-Path (Split-Path $PSScriptRoot -Parent) "CRM Demo\bin"
foreach ($platform in @("Win32", "Win64")) {
    $appFile = Join-Path $binRoot "$platform\helpchatai.json"
    if ((Test-Path $appFile) -and (Select-String -Path $appFile -Pattern '"ApiKey"\s*:\s*"\S' -Quiet)) {
        Write-Host "WARNING: $appFile carries an ApiKey - the demo will find that one." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "The demo now has no key: the next run opens License activation." -ForegroundColor Cyan
