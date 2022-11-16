#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/_functions.sh)
source "/root/pve-global-config.sh"

function menu() {
  sel=("1" "I want to select ..." \
       "2" "I want the Proxmox server ..." \
       "3" "I want all LXC ..." \
       "3" "I want all ..." \
       "" "" \
       "Q" "I want to exit/going back!")
  menuSelection=$(whiptail --menu --backtitle "© 2021 - iThieler's Proxmox Script collection" --title " DO UPDATE " "\nWhat do you want to update?" 0 80 0 "${sel[@]}" 3>&1 1>&2 2>&3)
  if [ $? -eq 1 ]; then echoLOG r "Aborting by user"; exit 1; fi

  if [[ $menuSelection == "1" ]]; then
    echoLOG b "Select >> I want to select ..."
    if [ -f /tmp/list.sh ]; then rm /tmp/list.sh; fi
    echo -e '#!/bin/bash\n\nlist=( \\' > /tmp/list.sh
    echo -e "\"000\" \""HOST - Proxmox Server"\" off \\" >> /tmp/list.sh
    for lxc in $(pct list | sed '1d' | awk '{print $1}'); do
      echo -e "\"${lxc}\" \""CT - $(pct list | grep ${lxc} | awk '{print $3}')"\" off \\" >> /tmp/list.sh
    done
    echo -e ')' >> /tmp/list.sh

    source /tmp/list.sh
    choice=$(whiptail --checklist --nocancel --backtitle "© 2021 - iThieler's Proxmox Script collection" --title " DO UPDATE " "\nSelect the machines you want to update?" 20 80 10 "${list[@]}" 3>&1 1>&2 2>&3 | sed 's#"##g')

    for selection in $choice; do
      name=$(pct list | grep ${choosed_guest} | awk '{print $3}')
      if [[ $selection == "000" ]]; then
        if updateHost; then
          echoLOG g "Update Proxmox Server"
        else
          echoLOG r "Update Proxmox Server"
        fi
      else
        echoLOG b "Update operating system only >> $selection - $name"
        pct exec $selection -- bash -ci "apt-get update >/dev/null 2>&1"
        pct exec $selection -- bash -ci "apt-get upgrade -y >/dev/null 2>&1"
        pct exec $selection -- bash -ci "apt-get dist-upgrade -y >/dev/null 2>&1"
        pct exec $selection -- bash -ci "apt-get autoremove -y >/dev/null 2>&1"
      fi
    menu
  elif [[ $menuSelection == "2" ]]; then
    echoLOG b "Select >> I want the Proxmox server ..."
    if updateHost; then
      echoLOG g "Update Proxmox Server"
    else
      echoLOG r "Update Proxmox Server"
    fi
    menu
  elif [[ $menuSelection == "3" ]]; then
    echoLOG b "Select >> I want all LXC ..."
    whip_message "DO UPDATE" "Only enabled containers will be updated."
    for lxc in $(pct list | sed '1d' | awk '{print $1}'); do
      name=$(pct list | grep ${lxc} | awk '{print $3}')
      if [ $(pct list | grep ${lxc} | grep -c running) -eq 1 ]; then
        echoLOG b "Update operating system only >> $lxc - $name"
        pct exec $selection -- bash -ci "apt-get update >/dev/null 2>&1"
        pct exec $selection -- bash -ci "apt-get upgrade -y >/dev/null 2>&1"
        pct exec $selection -- bash -ci "apt-get dist-upgrade -y >/dev/null 2>&1"
        pct exec $selection -- bash -ci "apt-get autoremove -y >/dev/null 2>&1"
      fi
    done
    menu
  elif [[ $menuSelection == "4" ]]; then
    echoLOG b "Select >> I want all ..."
    if updateHost; then
      echoLOG g "Update Proxmox Server"
    else
      echoLOG r "Update Proxmox Server"
    fi
    whip_message "DO UPDATE" "Only enabled containers will be updated."
    for lxc in $(pct list | sed '1d' | awk '{print $1}'); do
      name=$(pct list | grep ${lxc} | awk '{print $3}')
      if [ $(pct list | grep ${lxc} | grep -c running) -eq 1 ]; then
        echoLOG b "Update operating system only >> $lxc - $name"
        pct exec $selection -- bash -ci "apt-get update >/dev/null 2>&1"
        pct exec $selection -- bash -ci "apt-get upgrade -y >/dev/null 2>&1"
        pct exec $selection -- bash -ci "apt-get dist-upgrade -y >/dev/null 2>&1"
        pct exec $selection -- bash -ci "apt-get autoremove -y >/dev/null 2>&1"
      fi
    done
    menu
  elif [[ $menuSelection == "Q" ]]; then
    echoLOG b "Select >> I want to exit/going back!"
    cleanup
    exit 0
  else
    menu
  fi
}

menu
