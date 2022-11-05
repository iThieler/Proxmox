#!/bin/bash

# Function checked if an Package is installed, returned true or false
function check_pkg() {
  if [ $(dpkg-query -s "${1}" &> /dev/null | grep -cw "Status: install ok installed") -eq 1 ]; then
    true
  else
    false
  fi
}

function cloneGIT() {
  local repo=$1
  if [ -z "$2" ]; then
    local user="iThieler"
  else
    local user=$2
  fi
  git clone "https://github.com/${user}/${repo}.git" &>/dev/null
  #for file in `find "/root/Proxmox" -name '*.sh' -o -regex './s?bin/[^/]+' -o -regex './usr/sbin/[^/]+' -o -regex './usr/lib/[^/]+'`; do
  #  chmod +x  $file
  #done 
}

# Check Proxmox
if ! command -v pveversion >/dev/null 2>&1; then
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
    whiptail --textbox --backtitle "© 2021 - SmartHome-IoT.net" --title " CHECKUP " "\nNo Proxmox detected, Wrong Script!" 10 80
  exit 1
fi

# Checks the PVE MajorRelease
pve_majorversion=$(pveversion | cut -d/ -f2 | cut -d. -f1)
if [ "$pve_majorversion" -lt 7 ]; then
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
    whiptail --textbox --backtitle "© 2021 - SmartHome-IoT.net" --title " CHECKUP " "\nThis script works only on servers with Proxmox version 7.X\nYour Prxmox version: ${pve_majorversion}" 10 80
  exit 1
fi

# Checks if git package is installed
if ! check_pkg "git"; then
  apt update &>/dev/null
  apt install -y git &>/dev/null
fi

# Start the script
gitREPONAME="Proxmox"
configFILE="/root/pve-global-config.sh"

if [ -d "/root/${gitREPONAME}" ]; then
  rm -r "/root/${gitREPONAME}"
fi

if [ -f "/root/.iThieler" ]; then
  birth=$(stat .iThieler | grep "Birth" | cut -d' ' -f3,4,5)
  echo -e "$(date +'%Y-%m-%d  %T')  [\033[1;31mERROR\033[0m]  Configuration almost done at >> ${birth}"
else
  cloneGIT "${gitREPONAME}"
  cd "/root/${gitREPONAME}"
  bash "misc/global-config-file.sh" "$configFILE"
fi
