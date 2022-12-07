#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/_functions.sh)

function headerLOGO() {
  echo -e "
  _ _____ _    _     _         _      ___                                        _      _            _ _        _   _          
 (_)_   _| |_ (_)___| |___ _ _( )___ | _ \_ _ _____ ___ __  _____ __  ___ __ _ _(_)_ __| |_   __ ___| | |___ __| |_(_)___ _ _  
 | | | | | ' \| / -_) / -_) '_|/(_-< |  _/ '_/ _ \ \ / '  \/ _ \ \ / (_-</ _| '_| | '_ \  _| / _/ _ \ | / -_) _|  _| / _ \ ' \ 
 |_| |_| |_||_|_\___|_\___|_|   /__/ |_| |_| \___/_\_\_|_|_\___/_\_\ /__/\__|_| |_| .__/\__| \__\___/_|_\___\__|\__|_\___/_||_|
                                                                                  |_|                                          
"
}

function firstRUN() {
  whip_message "SYSTEM PREPARATION" "This Script runs for the first Time. Proxmox is checked for system updates, possibly required software will be installed. This will take a while."
  echoLOG y "starting system preparation"
  sed -i "s/^deb/#deb/g" /etc/apt/sources.list.d/pve-enterprise.list
  cat <<EOF > /etc/apt/sources.list
    deb http://ftp.debian.org/debian bullseye main contrib
    deb http://ftp.debian.org/debian bullseye-updates main contrib
    deb http://security.debian.org/debian-security bullseye-security main contrib
EOF
  cat <<EOF >> /etc/apt/sources.list.d/pve-no-subscription.list
    deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription
EOF
  echo "DPkg::Post-Invoke { \"dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\.js$'; if [ \$? -eq 1 ]; then { echo 'Removing subscription nag from UI...'; sed -i '/data.status/{s/\!//;s/Active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; }; fi\"; };" > /etc/apt/apt.conf.d/no-nag-script
  apt --reinstall install proxmox-widget-toolkit &>/dev/null

  apt-get update 2>&1 >/dev/null
  if apt-get install -y parted smartmontools libsasl2-modules mailutils lxc-pve 2>&1 >/dev/null; then
    echoLOG g "install needed Software"
  else
    echoLOG r "install needed Software"
  fi

  if updateHost; then
    echoLOG g "initial Systemupdate"
  else
    echoLOG r "initial Systemupdate"
  fi

  echoLOG g "system preparation finished"
}

function menu() {
  sel=("1" "I want to update ..." \
       "2" "I want to backup ..." \
       "3" "I want to restore ..." \
       "4" "I want to create ..." \
       "5" "I want to delete ..." \
       "6" "I want to passthrough ..." \
       "" "" \
       "Q" "I want to exit and clean up!")
  menuSelection=$(whiptail --menu --nocancel --backtitle "© 2021 - iThieler's Proxmox Script collection" --title " CONFIGURING PROXMOX " "\nWhat do you want to do?" 20 80 10 "${sel[@]}" 3>&1 1>&2 2>&3)

  if [[ $menuSelection == "1" ]]; then
    echoLOG b "Select >> I want to update ..."
    bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/helper/do-update.sh) checkup
    menu
  elif [[ $menuSelection == "2" ]]; then
    echoLOG b "Select >> I want to backup ..."
    bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/helper/do-backup.sh) checkup
    menu
  elif [[ $menuSelection == "3" ]]; then
    echoLOG b "Select >> I want to restore ..."
    bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/helper/do-restore.sh) checkup
    menu
  elif [[ $menuSelection == "4" ]]; then
    echoLOG b "Select >> I want to create ..."
    bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/helper/do-create.sh) checkup
    menu
  elif [[ $menuSelection == "5" ]]; then
    echoLOG b "Select >> I want to delete ..."
    bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/helper/do-delete.sh) checkup
    menu
  elif [[ $menuSelection == "6" ]]; then
    echoLOG b "Select >> I want to passthrough ..."
    bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/helper/do-passthrough.sh) checkup
    menu
  elif [[ $menuSelection == "Q" ]]; then
    echoLOG b "Select >> I want to exit and clean up!"
    echoLOG y "one moment please, while finishing script"
    cleanup
    exit 0
  else
    menu
  fi
}

# loads whiptail color sheme
if [ -f ~/.iThielers_NEWT_COLORS ]; then
  export NEWT_COLORS_FILE=~/.iThielers_NEWT_COLORS
else
  echoLOG b "no CI-Files found"
  if wget -q https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/newt_colors_file.txt -O ~/.iThielers_NEWT_COLORS; then
    echoLOG g "download normal mode CI-File"
    export NEWT_COLORS_FILE=~/.iThielers_NEWT_COLORS
  else
    echoLOG r "download normal mode CI-File"
  fi
  if wget -q https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/newt_colors_alert_file.txt -O ~/.iThielers_NEWT_COLORS_ALERT; then
    echoLOG g "download alert mode CI-File"
  else
    echoLOG r "download alert mode CI-File"
  fi
fi

clear
headerLOGO

# Check Proxmox
if ! command -v pveversion >/dev/null 2>&1; then
  whip_alert "CHECKUP" "No Proxmox detected, Wrong Script!"
  exit 1
fi

# Checks the PVE MajorRelease
pve_majorversion=$(pveversion | cut -d/ -f2 | cut -d. -f1)
if [ "$pve_majorversion" -lt 7 ]; then
  whip_alert "CHECKUP" "This script works only on servers with Proxmox version 7.X\nYour Prxmox version: ${pve_majorversion}"
  exit 1
fi

# if no-subscription is not enabled, the first run is performed
if [ ! -f "/etc/apt/sources.list.d/pve-no-subscription.list" ]; then firstRUN; fi

# check if this script has already configured this system
if [ -f "/root/.iThieler" ]; then
  birth=$(stat .iThieler | grep "Birth" | cut -d' ' -f3,4,5)
  echoLOG b "Global configuration almost done at >> ${birth}"
  menu
else
  bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/global-config-file.sh)
fi
