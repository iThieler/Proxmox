#!/bin/bash

ctID=$1
ctIP=$2
ctRootpw="$3"
containername="$4"
script_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cut -d/ -f1,2,3)

source "$script_path/helper/variables.sh"
source "$script_path/helper/functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

pct exec $ctID -- bash -ci "wget -qO - http://downloads-global.3cx.com/downloads/3cxpbx/public.key | apt-key add - > /dev/null 2>&1"
pct exec $ctID -- bash -ci "echo \"deb http://downloads-global.3cx.com/downloads/debian stretch main\" | tee /etc/apt/sources.list.d/3cxpbx.list > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get install -y iperf libicu57 libicu57 dphys-swapfile > /dev/null 2>&1"

exit 0
