# Description: This script checks if the computer is joined to Active Directory, renames it if necessary, and joins it to the specified domain.

    # Function to check if the computer is joined to Active Directory
function checkADStatus
    {
    Write-Host "Checking if the computer is joined to Active Directory..." -ForegroundColor Cyan
    $adDomain = (Get-WmiObject Win32_ComputerSystem).Domain # Get the domain of the computer
    if ($adDomain -eq "[DOMAIN]") # Check if the domain is [DOMAIN]
        {
            Write-Host "This computer is already joined to Active Directory domain: $adDomain" -ForegroundColor Green
            return $true # Return true if already joined
        }
    elseif ($adDomain -eq "WORKGROUP") # Check if the computer is in a workgroup
        {
            Write-Host "This computer is in a workgroup and not joined to Active Directory." -ForegroundColor Yellow
            return $false # Return false if in a workgroup
        } 
    elseif ($null -ne $adDomain -AND $adDomain -ne "") # Check if the domain is not null or empty 
        {
            Write-Host "This computer is joined to Active Directory domain: $adDomain" -ForegroundColor Green
            return $true # Return true if joined to any other domain
        }
    else
        {
            Write-Host "This computer is not joined to Active Directory... Joining to [DOMAIN]" -ForegroundColor Red
            Start-Sleep 3
            return $false # Return false if not joined to any domain
        }
    }

    # Function to join the computer to Active Directory
    function adJoinComputer
    {
        $ADStatus = checkADStatus
        if ($ADStatus -eq $false)
        {        
        Write-Host "Joining computer to Active Directory..." -ForegroundColor Cyan 
        $domain = "[DOMAIN]" # Specify the domain to join
        $ouPath = Read-Host "Please enter the path of the OU where the computer should be added" # Specify the OU path where the computer should be added
        $credential = Get-Credential -Message "Enter your Active Directory credentials to join the domain $domain" # Prompt for credentials
        $computerName = $env:COMPUTERNAME # Get the current computer name
        <#
        Want to eventually see if we can check if the computer is already registered in Active Directory before joining
        # This section checks if the Active Directory module is available and installs it if not
        if (!(Get-Module -ListAvailable -Name ActiveDirectory)) # Check if the Active Directory module is available
        {
            Write-Host "Active Directory module is not available. Installing it..." -ForegroundColor Yellow
            Import-Module ServerManager # Import the ServerManager module to use Install-WindowsFeature
            Install-WindowsFeature -Name RSAT-AD-PowerShell -IncludeAllSubFeature -IncludeManagementTools -ErrorAction Stop # Install the Active Directory module if not present
            Import-Module ActiveDirectory # Import the Active Directory module
            
        }
        else
        {
            Write-Host "Active Directory module is already available." -ForegroundColor Green # If the module is already available, no action is taken
        }
        # This section checks if the computer is already registered in Active Directory and removes it if necessary
        $adComputer = Get-ADComputer -Filter {Name -eq $computerName} -Server "[DOMAIN]" -Credential $credential -ErrorAction SilentlyContinue # Check if the computer is already in AD
        if ($null -eq $adComputer) # If the computer is not found in AD
        {
            Write-Host "Computer not found in Active Directory. Proceeding to join..." -ForegroundColor Yellow
        }
        else
        {
            Write-Host "Computer is already registered in Active Directory... Removing it from AD before rejoining." -ForegroundColor Yellow
            Remove-ADComputer -Identity $adComputer -Confirm:$false -Credential $credential -ErrorAction SilentlyContinue # Remove the computer from AD if it exists
        }
            #>
        Add-Computer -DomainName $domain -OUPath $ouPath -Credential $Credential -Force # Join the computer to the specified domain and OU
        Write-Host "Computer has been joined to Active Directory. It will now restart." -ForegroundColor Green 
        New-ItemProperty -Path "HKCU:\Software\Test" -Name "ScriptState" -Value "ADJoined" -Force # Set the script state to ADJoined
        Start-Sleep -Seconds 3
        }
        else
        {
            Write-Host "Computer is already joined to Active Directory. No action taken." -ForegroundColor Yellow # No action taken if already joined
            New-ItemProperty -Path "HKCU:\Software\Test" -Name "ScriptState" -Value "AlreadyADJoined" -Force # Set the script state to AlreadyADJoined
            Start-Sleep -Seconds 3
        }

    }

# Main script execution
adJoinComputer # Call the function to check AD status and join if necessary