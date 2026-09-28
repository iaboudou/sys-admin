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

the goal of this document is to provide a reproducible runbook that other poeple can follow to rebuild the same server.

## Installation   

   this is step by step, the installation process used as the base for this linux project.    
   * install VirtualBox
   * download the [Debian ISO](https://www.debian.org/download)
   * create a new VM
   * allocate a virtual disk of at least 20-25 GB 
   * select the Debian ISO
   * disable unattended installation
   * start the VM and boot from the Debian ISO
   * select the installation language
   * configure the location
   * configure the locale
   * configure the keyboard
   * if the automatic DHCP configuration fails skip it for later
   * configure the hostname
   * set the root password
   * create the normal user account
   * configure the timezone
   * select manual partitioning
   * create a new empty partition table
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

   ![Screenshot](./screenshots/snapshot1.png)
   ![Screenshot](./screenshots/installation.png)


## Volume size justification

   * `/` root filesystem

      This volume stores the operating system and the main system files. if it runs out of space, the system may   
      have problems installing packages or performing normal operations.    

   * `/home`

      this volume stores users personal files and configuration files. keeping it separate from `/` prevents user    
      files from using all the space available on the root filesystem. if `/home` becomes full, users may no longer   
      be able to create or save files.    

   * `/var`

      this volume contains data that changes while the system is running, such as logs, caches and other service data.  
      if it becomes full, some services may stop working correctly and new log entries may not be written.     

   * `swap`

      Swap provides additional disk space that can be used when the available RAM is low. it is configured as a separate         
      LVM logical volume so its size can be managed independently from the other filesystems. if swap becomes full while      
      RAM is also exhausted, the system may start terminating processes because there is no more available memory.

   Not all the space in the volume group (VG) is allocated during installation. the remaining free space can be checked       
   with the `vgs` command. Keeping some free extents in the VG makes it possible to extend a logical volume later without     
   repartitioning the disk.      

   growing a logical volume and its filesystem can be done while the filesystem is mounted, without unmounting it or losing      
   existing data. Shrinking is more complicated: for ext4, the filesystem must first be unmounted. Because of this, it is        
   useful to leave some free space in the volume group and increase the logical volumes later when more space is actually     
   needed, instead of allocating too much space during installation.     

   let's now demonstrate how to extend a logical volume (LV) while the system is running, without unmounting the filesystem      
   or losing existing data. first, check the current storage state with the `lvs`, `df -h` and `vgs` commands. Then, extend      
   the root logical volume by 500 MB with: `lvextend -L +500M /dev/vg/root`.     

   at this point, the logical volume is larger, but the filesystem itself has not yet been resized. Let's now grow the ext4 filesystem with:       
   `resize2fs /dev/vg/root`      

   finally, check the new size with `lvs` and `df -h`. Some free space must remain in the volume group before extending a     
   logical volume, which is why keeping unused space in the VG during installation is useful.

   ![Screenshot](./screenshots/extendlv.png)


## Configure a static IPv4 address and DNS.

   debian VM uses the enp0s3 interface, let's configure it with a static IPv4 address and DNS servers by editing /etc/network/interfaces :                 
   ```
      auto enp0s3
      iface enp0s3 inet static
         address 10.0.2.5
         netmask 255.255.255.0
         gateway 10.0.2.2
         dns-nameservers 1.1.1.1
   ```      

   note that the IP address, netmask, and gateway must match the VirtualBox network configuration (Bridged Adapter mode), and that     
   this is done by editing the configuration file directly, without any graphical tool.      

   at this point apply the configuration with `systemctl restart networking`, or bring the interface down and up with      
   `ip link set enp0s3 down` and `ip link set enp0s3 up`. then verify the configured IP address and routing table with  
   `ip addr show enp0s3` and `ip route` commands. the output should confirm that enp0s3 has the configured static IP address  
   and that the default route uses the configured gateway.        

## Verify DNS resolution

   the `dns-nameservers` line in /etc/network/interfaces is applied to /etc/resolv.conf automatically when the interface comes up. check           
   that it was written correctly with `cat /etc/resolv.conf`, it should contain a line like `nameserver 1.1.1.1`. if this line is missing,      
   it can be added directly to /etc/resolv.conf instead, though it may be overwritten the next time the interface is restarted.     

   note that without a valid DNS server, domain names will not resolve even if the network itself is working correctly.    

   then test name resolution with `ping google.com`. the output should confirm that the domain name resolves to an IP address and that         
   packets are being exchanged.      

## Verify internet connectivity  

   with the static IP, gateway, and DNS all configured, we can confirm that the machine has full access to the internet.            

   at this point test raw IP connectivity with `ping -c 4 8.8.8.8`, this confirms connectivity independently of DNS. the output  
   should show replies with 0% packet loss, confirming that the interface, routing, and internet access are all working correctly. 


   ![Screenshot](./screenshots/network2.png)


## A service of your own

   we are going to create a service named `myservice`. it runs continuously: it checks whether a specific file exists, recreates it if missing, logs what it did, then sleeps and repeats.

   log in as root (or use `su -`), then create the script on the VM with `nano /home/script.sh` and paste this content:

   `/home/script.sh`:
   ```bash
      #!/bin/bash

      FILE="/home/myservice_check.txt"

      while true; do
          if [ ! -f "$FILE" ]; then
              touch "$FILE"
              echo "$(date '+%Y-%m-%d %H:%M:%S') - file recreated" 
          else
              echo "$(date '+%Y-%m-%d %H:%M:%S') - file exists"
          fi
          sleep 2
      done
   ```
   save and exit nano (`Ctrl+O`, `Enter`, `Ctrl+X`), then make the script executable: `chmod +x /home/script.sh`     

## The systemd unit

   the unit is named `myservice.service`, the same name used consistently in the script, the unit file, and this runbook.     

   create the unit file with `nano /etc/systemd/system/myservice.service` and paste this content:     

   `/etc/systemd/system/myservice.service`:
   ```ini
      [Unit]
      Description=myservice

      [Service]
      Type=simple
      ExecStart=/home/script.sh
      Restart=always

      [Install]
      WantedBy=multi-user.target
   ```

   save and exit nano, then reload systemd, enable the service at boot and start it:

   ```
      systemctl daemon-reload
      systemctl enable myservice.service
      systemctl start myservice.service
   ```

   note that `Restart=always` is used instead of `Restart=on-failure`, because the goal is for the service to come back no    
   matter how it stopped, even a clean/manual kill, and systemd counts a plain kill as a clean exit.  
   `Type=simple` combined with the script's own infinite loop (`while true ... sleep 2`) means systemd only needs to restart     
   the process if it exits unexpectedly - a timer is not needed here since the script itself never exits under normal operation.       

   check that the service is active and enabled: `systemctl status myservice.service`     
   check its logs in the journal: `journalctl -u myservice.service`     

   confirm the file-recreation logic actually works: delete the file manually and verify the service recreates it automatically     
   within a few seconds.      

   ```
      rm "/home/myservice_check.txt"
      sleep 3
      ls -la "/home/myservice_check.txt"
      journalctl -u myservice.service -n 10
   ```

   the file should reappear, and the journal should show a "file recreated" entry followed by "file exists" entries.    
   confirm it survives a crash: kill the process manually and verify systemd restarts it automatically.     
   
   ```
      pkill -f script.sh
      systemctl status myservice.service
   ```

   the status should show the service as active again, with a new PID, and the restart should also be visible in the journal.       
   reboot with `reboot` the VM and check with `systemctl status myservice.service` that the service is running again without     
   manual intervention.    

   ![Screenshot](./screenshots/myservice.png)
   ![Screenshot](./screenshots/systemdunit-journal.png)