# autopilot-provisioning-scripts

Small PowerShell helpers for **Windows Autopilot** work: naming, group tags, sanity checks after enrolment, and rough deployment visibility via Microsoft Graph.

**Status:** working sketches: test on a lab device before production.
**Runs on:** PowerShell 5.1 or 7 with the Microsoft Graph modules, on a management workstation.
**Used by:** IT admins running Windows Autopilot rollouts.

These scripts are **operational sketches**. They are not guaranteed safe for every tenant, hardware type, or enrolment path. Read the notes, test on a lab device, and fix the bits that do not match how your estate behaves.

## Prerequisites

- Windows PowerShell 5.1 or PowerShell 7+ on a management workstation.
- `Microsoft.Graph` modules (DeviceManagement + Identity.DirectoryManagement as needed).
- Permissions depend on the script: see each file header and `docs/deployment-notes.md`.
- A test Autopilot device group; do not aim the rename/tag scripts at production until you are bored of fixing mistakes.

## Graph scopes (typical)

Least privilege varies by tenant lockdown. Starting points:

- **Imported device / Autopilot inventory:** `DeviceManagementServiceConfig.Read.All` (read) or `.ReadWrite.All` (tag updates).
- **Managed device rename (where supported):** often `DeviceManagementManagedDevices.ReadWrite.All`: behaviour differs by join type; do not assume Graph always renames the OS immediately.

Use `Connect-MgGraph -Scopes ...` and approve the consent prompt in a test tenant first.

## How to run

Dot-source or run the scripts from an elevated or normal session as noted in each script. Pass `-WhatIf` where implemented.

## What you must customise

Illustrative naming follows **Harven Group** (`harven.co.uk` / `harvengroup.onmicrosoft.com`). Serial numbers and Autopilot hashes in your runs are still real data: do not paste those into a public repo.

## Limitations

Autopilot timing is awkward: **MDM enrolment can lag behind OOBE**, Graph can be ahead or behind the local OS, and some operations only make sense after the device hits a specific provisioning phase. See `docs/deployment-notes.md`.
