#!/bin/bash

# Define the packages and their respective JSON URLs
APPS=(
    "proton-pass|https://proton.me/download/PassDesktop/linux/x64/version.json"
    "proton-mail|https://proton.me/download/mail/linux/version.json"
)

# Ask for root password upfront so it doesn't interrupt the installation loop later
if [ "$EUID" -ne 0 ]; then
    echo "Root privileges needed for installation. Please authenticate."
    sudo -v || exit 1
fi

for APP_DATA in "${APPS[@]}"; do
    # Split the string into variables
    IFS='|' read -r APP_NAME JSON_URL <<< "$APP_DATA"
    
    echo -e "\n----------------------------------------"
    echo "Checking updates for $APP_NAME..."
    
    JSON=$(curl -s "$JSON_URL")
    
    if [ -z "$JSON" ]; then
        echo "Error: Could not fetch JSON for $APP_NAME. Skipping."
        continue
    fi

    # Find the index of the first release marked as "Stable" (falls back to 0 if not found) # TODO: Fix this. Still pulling beta version.
    ReleaseIndex=$(echo "$JSON" | jq -r '.Releases | map(.CategoryName == "Stable") | index(true) // 0')

    # Get Version of the selected non-beta release
    AvailableVersion=$(echo "$JSON" | jq -r --argjson r "$ReleaseIndex" '.Releases[$r].Version')
    
    # Get currently installed version
    CurrentVersion=$(rpm -q --queryformat '%{VERSION}' "$APP_NAME" 2>/dev/null)

    # Determine if update is necessary
    if [ "$AvailableVersion" != "$CurrentVersion" ]; then
        echo "Upgrade/Install needed (Current: ${CurrentVersion:-None} -> Available: $AvailableVersion)"
        
        # Dynamically find the index for the RPM file type
        FileIndex=$(echo "$JSON" | jq -r --argjson r "$ReleaseIndex" '.Releases[$r].File | map(.Identifier == ".rpm (Fedora/RHEL)") | index(true)')

        # Fallback just in case the Proton Mail JSON uses a slightly different Identifier string than Pass
        if [ "$FileIndex" = "null" ] || [ -z "$FileIndex" ]; then
            FileIndex=$(echo "$JSON" | jq -r --argjson r "$ReleaseIndex" '.Releases[$r].File | map(.Url | test("\\.rpm$")) | index(true)')
        fi

        if [ "$FileIndex" = "null" ] || [ -z "$FileIndex" ]; then
            echo "No valid RPM file candidate found in JSON for $APP_NAME!"
            continue
        fi

        # Extract the download link and checksum
        DownloadLink=$(echo "$JSON" | jq -r --argjson r "$ReleaseIndex" --argjson f "$FileIndex" '.Releases[$r].File[$f].Url')
        ExpectedSum=$(echo "$JSON" | jq -r --argjson r "$ReleaseIndex" --argjson f "$FileIndex" '.Releases[$r].File[$f].Sha512CheckSum')
        
        filename=$(basename "$DownloadLink")
        echo "Downloading $filename..."
        wget -q -P /tmp "$DownloadLink"
        
        # Verify the checksum (using double space to strictly adhere to sha512sum formatting)
        if echo "$ExpectedSum  /tmp/$filename" | sha512sum --check --status; then
            echo "Checksum verified! Installing $AvailableVersion..."
            sudo dnf install -y "/tmp/$filename"
            rm -f "/tmp/$filename"
        else
            echo "Checksum Failure for $APP_NAME!"
            rm -f "/tmp/$filename"
            continue
        fi
    else
        echo "No upgrade required. Current version: $CurrentVersion"
    fi
done
