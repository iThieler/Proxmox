#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/_functions.sh)
source "/root/pve-global-config.sh"
if [[ $1 == "checkup" ]]; then goback=true; fi

function menu() {
  sel=("1" "I want to select ..." \
       "2" "I want all (Factory reset Proxmox) ..." \
       "" "" \
       "Q" "I want to exit/going back!")
  menuSelection=$(whiptail --menu --backtitle "© 2021 - iThieler's Proxmox Script collection" --title " DO DELETE " "\nWhat do you want to delete?" 0 80 0 "${sel[@]}" 3>&1 1>&2 2>&3)
  if [ $? -eq 1 ]; then echoLOG r "Aborting by user"; exit 1; fi

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
    guestchoice=$(whiptail --checklist --nocancel --backtitle "© 2021 - iThieler's Proxmox Script collection" --title " DO DELETE " "\nSelect the machines you want to delete?" 20 80 10 "${list[@]}" 3>&1 1>&2 2>&3 | sed 's#"##g')

    for choosed_guest in $guestchoice; do
      if [ $(pct list | grep -c ${choosed_guest}) -eq 1 ]; then
        name=$(pct list | grep ${choosed_guest} | awk '{print $3}')
        if $(whip_alert_yesno "YES" "NO" "DO DELETE" "Are you sure you want to delete the following container irrevocably?\nID: ${choosed_guest}\nName: ${name}"); then
          if [ $(pct list | grep ${choosed_guest} | grep -c running) -eq 1 ]; then
            pct shutdown ${choosed_guest} --forceStop 1 --timeout 10 >/dev/null 2>&1
            while [ $(pct status ${choosed_guest} | cut -d' ' -f2 | grep -c running) -eq 1 ]; do
              sleep 2
            done
          fi
          if pct destroy ${choosed_guest} --destroy-unreferenced-disks 1 --force 1 --purge 1 >/dev/null 2>&1; then
            echoLOG g "Delete >> $choosed_guest - $name"
          else
            echoLOG g "Delete >> $choosed_guest - $name"
          fi
        else
          echoLOG r "Aborting by user >> Delete >> $choosed_guest - $name"
        fi
      elif [ $(qm list | grep -c ${choosed_guest}) -eq 1 ]; then
        name=$(qm list | grep ${choosed_guest} | awk '{print $2}')
        if $(whip_alert_yesno "YES" "NO" "DO DELETE" "Are you sure you want to delete the following container irrevocably?\nID: ${choosed_guest}\nName: ${name}"); then
          if [ $(qm list | grep ${choosed_guest} | grep -c running) -eq 1 ]; then
            qm shutdown ${choosed_guest} --forceStop 1 --timeout 10 >/dev/null 2>&1
            while [ $(qm status ${choosed_guest} | cut -d' ' -f2 | grep -c running) -eq 1 ]; do
              sleep 2
            done
          fi
          if qm destroy ${choosed_guest} --destroy-unreferenced-disks 1 --force 1 --skiplock 1 >/dev/null 2>&1; then
            echoLOG g "Delete >> $choosed_guest - $name"
          else
            echoLOG g "Delete >> $choosed_guest - $name"
          fi
        else
          echoLOG r "Aborting by user >> Delete >> $choosed_guest - $name"
        fi
      fi
    done
    menu
  elif [[ $menuSelection == "2" ]]; then
    echoLOG b "Select >> I want all (Factory reset Proxmox) ..."
    for lxc in $(pct list | sed '1d' | awk '{print $1}'); do
      name=$(pct list | grep ${lxc} | awk '{print $3}')
      if $(whip_alert_yesno "YES" "NO" "DO DELETE" "Are you sure you want to delete the following container irrevocably?\nID: ${lxc}\nName: ${name}"); then
        if [ $(pct list | grep ${lxc} | grep -c running) -eq 1 ]; then
          pct shutdown ${lxc} --forceStop 1 --timeout 10 >/dev/null 2>&1
          while [ $(pct status ${lxc} | cut -d' ' -f2 | grep -c running) -eq 1 ]; do
            sleep 2
          done
        fi
        if pct destroy ${lxc} --destroy-unreferenced-disks 1 --force 1 --purge 1 >/dev/null 2>&1; then
          echoLOG g "Delete >> $lxc - $name"
        else
          echoLOG g "Delete >> $lxc - $name"
        fi
      else
        echoLOG r "Aborting by user >> Delete >> $lxc - $name"
      fi
    done
    for vm in $(qm list | sed '1d' | awk '{print $1}'); do
      name=$(qm list | grep ${vm} | awk '{print $2}')
      if $(whip_alert_yesno "YES" "NO" "DO DELETE" "Are you sure you want to delete the following container irrevocably?\nID: ${vm}\nName: ${name}"); then
        if [ $(qm list | grep ${vm} | grep -c running) -eq 1 ]; then
          qm shutdown ${vm} --forceStop 1 --timeout 10 >/dev/null 2>&1
          while [ $(qm status ${vm} | cut -d' ' -f2 | grep -c running) -eq 1 ]; do
            sleep 2
          done
        fi
        if qm destroy ${vm} --destroy-unreferenced-disks 1 --force 1 --skiplock 1 >/dev/null 2>&1; then
          echoLOG g "Delete >> $vm - $name"
        else
          echoLOG g "Delete >> $vm - $name"
        fi
      else
        echoLOG r "Aborting by user >> Delete >> $vm - $name"
      fi
    done
    # Reset Proxmox to factory settings
    if [ -n "$nasIP" ]; then
      pvesm remove backups
      grep -v "vzdump" /etc/cron.d/vzdump > tmpfile && mv tmpfile /etc/cron.d/vzdump #delete Backup cronjob
      grep -v "BackupPool" /etc/pve/user.cfg > tmpfile && mv tmpfile /etc/pve/user.cfg
    fi
    if [ -n "$mailSERVER" ]; then
      bakFILE recover "/etc/aliases" #delete Postfix config
      rm "/etc/postfix/canonical"
      rm "/etc/postfix/sasl_passwd"
      bakFILE recover "/etc/postfix/main.cf"
      bakFILE recover "/etc/ssl/certs/ca-certificates.crt"
    fi
    echo "" > /etc/pve/firewall/cluster.fw
    echo "" > /etc/pve/nodes/$(hostname)/host.fw
    if apt-get autoremove -y parted smartmontools libsasl2-modules mailutils 2>&1 >/dev/null; then
      echoLOG g "remove needed Software"
    else
      echoLOG r "remove needed Software"
    fi
    bash <(curl -s https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh) uninstall 2>&1 >/dev/null
    whip_message "DO DELETE" "The package sources cannot be changed after they have been used. If you want to use the enterprise repository of Proxmox again, you have to reinstall Proxmox."
    cleanup
    whip_message "DO DELETE" "Your server must be restarted now."
    reboot
  elif [[ $menuSelection == "Q" ]]; then
    echoLOG b "Select >> I want to exit/going back!"
    if [ "$goback" != true ]; then cleanup; fi
    exit 0
  else
    menu
  fi
}

menu
