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

the goal of this document is to provide a reproducible runbook that
another poeple can follow to rebuild the same server.