#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/_functions.sh)
source "/root/pve-global-config.sh"
if [[ $1 == "checkup" ]]; then goback=true; fi

function menu() {
  sel=("1" "I want create LXC ..." \
       "2" "I want create KVM ..." \
       "" "" \
       "Q" "I want to exit/going back!")
  menuSelection=$(whiptail --menu --backtitle "© 2021 - iThieler's Proxmox Script collection" --title " DO CREATE " "\nWhat do you want to create?" 0 80 0 "${sel[@]}" 3>&1 1>&2 2>&3)
  if [ $? -eq 1 ]; then echoLOG r "Aborting by user"; exit 1; fi

  if [[ $menuSelection == "1" ]]; then
    echoLOG b "Select >> I want create LXC ..."
    menu
  elif [[ $menuSelection == "2" ]]; then
    echoLOG b "Select >> I want create KVM ..."
    menu
  elif [[ $menuSelection == "Q" ]]; then
    echoLOG b "Select >> I want to exit/going back!"
    if [ "$goback" != true ]; then cleanup; fi
    exit 0
  else
    menu
  fi
}
 
menu
