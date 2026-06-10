# LINC Setup

PowerShell automation for provisioning a Windows device with a standard local user, custom applications, and Windows Update.

## Project layout

```text
LINC.Setup\
  LINC.Setup.ps1
  LINC.Setup.psd1
  Build-LINCExecutable.ps1
  README.md
  Modules\
    LINC.Common.psm1
    LINC.Users.psm1
    LINC.Apps.psm1
    LINC.Updates.psm1
```

## What it does

- Creates a local standard user account.
- Installs Google Chrome.
- Installs Zoom.
- Runs Microsoft Update / Windows Update.
- Provides consistent logging and error handling.

## Requirements

- Windows PowerShell 5.1 or later.
- Administrator privileges.
- Internet access for application downloads and updates.
- `PSWindowsUpdate` for Windows Update operations.

## Run the setup

```powershell
.\LINC.Setup.ps1
```

## Validate the manifest

```powershell
Test-ModuleManifest .\LINC.Setup.psd1
```

## Build the executable package

```powershell
.\Build-LINCExecutable.ps1
```

The build output is placed in `.\dist\package\`.

## Notes

This project is structured as a script-driven module project with a packaging step for EXE distribution.