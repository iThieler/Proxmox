#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/_functions.sh)
source "/root/pve-global-config.sh"
if [[ $1 == "checkup" ]]; then goback=true; fi

function menu() {
  sel=("1" "I want to select ..." \
       "2" "I want all ..." \
       "" "" \
       "Q" "I want to exit/going back!")
  menuSelection=$(whiptail --menu --backtitle "© 2021 - iThieler's Proxmox Script collection" --title " DO BACKUP " "\nWhat do you want to restore?" 0 80 0 "${sel[@]}" 3>&1 1>&2 2>&3)
  if [ $? -eq 1 ]; then echoLOG r "Aborting by user"; exit 1; fi

  if [[ $menuSelection == "1" ]]; then
    echoLOG b "Select >> I want to select ..."
    if [ -f /tmp/list.sh ]; then rm /tmp/list.sh; fi
    echo -e '#!/bin/bash\n\nlist=( \\' > /tmp/list.sh
    for file in $(ls /mnt/pve/backups/dump/manual/ | grep 'tar\|vma'); do
      echo -e "\"$(echo $file | cut -d. -f1 | cut -d- -f1)\" \""$(echo $file | cut -d. -f1 | cut -d- -f2)"\" off \\" >> /tmp/list.sh
    done
    echo -e ')' >> /tmp/list.sh

    source /tmp/list.sh
    choice=$(whiptail --checklist --nocancel --backtitle "© 2021 - iThieler's Proxmox Script collection" --title " DO BACKUP " "\nSelect the backups you want to restore" 0 80 0 "${list[@]}" 3>&1 1>&2 2>&3 | sed 's#"##g')

    for selection in $choice; do
      guestname=$(cat /tmp/list.sh | sed 's/\"//g' | grep ${selection} | awk '{print $2}')
      if [ -f "/mnt/pve/backups/dump/manual/${selection}-${guestname}.tar.zst" ]; then
        if [ $(pct list | grep -c ${selection}) -eq 1 ] || [ $(pct list | grep -c ${selection}) -eq 1 ]; then
          if whip_yesno "OVERWRITE" "NEW ID" "DO RESTORE" "The machine you want to restore already exists, do you want to overwrite it or choose a new ID?"; then
            if pct restore ${selection} "/mnt/pve/backups/dump/manual/${selection}-${guestname}.tar.zst" --storage $(pvesm status --content images,rootdir | grep active | awk '{print $1}') --pool "BackupPool" --force 1 > /dev/null 2>&1; then
              echoLOG g "Restore >> $selection - $guestname"
            else
              echoLOG r "Restore >> $selection - $guestname"
            fi
          else
            newID=$(whip_inputbox "OK" "DO RESTORE" "Which unique ID should be used?")
            if [[ $newID == "" ]]; then newID=$(whip_alert_inputbox "OK" "DO RESTORE" "Which unique ID should be used?"); fi
            newNAME=$(whip_inputbox "OK" "DO RESTORE" "Which unique hostname should be used?")
            if [[ $newNAME == "" ]]; then newNAME=$(whip_alert_inputbox "OK" "DO RESTORE" "Which unique hostname should be used?"); fi
            if pct restore ${newID} --hostname ${newNAME} "/mnt/pve/backups/dump/manual/${selection}-${guestname}.tar.zst" --storage $(pvesm status --content images,rootdir | grep active | awk '{print $1}') --pool "BackupPool" > /dev/null 2>&1; then
              echoLOG g "Restore >> $newID - $newNAME"
            else
              echoLOG r "Restore >> $newID - $newNAME"
            fi
          fi
        fi
      elif [ -f "/mnt/pve/backups/dump/manual/${selection}-${guestname}.vma.zst" ]; then
        if [ $(qm list | grep -c ${selection}) -eq 1 ]; then
          if whip_yesno "OVERWRITE" "CANCEL" "DO RESTORE" "The machine you want to restore already exists. Do you want to overwrite it?"; then
            if qmrestore ${selection} "/mnt/pve/backups/dump/manual/${selection}-${guestname}.vma.zst" --storage $(pvesm status --content images,rootdir | grep active | awk '{print $1}') --pool "BackupPool" --force 1 > /dev/null 2>&1; then
              echoLOG g "Restore >> $selection - $guestname"
            else
              echoLOG r "Restore >> $selection - $guestname"
            fi
          fi
        fi
      fi
    done
    rm /tmp/list.sh
    menu
  elif [[ $menuSelection == "2" ]]; then
    echoLOG b "Select >> I want all ..."
    for file in $(ls /mnt/pve/backups/dump/manual/ | grep 'tar\|vma'); do
      guestID=$(echo $file | cut -d. -f1 | cut -d- -f1)
      guestname=$(echo $file | cut -d. -f1 | cut -d- -f2)
      if [ $(echo $file | grep -c tar) -eq 1 ]; then
        if whip_yesno "OVERWRITE" "NEW ID" "DO RESTORE" "The machine you want to restore already exists, do you want to overwrite it or choose a new ID?"; then
          if pct restore ${guestID} "/mnt/pve/backups/dump/manual/${guestID}-${guestname}.tar.zst" --storage $(pvesm status --content images,rootdir | grep active | awk '{print $1}') --pool "BackupPool" --force 1 > /dev/null 2>&1; then
            echoLOG g "Restore >> $guestID - $guestname"
          else
            echoLOG r "Restore >> $guestID - $guestname"
          fi
        else
          newID=$(whip_inputbox "OK" "DO RESTORE" "Which unique ID should be used?")
          if [[ $newID == "" ]]; then newID=$(whip_alert_inputbox "OK" "DO RESTORE" "Which unique ID should be used?"); fi
          newNAME=$(whip_inputbox "OK" "DO RESTORE" "Which unique hostname should be used?")
          if [[ $newNAME == "" ]]; then newNAME=$(whip_alert_inputbox "OK" "DO RESTORE" "Which unique hostname should be used?"); fi
          if pct restore ${newID} --hostname ${newNAME} "/mnt/pve/backups/dump/manual/${guestID}-${guestname}.tar.zst" --storage $(pvesm status --content images,rootdir | grep active | awk '{print $1}') --pool "BackupPool" > /dev/null 2>&1; then
            echoLOG g "Restore >> $newID - $newNAME"
          else
            echoLOG r "Restore >> $newID - $newNAME"
          fi
        fi
      elif [ $(echo $file | grep -c vma) -eq 1 ]; then
        if [ $(qm list | grep -c ${guestID}) -eq 1 ]; then
          if whip_yesno "OVERWRITE" "CANCEL" "DO RESTORE" "The machine you want to restore already exists. Do you want to overwrite it?"; then
            if qmrestore ${guestID} "/mnt/pve/backups/dump/manual/${guestID}-${guestname}.vma.zst" --storage $(pvesm status --content images,rootdir | grep active | awk '{print $1}') --pool "BackupPool" --force 1 > /dev/null 2>&1; then
              echoLOG g "Restore >> $guestID - $guestname"
            else
              echoLOG r "Restore >> $guestID - $guestname"
            fi
          fi
        fi
      fi
    done
    menu
  elif [[ $menuSelection == "Q" ]]; then
    echoLOG b "Select >> I want to exit/going back!"
    if [ "$goback" != true ]; then cleanup; fi
    exit 0
  else
    menu
  fi
}

if [ -n "$nasIP" ]; then
  if [ ! -d "/mnt/pve/backups/dump/manual/" ]; then
    whip_alert "DO RESTORE" "No manual backups were found.\nIf you want to restore an automatically created backup, please use the Proxmox web interface."
    exit 1
  fi
  menu
else
  whip_alert "DO RESTORE" "This function is only available if a NAS has been mounted as a backup drive with the main script."
  exit 1
fi
