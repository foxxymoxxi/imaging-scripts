#!/bin/bash
# This script updates macOS and several common applications to their latest versions.
# Update Zoom
echo "Installing/Updating Zoom..."
curl -L -o Zoom.pkg https://zoom.us/client/latest/Zoom.pkg && sudo installer -pkg Zoom.pkg -target /
rm Zoom.pkg

# Update Microsoft Teams
echo "Installing/Updating Microsoft Teams..."
curl -L -o Teams.pkg https://go.microsoft.com/fwlink/p/?linkid=869428 && sudo installer -pkg Teams.pkg -target /
rm Teams.pkg

# Update Microsoft Office
echo "Installing/Updating Microsoft Office..."
curl -L -o Office.pkg https://go.microsoft.com/fwlink/?linkid=525133 && sudo installer -pkg Office.pkg -target /
rm Office.pkg

# Update Firefox
echo "Installing/Updating Firefox..."
curl -L -o Firefox.dmg https://download.mozilla.org/?product=firefox-latest&os=osx&lang=en-US && hdiutil attach Firefox.dmg
sudo cp -R /Volumes/Firefox/Firefox.app /Applications/
hdiutil detach /Volumes/Firefox
rm Firefox.dmg

# Update Google Chrome
echo "Installing/Updating Google Chrome..."
curl -L -o Chrome.dmg https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg && hdiutil attach Chrome.dmg
sudo cp -R "/Volumes/Google Chrome/Google Chrome.app" /Applications/
hdiutil detach "/Volumes/Google Chrome"
rm Chrome.dmg

# Update Microsoft Edge
echo "Installing/Updating Microsoft Edge..."
curl -L -o MicrosoftEdge.dmg https://go.microsoft.com/fwlink/?linkid=2069148 && hdiutil attach MicrosoftEdge.dmg
sudo cp -R "/Volumes/Microsoft Edge/Microsoft Edge.app" /Applications/
hdiutil detach "/Volumes/Microsoft Edge"
rm MicrosoftEdge.dmg

# Update VLC
echo "Installing/Updating VLC..."
curl -L -o VLC.dmg https://get.videolan.org/vlc/last/macOS/VLC.dmg && hdiutil attach VLC.dmg
sudo cp -R "/Volumes/VLC/VLC.app" /Applications/
hdiutil detach "/Volumes/VLC"
rm VLC.dmg

# Update macOS software
echo "Checking for macOS updates..."
sudo softwareupdate -i -a

echo "All software is up to date!"