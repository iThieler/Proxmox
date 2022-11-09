#!/bin/bash

fileName=$(basename "${BASH_SOURCE:-$0}")
filePATH=$(realpath "$0" | sed 's|\(.*\)/.*|\1|')

source <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/_functions.sh)

function create_Global_Config() {
  # get Variables from Server
  hostNETWORKID=$(hostname -I | cut -d. -f1,2,3)
  echoLOG y "hostNETWORKID= ${hostNETWORKID}"
  hostDOMAIN=$(pveum user list | grep "root@pam" | awk '{print $5}' | cut -d\@ -f2)
  hostGATEWAY=$(ip r | grep default | cut -d' ' -f3)
  hostROOTMAIL=$(pveum user list | grep "root@pam" | awk '{print $5}')
  
  # config Netrobot
  robotNAME=$(whip_inputbox "OK" "NETZWERKROBOTER" "Wie lautet der Name, deines Netzwerkroboter?" "netrobot")
  robotPASS=$(whip_inputbox_password_autogenerate "OK" "NETZWERKROBOTER" "Wie lautet das Passwort von >>${robotNAME}<<?\nLeer = Passwort automatisch erstellen")
  whip_message "NETZWERKROBOTER" "Stell sicher, das sich auf deinen Geräten (Router, NAS, Switch, AccessPoint) der folgende Benutzer mit Adminrechten befindet.\n\nBenutzername: ${robotNAME}\nPasswort: ${robotPASS}"

  # config SMTP server for email notification
  if whip_yesno "JA" "NEIN" "MAILSERVER" "Soll ein eigener Mailserver für den Versand von Benachrichtigungen verwendet werden?"; then
    mailUSER=$(whip_inputbox "OK" "MAILSERVER" "Welcher Benutzername wird für den Login am Mailserver verwendet?" "notify@${hostDOMAIN}")
    mailPASS=$(whip_inputbox "OK" "MAILSERVER" "Wie lautet das Passwort, welches für den Login am Mailserver verwendet wird?")
    mailTO=$(whip_inputbox "OK" "MAILSERVER" "An welche E-Mailadresse sollen Benachrichtigungen von deinem Server gesendet werden?" "${hostROOTMAIL}")
    mailFROM=$(whip_inputbox "OK" "MAILSERVER" "Die Absendeadresse lautet?" "notify@${hostDOMAIN}")
    mailSERVER=$(whip_inputbox "OK" "MAILSERVER" "Wie lautet die Adresse deines Postausgangsserver?" "smtp.${hostDOMAIN}")
    mailPORT=$(whip_inputbox "OK" "MAILSERVER" "Welchen Port benutzt dein Postausgangsserver?" "587")
    if whip_yesno "JA" "NEIN" "MAILSERVER" "Benötigt dein Mailserver für den Login SSL?"; then
      mailTLS=true
    else
      mailTLS=false
    fi
  fi

  # config NAS
  if whip_yesno "JA" "NEIN" "NAS" "Befindet sich ein Network Attached Storage (NAS) in deinem Netzwerk?"; then
    nasIP=$(whip_inputbox "OK" "NAS" "Wie lautet die IP-Adresse der NAS?" "${hostNETWORKID}.")
    nasBAKPATH=$(whip_inputbox "OK" "NAS" "Wie heisst der Ordner in dem Backups gespeichert werden sollen?\nProxmox erstellt automatisch einen Unterordner namens >>dump<<." "backups")
    if whip_yesno "SAMBA" "NFS" "NAS" "Kann dieses Verzeichnis per NFS (Linux Standard) angebunden werden, oder soll das Samba Protokoll (Windows Standard) genutzt werden?"; then
      nasPROTOCOL=cifs
      nasUSER=$(whip_inputbox "OK" "NAS" "Wie lautet der Benutzername eines Adminnutzer?" "${robotNAME}.")
      nasPASS=$(whip_inputbox "OK" "NAS" "Wie lautet das Passwort von >>${nasUSER}<<?\nLeer = Passwort von >>${robotNAME}<<")
    else
      nasPROTOCOL=nfs
    fi
    if [[ $(whip_inputbox "OK" "NAS" "Von welchem Hersteller ist die NAS?\n1 = Synology - 2 = QNAP - 3 = andere") == "1" ]]; then
      nasMAN=synology
    elif [[ $(whip_inputbox "OK" "NAS" "Von welchem Hersteller ist die NAS?\n1 = Synology - 2 = QNAP - 3 = andere") == "2" ]]; then
      nasMAN=qnap
    fi
  fi

  # config VLAN
  if whip_yesno "JA" "NEIN" "VLAN" "Werden in diesem Netzwerk VLANs genutzt?"; then
    local network=$(${hostNETWORKID} | cut -d. -f1,2)
    if whip_yesno "JA" "NEIN" "VLAN" "Wird ein VLAN für Server genutzt?"; then
      local vlanid=$(${hostNETWORKID} | cut -d. -f3)
      vlanSERVERID=$(whip_inputbox "OK" "VLAN" "Wie lautet die VLAN-ID?" "${vlanid}")
      vlanSERVERGW=$(whip_inputbox "OK" "VLAN" "Wie lautet die IP-Adresse des Gateways?" "${hostGATEWAY}")
    fi
    if whip_yesno "JA" "NEIN" "VLAN" "Wird ein VLAN für SmartHome Geräte genutzt?"; then
      vlanSMARTHOMEID=$(whip_inputbox "OK" "VLAN" "Wie lautet die VLAN-ID?")
      vlanSMARTHOMEGW=$(whip_inputbox "OK" "VLAN" "Wie lautet die IP-Adresse des Gateways?" "${network}.${vlanSMARTHOMEID}.254")
    fi
    if whip_yesno "JA" "NEIN" "VLAN" "Wird ein VLAN für DHCP/Produktiv (Handys, Laptops, Fernseher usw.) genutzt?"; then
      vlanDHCPID=$(whip_inputbox "OK" "VLAN" "Wie lautet die VLAN-ID?")
      vlanDHCPGW=$(whip_inputbox "OK" "VLAN" "Wie lautet die IP-Adresse des Gateways?" "${network}.${vlanDHCPID}.254")
    fi
    if whip_yesno "JA" "NEIN" "VLAN" "Wird ein VLAN für Gäste WLAN genutzt?"; then
      vlanGUESTID=$(whip_inputbox "OK" "VLAN" "Wie lautet die VLAN-ID?")
      vlanGUESTGW=$(whip_inputbox "OK" "VLAN" "Wie lautet die IP-Adresse des Gateways?" "${network}.${vlanGUESTID}.1")
    fi
  else
    vlanSERVERID=0
    vlanSERVERGW="${hostNETWORKID}.${hostGATEWAY}"
  fi

  # create config File
  echo > "/root/.iThieler"
  echo -e "\0043\0041/bin/bash
  \0043 This file stores variables that are specified during the first execution of the post-processing script by the >
  \0043 This makes re-execution of the script easier, and follows a standard. The advantage is that the user does not >
  \0043 to answer all the questions again and again.\n
  \0043 NOTICE: Backup Proxmox Configuration Script from https://ithieler.github.io/Proxmox/
  \0043 Created on $(date)
  \n\0043 Variables - Netrobot
  robotNAME=${robotNAME}
  robotPASS=${robotPASS}
  \n\0043 Variables - Mailserver (SMTP)
  mailUSER=${mailUSER}
  mailPASS=${mailPASS}
  mailTO=${mailTO}
  mailFROM=${mailFROM}
  mailSERVER=${mailSERVER}
  mailPORT=${mailPORT}
  mailTLS=${mailTLS}
  \n\0043 Variables - NAS
  nasIP=${nasIP}
  nasBAKPATH=${nasBAKPATH}
  nasPROTOCOL=${nasPROTOCOL}
  nasUSER=${nasUSER}
  nasPASS=${nasPASS}
  nasMAN=${nasMAN}
  \n\0043 Variables - VLANs
  vlanSERVERID=${vlanSERVERID}
  vlanSERVERGW=${vlanSERVERGW}
  vlanSMARTHOMEID=${vlanSMARTHOMEID}
  vlanSMARTHOMEGW=${vlanSMARTHOMEGW}
  vlanDHCPID=${vlanDHCPID}
  vlanDHCPGW=${vlanDHCPGW}
  vlanGUESTID=${vlanGUESTID}
  vlanGUESTGW=${vlanGUESTGW}" > "/root/pve-global-config.sh"
}

echoLOG b "Starte globale Konfiguration :-)"
create_Global_Config

if [ -n "$nasIP" ]; then
  bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/config-nas.sh)
fi

if [ -n "$mailSERVER" ]; then
  bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/config-postfix.sh)
fi

bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/config-pve.sh)

sleep 2

reboot
