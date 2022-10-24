#!/bin/bash

source $(dirname "$0")/misc//basic-functions.sh
source $(dirname "$0")/misc/whiptail-functions.sh
if [ -f /root/pve-global-config.sh ]; then
  source /root/pve-global-config.sh
else
  bash ./global-config-file.sh
fi

# mount NAS as Backupstorage in Proxmox
if check_ip "${nasIP}"; then
  if [[ $nasPROTOCOL == "nfs" ]]; then
    mountDIR=$(pvesm nfsscan $nasIP | grep -w $nasBAKPATH | cut -d' ' -f1) #/volume1/backups
    pvesm add nfs backups --server $nasIP --path "/mnt/pve/backups/" --export "$mountDIR" --content backup > /dev/null 2>&1
  elif [[ $nasPROTOCOL == "cifs" ]]; then
    mountDIR=$(pvesm scan cifs $nasIP --username $nasUSER --password "$nasPASS" | grep -w $nasBAKPATH | cut -d' ' -f1) #backups
    pvesm add cifs backups --server $nasIP --share "$mountDIR" --username "$nasUSER" --password "$nasPASS" --content backup > /dev/null 2>&1
  fi
fi

# create Backupjob every Day at 3:00
echo "0 3 * * *   root   vzdump --compress zstd --mailto root --mailnotification always --exclude-path /mnt/ --exclude-path /media/ --mode snapshot --quiet 1 --pool BackupPool --maxfiles 6 --storage backups" >> /etc/cron.d/vzdump
