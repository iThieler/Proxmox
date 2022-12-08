#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/_functions.sh)

function create_Global_Config() {
  # get Variables from Server
  hostDOMAIN=$(pveum user list | grep "root@pam" | awk '{print $5}' | cut -d\@ -f2)
  
  # config Netrobot
  if whip_yesno "YES" "NO" "NETWORKROBOT" "Do you use a network robot in your network (general user that has admin/super user rights on all devices)?"; then
    robot=true
    robotNAME=$(whip_inputbox "OK" "NETWORKROBOT" "What is the name of your network robot?" "netrobot")
    robotPASS=$(whip_inputbox_password_autogenerate "OK" "NETWORKROBOT" "What is the password of >>${robotNAME}<<?\nBlank = create password automatically")
    whip_message "NETWORKROBOT" "Make sure that on your devices (Router, NAS, Switches, AccessPoints) there is the following user with admin rights.\n\nUsername: ${robotNAME}\nPassword: ${robotPASS}"
  fi

  # config SMTP server for email notification
  if whip_yesno "Continue" "Exit" "MAILSERVER" "To be able to receive notifications you have to enter the data of your mail server. You can find them in the help section of your email provider.\n\nDo you want to continue?"; then
    mailUSER=$(whip_inputbox "OK" "MAILSERVER" "Which username is used to login to the mail server?" "notify@${hostDOMAIN}")
    mailPASS=$(whip_inputbox "OK" "MAILSERVER" "What is the password used to login to the mail server?")
    mailTO=$(whip_inputbox "OK" "MAILSERVER" "To which e-mail address should notifications from your server be sent?" "$(pveum user list | grep "root@pam" | awk '{print $5}')")
    mailFROM=$(whip_inputbox "OK" "MAILSERVER" "The sending address is?" "notify@${hostDOMAIN}")
    mailSERVER=$(whip_inputbox "OK" "MAILSERVER" "What is the address of your outgoing mail server (SMTP server address)?" "smtp.${hostDOMAIN}")
    mailPORT=$(whip_inputbox "OK" "MAILSERVER" "What port does your outgoing mail server use (SMTP server address)?" "587")
    if whip_yesno "YES" "NO" "MAILSERVER" "Does your mail server require SSL/TLS/STARTTLS for login?"; then
      mailTLS=true
    else
      mailTLS=false
    fi
  fi

  # config NAS
  if whip_yesno "YES" "NO" "NETWORK ATTACHED STORAGE" "Is there a Network Attached Storage (NAS) on your network?"; then
    nasIP=$(whip_inputbox "OK" "NETWORK ATTACHED STORAGE" "What is the IP address of your NAS?" "$(hostname -I | cut -d. -f1,2).")
    nasBAKPATH=$(whip_inputbox "OK" "NETWORK ATTACHED STORAGE" "What is the name of the folder where backups should be stored?\nProxmox automatically creates a subfolder called >>dump<<." "backups")
    if ! $robot; then
      nasUSER=$(whip_inputbox "OK" "NETWORK ATTACHED STORAGE" "What is the username of a user with full access rights to this folder?" "${robotNAME}.")
      nasPASS=$(whip_inputbox "OK" "NETWORK ATTACHED STORAGE" "What is the password of >>${nasUSER}<<?")
    fi
    if whip_yesno "SAMBA" "NFS" "NETWORK ATTACHED STORAGE" "Can your NAS be mounted via NFS (Linux standard) or should the SAMBA protocol (Windows share) be used?"; then
      nasPROTOCOL=cifs
    else
      nasPROTOCOL=nfs
    fi
    sel=("1" "SYNOLOGY" \
       "2" "QNAP" \
       "3" "OTHER")
    menuSelection=$(whiptail --menu --nocancel --backtitle "© 2021 - iThieler's Proxmox Script collection" --title " NETWORK ATTACHED STORAGE " "\nWhich manufacturer is the NAS from?" 20 80 10 "${sel[@]}" 3>&1 1>&2 2>&3)
    if [[ $menuSelection == "1" ]]; then
      nasMAN=synology
    elif [[ $menuSelection == "2" ]]; then
      nasMAN=qnap
    else
      nasMAN=other
    fi
  fi

  # config VLAN
  if whip_yesno "YES" "NO" "VIRTUAL LACAL AREA NETWORK" "Do you use Virtual Local Area Networks (VLANs) in your network?"; then
    network=$(hostname -I | cut -d. -f1,2)
    if whip_yesno "Yes" "No" "VIRTUAL LACAL AREA NETWORK" "Is there a VLAN used for servers?"; then
      vlanid=$(hostname -I | cut -d. -f3)
      vlanSERVERID=$(whip_inputbox "OK" "VIRTUAL LACAL AREA NETWORK" "What is the VLAN ID?" "${vlanid}")
      vlanSERVERGW=$(whip_inputbox "OK" "VIRTUAL LACAL AREA NETWORK" "What is the IP address of the gateway of this VLAN in CIDR notation (192.168.0.1/24)?" "$(ip r | grep default | cut -d' ' -f3)")
    fi
    if whip_yesno "Yes" "No" "VIRTUAL LACAL AREA NETWORK" "Is there a VLAN used for SmartHome devices (IoT)?"; then
      vlanSMARTHOMEID=$(whip_inputbox "OK" "VIRTUAL LACAL AREA NETWORK" "What is the VLAN ID?")
      vlanSMARTHOMEGW=$(whip_inputbox "OK" "VIRTUAL LACAL AREA NETWORK" "What is the IP address of the gateway of this VLAN in CIDR notation (192.168.0.1/24)?" "${network}.${vlanSMARTHOMEID}.254")
    fi
    if whip_yesno "Yes" "No" "VIRTUAL LACAL AREA NETWORK" "Is there a VLAN used for normal devices (DHCP and/or cell phones, laptops, TVs, etc.)?"; then
      vlanDHCPID=$(whip_inputbox "OK" "VIRTUAL LACAL AREA NETWORK" "What is the VLAN ID?")
      vlanDHCPGW=$(whip_inputbox "OK" "VIRTUAL LACAL AREA NETWORK" "What is the IP address of the gateway of this VLAN in CIDR notation (192.168.0.1/24)?" "${network}.${vlanDHCPID}.254")
    fi
    if whip_yesno "Yes" "No" "VIRTUAL LACAL AREA NETWORK" "Is there a VLAN used for guests?"; then
      vlanGUESTID=$(whip_inputbox "OK" "VIRTUAL LACAL AREA NETWORK" "What is the VLAN ID?")
      vlanGUESTGW=$(whip_inputbox "OK" "VIRTUAL LACAL AREA NETWORK" "What is the IP address of the gateway of this VLAN in CIDR notation (192.168.0.1/24)?" "${network}.${vlanGUESTID}.1")
    fi
  else
    gwIP=$(ip r | grep default | cut -d' ' -f3)
    gwCIDR=$(ip r | grep $(hostname -I) | cut -d' ' -f1 | cut -d/ -f2)
    vlanSERVERID=0
    vlanSERVERGW="$gwIP/$gwCIDR"
  fi

  # create config File
  cat << EOF >/root/pve-global-config.sh
#!/bin/bash
# This file stores variables that are specified during the first execution of the post-processing script by the
# This makes re-execution of the script easier, and follows a standard. The advantage is that the user does not
# to answer all the questions again and again.

# NOTICE: Backup Proxmox Configuration Script from https://ithieler.github.io/Proxmox/
# Created on $(date)

# Variables - Netrobot
robot=${robot}
robotNAME=${robotNAME}
robotPASS=${robotPASS}

# Variables - Mailserver (SMTP)
mailUSER=${mailUSER}
mailPASS=${mailPASS}
mailTO=${mailTO}
mailFROM=${mailFROM}
mailSERVER=${mailSERVER}
mailPORT=${mailPORT}
mailTLS=${mailTLS}

# Variables - NAS
nasIP=${nasIP}
nasBAKPATH=${nasBAKPATH}
nasPROTOCOL=${nasPROTOCOL}
nasUSER=${nasUSER}
nasPASS=${nasPASS}
nasMAN=${nasMAN}

# Variables - VLANs
vlanSERVERID=${vlanSERVERID}
vlanSERVERGW=${vlanSERVERGW}
vlanSMARTHOMEID=${vlanSMARTHOMEID}
vlanSMARTHOMEGW=${vlanSMARTHOMEGW}
vlanDHCPID=${vlanDHCPID}
vlanDHCPGW=${vlanDHCPGW}
vlanGUESTID=${vlanGUESTID}
vlanGUESTGW=${vlanGUESTGW}
EOF
}

