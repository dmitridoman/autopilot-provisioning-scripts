<#
.SYNOPSIS
    List imported Autopilot identities (and basic fields) for troubleshooting intake and assignment.

.DESCRIPTION
    Read-only Graph pull. Useful when someone pasted the wrong serial into the supplier spreadsheet.

.NOTES
    Large tenants: `-All` can take a bit. If you know the serial, filter after import in the console or pipe to Where-Object.
    This does not show live OOBE status — it is inventory, not a crystal ball.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] $SerialNumber,

    [Parameter(Mandatory = $false)]
    [string] $LogPath
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

if (-not (Get-Module Microsoft.Graph.DeviceManagement -ErrorAction SilentlyContinue)) {
    Import-Module Microsoft.Graph.DeviceManagement -ErrorAction Stop
}

Write-LogLine "Fetching imported Autopilot identities (read-only)."

$items = Get-MgDeviceManagementImportedWindowsAutopilotDeviceIdentity -All -ErrorAction Stop

if ($SerialNumber) {
    $sn = $SerialNumber.Trim()
    $items = $items | Where-Object { $_.SerialNumber -eq $sn }
    Write-LogLine "Filtered to serial $sn — $($items.Count) record(s)."
}

$items |
    Select-Object Id, SerialNumber, Model, Manufacturer, GroupTag, LastContactedDateTime |
    Format-Table -AutoSize

# Return objects for pipeline use
$items
