<h1 align="center" id="heading">Scripts for Proxmox</h1>

<p align="center"><sub> Always remember to use due diligence when sourcing scripts and automation tasks from third-party sites. Primarily, I created this collection of scripts to make setting up Proxmox servers easier and also faster for me. If you want to use a script, do it. </sub></p>

<p align="center">
  <a href="https://github.com/iThieler/Proxmox/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" ></a>
  <a href="https://github.com/iThieler/Proxmox/discussions"><img src="https://img.shields.io/badge/%F0%9F%92%AC-Discussions-orange" /></a>
  <a href="https://github.com/iThieler/Proxmox/blob/master/CHANGELOG.md"><img src="https://img.shields.io/badge/🔶-Changelog-blue" /></a>
  <a href="https://ko-fi.com/U7U3FUTLF"><img src="https://img.shields.io/badge/%E2%98%95-Buy%20me%20a%20coffee-red" /></a>
</p>

<h1 align="center" id="heading">Content</h1>

<details>
<summary markdown="span"> Proxmox Host Server </summary>
-------------------- BEGIN SUBMENU --------------------
<details>
<summary markdown="span"> Proxmox Basic config </summary>
 
<p align="center"><img src="https://github.com/home-assistant/brands/blob/master/core_integrations/proxmoxve/icon.png?raw=true" height="100"/></p>

<h1 align="center" id="heading"> Proxmox Basic config </h1>

This script performs the following tasks after creating a configuration file. The configuration file is created by answering questions and is used to find variables for other tasks that are added in the future.
- If not already done and supported by the system hard disk, S.M.A.R.T. support is enabled on it
- The cluster and host firewall is set up and activated
- A backup tool is created in which VMs can be set.
- A cronjob is created, which creates backups of all VMs in the backup pool.
- Proxmox dark mode is activated >> Thanks to [Weilbyte](https://github.com/Weilbyte/PVEDiscordDark) for his work
- The "source" lists are updated and adapted.
  - Adding the correct PVE7 sources
  - Activate the no-subscription repo
  - Deactivating the Subscription Nag
- Complete update of the host server
- Restart of the Host server
 
Run the following in the Proxmox Shell. ⚠️ **PVE7 ONLY**

```bash
bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/misc/global-config-file.sh) install
```
____________________________________________________________________________________________ 
</details>

<details>
<summary markdown="span"> Resize Container Disk (LXC) </summary>
 
<h1 align="center" id="heading"> Resize Container Disk (LXC) </h1>

You will need access to your Proxmox node via SSH or directly. This applies to the standard Proxmox setup using LVM. In this example, the hard disk of the VMID 100 is reduced from 16GB to 8GB. On your Proxmox node, do the following:

List containers
```bash
pct list
```


Stop the container you want to resize
```bash
pct stop 100
```


Find out it's path on the node
```bash
lvdisplay | grep "LV Path\|LV Size"
```


Run a file system check
```bash
e2fsck -fy /dev/pve/vm-100-disk-0
```


Resize the file system
```bash
resize2fs /dev/pve/vm-100-disk-0 8G
```


Resize the local volume
```bash
lvreduce -L 8G /dev/pve/vm-100-disk-0
```


Edit the container's conf file
```bash
nano /etc/pve/lxc/100.conf
```


Update the following line accordingly
```bash
FROM:
rootfs: local-lvm:vm-100-disk-0,size=16G
TO:
rootfs: local-lvm:vm-100-disk-0,size=8G
```


Start the container
```bash
pct start 100
```


Enter and check the resize container disk
```bash
pct enter 100
df -h
```
____________________________________________________________________________________________ 
</details>

--------------------- END SUBMENU ---------------------
</details>

<details>
<summary markdown="span"> LXC Container </summary>
-------------------- BEGIN SUBMENU --------------------
<details>
<summary markdown="span"> LXC 1 </summary>
 
<p align="center"><img src="" height="100"/></p>

<h1 align="center" id="heading"> LXC 1 </h1>

```bash
bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/lxc/*.sh) install
```
____________________________________________________________________________________________ 
</details>

<details>
<summary markdown="span"> LXC 2 </summary>
 
<p align="center"><img src="" height="100"/></p>

<h1 align="center" id="heading"> LXC 2 </h1>

```bash
bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/lxc/*.sh) install
```
____________________________________________________________________________________________ 
</details>

<details>
<summary markdown="span"> LXC 3 </summary>
 
<p align="center"><img src="" height="100"/></p>

<h1 align="center" id="heading"> LXC 3 </h1>

```bash
bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/lxc/*.sh) install
```
____________________________________________________________________________________________ 
</details>

--------------------- END SUBMENU ---------------------
</details>

<details>
<summary markdown="span"> Virtual machines </summary>
-------------------- BEGIN SUBMENU --------------------
<details>
<summary markdown="span"> VM 1 </summary>
 
<p align="center"><img src="" height="100"/></p>

<h1 align="center" id="heading"> VM 1 </h1>

```bash
bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/vm/*.sh) install
```
____________________________________________________________________________________________ 
</details>

<details>
<summary markdown="span"> VM 2 </summary>
 
<p align="center"><img src="" height="100"/></p>

<h1 align="center" id="heading"> VM 2 </h1>

```bash
bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/vm/*.sh) install
```
____________________________________________________________________________________________ 
</details>

<details>
<summary markdown="span"> VM 3 </summary>
 
<p align="center"><img src="" height="100"/></p>

<h1 align="center" id="heading"> VM 3 </h1>

```bash
bash <(curl -s https://raw.githubusercontent.com/iThieler/Proxmox/main/vm/*.sh) install
```
____________________________________________________________________________________________ 
</details>

--------------------- END SUBMENU ---------------------
</details>

<details>
<summary markdown="span"> My Stats & Skills </summary>

<h1 align="center" id="heading">My Stats & Skills</h1>

<p align="center">
  <a href="https://iThieler.github.io/Proxmox/"><img src="https://github-readme-stats.vercel.app/api?username=iThieler&hide=stars&count_private=true&show_icons=true&theme=dark" height="130" /></a>
  <a href="https://iThieler.github.io/Proxmox/"><img src="https://github-readme-stats.vercel.app/api/top-langs?username=iThieler&layout=compact&theme=dark" height="130" /></a>
</p>
</details>
