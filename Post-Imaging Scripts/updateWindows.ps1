function checkWindowsUpdates {
    Write-Host "Checking for Windows Updates..." -ForegroundColor Cyan
    $Updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
    if ($Updates) {
        Write-Host "Installing Windows Updates..." -ForegroundColor Green
        $Updates | Install-WindowsUpdate -AcceptAll -AutoReboot -Confirm:$false -ForceInstall
    } else {
        Write-Host "No updates available." -ForegroundColor Yellow
        New-ItemProperty -Path "HKCU:\Software\Test" -Name "ScriptState" -Value "WindowsUpdatesComplete" -Force
    }
}

checkWindowsUpdates # Call the function to check and install Windows updates