# Deployment notes

Where these scripts sit in a typical Autopilot flow, and where they fall over if you run them too early.

## Phases (rough)

1. **Hardware hash imported** — device exists in Autopilot inventory with a serial, maybe a group tag.
2. **Pre-provisioning (white glove)** — tech-driven phase; some orgs run checks before the user sees OOBE.
3. **User-driven OOBE** — Entra join + Intune enrolment; this is where “wait a minute” actually means ten.
4. **Post-enrolment** — policies apply, apps install, naming may settle; good place for `Test-CoreApps.ps1`.

## Script mapping

| Script | Typical phase | Comment |
|--------|----------------|--------|
| `Set-GroupTag.ps1` | Before shipment / intake repair | Updates imported device identity in Graph. Wrong tag means wrong profile assignment — verify assignment filters if you use them. |
| `Set-DeviceNaming.ps1` | Post-enrolment (sometimes) | Renaming is messy: local `Rename-Computer`, Entra display name, and Intune “managed device” name can disagree until everything syncs. |
| `Get-AutopilotDeploymentStatus.ps1` | Troubleshooting anywhere | Read-only inventory sanity check; useful when someone swears the device is not in Autopilot. |
| `Test-CoreApps.ps1` | Post-enrolment | Assumes Win32/LOB targets finished or failed loudly enough to detect. |

## Timing friction

Intune can report **compliant** while a machine is still chewing through app installs. If your script checks for binaries too early, you get false failures — wait for the deployment state you actually trust, or re-run after a sensible delay.

Graph sometimes lists a device before the local MDM channel has applied naming policies. If rename scripts fight with a naming template, pick one authority and document it.

## Graph permission reality

Read operations are easier to get approved. **Write** operations on Autopilot imported identities or managed devices often need broader roles (`Intune Administrator`, or custom role with the right micro-permissions). Some tenants block service principals from these writes — you may be stuck with interactive admin for certain fixes.

## Not production promises

None of this replaces your vendor support runbook, your imaging standard, or your HR/offboarding process. It is glue for admins who already know what Autopilot is supposed to do.