if [ ! -f "/root/pve-global-config.sh" ]; then
  echoLOG b "start creating configuration file"
  create_Global_Config
fi

if [ -n "$nasIP" ]; then
  if bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/config-nas.sh); then
    echoLOG g "mounting NAS as backup drive"
  else
    echoLOG r "mounting NAS as backup drive"
  fi
fi

if [ -n "$mailSERVER" ]; then
  if bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/config-postfix.sh); then
    echoLOG g "configure mail server for notifications"
  else
    echoLOG r "configure mail server for notifications"
  fi
fi

if bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/config-pve.sh); then
  echoLOG g "configure Proxmox main system"
  whip_message "PROXMOX" "The basic configuration of the server is now complete. The server must be restarted. After the restart, this script can be called again to install and configure containers and virtual machines."
else
  echoLOG r "configure Proxmox main system"
fi

echo > "/root/.iThieler"

# mail configuration file to root
if [ -n "$mailUSER" ]; then
  confmailto=$(whip_inputbox "OK" "CONFIGURATION FILE" "An welche Adresse soll eine Kopie der Konfiguartionsdatei gesendet werden?" "${mailTO}")
  cp /root/pve-global-config.sh /tmp/proxmox-configuration.txt
  sed -i 's|robotPASS=".*"|robotPASS=""|g' /tmp/proxmox-configuration.txt
  sed -i 's|mailPASS=".*"|mailPASS=""|g' /tmp/proxmox-configuration.txt
  sed -i 's|nasPASS=".*"|nasPASS=""|g' /tmp/proxmox-configuration.txt
  echo -e "In the attachment you will find the file >>proxmox-configuration.txt<<. This should be absolutely saved. With this file a new configuration can be done faster, because all questions are already answered. If a NAS was specified, this file is also saved in the backup folder." | mail.mailutils -a "From: \"Proxmox Server\" <${mailFROM}>" -s "[HomeServer] Configuration File" "${confmailto}" -A "/tmp/proxmox-configuration.txt"
  echoLOG b "Kopie der Konfiurationsdatei an >> ${confmailto} << gesendet."
fi

# copy configuration to NAS
if [ -n "$nasIP" ]; then
  cp /root/pve-global-config.sh /mnt/pve/backups/proxmox-configuration.txt > /dev/null 2>&1
  echoLOG b "Kopie der Konfiurationsdatei auf NAS gespeichert."
fi

cleanup
reboot
