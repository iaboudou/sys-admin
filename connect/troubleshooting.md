### Problem 1 : Vagrant cannot configure pc-a network interface

1. Error: Vagrant failed to configure `enp0s8` because `/etc/network/interfaces` contained an empty `address` value.
    - ![](/screenshots/interface.png)
2. Cause: Vagrant tried to configure the interface with a static IP, but no IP address was provided.
3. Solution:
   - Checked `/etc/network/interfaces` using `nl -ba /etc/network/interfaces`.
   - Found the empty `address` option on line 19.
   - Added `auto_config: false` to prevent Vagrant from configuring the interface.
   - Let the DHCP server on `gateway` assign the IP address.


### Problem 2 : Network configuration error on pc-b

1. Error: Netplan showed an error because the YAML file had incorrect indentation.

    - ![](/screenshots/network-yamlfile.png)

2. Cause: route-metric: 0 was not placed correctly under dhcp4-overrides.
3. Solution: Fixed the indentation and applied the network configuration again.

### Problem 3 : pc-b cannot reach pc-a

1. Error: Ping to 192.168.10.2 failed, and pc-a could not be found

    - ![](/screenshots/from-pc-b-ping-unreachable.png)

2. Cause: Network communication not working correctly.
3. Solution: 

- check the ip : `ip a`

    - ![](/screenshots/ip-not-set-from-dhcp.png)

- add dhcp-range to `/etc/dnsmasq.d/dhcp.conf` 

    - ![](/screenshots/dhcp-range.png)

- restart provision with `vagrant provision gateway`

    - ![](/screenshots/set-ip-to-pc-b.png)
    - ![](/screenshots/ping-pc-b.png)

### Problem 4 : pc-a cannot resolve pc-b hostname

1. Error: pc-a could ping pc-b using its IP address (192.168.20.2), but could not find pc-b using its hostname (pc-b).
    - ![](/screenshots/ping-from-pc-a.png)

2. Cause: DNS name resolution was not working correctly.
3. Solution: 
    - Checked the DNS server configuration 
    - then check the `/etc/resolv.conf` is correctly configured 

    - ![](/screenshots/dns-resolution.png)


