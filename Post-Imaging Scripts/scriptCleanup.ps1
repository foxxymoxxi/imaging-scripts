# PowerShell script to clean up after script execution
# This script will remove registry keys, scheduled tasks, and temporary files created by the main script

Write-Host "Cleaning up script..." -ForegroundColor Cyan
Remove-Item -Path "HKCU:\Software\Test" -Force -ErrorAction SilentlyContinue # Remove the registry key created by the script
Remove-Item -Path "HKCU:\Control Panel\PowerCfg\PowerPolicies\" -Recurse -Force -ErrorAction SilentlyContinue # Remove the PowerPolicies registry key created by the script
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon" -Value "0" # Remove the AutoAdminLogon registry key
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultUserName" -ErrorAction SilentlyContinue # Remove the DefaultUserName registry key
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultPassword" -ErrorAction SilentlyContinue # Remove the DefaultPassword registry key
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DisableLockWorkstation" -Value "0" -Force # Re-enable the lock workstation policy
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "InactivityTimeoutSecs" -Value "900" -Force # Set the inactivity timeout to 15 minutes
Unregister-ScheduledTask "RebootAfterScript" -Confirm:$false -ErrorAction SilentlyContinue # Remove the scheduled task created by the script
Remove-Item -Path "$env:TEMP\DeployScripts" -Recurse -Force -ErrorAction SilentlyContinue # Remove the DeployScripts directory in the TEMP folder
net use /delete * /y # Remove any network drives mapped by the script
Read-Host "Cleanup complete. Press Enter to close this window." # Wait for user input before closing the window
exit 0 # Exit the script