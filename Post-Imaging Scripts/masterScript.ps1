# This script checks the state of the script execution and performs actions based on the state.
# It initializes the script, checks if the computer needs to be renamed, checks if it is joined to Active Directory, installs Windows updates, and installs software updates.

# This function initializes the script by creating a directory in the TEMP folder and copying the script files to it.
function initializeScript
{
    Write-Host "Initializing script and installing pre-requisites..." -ForegroundColor Cyan
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if (-not (Test-Path $env:TEMP\DeployScripts)) {
        # Create the DeployScripts directory in the TEMP folder if it does not exist
        New-Item -Path $env:TEMP\DeployScripts -ItemType Directory -Force
        Copy-Item $PSScriptRoot\*.ps1 $env:TEMP\DeployScripts\ -Force
        Write-Host "Created DeployScripts directory in TEMP folder." -ForegroundColor Green
        Start-Sleep -Seconds 2
    } else {
        Write-Host "DeployScripts directory already exists in TEMP folder." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
    }

        New-Item -Path "HKCU:\Software\Test" -Force
        # Set the initial script state to "Initialized"
        Set-ItemProperty -Path "HKCU:\Software\Test" -Name "ScriptState" -Value "Initialized" -Force
        
        installNuGet
        installPowershellGet

        # Install PSWindowsUpdate module if not already installed
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            installWindowsUpdateModule # Install the PSWindowsUpdate module if not already installed
        }
        else {
            Write-Host "PSWindowsUpdate module is already installed." -ForegroundColor Yellow
        }
}

# This function installs the PSWindowsUpdate module if it is not already installed.
function installWindowsUpdateModule {
        # If windows update module is not installed, install it
        if(-Not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Host "Installing PSWindowsUpdate module..." -ForegroundColor Yellow
            Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser -AllowClobber -Confirm:$false
            Import-Module PSWindowsUpdate -Force
        }
        else {
            Write-Host "PSWindowsUpdate module is already installed." -ForegroundColor Green
        }
}

# This function installs the NuGet package provider if it is not already installed.
function installNuGet
{
    # Check if NuGet is already installed
    if (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue) {
        Write-Host "NuGet package provider is already installed." -ForegroundColor Yellow
    }
    else {
        Write-Host "Installing NuGet package provider..." -ForegroundColor Cyan
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5 -Confirm:$false -Force
        Write-Host "NuGet package provider installed successfully." -ForegroundColor Green
    }
}

# This function installs the PowerShellGet module if it is not already installed.
function installPowershellGet
{
    if (-not (Get-Module -ListAvailable -Name PowerShellGet)) {
        Write-Host "Installing PowerShellGet module..." -ForegroundColor Cyan
        Install-Module -Name PowerShellGet -Force -Scope CurrentUser -AllowClobber -Confirm:$false -ErrorAction Stop
        Import-Module PowerShellGet -Force -Confirm:$false
        Write-Host "PowerShellGet module installed successfully." -ForegroundColor Green
    } else {
        Write-Host "PowerShellGet module is already installed." -ForegroundColor Yellow
    }
}

# This function checks if the script is running as an administrator. If not, it prompts the user to run it as an administrator.
function checkAdmin
    {
    Write-Host "Checking if script is running as administrator..." -ForegroundColor Cyan
    # From https://superuser.com/questions/749243/detect-if-powershell-is-running-as-administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)  
    if (!$isAdmin)
        {
            Write-Host "This script must be run as an administrator. Please run PowerShell as an administrator and try again." -ForegroundColor Red
        Start-Sleep 3
        exit 1
        }
    else
        {
            Write-Host "Script is running as administrator." -ForegroundColor Green
        }
    }

# Function to configure auto-login for the Administrator account
function configureAutoLogin
{
    # If the AutoAdminLogon registry key is 0, configure auto-login
    Write-Host "Configuring auto-login for the Administrator account..." -ForegroundColor Cyan
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    New-ItemProperty -Path $regPath -Name "AutoAdminLogon" -Value "1" -Force
    New-ItemProperty -Path $regPath -Name "DefaultUserName" -Value "Administrator" -Force
    if ($null -eq (Get-ItemProperty -Path $regPath -Name "DefaultPassword" -ErrorAction SilentlyContinue)) {
        New-ItemProperty -Path $regPath -Name "DefaultPassword" -Value "" -Force
        $adminCredential = Read-Host -Prompt "Enter the password for the Administrator account" -AsSecureString
        $adminPW = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminCredential))
        New-ItemProperty -Path $regPath -Name "DefaultPassword" -Value "$adminPW" -Force
    } 
    else {
        Write-Host "DefaultPassword registry key already exists." -ForegroundColor Yellow
    }
    Write-Host "Auto-login configured successfully." -ForegroundColor Green
    Start-Sleep -Seconds 2
}

