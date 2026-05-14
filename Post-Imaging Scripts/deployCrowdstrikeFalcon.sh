#!/bin/bash

# This script checks to see if Crowdstrike Falcon or Sophos antivirus is installed on macOS.
# If Sophos is found, the script will exit with an error prompting to uninstall or automate the uninstall.
# If Crowdstrike Falcon is found, the script will complete as the antivirus is already installed.
# If neither is found, the script will proceed with the installation of Crowdstrike Falcon.

# Function to check if a specific application is installed
is_installed() {
    local app_name="$1"
    if mdfind "kMDItemCFBundleIdentifier == '$app_name'" | grep -q .; then
        return 0
    else
        return 1
    fi
}

# Check for Sophos antivirus
if is_installed "com.sophos.endpoint"; then
    echo "Sophos antivirus is installed. Please uninstall it before proceeding."
    exit 1
fi

# Check for Crowdstrike Falcon
if is_installed "com.crowdstrike.falcon.Agent"; then
    echo "Crowdstrike Falcon is already installed. No further action required."
    exit 0
fi

# Proceed with the installation of Crowdstrike Falcon
echo "Crowdstrike Falcon is not installed. Proceeding with installation..."

# Mount the network share to access the installer
read -p "Enter your AD username: " username
mkdir -p /Volumes/mountdrive
mount_smbfs //$username@[REDACTED] /Volumes/mountdrive

# Copy the Falcon installer to a temporary location
cp /Volumes/mountdrive/FalconSensor/FalconSensorMacOS.pkg /tmp/FalconSensorMacOS.pkg

# Unmount the network share
umount /Volumes/mountdrive

echo "Installing Crowdstrike Falcon..."

# Run the installer
sudo installer -pkg /tmp/FalconSensorMacOS.pkg -target /

echo "Installation complete."

/Applications/Falcon.app/Contents/Resources/falconctl license [REDACTED]
/Applications/Falcon.app/Contents/Resources/falconctl grouping-tags set [REDACTED]

echo "Crowdstrike Falcon has been successfully installed and configured."

exit 0