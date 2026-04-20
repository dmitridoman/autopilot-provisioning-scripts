<#
.SYNOPSIS
    Post-enrolment smoke test: check a short list of apps you expect on Autopilot-built devices.

.DESCRIPTION
    Looks for display names in the registry uninstall keys — quick and dirty, not a full Win32 detection engine.

.NOTES
    App installs can still be running when this fires; a failure might mean "slow", not "broken".
    Tweak $Expected list per estate — defaults are placeholders only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]] $Expected = @('Company Portal', 'Microsoft Edge'),

    [Parameter(Mandatory = $false)]
    [string] $LogPath,

    [Parameter(Mandatory = $false)]
    [int] $DelaySeconds = 0
)

function Write-LogLine {
    param([string] $Message)
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$ts] $Message"
    Write-Host $line
    if ($LogPath) {
        Add-Content -Path $LogPath -Value $line
    }
}

if ($LogPath) {
    $logDir = Split-Path -Parent $LogPath
    if ($logDir -and -not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
}

if ($DelaySeconds -gt 0) {
    Write-LogLine "Waiting $DelaySeconds seconds — enrolment churn is real."
    Start-Sleep -Seconds $DelaySeconds
}

function Get-InstalledDisplayNames {
    $paths = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($p in $paths) {
        Get-ItemProperty $p -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName } |
            ForEach-Object { $_.DisplayName }
    }
}

$installed = @(Get-InstalledDisplayNames | Sort-Object -Unique)
$missing = New-Object System.Collections.Generic.List[string]

foreach ($name in $Expected) {
    $hit = $installed | Where-Object { $_ -like "*$name*" }
    if (-not $hit) {
        $missing.Add($name) | Out-Null
        Write-LogLine "MISSING (by rough match): $name"
    }
    else {
        Write-LogLine "OK: $name -> $($hit | Select-Object -First 1)"
    }
}

if ($missing.Count -gt 0) {
    Write-LogLine "Finished with $($missing.Count) missing expected entries. Re-run after apps settle."
    exit 1
}

Write-LogLine "All expected apps matched loosely."
exit 0
