This linux consists of installing and configuring a minimal Debian
server in a VirtualBox (VM).     
the server is configured with: 
   * no desktop environment      
   * LVM storage  
   * separate logical volumes for `/`, `/home`, `/var` and swap   
   * a static IPv4 address 
   * DNS configuration  
   * a custom continuously running `systemd` service
   * persistent service logs in the system journal
   * boot-time analysis with `systemd-analyze`

the goal of this document is to provide a reproducible runbook that another poeple can follow to rebuild the same server.

## Installation   

   this is step by step, the installation process used as the base for this linux project.    
   * install VirtualBox
   * download the Debian ISO
   * create a new VM
   * allocate a virtual disk of at least 20-25 GB 
   * select the Debian ISO
   * disable unattended installation
   * start the VM and boot from the Debian ISO
   * select the installation language
   * configure the location
   * configure the locale
   * configure the keyboard
   * configure the hostname
   * set the root password
   * create the normal user account
   * configure the timezone
   * select manual partitioning
   * create a new partition table
   * configure the disk using LVM
   * create a physical volume (PV) on the partition dedicated to LVM
   * create a volume group (VG) named `vg`
   * create logical volumes(LV) for `/`, `/home`, `/var` and swap
   * assign the appropriate filesystem (ext4) and mount point to each logical volume:
      - root: 5 GB, ext4, mounted on `/`    
      - home: 2 GB, ext4, mounted on `/home`      
      - var: 2 GB, ext4, mounted on `/var`  
      - swap: 1 GB, used as swap   
      - leave the remaining space unallocated in the volume group (VG)  
   * write the partition changes to disk  
   * configure the apt mirror (can be skipped)
   * decline the package usage survey
   * select software to install: uncheck "Debian desktop environment", keep only "standard system utilities"
   * install GRUB 
   * finish the Debian installation with minimal system packages installed
   * take a VM snapshot immediately after the clean install
   * verify LVM configuration with `lsblk`, `df -h`, and `vgs` (to confirm free extents remain in the VG)