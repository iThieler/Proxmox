#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/_functions.sh)

function menuMAIN() {
  sel=("1" "... bind Zigbee Stick" \
       "2" "... bind DVB-Device" \
       "3" "... bind grafic Card" \
       "4" "... bind Storage" \
       "" "" \
       "Q" "... back")
  menuSelection=$(whiptail --menu --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " BIND DEVICE TO LXC " "\nWhat do you want to do?" 20 80 10 "${sel[@]}" 3>&1 1>&2 2>&3)

  if [[ $menuSelection == "1" ]]; then
    #get container ID and stop
    ctID=
    pct stop $ctID
    while [ $(pct status $ctID | cut -d' ' -f2 | grep -cw running) -eq 1 ]; do
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
    device=$(lsusb | grep "$usbdev")
    usbBUS=$(lsusb | grep "$usbdev" | cut -d' ' -f2)
    usbDEVICE=$(lsusb | grep "$usbdev" | cut -d' ' -f4 | cut -d: -f1)
    usbDEVICEID=$(ls -l /dev/bus/usb/$usbBUS/$usbDEVICE | cut -d' ' -f5 | cut -d, -f1)
    usbVENDORID=$(lsusb | grep "$usbdev" | cut -d' ' -f6 | cut -d: -f1)
    usbPRODUCTID=$(lsusb | grep "$usbdev" | cut -d' ' -f6 | cut -d: -f2)
    usbPRODUCTNAME=$(ls /dev/serial/by-id/)
    if [ -e "/dev/ttyACM"* ]; then
      usbPATH=$(ls -l /dev/ttyACM* | cut -d' ' -f10 | cut -d/ -f3)
      usbDAILOUT=$(ls -l /dev/ttyACM* | cut -d' ' -f5 | cut -d, -f1)
    elif [ -e "/dev/ttyUSB"* ]; then
      usbPATH=$(ls -l /dev/ttyUSB* | cut -d' ' -f10 | cut -d/ -f3)
      usbDAILOUT=$(ls -l /dev/ttyUSB* | cut -d' ' -f5 | cut -d, -f1)
    fi

    if [[ $(lsusb | grep "$usbdev" | grep -cw "ConBee II") -eq 1 ]]; then
      mkdir /var/lib/lxc/$ctID/devices
      cd /var/lib/lxc/$ctID/devices
      mknod -m 666 $usbPATH c $usbDAILOUT 0
      cd /root
      line1="lxc.cgroup2.devices.allow: c $usbDEVICEID:* rwm"
      line2="lxc.mount.entry: $usbPRODUCTNAME dev/serial/by-id/$usbPRODUCTNAME none bind,optional,create=file"
      line3="lxc.cgroup2.devices.allow: c $usbDAILOUT:* rwm"
      line4="lxc.mount.entry: /var/lib/lxc/$ctID/devices/$usbPATH dev/$usbPATH none bind,optional,create=file"
    elif [[ $(lsusb | grep "$usbdev" | grep -cw "Silicon Labs") -eq 1 ]]; then
      line1="lxc.cgroup2.devices.allow: c $usbDEVICEID:* rwm"
      line2="lxc.mount.entry: $usbPRODUCTNAME dev/serial/by-id/$usbPRODUCTNAME none bind,optional,create=file"
      line3="lxc.cgroup2.devices.allow: c $usbDAILOUT:* rwm"
      line4="lxc.mount.entry: /dev/$usbPATH dev/$usbPATH none bind,optional,create=file"
    fi

    #search for line number to insert if there are deviations in the config file
    if [ $(cat "/etc/pve/lxc/$ctID.conf" | grep -cw "\[") -eq 1 ]; then
      lineNUMBER=$(cat "/etc/pve/lxc/$ctID.conf" | grep -m1 -n "\[" | cut -d: -f1)
      lineNUMBER=$(($lineNUMBER-1))
      #insert text to lxc conigfile
      sed -i "$lineNUMBER i $line1\n$line2\n$line3\n$line4" "/etc/pve/lxc/$ctID.conf"
    else
      #insert text to lxc conigfile
      echo -e "$line1\n$line2\n$line3\n$line4" >> "/etc/pve/lxc/$ctID.conf"
    fi
    chmod o+rw "/dev/$usbPATH"

    #create udev rule
    echo -e "SUBSYSTEMS=="usb", ATTRS{idVendor}=="${usbVENDORID}", ATTRS{idProduct}=="${usbPRODUCTID}", GROUP="users", MODE="0666"" > "/etc/udev/rules.d/50-myusb.rules"
    udevadm control --reload

    #start container
    pct start $ctID
  elif [[ $menuSelection == "2" ]]; then
    #bind DVB-Device
    menuMAIN
  elif [[ $menuSelection == "3" ]]; then
    #bind grafic Card
    menuMAIN
  elif [[ $menuSelection == "4" ]]; then
    #bind Storage
    menuMAIN
  elif [[ $menuSelection == "Q" ]]; then
    #going back
    bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/checkup.sh)
  else
    menuMAIN
  fi
}