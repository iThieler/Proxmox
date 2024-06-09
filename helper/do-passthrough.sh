#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/_functions.sh)
source "/root/pve-global-config.sh"
if [[ $1 == "checkup" ]]; then goback=true; fi

function zigbee() {
    #get container ID and stop
    ctID=$(whip_inputbox "OK" "Container ID" "Wie lautet die Container-ID, an die der Zigbee-Stick gebunden werden soll?" "$(pct list | grep "ioBroker" | cut -d' ' -f 1)")
    pct stop $ctID
    while [ "$(pct status $ctID | cut -d' ' -f2 | grep -cw running)" -eq 1 ]; do
      sleep 2
    done

    #bakup files
    if [ -f "/etc/pve/lxc/$ctID.conf" ]; then
      bakFILE backup "/etc/pve/lxc/$ctID.conf"
    fi
    if [ -f "/etc/udev/rules.d/50-myusb.rules" ]; then
      bakFILE backup "/etc/udev/rules.d/50-myusb.rules"
    fi

    #get device infos
    usbdev=""
    conbee=""

    if [[ $(lsusb | grep -cw "ConBee II") -eq 1 ]]; then
      usbdev="ConBee II"
      conbee=true
    elif [[ $(lsusb | grep -cw "Silicon Labs") -eq 1 ]]; then
      usbdev="Silicon Labs"
      conbee=false
    fi

    if [ -z "$usbdev" ]; then
      echoLOG r "Kein unterstütztes USB-Gerät gefunden."
      exit 1
    fi

    device=$(lsusb | grep "$usbdev")
    usbBUS=$(echo "$device" | cut -d' ' -f2)
    usbDEVICE=$(echo "$device" | cut -d' ' -f4 | cut -d: -f1)
    usbDEVICEID=$(ls -l "/dev/bus/usb/$usbBUS/$usbDEVICE" | awk '{print $5}' | cut -d, -f1)
    usbVENDORID=$(echo "$device" | awk '{print $6}' | cut -d: -f1)
    usbPRODUCTID=$(echo "$device" | awk '{print $6}' | cut -d: -f2)
    usbPRODUCTNAME=$(ls /dev/serial/by-id/ | head -n 1)

    if [ -e "/dev/ttyACM"* ]; then
      usbPATH=$(ls -l /dev/ttyACM* | awk '{print $10}' | cut -d/ -f3)
      usbDAILOUT=$(ls -l /dev/ttyACM* | awk '{print $5}' | cut -d, -f1)
    elif [ -e "/dev/ttyUSB"* ]; then
      usbPATH=$(ls -l /dev/ttyUSB* | awk '{print $10}' | cut -d/ -f3)
      usbDAILOUT=$(ls -l /dev/ttyUSB* | awk '{print $5}' | cut -d, -f1)
    fi

    if $conbee; then
      mkdir -p "/var/lib/lxc/$ctID/devices"
      mknod -m 666 "/var/lib/lxc/$ctID/devices/$usbPATH" c "$usbDAILOUT" 0
      line1="lxc.cgroup2.devices.allow: c $usbDEVICEID:* rwm"
      line2="lxc.mount.entry: $usbPRODUCTNAME dev/serial/by-id/$usbPRODUCTNAME none bind,optional,create=file"
      line3="lxc.cgroup2.devices.allow: c $usbDAILOUT:* rwm"
      line4="lxc.mount.entry: /var/lib/lxc/$ctID/devices/$usbPATH dev/$usbPATH none bind,optional,create=file"
    else
      line1="lxc.cgroup2.devices.allow: c $usbDEVICEID:* rwm"
      line2="lxc.mount.entry: $usbPRODUCTNAME dev/serial/by-id/$usbPRODUCTNAME none bind,optional,create=file"
      line3="lxc.cgroup2.devices.allow: c $usbDAILOUT:* rwm"
      line4="lxc.mount.entry: /dev/$usbPATH dev/$usbPATH none bind,optional,create=file"
    fi

    #search for line number to insert if there are deviations in the config file
    if [[ $(grep -cw "\[" "/etc/pve/lxc/$ctID.conf") -eq 1 ]]; then
      lineNUMBER=$(grep -m1 -n "\[" "/etc/pve/lxc/$ctID.conf" | cut -d: -f1)
      lineNUMBER=$((lineNUMBER - 1))
      #insert text to lxc config file
      sed -i "$lineNUMBER i $line1\n$line2\n$line3\n$line4" "/etc/pve/lxc/$ctID.conf"
    else
      #insert text to lxc config file
      echo -e "$line1\n$line2\n$line3\n$line4" >> "/etc/pve/lxc/$ctID.conf"
    fi
    chmod o+rw "/dev/$usbPATH"

    #create udev rule
    echo -e "SUBSYSTEMS==\"usb\", ATTRS{idVendor}==\"${usbVENDORID}\", ATTRS{idProduct}==\"${usbPRODUCTID}\", GROUP=\"users\", MODE=\"0666\"" > "/etc/udev/rules.d/50-myusb.rules"
    udevadm control --reload

    #start container
    pct start $ctID
}

function menu() {
  sel=("1" "... bind Zigbee Stick" \
       "2" "... bind DVB-Device" \
       "3" "... bind grafic Card" \
       "4" "... bind Storage" \
       "" "" \
       "Q" "... back")
  menuSelection=$(whiptail --menu --nocancel --backtitle "© 2021 - iThieler's Proxmox Script collection" --title " BIND DEVICE TO LXC " "\nWhat do you want to do?" 20 80 10 "${sel[@]}" 3>&1 1>&2 2>&3)

  if [[ $menuSelection == "1" ]]; then
    #bind zigbee
    zigbee
  elif [[ $menuSelection == "2" ]]; then
    #bind DVB-Device
    menu
  elif [[ $menuSelection == "3" ]]; then
    #bind grafic Card
    menu
  elif [[ $menuSelection == "4" ]]; then
    #bind Storage
    menu
  elif [[ $menuSelection == "Q" ]]; then
    #going back
    if [ "$goback" != true ]; then cleanup; fi
    exit 0
  else
    menu
  fi
}

menu
