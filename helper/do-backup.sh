#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/_functions.sh)
source "/root/pve-global-config.sh"

function menu() {
  sel1=("1" "I want to select ..." \
       "2" "I want only running ..." \
       "3" "I want only stopped ..." \
       "4" "I want all LXC ..." \
       "5" "I want all KVM ..." \
       "6" "I want all ..." \
       "" "" \
       "Q" "I want to exit / going back!")
  menuSelection=$(whiptail --menu --nocancel --backtitle "© 2021 - iThieler's Proxmox Script collection" --title " DO BACKUP " "\nWhat do you want to do?" 20 80 10 "${sel[@]}" 3>&1 1>&2 2>&3)

  if [[ $menuSelection == "1" ]]; then
    echoLOG b "Select >> I want to select ..."
    if [ -f /tmp/list.sh ]; then rm /tmp/list.sh; fi
    echo -e '#!/bin/bash\n\nlist=( \\' > /tmp/list.sh
    for lxc in $(pct list | sed '1d' | awk '{print $1}'); do
      echo -e "\"${lxc}\" \""CT - $(pct list | grep ${lxc} | awk '{print $3}')"\" off \\" >> /tmp/list.sh
    done
    for vm in $(qm list | sed '1d' | awk '{print $1}'); do
      echo -e "\"${vm}\" \""VM - $(qm list | grep ${vm} | awk '{print $2}')"\" off \\" >> /tmp/list.sh
    done
    echo -e ')' >> /tmp/list.sh

    source /tmp/list.sh
    var_guestchoice=$(whiptail --checklist --nocancel --backtitle "© 2021 - iThieler's Proxmox Script collection" --title " DO BACKUP " "\nSelect the machines from which you want to create a backup?" 20 80 10 "${list[@]}" 3>&1 1>&2 2>&3 | sed 's#"##g')

    for choosed_guest in $var_guestchoice; do
      if [ $(pct list | grep -c $choosed_guest) -eq 1 ]; then
        pct shutdown ${choosed_guest} --forceStop 1 --timeout 10 > /dev/null 2>&1
        while [ $(pct status $ctID | cut -d' ' -f2 | grep -c running) -eq 1 ]; do
          sleep 2
        done
      elif [ $(qm list | grep -c $choosed_guest) -eq 1 ]; then
        qm shutdown ${choosed_guest} --forceStop 1 --timeout 30 > /dev/null 2>&1
        while [ $(qm status $ctID | cut -d' ' -f2 | grep -c running) -eq 1 ]; do
          sleep 2
        done
      fi
      if vzdump ${choosed_guest} --dumpdir /mnt/pve/backups/dump/manual --mode stop --compress zstd --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
        filename=$(ls -ldst /mnt/pve/backups/dump/manual/*-${choosed_guest}-*.*.zst | awk '{print $10}' | cut -d. -f1 | head -n1)
        if [ -f "${filename}.tar.zst" ]; then
          echo "" > ${filename}.tar.zst.notes
        else
          mv ${filename}.vma.zst ${filename}_manual.vma.zst
          echo "${txt_1108}  SmartHome-IoT.net" > ${filename}_manual.vma.zst.notes
        fi
        mv ${filename}.log ${filename}_manual.log
        echoLOG g "${txt_1106}"
      else
        echoLOG r "${txt_1107}"
      fi
      if [ $(pct list | grep -c $choosed_guest) -eq 1 ]; then
        pct start ${choosed_guest} > /dev/null 2>&1
      elif [ $(qm list | grep -c $choosed_guest) -eq 1 ]; then
        qm start ${choosed_guest} > /dev/null 2>&1
      fi
    done
    rm /tmp/list.sh
    menu
  elif [[ $menuSelection == "2" ]]; then
    echoLOG b "Select >> I want only running ..."
    bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/helper/do-backup.sh)
    menu
  elif [[ $menuSelection == "3" ]]; then
    echoLOG b "Select >> I want only stopped ..."
    bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/helper/do-restore.sh)
    menu
  elif [[ $menuSelection == "4" ]]; then
    echoLOG b "Select >> I want all LXC ..."
    bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/helper/do-create.sh)
    menu
  elif [[ $menuSelection == "5" ]]; then
    echoLOG b "Select >> I want all KVM ..."
    bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/helper/do-delete.sh)
    menu
  elif [[ $menuSelection == "6" ]]; then
    echoLOG b "Select >> I want all ..."
    bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/helper/do-passthrough.sh)
    menu
  elif [[ $menuSelection == "Q" ]]; then
    echoLOG b "Select >> I want to exit / going back!"
    echoLOG y "one moment please, while finishing script"
    #finish
    exit 0
  fi
}

if [ $(pct list | grep -c 1.*) -eq 0 ] && [ $(qm list | grep -c 2.*) -eq 0 ] ; then
  whip_alert "DO BACKUP" "No containers or virtual machines were found. There is nothing from which a backup could be created."
  exit 1
fi

if [ -d "/mnt/pve/backups/dump/manual/" ]; then
  whip_alert "DO BACKUP" "Manual backups were found. If you continue, these will be deleted and new ones created.\nThe daily automatically created backups will be kept."
  rm -r "/mnt/pve/backups/dump/manual/"
fi

echo "NASIP: $nasIP"

if [ -n "$nasIP" ]; then
  echo "halli Hallo Hallöle"
  mkdir -p "/mnt/pve/backups/dump/manual"
  menu
else
  whip_alert "DO BACKUP" "This function is only available if a NAS has been mounted as a backup drive with the main script."
  exit 1
fi




<<com
if [ -n "$nasIP" ]; then
  if whip_yesno "ALL" "SELECT" "DO BACKUP" "Do you want to backup all containers and virtual machines, or select individual ones?"; then
    #Backup all
    whip_message "DO BACKUP" "To ensure the highest possible backup quality, the respective guest system is shut down."
    for ctID in $(pct list | sed '1d' | awk '{print $1}'); do
      pct stop $ctID 2>&1 >/dev/null
      while [ $(pct status $ctID | cut -d' ' -f2 | grep -cw running) -eq 1 ]; do
        sleep 2
      done
      name=$(pct list | sed '1d' | awk '{print $3}')
      if vzdump ${ctID} --dumpdir ${bakdir} --mode stop --compress zstd --notes-template '{{guestname}}' --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
        echoLOG g "Backup >> $ctID - $name"
      else
        echoLOG r "Backup >> $ctID - $name"
      fi
      pct start $ctID 2>&1 >/dev/null
    done
    for kvmID in $(qm list | sed '1d' | awk '{print $1}'); do
      qm stop $kvmID 2>&1 >/dev/null
      if vzdump ${kvmID} --dumpdir ${bakdir} --mode stop --compress zstd --notes-template '{{guestname}}' --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
        echoLOG g "Backup >> $kvmID - $name"
      else
        echoLOG r "Backup >> $kvmID - $name"
      fi
      qm start $kvmID 2>&1 >/dev/null
    done
    exit 0
  else
    #backup selected
    exit 0
  fi
else
  whip_alert "DO BACKUP" "This function is only available if a NAS has been mounted as a backup drive with the main script."
  exit 1
fi
com
