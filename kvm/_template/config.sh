#!/bin/bash

################### Load needed Files ###################
source "$script_path/helper/variables.sh"
source "$script_path/helper/functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

################## Get Container Infos ##################
local ID=$1
local PASS="$2"
local IP=$(pct exec ${ctID} ip addr show | grep -w 192.168 | cut -d' ' -f6 | cut -d/ -f1)
local NAME=$(pct exec ${ctID} hostname)

############ Commands to execute in Container ###########
pct exec $ctID -- bash -ci ""
pct exec $ctID -- bash -ci ""
pct exec $ctID -- bash -ci ""
pct exec $ctID -- bash -ci ""

############# Finish/Exit container config ##############
exit 0
