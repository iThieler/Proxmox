#!/bin/bash

source "/root/Proxmox/misc/functions-whiptail.sh"

# Function ping given IP and return TRUE if available
function pingIP() {
  if ping -c 1 $1 &> /dev/null; then
    true
  else
    false
  fi
}

# Function give the entered IP to FUNCTION pingIP. Returns true if IP is pingable if not, you cancheck and change the IP
function check_ip() {
  # Call with: check_ip "192.168.0.1"
  # you can also call with: if check_ip "${nas_ip}"; then ipExist=true; else ipExist=false; fi
  if [ -n $1 ]; then ip="$1"; else ip=""; fi
  while ! pingIP ${ip}; do
    ip=$(whip_alert_inputbox_cancel "OK" "Abbrechen" "${whip_title_fr}" "Die angegebene IP-Adresse kann nicht gefunden werden, bitte prüfen und noch einmal versuchen!" "$(echo ${ip})")
    RET=$?
    if [ $RET -eq 1 ]; then return 1; fi  # Check if User selected cancel
  done
}

# Function checked if an Package is installed, returned true or false
function check_pkg() {
  if [ $(dpkg-query -s "${1}" &> /dev/null | grep -cw "Status: install ok installed") -eq 1 ]; then
    true
  else
    false
  fi
}

# Function generates a random secure Linux password
function generatePassword() {
  # Call with: generatePassword 12 >> 12 is the password length
  chars=({0..9} {a..z} {A..Z} "_" "%" "+" "-" ".")
  for i in $(eval echo "{1..$1}"); do
    echo -n "${chars[$(($RANDOM % ${#chars[@]}))]}"
  done 
}

# Function generates a random API-Key
function generateAPIKey() {
  # Call with: generateAPIKey 32 >> 32 is the API-Key length
  chars=({0..9} {a..f})
  for i in $(eval echo "{1..$1}"); do
    echo -n "${chars[$(($RANDOM % ${#chars[@]}))]}"
  done 
}

# Function update HomeServer (Host)
function updateHost() {
  {
    echo -e "XXX\n12\nSystemupdate wird ausgeführt ...\nXXX"
    if ! apt-get update 2>&1 >/dev/null; then false; fi
    echo -e "XXX\n25\nSystemupdate wird ausgeführt ...\nXXX"
    if ! apt-get upgrade -y 2>&1 >/dev/null; then false; fi
    echo -e "XXX\n47\nSystemupdate wird ausgeführt ...\nXXX"
    if ! apt-get dist-upgrade -y 2>&1 >/dev/null; then false; fi
    echo -e "XXX\n64\nSystemupdate wird ausgeführt ...\nXXX"
    if ! apt-get autoremove -y 2>&1 >/dev/null; then false; fi
    echo -e "XXX\n79\nSystemupdate wird ausgeführt ...\nXXX"
    if ! pveam update 2>&1 >/dev/null; then false; fi
    echo -e "XXX\n98\nSystemupdate wird ausgeführt ...\nXXX"
  } | whiptail --gauge --backtitle "© 2021 - iThieler's Proxmox Script collection" --title " SYSTEMVORBEREITUNG " "Dein HomeServer wird auf Systemupdates geprüft ..." 10 80 0
  return true
}

# Function generates an Filebackup
function bak_file() {
  # Call with: bak_file backup "path/to/file/filename.ext"
  # Call with: bak_file recover "path/to/file/filename.ext"
  mode=$1
  file=$2

  if [[ $mode == "backup" ]]; then
    if [ -f "${file}.bak" ]; then
      rm "${file}.bak"
    fi
    cp "${file}" "${file}.bak"
  elif [[ $mode == "recover" ]]; then
    if [ -f "${file}.bak" ]; then
      rm "${file}"
      cp "${file}.bak" "${file}"
      rm "${file}.bak"
    else
      echoLOG r "Es wurde kein Dateibackup von ${file} gefunden. Die gewünschte Datei konnte nicht wiederhergestellt werden."
    fi
  fi
}

# Function clean the Shell History and exit
function cleanup_and_exit() {
  unset gh_tag
  unset main_language
  unset script_path
  cat /dev/null > ~/.bash_history && history -c && history -w
  sleep 5
  exit
}

# Function write event to logfile and echo colorized in shell
function echoLOG() {
  typ=$1
  text=$2
  nc='\033[0m'
  red='\033[1;31m'
  green='\033[1;32m'
  yellow='\033[1;33m'
  blue='\033[1;34m'
  
  if [ ! -d "${config_path}" ]; then mkdir -p "${config_path}"; fi
  if [ ! -f "${log_file}" ]; then touch "${log_file}"; fi
  
  if [[ $typ == "r" ]]; then
    echo -e "$(date +'%Y-%m-%d  %T')  [${red}ERROR${nc}]  $text"
    echo -e "$(date +'%Y-%m-%d  %T')  [ERROR]  $text" >> "${log_file}"
  elif [[ $typ == "g" ]]; then
    echo -e "$(date +'%Y-%m-%d  %T')  [${green}OK${nc}]     $text"
    echo -e "$(date +'%Y-%m-%d  %T')  [OK]     $text" >> "${log_file}"
  elif [[ $typ == "y" ]]; then
    echo -e "$(date +'%Y-%m-%d  %T')  [${yellow}WAIT${nc}]   $text"
    echo -e "$(date +'%Y-%m-%d  %T')  [WARTE]   $text" >> "${log_file}"
  elif [[ $typ == "b" ]]; then
    echo -e "$(date +'%Y-%m-%d  %T')  [${blue}INFO${nc}]   $text"
    echo -e "$(date +'%Y-%m-%d  %T')  [INFO]   $text" >> "${log_file}"
  fi
}

# Function configures SQL secure in LXC Containers
function lxc_SQLSecure() {
  ctID=${1}
  SECURE_MYSQL=$(expect -c "
  set timeout 3
  spawn mysql_secure_installation
  expect \"Press y|Y for Yes, any other key for No:\"
  send \"n\r\"
  expect \"New password:\"
  send \"${ctRootPW}\r\"
  expect \"Re-enter new password:\"
  send \"${ctRootPW}\r\"
  expect \"Remove anonymous users?\"
  send \"y\r\"
  expect \"Disallow root login remotely?\"
  send \"y\r\"
  expect \"Remove test database and access to it?\"
  send \"y\r\"
  expect \"Reload privilege tables now?\"
  send \"y\r\"
  expect eof
  ")

  pct exec $ctID -- bash -ci "apt-get install -y expect > /dev/null 2>&1"
  pct exec $ctID -- bash -ci "echo \"${SECURE_MYSQL}\" > /dev/null 2>&1"
  pct exec $ctID -- bash -ci "apt-get purge -y expect > /dev/null 2>&1"
}