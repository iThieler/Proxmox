#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/_functions.sh)
source "/root/pve-global-config.sh"
if [[ $1 == "checkup" ]]; then goback=true; fi

function menu() {
  sel=("1" "I want to select ..." \
       "2" "I want only running ..." \
       "3" "I want only stopped ..." \
       "4" "I want all LXC ..." \
       "5" "I want all KVM ..." \
       "6" "I want all ..." \
       "" "" \
       "Q" "I want to exit/going back!")
  menuSelection=$(whiptail --menu --nocancel --backtitle "© 2021 - iThieler's Proxmox Script collection" --title " DO BACKUP " "\nWhat do you want to Backup?" 0 80 0 "${sel[@]}" 3>&1 1>&2 2>&3)
  if [ $? -eq 1 ]; then echoLOG r "Aborting by user"; exit 1; fi

  echoLOG y "Starting Backup Process"

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
      if [ $(pct list | grep -c ${choosed_guest}) -eq 1 ]; then
        name=$(pct list | grep ${choosed_guest} | awk '{print $3}')
        if [ $(pct list | grep ${choosed_guest} | grep -c running) -eq 1 ]; then
          pct shutdown ${choosed_guest} --forceStop 1 --timeout 10 >/dev/null 2>&1
          while [ $(pct status ${choosed_guest} | cut -d' ' -f2 | grep -c running) -eq 1 ]; do
            sleep 2
          done
        fi
      elif [ $(qm list | grep -c ${choosed_guest}) -eq 1 ]; then
        name=$(qm list | grep ${choosed_guest} | awk '{print $2}')
        if [ $(qm list | grep ${choosed_guest} | grep -c running) -eq 1 ]; then
          qm shutdown ${choosed_guest} --forceStop 1 --timeout 10 >/dev/null 2>&1
          while [ $(qm status ${choosed_guest} | cut -d' ' -f2 | grep -c running) -eq 1 ]; do
            sleep 2
          done
        fi
      fi
      if vzdump ${choosed_guest} --dumpdir /mnt/pve/backups/dump/manual --mode stop --compress zstd --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
        filename=$(ls -ldst /mnt/pve/backups/dump/manual/*-${choosed_guest}-*.*.zst | awk '{print $10}' | cut -d. -f1 | head -n1)
        if [ -f "${filename}.tar.zst" ]; then
          mv "${filename}.tar.zst" "/mnt/pve/backups/dump/manual/${choosed_guest}-${name}.tar.zst"
          rm "${filename}.log"
        elif [ -f "${filename}.vma.zst" ]; then
          mv "${filename}.vma.zst" "/mnt/pve/backups/dump/manual/${choosed_guest}-${name}.vma.zst"
          rm "${filename}.log"
        fi
        echoLOG g "Backup >> $choosed_guest - $name"
      else
        echoLOG r "Backup >> $choosed_guest - $name"
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
    for choosed_guest in $(pct list | grep running | awk '{print $1}'); do
      if [ $(pct list | grep -c ${choosed_guest}) -eq 1 ]; then
        name=$(pct list | grep ${choosed_guest} | awk '{print $3}')
        if [ $(pct list | grep ${choosed_guest} | grep -c running) -eq 1 ]; then
          pct shutdown ${choosed_guest} --forceStop 1 --timeout 10 >/dev/null 2>&1
          while [ $(pct status ${choosed_guest} | cut -d' ' -f2 | grep -c running) -eq 1 ]; do
            sleep 2
          done
        fi
      fi
      if vzdump ${choosed_guest} --dumpdir /mnt/pve/backups/dump/manual --mode stop --compress zstd --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
        filename=$(ls -ldst /mnt/pve/backups/dump/manual/*-${choosed_guest}-*.*.zst | awk '{print $10}' | cut -d. -f1 | head -n1)
        mv "${filename}.tar.zst" "/mnt/pve/backups/dump/manual/${choosed_guest}-${name}.tar.zst"
        rm "${filename}.log"
        echoLOG g "Backup >> $choosed_guest - $name"
      else
        echoLOG r "Backup >> $choosed_guest - $name"
      fi
      pct start ${choosed_guest} > /dev/null 2>&1
    done
    for choosed_guest in $(qm list | grep running | awk '{print $1}'); do
      if [ $(qm list | grep -c ${choosed_guest}) -eq 1 ]; then
        name=$(qm list | grep ${choosed_guest} | awk '{print $2}')
        if [ $(qm list | grep ${choosed_guest} | grep -c running) -eq 1 ]; then
          qm shutdown ${choosed_guest} --forceStop 1 --timeout 10 >/dev/null 2>&1
          while [ $(qm status ${choosed_guest} | cut -d' ' -f2 | grep -c running) -eq 1 ]; do
            sleep 2
          done
        fi
      fi
      if vzdump ${choosed_guest} --dumpdir /mnt/pve/backups/dump/manual --mode stop --compress zstd --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
        filename=$(ls -ldst /mnt/pve/backups/dump/manual/*-${choosed_guest}-*.*.zst | awk '{print $10}' | cut -d. -f1 | head -n1)
        mv "${filename}.vma.zst" "/mnt/pve/backups/dump/manual/${choosed_guest}-${name}.vma.zst"
        rm "${filename}.log"
        echoLOG g "Backup >> $choosed_guest - $name"
      else
        echoLOG r "Backup >> $choosed_guest - $name"
      fi
      qm start ${choosed_guest} > /dev/null 2>&1
    done
    menu
  elif [[ $menuSelection == "3" ]]; then
    echoLOG b "Select >> I want only stopped ..."
    for choosed_guest in $(pct list | grep stopped | awk '{print $1}'); do
      if [ $(pct list | grep -c ${choosed_guest}) -eq 1 ]; then
        name=$(pct list | grep ${choosed_guest} | awk '{print $3}')
      fi
      if vzdump ${choosed_guest} --dumpdir /mnt/pve/backups/dump/manual --mode stop --compress zstd --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
        filename=$(ls -ldst /mnt/pve/backups/dump/manual/*-${choosed_guest}-*.*.zst | awk '{print $10}' | cut -d. -f1 | head -n1)
        mv "${filename}.tar.zst" "/mnt/pve/backups/dump/manual/${choosed_guest}-${name}.tar.zst"
        rm "${filename}.log"
        echoLOG g "Backup >> $choosed_guest - $name"
      else
        echoLOG r "Backup >> $choosed_guest - $name"
      fi
      pct start ${choosed_guest} > /dev/null 2>&1
    done
    for choosed_guest in $(qm list | grep stopped | awk '{print $1}'); do
      if [ $(qm list | grep -c ${choosed_guest}) -eq 1 ]; then
        name=$(qm list | grep ${choosed_guest} | awk '{print $2}')
      fi
      if vzdump ${choosed_guest} --dumpdir /mnt/pve/backups/dump/manual --mode stop --compress zstd --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
        filename=$(ls -ldst /mnt/pve/backups/dump/manual/*-${choosed_guest}-*.*.zst | awk '{print $10}' | cut -d. -f1 | head -n1)
        mv "${filename}.vma.zst" "/mnt/pve/backups/dump/manual/${choosed_guest}-${name}.vma.zst"
        rm "${filename}.log"
        echoLOG g "Backup >> $choosed_guest - $name"
      else
        echoLOG r "Backup >> $choosed_guest - $name"
      fi
      qm start ${choosed_guest} > /dev/null 2>&1
    done
    menu
  elif [[ $menuSelection == "4" ]]; then
    echoLOG b "Select >> I want all LXC ..."
    for choosed_guest in $(pct list | grep 'running\|stopped' | awk '{print $1}'); do
      if [ $(pct list | grep -c ${choosed_guest}) -eq 1 ]; then
        name=$(pct list | grep ${choosed_guest} | awk '{print $3}')
        if [ $(pct list | grep ${choosed_guest} | grep -c running) -eq 1 ]; then
          pct shutdown ${choosed_guest} --forceStop 1 --timeout 10 >/dev/null 2>&1
          while [ $(pct status ${choosed_guest} | cut -d' ' -f2 | grep -c running) -eq 1 ]; do
            sleep 2
          done
        fi
      fi
      if vzdump ${choosed_guest} --dumpdir /mnt/pve/backups/dump/manual --mode stop --compress zstd --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
        filename=$(ls -ldst /mnt/pve/backups/dump/manual/*-${choosed_guest}-*.*.zst | awk '{print $10}' | cut -d. -f1 | head -n1)
        mv "${filename}.tar.zst" "/mnt/pve/backups/dump/manual/${choosed_guest}-${name}.tar.zst"
        rm "${filename}.log"
        echoLOG g "Backup >> $choosed_guest - $name"
      else
        echoLOG r "Backup >> $choosed_guest - $name"
      fi
      pct start ${choosed_guest} > /dev/null 2>&1
    done
    menu
  elif [[ $menuSelection == "5" ]]; then
    echoLOG b "Select >> I want all KVM ..."
    for choosed_guest in $(qm list | grep 'running\|stopped' | awk '{print $1}'); do
      if [ $(qm list | grep -c ${choosed_guest}) -eq 1 ]; then
        name=$(qm list | grep ${choosed_guest} | awk '{print $2}')
        if [ $(qm list | grep ${choosed_guest} | grep -c running) -eq 1 ]; then
          qm shutdown ${choosed_guest} --forceStop 1 --timeout 10 >/dev/null 2>&1
          while [ $(qm status ${choosed_guest} | cut -d' ' -f2 | grep -c running) -eq 1 ]; do
            sleep 2
          done
        fi
      fi
      if vzdump ${choosed_guest} --dumpdir /mnt/pve/backups/dump/manual --mode stop --compress zstd --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
        filename=$(ls -ldst /mnt/pve/backups/dump/manual/*-${choosed_guest}-*.*.zst | awk '{print $10}' | cut -d. -f1 | head -n1)
        mv "${filename}.vma.zst" "/mnt/pve/backups/dump/manual/${choosed_guest}-${name}.vma.zst"
        rm "${filename}.log"
        echoLOG g "Backup >> $choosed_guest - $name"
      else
        echoLOG r "Backup >> $choosed_guest - $name"
      fi
      qm start ${choosed_guest} > /dev/null 2>&1
    done
    menu
  elif [[ $menuSelection == "6" ]]; then
    echoLOG b "Select >> I want all ..."
    for choosed_guest in $(pct list | grep 'running\|stopped' | awk '{print $1}'); do
      if [ $(pct list | grep -c ${choosed_guest}) -eq 1 ]; then
        name=$(pct list | grep ${choosed_guest} | awk '{print $3}')
        if [ $(pct list | grep ${choosed_guest} | grep -c running) -eq 1 ]; then
          pct shutdown ${choosed_guest} --forceStop 1 --timeout 10 >/dev/null 2>&1
          while [ $(pct status ${choosed_guest} | cut -d' ' -f2 | grep -c running) -eq 1 ]; do
            sleep 2
          done
        fi
      fi
      if vzdump ${choosed_guest} --dumpdir /mnt/pve/backups/dump/manual --mode stop --compress zstd --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
        filename=$(ls -ldst /mnt/pve/backups/dump/manual/*-${choosed_guest}-*.*.zst | awk '{print $10}' | cut -d. -f1 | head -n1)
        mv "${filename}.tar.zst" "/mnt/pve/backups/dump/manual/${choosed_guest}-${name}.tar.zst"
        rm "${filename}.log"
        echoLOG g "Backup >> $choosed_guest - $name"
      else
        echoLOG r "Backup >> $choosed_guest - $name"
      fi
      pct start ${choosed_guest} > /dev/null 2>&1
    done
    for choosed_guest in $(qm list | grep 'running\|stopped' | awk '{print $1}'); do
      if [ $(qm list | grep -c ${choosed_guest}) -eq 1 ]; then
        name=$(qm list | grep ${choosed_guest} | awk '{print $2}')
        if [ $(qm list | grep ${choosed_guest} | grep -c running) -eq 1 ]; then
          qm shutdown ${choosed_guest} --forceStop 1 --timeout 10 >/dev/null 2>&1
          while [ $(qm status ${choosed_guest} | cut -d' ' -f2 | grep -c running) -eq 1 ]; do
            sleep 2
          done
        fi
      fi
      if vzdump ${choosed_guest} --dumpdir /mnt/pve/backups/dump/manual --mode stop --compress zstd --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
        filename=$(ls -ldst /mnt/pve/backups/dump/manual/*-${choosed_guest}-*.*.zst | awk '{print $10}' | cut -d. -f1 | head -n1)
        mv "${filename}.vma.zst" "/mnt/pve/backups/dump/manual/${choosed_guest}-${name}.vma.zst"
        rm "${filename}.log"
        echoLOG g "Backup >> $choosed_guest - $name"
      else
        echoLOG r "Backup >> $choosed_guest - $name"
      fi
      qm start ${choosed_guest} > /dev/null 2>&1
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

if [ $(pct list | grep -c 1.*) -eq 0 ] && [ $(qm list | grep -c 2.*) -eq 0 ] ; then
  whip_alert "DO BACKUP" "No containers or virtual machines were found. There is nothing from which a backup could be created."
  exit 1
fi

if [ -n "$nasIP" ]; then
  if [ -d "/mnt/pve/backups/dump/manual/" ]; then
    whip_alert "DO BACKUP" "Manual backups were found. If you continue, these will be deleted and new ones created.\nThe daily automatically created backups will be kept."
    rm -r "/mnt/pve/backups/dump/manual/"
  fi
  mkdir -p "/mnt/pve/backups/dump/manual"
  menu
else
  whip_alert "DO BACKUP" "This function is only available if a NAS has been mounted as a backup drive with the main script."
  exit 1
fi
