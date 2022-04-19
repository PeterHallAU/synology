#!/bin/bash
# Description:  This script updates Plex Media Server to the latest version available.

# Check script is running as root
if [ "$EUID" -ne "0" ];
  then
    echo Error: This script must be run by root.
    exit 1
fi

# Check current version of DSM
dsm_version=$(cat /etc.defaults/VERSION | grep -i 'majorversion=' | cut -d"\"" -f 2)
/usr/bin/dpkg --compare-versions 7 gt "$dsm_version"
if [ "$?" -eq "0" ];
  then
    echo Error: This script requires DSM version 7.0.
    exit 1
fi

# Get latest version of Plex Media Server
mkdir -p /tmp/plex/ > /dev/null 2>&1
token=$(cat /volume1/PlexMediaServer/AppData/Plex\ Media\ Server/Preferences.xml | grep -oP 'PlexOnlineToken="\K[^"]+')
url=$(echo "https://plex.tv/api/downloads/5.json?channel=plexpass&X-Plex-Token=$token")
jq=$(curl -s ${url})
new_version=$(echo $jq | jq -r '.nas."Synology (DSM 7)".version' | grep -oP '^.+?(?=\-)')
installed_version=$(synopkg version "PlexMediaServer" | grep -oP '^.+?(?=\-)')

echo New version : $new_version
echo Current version : $installed_version

# Check current version of Plex Media Server is up to date
if [ "$new_version" != "$installed_version" ]
  then
    echo New version available! Installing... :
    cpu=$(uname -m)
    url=$(echo "${jq}" | jq -r '.nas."Synology (DSM 7)".releases[] | select(.build=="linux-'"${cpu}"'") | .url')
    /bin/wget $url -P /tmp/plex/
    /usr/syno/bin/synopkg install /tmp/plex/*.spk
    sleep 30
    /usr/syno/bin/synopkg start "PlexMediaServer"
    rm -rf /tmp/plex/*
  else
    echo Current version up to date! Skipping...
fi
exit
