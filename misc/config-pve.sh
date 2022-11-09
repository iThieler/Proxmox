#!/bin/bash

source "/root/pve-global-config.sh"
source <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/_functions.sh)

# Enable S.M.A.R.T. support on system hard drive, when disabled and device is SMART-enabled
if [ $(smartctl -a /dev/$(eval $(lsblk -oMOUNTPOINT,PKNAME -P | grep 'MOUNTPOINT="/"'); echo $PKNAME | sed 's|[0-9]*$||') | grep -c "SMART support is: Enabled") -eq 0 ]; then
  if [ $(smartctl -a /dev/$(eval $(lsblk -oMOUNTPOINT,PKNAME -P | grep 'MOUNTPOINT="/"'); echo $PKNAME | sed 's|[0-9]*$||') | grep -c "SMART support is: Unavailable") -eq 0 ]; then
    smartctl -s on -a /dev/$(eval $(lsblk -oMOUNTPOINT,PKNAME -P | grep 'MOUNTPOINT="/"'); echo $PKNAME | sed 's|[0-9]*$||')
  fi
fi

# configure Firewall in Proxmox
mkdir -p /etc/pve/firewall
mkdir -p /etc/pve/nodes/$(hostname)

if [ -n "$vlanDHCPGW" ]; then
  ipsetNETWORK="${vlanSERVERGW}/24\n \
                ${vlanDHCPGW}/24\n\n"
else
  ipsetNETWORK="${vlanSERVERGW}/24\n\n"
fi

echo -e "[OPTIONS]\n \
        enable: 1\n\n \
        [IPSET network] # local Network\n \
        ${ipsetNETWORK} \
        [IPSET pnetwork] # All private Networks, important for VPN\n \
        10.0.0.0/8\n \
        172.16.0.0/12\n \
        192.168.0.0/16\n\n \
        [RULES]\n \
        GROUP proxmox\n\n \
        [group proxmox]\n \
        IN SSH(ACCEPT) -source +network -log nolog\n \
        IN ACCEPT -source +pnetwork -p tcp -dport 8006 -log nolog\n \
        IN ACCEPT -source +pnetwork -p tcp -dport 5900:5999 -log nolog\n \
        IN ACCEPT -source +pnetwork -p tcp -dport 3128 -log nolog\n \
        IN ACCEPT -source +pnetwork -p udp -dport 111 -log nolog\n \
        IN ACCEPT -source +pnetwork -p udp -dport 5404:5405 -log nolog\n \
        IN ACCEPT -source +pnetwork -p tcp -dport 60000:60050 -log nolog\n\n" > /etc/pve/firewall/cluster.fw
echo -e "[OPTIONS]\n \
        enable: 1\n\n \
        [RULES]\n \
        GROUP proxmox\n\n" > /etc/pve/nodes/$(hostname)/host.fw

# create Backuppool
pvesh create /pools --poolid BackupPool --comment "VMs in this pool are backed up daily"

# configure sources.lists
sed -i "s/^deb/#deb/g" /etc/apt/sources.list.d/pve-enterprise.list
cat <<EOF > /etc/apt/sources.list
deb http://ftp.debian.org/debian bullseye main contrib
deb http://ftp.debian.org/debian bullseye-updates main contrib
deb http://security.debian.org/debian-security bullseye-security main contrib
EOF
cat <<EOF >> /etc/apt/sources.list.d/pve-no-subscription.list
deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription
EOF
echo "DPkg::Post-Invoke { \"dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\.js$'; if [ \$? -eq 1 ]; then { echo 'Removing subscription nag from UI...'; sed -i '/data.status/{s/\!//;s/Active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; }; fi\"; };" > /etc/apt/apt.conf.d/no-nag-script
apt --reinstall install proxmox-widget-toolkit &>/dev/null

updateHost

whip_message "PROXMOX" "Die Grundkonfiguration des Servers ist nun abgeschlossen. Der Server muss neu gestartet werden. Nach dem Neustart kann dieses Skript zur installation und konfiguration von Containern und virtuellen Maschinen erneut aufgerufen werden."
