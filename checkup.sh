#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/_functions.sh)

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
    echoLOG y "Start full update Host Server"
    updateHost
    echoLOG g "Full Hostupdate done"
    menuMAIN
  elif [[ $menuSelection == "2" ]]; then
    echoLOG y "Start full update Host Server"
    updateHost
    echoLOG g "Full Hostupdate done"
    echoLOG y "Start updating Container"
    #update "all"
    echoLOG g "All Containerupdates done"
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
    echoLOG y "one moment please, while finishing script"
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

# if no-subscription is not enabled, the first run is performed
if [ ! -f "/etc/apt/sources.list.d/pve-no-subscription.list" ]; then firstRUN; fi

# check if this script has already configured this system
if [ -f "/root/.iThieler" ]; then
  birth=$(stat .iThieler | grep "Birth" | cut -d' ' -f3,4,5)
  echoLOG b "Global configuration almost done at >> ${birth}"
  menuMAIN
else
  bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/global-config-file.sh)
fi
