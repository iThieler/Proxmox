#!/bin/bash

################### Container Configuration ###################
template=${osDebian9}
hddsize=
cpucores=
memory=
swap=
unprivileged=
features="mount=cifs;nfs"

#################### WebGUI Configuration #####################
webgui=true
webguiName=( "" "" "" )
webguiPort=( "" "" "" )
webguiPath=( "" "" "" )
webguiUser=( "" "" "" )
webguiPass=( "" "" "" )
webguiProt=( "" "" "" )

################### Firewall Configuration ####################
fwPort=( "" "" "" )
fwNetw=( "" "" "" )
fwProt=( "" "" "" )
fwDesc=( "" "" "" )

#################### Needed Hardwarebinds #####################
nasneeded=false
dvbneeded=false
vganeeded=false

####################### Needed Services #######################
smtpneeded=false
apparmorProfile=""
sambaneeded=false
sambaUser=""
smarthomeVLAN=false
guestVLAN=false
nasonly=false
userinput=false

################## Descriptions ###################
desc_en=""
desc_de=""

################## Info E-Mail ###################
commands=""

mail_en=""
mail_de=""
