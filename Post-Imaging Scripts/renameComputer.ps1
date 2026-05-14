Write-Host "Checking current computer name..." -ForegroundColor Cyan
$currentName = (Get-WmiObject Win32_ComputerSystem).Name
Write-Host "Current computer name: $currentName" -ForegroundColor Yellow

if (($currentName -notmatch "^ED-P[0-9]{8}$")) 
{
    Write-Host "Computer name does not match the required format (ED-P####). Renaming computer..." -ForegroundColor Red
    while ($name_entry -notmatch "^ED-P[0-9]{8}$") # Ensure the asset tag is exactly 8 digits
    {
        $name_entry = Read-Host "Please enter the computer's asset tag (ED-#####) to rename the computer. Including the prefix and 8 digits."
            if ($name_entry -notmatch "^ED-P[0-9]{8}$")
            {
                Write-Host "Invalid input. Please enter exactly 8 digits." -ForegroundColor Red
            }
        }

        $newName = $name_entry
        Rename-Computer -NewName $newName -Force
        Write-Host "Computer has been renamed to $newName and will now restart." -ForegroundColor Green
        New-ItemProperty -Path "HKCU:\Software\Test" -Name "ScriptState" -Value "Renamed" -Force
        Start-Sleep -Seconds 3
}
else {
    Write-Host "Computer name is already in the correct format. No action taken." -ForegroundColor Yellow
    New-ItemProperty -Path "HKCU:\Software\Test" -Name "ScriptState" -Value "NoRenameNeeded" -Force
    Start-Sleep -Seconds 3
}