<#
.SYNOPSIS
    Rename the local computer and optionally try to align Entra / Intune naming (best-effort).

.DESCRIPTION
    Autopilot + Intune estates often have three "names" that drift: OS hostname, Entra device displayName,
    managed device name in Graph. This script handles the local rename in a controlled way.
    Graph updates are optional and tenant-dependent — verify behaviour on a throwaway device first.

.NOTES
    Example naming: `HVN-LT-042` / `HVN-DT-018` style prefixes for Harven-style estates — adjust to your standard.
    Run post-enrolment when you have a stable session. Reboot may be required for the hostname to stick everywhere.
    Graph rename paths change over time; if Update-Mg* fails, fix the cmdlet to match your module version.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $NewComputerName,

    [Parameter(Mandatory = $false)]
    [string] $ManagedDeviceId,

    [Parameter(Mandatory = $false)]
    [switch] $SkipGraph,

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

$current = $env:COMPUTERNAME
Write-LogLine "Current computer name: $current; target: $NewComputerName"

if ($current -eq $NewComputerName) {
    Write-LogLine "Already named correctly. Exiting."
    return
}

if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Rename computer to $NewComputerName")) {
    try {
        # Local rename — still the most reliable bit if you have rights.
        Rename-Computer -NewName $NewComputerName -Force -ErrorAction Stop
        Write-LogLine "Rename-Computer issued. Reboot required for full effect."
    }
    catch {
        Write-LogLine "Rename-Computer failed: $($_.Exception.Message)"
        throw
    }
}

if (-not $SkipGraph -and $ManagedDeviceId) {
    if (-not (Get-Module Microsoft.Graph.DeviceManagement -ErrorAction SilentlyContinue)) {
        Import-Module Microsoft.Graph.DeviceManagement -ErrorAction Stop
    }
    Write-LogLine "Attempting managed device displayName update in Graph (may not match hostname immediately)."
    try {
        if ($PSCmdlet.ShouldProcess($ManagedDeviceId, "Update managed device display name")) {
            $body = @{ displayName = $NewComputerName }
            Update-MgDeviceManagementManagedDevice -ManagedDeviceId $ManagedDeviceId -BodyParameter $body -ErrorAction Stop
            Write-LogLine "Graph update sent. Verify in Intune — sync is not instant."
        }
    }
    catch {
        Write-LogLine "Graph update failed (common if modules/scopes/version mismatch): $($_.Exception.Message)"
    }
}
elseif (-not $SkipGraph -and -not $ManagedDeviceId) {
    Write-LogLine "Graph path skipped — no ManagedDeviceId passed."
}