# Function to initialize the reboot process and set the script state in the registry
    function initializeReboot
{
    if (!(Get-ScheduledTask -TaskName "RebootAfterScript" -ErrorAction SilentlyContinue)) {
        # If the scheduled task does not exist, create it
        Write-Host "Creating scheduled task to reboot after script execution..." -ForegroundColor Cyan
        $newtask = New-ScheduledTask "RebootAfterScript" -Action (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command `"$env:TEMP\DeployScripts\masterScript.ps1`"" ) -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Settings (New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries) -Principal (New-ScheduledTaskPrincipal -UserId "$env:computername\Administrator") -CimSession (New-CimSession)
        $newtask | Register-ScheduledTask -TaskName "RebootAfterScript"
    } 
    else {
        Write-Host "Scheduled task 'RebootAfterScript' already exists." -ForegroundColor Yellow
        $newtask = Set-ScheduledTask -TaskName "RebootAfterScript" -Action (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command `"$env:TEMP\DeployScripts\masterScript.ps1`"") -Trigger (New-ScheduledTaskTrigger -AtLogon)
        Write-Host "Script state is: "$scriptState.ScriptState". The computer will now restart to apply changes." -ForegroundColor Green; Start-Sleep -Seconds 5
    }
    
    $newtask | Register-ScheduledTask -TaskName "RebootAfterScript" -Force
    # Restart the computer to apply changes
    configureAutoLogin
    # Configure auto-login for the Administrator account
    Restart-Computer -Force
}


checkAdmin
# Check if the script is running as administrator

$scriptState = Get-ItemProperty -Path "HKCU:\Software\Test" -Name "ScriptState" -ErrorAction SilentlyContinue
while ($scriptState.ScriptState -notmatch "Completed")
{
    switch ($scriptState.ScriptState)
    {
        "Initialized" {
            
            powershell -ExecutionPolicy Bypass -File $env:TEMP\DeployScripts\renameComputer.ps1 -Wait -WindowStyle Maximized
            if ((Get-ItemProperty -Path "HKCU:\Software\Test" -Name "ScriptState" -ErrorAction SilentlyContinue) -match "NoRenameNeeded") 
            {
                Write-Host "No renaming needed. Skipping reboot..." -ForegroundColor Yellow
            } 
            else {
                Write-Host "Computer renamed successfully. Proceeding to next step." -ForegroundColor Green
                initializeReboot
            }
        }
        "Renamed" {
            Write-Host "Computer has been renamed. Proceeding to check if the computer is joined to Active Directory." -ForegroundColor Green
             powershell -ExecutionPolicy Bypass -File $env:TEMP\DeployScripts\ADJoin.ps1 -Wait -WindowStyle Maximized
            # Run the ADJoin script to check if the computer is joined to Active Directory
            initializeReboot
        }
        "NoRenameNeeded" {
            Write-Host "Computer name is already in the correct format. Proceeding to check Active Directory status." -ForegroundColor Yellow
            powershell -ExecutionPolicy Bypass -File $env:TEMP\DeployScripts\ADJoin.ps1 -Wait -WindowStyle Maximized
            $alreadyADJoined = (Get-ItemProperty -Path "HKCU:\Software\Test" -Name "ScriptState" -ErrorAction SilentlyContinue) -match "AlreadyADJoined"
            if ($alreadyADJoined -eq $true) 
            {
                Write-Host "Computer is already joined to Active Directory. Proceeding to install Windows Updates." -ForegroundColor Yellow
            } 
            elseif ($alreadyADJoined -eq $false) {
                Write-Host "Computer need to reboot to finishing joining AD" -ForegroundColor Red
                initializeReboot
            }
            # Run the ADJoin script to check if the computer is joined to Active Directory
        }
        "ADJoined" {
            Write-Host "Computer is joined to Active Directory. Proceeding to install Windows Updates." -ForegroundColor Green
            powershell -ExecutionPolicy Bypass -File $env:TEMP\DeployScripts\updateWindows.ps1 -WindowStyle Maximized
            # Run the updateWindows script to check for and install Windows updates
        }
        "AlreadyADJoined" {
            powershell -ExecutionPolicy Bypass -File $env:TEMP\DeployScripts\updateWindows.ps1 -WindowStyle Maximized
            # Run the updateWindows script to check for and install Windows updates
        }
        "WindowsUpdatesComplete" {
            Write-Host "All Windows updates have been installed. Proceeding to install software." -ForegroundColor Green
            powershell -ExecutionPolicy Bypass -File "$env:TEMP\DeployScripts\updateSoftware.ps1" -WindowStyle Maximized
            # Run the updateSoftware script to check for and install software updates
        } 
        "WindowsUpdates" {
            Write-Host "Windows updates are being installed. Please wait..." -ForegroundColor Cyan
            Start-Sleep -Seconds 3
            powershell -ExecutionPolicy Bypass -File $env:TEMP\DeployScripts\updateWindows.ps1 -WindowStyle Maximized
            # Run the updateWindows script to check for and install Windows updates
            # Set the script state to "WindowsUpdatesComplete" to indicate that the Windows updates have been installed
        }
        "SoftwareInstalled" {
            Write-Host "Software installation completed. Proceeding to script cleanup" -ForegroundColor Green
            Start-Sleep -Seconds 3
            New-ItemProperty -Path "HKCU:\Software\Test" -Name "ScriptState" -Value "ScriptCleanup" -Force
            # Set the script state to "ScriptCompleted" to indicate that the script has finished executing
        }
        "ScriptCleanup" {
            Read-Host "Script execution completed. Script will now cleanup, this window will close automatically, press Enter to continue"
            powershell -ExecutionPolicy Bypass -File $env:TEMP\DeployScripts\scriptCleanup.ps1 -WindowStyle Maximized
            exit 0
            # Call the scriptCleanup script to remove the registry key and the DeployScripts directory
        }

        default {
            Write-Host "Unknown script state. Re-initializing." -ForegroundColor Red
            initializeScript
            # Re-initialize the script if the state is unknown

        }
    }
    $scriptState = Get-ItemProperty -Path "HKCU:\Software\Test" -Name "ScriptState" -ErrorAction SilentlyContinue
}