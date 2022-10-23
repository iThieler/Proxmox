You will need access to your Proxmox node via SSH or directly. This applies to the standard Proxmox setup using LVM. In this example, the hard disk of the VMID 100 is reduced from 16GB to 8GB. On your Proxmox node, do the following:

List containers
```
pct list
```


Stop the container you want to resize
```
pct stop 100
```


Find out it's path on the node
```
lvdisplay | grep "LV Path\|LV Size"
```


Run a file system check
```
e2fsck -fy /dev/pve/vm-100-disk-0
```


Resize the file system
```
resize2fs /dev/pve/vm-100-disk-0 8G
```


Resize the local volume
```
lvreduce -L 8G /dev/pve/vm-100-disk-0
```


Edit the container's conf file
```
nano /etc/pve/lxc/100.conf
```


Update the following line accordingly
```
FROM:
rootfs: local-lvm:vm-100-disk-0,size=16G
TO:
rootfs: local-lvm:vm-100-disk-0,size=8G
```


Start the container
```
pct start 100
```


Enter and check the resize container disk
```
pct enter 100
df -h
```
