#!/bin/bash

################### Container Configuration ###################

template=${osDebian9}
hddsize=32
cpucores=1
memory=1024
swap=1024
unprivileged=0
features="mount=cifs;nfs"

#################### WebGUI Configuration #####################

webgui=true
webguiName=( "WebGUI ($(echo ${wrd_0019}))" "WebGUI ($(echo ${wrd_0011}))" "WebGUI ($(echo ${wrd_0018}))" )
webguiPort=( "5001" "5001" "5015" )
webguiPath=( "" "/webclient" "?v=2" )
webguiUser=( "" " " "" )
webguiPass=( "" "$(echo ${des_0001})" "" )
webguiProt=( "http" "http" "http" )

################### Firewall Configuration ####################

fwPort=( "5015" "5001" "5062" "5062" "5063" "5090" "5090" "9000:10999" )
fwNetw=( "network" "pnetwork" "" "" "" "" "" "" )
fwProt=( "tcp" "tcp" "udp" "tcp" "tcp" "udp" "tcp" "udp" )
fwDesc=( "Web interface for initial setup" "Web GUI" "SIP" "SIP" "secure SIP" "Tunnel" "Tunnel" "RTP" )

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
userinput=true

################## Descriptions ###################
desc_en="VoIP Phone System"
desc_de="VoIP Telefonanlage"

################## Info E-Mail ###################
commands="apt-get install -y 3cxpbx"

mail_en="Since user input is required when installing the phone system software, you must log in to the container's console and run the following command. Sorry for the inconvenience."
mail_de="Da bei der Installation der Telefonanlagensoftware Benutzereingaben benötigt werden, musst du dich an der Konsole des Containers einloggen und folgenden Befehl ausführen. Entschuldige die Umstände."
