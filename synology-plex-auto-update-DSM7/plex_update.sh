#!/bin/bash

# Author: @loicdugay https://github.com/loicdugay
# Link: https://github.com/loicdugay/synology-plex-auto-update
#
# Thanks to:
# @mj0nsplex https://forums.plex.tv/u/j0nsplex
# @martinorob https://github.com/martinorob/plexupdate
# @michealespinola https://github.com/michealespinola/syno.plexupdate

# Checking for script running as root
if [ "$EUID" -ne "0" ];
  then
    printf " %s\n" "This script must be run with root persmissions."
    /usr/syno/bin/synonotify PKGHasUpgrade '{"%PKG_HAS_UPDATE%": "Plex Media Server automatic update script failed.\n\nThis script must be run with root permissions."}'
    printf "\n"
    exit 1
fi

# Checking the version of DSM
DSMVersion=$(cat /etc.defaults/VERSION | grep -i 'majorversion=' | cut -d"\"" -f 2)
/usr/bin/dpkg --compare-versions 7 gt "$DSMVersion"
if [ "$?" -eq "0" ];
  then
    printf " %s\n" "This script requires DSM 7 to be installed."
    /usr/syno/bin/synonotify PKGHasUpgrade '{"%PKG_HAS_UPDATE%": "Plex Media Server automatic update script failed.\n\nThe script requires DSM 7 to be installed."}'
    printf "\n"
    exit 1
fi

# Finding the Plex Media Server version
mkdir -p /tmp/plex/ > /dev/null 2>&1
token=$(cat /volume1/@apphome/PlexMediaServer/Plex\ Media\ Server/Preferences.xml | grep -oP 'PlexOnlineToken="\K[^"]+')
url=$(echo "https://plex.tv/api/downloads/5.json?channel=plexpass&X-Plex-Token=$token")
jq=$(curl -s ${url})
newversion=$(echo $jq | jq -r '.nas."Synology (DSM 7)".version')
newversion=$(echo $newversion | grep -oP '^.+?(?=\-)')
curversion=$(synopkg version "PlexMediaServer")
curversion=$(echo $curversion | grep -oP '^.+?(?=\-)')

echo Version available : $newversion
echo Version installed : $curversion

if [ "$newversion" != "$curversion" ]
  then
    echo New version available, installation in progress. :
    CPU=$(uname -m)
    url=$(echo "${jq}" | jq -r '.nas."Synology (DSM 7)".releases[] | select(.build=="linux-'"${CPU}"'") | .url')
    /bin/wget $url -P /tmp/plex/
    /usr/syno/bin/synopkg install /tmp/plex/*.spk
    sleep 30
    /usr/syno/bin/synopkg start "PlexMediaServer"
    rm -rf /tmp/plex/*
    /usr/syno/bin/synonotify PKGHasUpgrade '{"%PKG_HAS_UPDATE%": "Plex Media Server automatic update script installed to the latest available version."}'
  else
    echo No new version to install.
fi
exit