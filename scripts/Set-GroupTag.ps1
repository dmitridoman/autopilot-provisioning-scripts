<#
.SYNOPSIS
    Update the Autopilot group tag on an imported Windows Autopilot device identity.

.DESCRIPTION
    Uses Microsoft Graph imported device identities. Handy when intake missed the tag and profiles are assigned from it.

.NOTES
    Requires write permission to Autopilot objects. If consent is missing, Connect-MgGraph will whinge — fix scopes or role.
    Serial matching is case-sensitive on some exports; trim whitespace from CSV intake.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
    [ValidateNotNullOrEmpty()]
    [string] $ImportedDeviceIdentityId,

    [Parameter(Mandatory = $true, ParameterSetName = 'BySerial')]
    [ValidateNotNullOrEmpty()]
    [string] $SerialNumber,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $GroupTag,

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

$id = $ImportedDeviceIdentityId
if ($PSCmdlet.ParameterSetName -eq 'BySerial') {
    Write-LogLine "Looking up imported identity by serial (pagination warning — big tenants can be slow)."
    $found = $null
    $serialNorm = $SerialNumber.Trim()
    # MgGraph tends to expose imported identities via paging — keep it simple for a portfolio script.
    $page = Get-MgDeviceManagementImportedWindowsAutopilotDeviceIdentity -All -ErrorAction Stop
    $found = $page | Where-Object { $_.SerialNumber -eq $serialNorm } | Select-Object -First 1
    if (-not $found) {
        throw "No imported Autopilot identity matched serial '$serialNorm'."
    }
    $id = $found.Id
    Write-LogLine "Resolved identity Id: $id"
}

Write-LogLine "Setting group tag to '$GroupTag' on $id"

if ($PSCmdlet.ShouldProcess($id, "Set Autopilot group tag")) {
    $body = @{ groupTag = $GroupTag }
    Update-MgDeviceManagementImportedWindowsAutopilotDeviceIdentity -ImportedWindowsAutopilotDeviceIdentityId $id -BodyParameter $body -ErrorAction Stop
    Write-LogLine "Update submitted. Give Graph a moment — assignment can lag."
}
