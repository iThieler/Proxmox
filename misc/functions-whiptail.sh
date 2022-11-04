#!/bin/bash

source "/root/Proxmox/misc/functions-basic.sh"

################################
##   normal Whiptail Boxes    ##
################################

# give an whiptail message box
function whip_message() {
  #call whip_message "title" "message"
  whiptail --msgbox --ok-button " OK " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${1} " "${2}" 0 80
  echoLOG b "${message}"
}

# give a whiptail question box
function whip_yesno() {
  #call whip_yesno "btn1" "btn2" "title" "message"  >> btn1 = true  btn2 = false
  whiptail --yesno --yes-button " ${1} " --no-button " ${2} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${3} " "${4}" 0 80
  yesno=$?
  if [ ${yesno} -eq 0 ]; then true; else false; fi
}

# give a whiptail box with inpput field
function whip_inputbox() {
  #call whip_inputbox "btn" "title" "message" "default value"
  input=$(whiptail --inputbox --ok-button " ${1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${2} " "\n${3}" 0 80 "${4}" 3>&1 1>&2 2>&3)
  if [[ $input == "" ]]; then
    whip_inputbox "$1" "$2" "$3" "$4\n\n!!! Es muss eine Eingabe erfolgen !!!" ""
  else
    echo "${input}"
  fi
}

# give a whiptail box with inpput field and cancel button
function whip_inputbox_cancel() {
  #call whip_inputbox_cancel "btn1" "btn2" "title" "message" "default value"
  input=$(whiptail --inputbox --ok-button " ${1} " --cancel-button " ${2} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${3} " "\n${4}" 0 80 "${5}" 3>&1 1>&2 2>&3)
  if [ $? -eq 1 ]; then
    echo cancel
  else
    if [[ $input == "" ]]; then
      whip_inputbox_cancel "$1" "$2" "$3" "$4\n\n!!! Es muss eine Eingabe erfolgen !!!" ""
    else
      echo "${input}"
    fi
  fi
}

# give a whiptail box with inpput field for passwords
function whip_inputbox_password() {
  #call whip_inputbox "btn" "title" "message"
  input=$(whiptail --passwordbox --ok-button " ${1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${2} " "\n${3}" 10 80 3>&1 1>&2 2>&3)
  if [[ $input == "" ]]; then
    whip_inputbox "$1" "$2" "$3" "$4\n\n!!! Es muss eine Eingabe erfolgen !!!" ""
  else
    echo "${input}"
  fi
}

# give a whiptail box with inpput field for passwords
function whip_inputbox_password_autogenerate() {
  #call whip_inputbox "btn" "title" "message"
  input=$(whiptail --passwordbox --ok-button " ${1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${2} " "\n${3}" 10 80 3>&1 1>&2 2>&3)
  if [[ $input == "" ]]; then
    echo $(generatePassword 26)
  else
    echo "${input}"
  fi
}

function whip_filebrowser() {
  #call whip_filebrowser "startpath"
  #returns $filename and $filepath
  if [ -z $1 ] ; then
    dir_list=$(ls -lhp | grep "^d" | awk '{print $9 "  " $7 $6 "-" $8}' && ls -lhp | grep -v "^d" | grep -v "^l" | grep -v "^total" | awk '{print $9 "  " $7 $6 "-" $8}')
  else
    cd "$1"
    dir_list=$(ls -lhp | grep "^d" | awk '{print $9 "  " $7 $6 "-" $8}' && ls -lhp | grep -v "^d" | grep -v "^l" | grep -v "^total" | awk '{print $9 "  " $7 $6 "-" $8}')
  fi

  curdir=$(pwd)
  if [ "$curdir" == "/" ] ; then  # Check if current dir is root folder
    selection=$(whiptail --menu --ok-button " Select " --cancel-button " Cancel " --backtitle "© 2021 - SmartHome-IoT.net" --title " Dateiauswahl " "Aktueller Pfad\n$curdir" 0 80 0 $dir_list 3>&1 1>&2 2>&3)
  else   # Not root dir so show ../ selection in Menu
    selection=$(whiptail --menu --ok-button " Select " --cancel-button " Cancel " --backtitle "© 2021 - SmartHome-IoT.net" --title " Dateiauswahl " "Aktueller Pfad\n$curdir" 0 80 0 ../ " " $dir_list 3>&1 1>&2 2>&3)
  fi

  RET=$?
  if [ $RET -eq 1 ]; then return 1; fi  # Check if User selected cancel
  
  if [[ -d "$selection" ]]; then  # Check if Directory selected
    whip_filebrowser "$selection"
  elif [[ -f "$selection" ]]; then  # Check if File selected
    if file --mime-type "$selection" | grep -q text; then  # Check if selected File can read as Text-File
      if (whip_yesno "Bestätigen" "Wiederholen" "Auswahl bestätigen" "Pfad     : $curdir\nDateiname: $selection"); then
        filename="$selection"
        filepath="$curdir"    # Return full filepath and filename as selection variables
      else
        whip_filebrowser "$curdir"
      fi
    else   # Not correct fileselection so inform User and restart fileselection
      whip_alert "ERROR" "Du musst eine Datei wählen, dieals Text-Datei gelesenwerden kann (z.B. *.sh oder *.txt)\n$selection"
      whip_filebrowser "$curdir"
    fi
  else
    # Could not detect a file or folder so Try Again
    whip_alert "ERROR" "Fehler beim Wechseln zum Pfad\n$selection"
    whip_filebrowser "$curdir"
  fi
}


#######################################
##   Whiptail Boxes in alert mode    ##
#######################################

# give an whiptail message box in alert mode
function whip_alert() {
  #call whip_alert "title" "message"
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
    whiptail --msgbox --ok-button " OK " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${1} " "${2}" 0 80
    echoLOG r "${message}"
}

# give an whiptail question box in alert mode
function whip_alert_yesno() {
  #call whip_alert_yesno "btn1" "btn2" "title" "message"  >> btn1 = true  btn2 = false
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
    whiptail --yesno --yes-button " ${1} " --no-button " ${2} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${3} " "${4}" 0 80
    yesno=$?
    if [ ${yesno} -eq 0 ]; then echoLOG r "${4} ${blue}${1}${nc}"; else echoLOG r "${4} ${blue}${2}${nc}"; fi
    if [ ${yesno} -eq 0 ]; then true; else false; fi
}

# give a whiptail box with inpput field in alert mode
function whip_alert_inputbox() {
  #call whip_inputbox "btn" "title" "message" "default value"
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
  input=$(whiptail --inputbox --ok-button " ${1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${2} " "\n${3}" 0 80 "${4}" 3>&1 1>&2 2>&3)
  if [[ $input == "" ]]; then
    whip_inputbox "$1" "$2" "$3" "$4\n\n!!! Es muss eine Eingabe erfolgen !!!" ""
  else
    echo "${input}"
  fi
}

# give a whiptail box with inpput field and cancel button in alert mode
function whip_alert_inputbox_cancel() {
  #call whip_inputbox_cancel "btn1" "btn2" "title" "message" "default value"
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
  input=$(whiptail --inputbox --ok-button " ${1} " --cancel-button " ${2} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${3} " "\n${4}" 0 80 "${5}" 3>&1 1>&2 2>&3)
  if [ $? -eq 1 ]; then
    echo cancel
  else
    if [[ $input == "" ]]; then
      whip_inputbox_cancel "$1" "$2" "$3" "$4\n\n!!! Es muss eine Eingabe erfolgen !!!" ""
    else
      echo "${input}"
    fi
  fi
}