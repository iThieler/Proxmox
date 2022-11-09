#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/_functions.sh)

function menuMAIN() {
  sel=("1" "... update my HomeServer" \
       "2" "... update my HomeServer and all containers" \
       "3" "... install and configure containers" \
       "4" "... install and configure virtual machine(s)" \
       "5" "... create a backup of one or more guest systems" \
       "6" "... restore one or more guest systems from backup" \
       "7" "... delete one or more containers" \
       "8" "... delete one or more virtual machine(s)" \
       "" "" \
       "Q" "... exit and clean up")
  menuSelection=$(whiptail --menu --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " CONFIGURING PROXMOX " "\nWhat do you want to do?" 20 80 10 "${sel[@]}" 3>&1 1>&2 2>&3)

  if [[ $menuSelection == "1" ]]; then
    #update "server"
    menuMAIN
  elif [[ $menuSelection == "2" ]]; then
    #update "all"
    menuMAIN
  elif [[ $menuSelection == "3" ]]; then
    #install "LXC"
    menuMAIN
  elif [[ $menuSelection == "4" ]]; then
    #install "VM"
    menuMAIN
  elif [[ $menuSelection == "5" ]]; then
    if whip_yesno "ALL" "SELECT" "BACKUP GUEST SYSTEMS" "Do you want to back up all containers and virtual machines, or select individual ones?"; then
      #backuprestore "backup" "all"
      menuMAIN
    else
      #backuprestore "backup" "select"
      menuMAIN
    fi
    menuMAIN
  elif [[ $menuSelection == "6" ]]; then
    #backuprestore "restore" "all"
    menuMAIN
  elif [[ $menuSelection == "7" ]]; then
    #delete "LXC"
    menu
  elif [[ $menuSelection == "8" ]]; then
    #delete "VM"
    menuMAIN
  elif [[ $menuSelection == "Q" ]]; then
    #finish
    exit 0
  else
    menuMAIN
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
if ! checkPKG "git"; then
  apt update &>/dev/null
  apt install -y git &>/dev/null
fi

# Start the script
gitREPONAME="Proxmox"

if [ -d "/root/${gitREPONAME}" ]; then
  rm -r "/root/${gitREPONAME}"
fi

if [ -f "/root/.iThieler" ]; then
  birth=$(stat .iThieler | grep "Birth" | cut -d' ' -f3,4,5)
  echo -e "$(date +'%Y-%m-%d  %T')  [\033[1;31mERROR\033[0m]  Configuration almost done at >> ${birth}"
  menuMAIN
else
  bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/global-config-file.sh) "/root/pve-global-config.sh"
fi
