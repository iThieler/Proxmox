#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/_functions.sh)
source "/root/pve-global-config.sh"

if [ $(pct list | grep -c 1.*) -eq 0 ] && [ $(qm list | grep -c 2.*) -eq 0 ] ; then
  whip_alert "DO BACKUP" "No containers or virtual machines were found. There is nothing from which a backup could be created."
  exit 1
fi

if [ -d "/mnt/pve/backups/dump/manual/" ]; then
  whip_alert "DO BACKUP" "Manual backups were found, click OK to delete them and create new ones. If you want to keep the existing ones, you have to backup them manually before clicking OK.\nBackups that were created automatically will of course be kept."
  rm -r "/mnt/pve/backups/dump/manual/"
fi

if [ -n "$nasIP" ]; then
  bakdir="/mnt/pve/backups/dump/manual"
  mkdir -p $bakdir
  if whip_yesno "ALL" "SELECT" "DO BACKUP" "Do you want to backup all containers and virtual machines, or select individual ones?"; then
    #Backup all
    whip_message "DO BACKUP" "To ensure the highest possible backup quality, the respective guest system is shut down."
    for ctID in $(pct list | sed '1d' | awk '{print $1}'); do
      pct stop $ctID
      while [ $(pct status $ctID | cut -d' ' -f2 | grep -cw running) -eq 1 ]; do
        sleep 2
      done
      name=$(pct list | sed '1d' | awk '{print $3}')
      if vzdump ${ctID} --dumpdir ${bakdir} --mode stop --compress zstd --notes-template '{{guestname}}' --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
        echoLOG g "Backup >> $ctID - $name"
      else
        echoLOG r "Backup >> $ctID - $name"
      fi
      pct start $ctID
    done
    for kvmID in $(qm list | sed '1d' | awk '{print $1}'); do
      qm stop $kvmID
      if vzdump ${kvmID} --dumpdir ${bakdir} --mode stop --compress zstd --notes-template '{{guestname}}' --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
        echoLOG g "Backup >> $kvmID - $name"
      else
        echoLOG r "Backup >> $kvmID - $name"
      fi
      qm start $kvmID
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
