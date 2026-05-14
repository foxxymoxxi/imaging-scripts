# 🖥️ Imaging Deployment Scripts

This repository contains a suite of PowerShell scripts written while at a previous employer for automating the imaging and configuration of Windows machines. The workflow includes renaming computers, joining them to Active Directory, installing Windows updates, deploying essential software, and cleaning up post-deployment.

---

## 📁 Scripts Overview

### `masterScript.ps1`

The central orchestration script that manages the entire imaging workflow. It tracks progress using a registry key (`HKCU:\Software\Test\ScriptState`) and executes steps conditionally:

- Initializes environment and installs prerequisites
- Renames computer if needed
- Joins computer to Active Directory
- Installs Windows updates
- Installs software packages
- Cleans up temporary files and registry keys

### `renameComputer.ps1`

Renames the computer to match the required format `ED-P########` (8-digit asset tag). If renaming occurs, the script updates the registry and triggers a reboot.

### `ADJoin.ps1`

Checks if the computer is joined to Active Directory. If not, it prompts for credentials and joins the machine to the `[REDACTED]` domain under a specified OU.

### `updateWindows.ps1`

Uses the `PSWindowsUpdate` module to check for and install Windows updates. Automatically reboots if required and updates the script state to `WindowsUpdatesComplete`.

### `updateSoftware.ps1`

Installs essential software using `winget`, including:

- Google Chrome
- Mozilla Firefox
- Zoom
- VLC Media Player
- Microsoft Teams
- Microsoft Office
- 7-Zip

Also detects BIOS manufacturer and installs:

- Lenovo Vantage
- Dell SupportAssist
- HP Support Assistant

Updates the registry key to `SoftwareInstalled` upon completion.

### `scriptCleanup.ps1`

Final cleanup script that:

- Removes registry keys and scheduled tasks
- Deletes temporary files
- Resets system policies
- Clears mapped network drives

---

## 🛠️ Requirements

- Windows 10 version 1809 or later
- PowerShell with administrator privileges
- Internet access for downloading modules and software
- `winget` package manager (also installed during script execution)

## 📝 Notes

- Script progress is tracked using the registry key `HKCU:\Software\Test\ScriptState`
- Reboots are scheduled using Windows Task Scheduler
- Auto-login is temporarily configured to resume script execution after reboot
- All scripts should be placed in the same directory and copied to `TEMP\DeployScripts` by `masterScript.ps1`
