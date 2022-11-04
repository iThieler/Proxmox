#!/bin/bash

# Function checked if an Package is installed, returned true or false
function check_pkg() {
  if [ $(dpkg-query -s "${1}" &> /dev/null | grep -cw "Status: install ok installed") -eq 1 ]; then
    true
  else
    false
  fi
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
configFILE="/root/pve-global-config.sh"

if [ -d "/root/Proxmox" ]; then
  rm -r "/root/Proxmox"
fi

if [ ! -f "/root/.iThieler" ]; then
  git clone https://github.com/iThieler/Proxmox.git
  bash "/root/Proxmox/misc/global-config-file.sh" "$configFILE"
else
  echo "Configuration done"
fi
