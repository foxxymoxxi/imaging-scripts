# This script manages the installation of essential software and checks for Windows updates. The script also checks if Lenovo Vantage is needed based on the BIOS manufacturer.



# Function to install Lenovo Vantage
function installLenovoVantage
    {
        winget install --id 9NR5B8GVVM13 --silent --accept-package-agreements --force --accept-package-agreements --accept-source-agreements # Using winget to install Lenovo Commercial Vantage silently
    }

# Functions to install Firefox, Chrome, Zoom, VLC, and Microsoft Teams
function installFirefox 
    {
        winget install --id Mozilla.Firefox --silent --accept-package-agreements --force --accept-package-agreements --accept-source-agreements  # Using winget to install Firefox silently
    }

function installChrome 
    {
        winget install --id Google.Chrome --silent --accept-package-agreements --force --accept-package-agreements --accept-source-agreements  # Using winget to install Chrome silently
    }
function installZoom 
    {
      winget install --id Zoom.Zoom --silent --accept-package-agreements --force --accept-package-agreements --accept-source-agreements
    }

function installVLC 
    {
        winget install --id VideoLAN.VLC --silent --accept-package-agreements --force --accept-package-agreements --accept-source-agreements  # Using winget to install VLC silently
    }

function installTeams
    {
        winget install --id Microsoft.Teams --silent --accept-package-agreements --force --accept-package-agreements --accept-source-agreements  # Using winget to install Microsoft Teams silently
    }

function install7zip
    {
        winget install --id 7zip.7zip --silent --accept-package-agreements --force --accept-package-agreements --accept-source-agreements  # Using winget to install 7-Zip silently
    }

function installMSOffice
    {
        winget install --id Microsoft.Office --silent --accept-package-agreements --force --accept-package-agreements --accept-source-agreements  # Using winget to install Microsoft Office silently
    }
# Main script execution starts here
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # Ensure TLS 1.2 is used for secure downloads
Write-Host "Starting software installation..." -ForegroundColor Cyan
    # If we don't have winget, we will install it
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    if ((Get-WmiObject -Class Win32_OperatingSystem).Version -gt "10.0.17763")  { # Check if the OS version is 10.0.17763 or higher (Windows 10 1809 and later)
        Install-Script -Name winget-install -Force -Confirm:$false -ErrorAction Stop
        winget-install
        Write-Host "winget installed successfully." -ForegroundColor Green
    }
    else {
        Write-Host "winget requires Windows 10 version 1809 or later. Please update your system." -ForegroundColor Red
        Read-Host "Please remember to update this system manually, as this script will now skip Windows Updates to install software."
        New-ItemProperty -Path "HKCU:\Software\Test" -Name "ScriptState" -Value "WindowsUpdatesComplete" -Force # Set the script state to WindowsUpdatesComplete since we can't update without.. updating manually
        exit 1 # Exit the script if winget cannot be installed due to OS version
    }
}
    
    else {
        Write-Host "winget is already installed." -ForegroundColor Yellow
    }
installChrome # Install chrome
installFirefox # Install Firefox
installZoom # Install Zoom
installVLC # Install VLC
installTeams # Install Microsoft Teams
installMSOffice # Install Microsoft Office
install7zip # Install 7-Zip

Write-Host "`nChecking if additional software is needed..." -ForegroundColor Cyan

# I use Get-CimInstance here instead of Get-ComputerInfo as it's faster and more reliable for system information retrieval.
$BiosManufacturer = Get-CimInstance -Class Win32_BIOS | Select-Object -Property Manufacturer
Write-Host $BiosManufacturer -ForegroundColor Cyan
if ($BiosManufacturer -match "Lenovo") {
    Write-Host "Lenovo BIOS detected. Installing Lenovo Vantage..." -ForegroundColor Cyan
    installLenovoVantage
}
elseif ($BiosManufacturer -match "Dell") {
    Write-Host "Dell BIOS detected. Installing Support Assist" -ForegroundColor Yellow
    winget install --id Dell.SupportAssist --silent # Using winget to install Dell SupportAssist silently
}
elseif ($BiosManufacturer -match "HP") {
    Write-Host "HP BIOS detected. Installing HP Support Assistant..." -ForegroundColor Cyan
    winget install --id HP.HPSupportAssistant --silent # Using winget to install HP Support Assistant silently
} 
else {
    Write-Host "Unknown BIOS manufacturer: $($BiosManufacturer.Manufacturer). No additional software needed." -ForegroundColor Yellow
}

Write-Host "`nAll applications installed" -ForegroundColor Green
New-ItemProperty -Path "HKCU:\Software\Test" -Name "ScriptState" -Value "SoftwareInstalled" -Force # Set the script state to SoftwareInstalled


