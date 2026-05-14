<# 
This script checks to see if Crowdstrike Falcon or Sophos antivirus is installed. 

If Sophos is found we should either exit script with error prompting to uninstall or automate the uninstall. 
If Crowdstrike Falcon is found we already have the antivirus and the script should complete.
If Crowdstrike Falcon is found, we should proceed with the install.

#>

function mountNetworkShare {

    $uncPath = "[REDACTED]"

    # Check if network path is already mapped
    if (Test-Path "$uncPath") {
        Write-Host "Network path is already accessible." -ForegroundColor Green
        return $true
    }
    else {
        $credential = Get-Credential -Message "Enter credentials for accessing the network share"
        Write-Host "Network path is not accessible. Attempting to create a new PSDrive..." -ForegroundColor Yellow
        New-PSDrive -Name "Z" -PSProvider FileSystem -Root $networkPath -Credential $credential 
    }
}

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

function checkSophos {
    $sophosPath = "C:\Program Files\Sophos\Sophos Endpoint Agent"
    if (Test-Path $sophosPath) {
        Write-Host "Sophos antivirus is installed. Please uninstall it before proceeding." -ForegroundColor Red
        Start-Sleep 5
        return 1
    } 
    else {
        Write-Host "Sophos antivirus is not installed." -ForegroundColor Green
        Start-Sleep 2
        return 0
    }}

function checkCrowdstrike{
    $falconService = Get-Service -Name "CSFalconService" -ErrorAction SilentlyContinue
    if ($falconService -and $falconService.Status -eq 'Running') {
        Write-Host "Crowdstrike Falcon is already installed and running." -ForegroundColor Green
        Start-Sleep 2
        return 0
    } 
    elseif ($falconService -and $falconService.Status -eq 'Stopped') {
        Write-Host "Crowdstrike Falcon service is installed but not running. Please start the service." -ForegroundColor Yellow
        Start-Sleep 2
        return 2
    }
    else {
        Write-Host "Crowdstrike Falcon is not installed." -ForegroundColor Red
        Start-Sleep 5
        return 1
    }}

function installCrowdstrike {

    if ($mountResult -eq $true) {
        $installerLocation = "$uncPath\FalconSensor_Windows.exe"
    }
    else {
        $installerLocation = "Z:\FalconSensor_Windows.exe"
        }
    
    $customerID = "[REDACTED]"
    $groupingTag = "[REDACTED]"

    # Copy the installer to a local temp directory
    $tempDir = "$env:TEMP\Crowdstrike"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    Copy-Item -Path $installerLocation -Destination $tempDir -Force

    
    # Install the Crowdstrike Falcon sensor
    Write-Host "Installing Crowdstrike Falcon sensor... Please wait..." -ForegroundColor Cyan
    Start-Process -FilePath "$tempDir\FalconSensor_Windows.exe" -ArgumentList "/install", "/silent", "/norestart", "CID=$customerID", "GROUPING_TAGS=$groupingTag" -Wait
    Get-Service -Name "CSFalconService"
    Write-Host "Crowdstrike Falcon installation completed." -ForegroundColor Green
}

# Main script execution

checkAdmin
$mountResult = mountNetworkShare
$sophosCheck = checkSophos
$crowdstrikeCheck = checkCrowdstrike

if ($sophosCheck -eq 1) {
    Write-Host "Exiting script due to Sophos installation. Please uninstall Sophos and try again." -ForegroundColor Red
    exit 1
} elseif ($crowdstrikeCheck -eq 0) {
    Write-Host "No action needed. Exiting script." -ForegroundColor Green
    exit 0
} elseif ($crowdstrikeCheck -eq 2) {
    Write-Host "Please start the Crowdstrike Falcon service. Exiting script." -ForegroundColor Yellow
    Start-Sleep 2
    exit 2
} else {
    Write-Host "Proceeding with Crowdstrike Falcon installation..." -ForegroundColor Green
    Start-Sleep 2
    installCrowdstrike
}