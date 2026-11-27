### connect

Build a routed network with two subnets, entirely from code (`vagrant up`).

### architecture (3 VMs)
----

- gateway: routes between the subnets, does NAT to the internet, runs the DHCP and DNS server, and runs the firewall
- pc-a: client on subnet A. It gets `192.168.10.2` from a DHCP reservation, tied to its fixed MAC address
- pc-b: client on subnet B. It has the static IP `192.168.20.2`

    ![](/diagram.webp)

### addressing plan
----

1. Reserved addresses:

```text
Subnet A      (192.168.10.0/24)
- .0          network address
- .1          gateway + DHCP + DNS server
- .2          pc-a (static DHCP reservation, by MAC)
- .100-.200   DHCP pool
- .255        broadcast

Subnet B      (192.168.20.0/24)
- .0          network address
- .1          gateway + DNS server
- .2          pc-b (static)
- .255        broadcast
```

2. CIDR ranges:

Usable hosts: 254 per subnet ([256 addresses] - [network address `.0`] - [broadcast address `.255`]).
```
Subnet A : 192.168.10.0/24
Subnet B : 192.168.20.0/24
```

3. why /24:
- we have only a few hosts today, so we do not need a big range
- /24 gives 254 hosts, so there is room to grow
- /24 is easy to read: the network ends at .255
- /25 or /26 would also work, but /24 is simpler
- /23 or bigger would waste many addresses

### topology
----

| VM                   | Subnet  | Address                                                        |
| -------------------- | ------- | ---------------------------------------------------------------|
| gateway              | A and B | 192.168.10.1 / 192.168.20.1 (gateway + DHCP + DNS server)      |
| pc-a                 | A       | 192.168.10.2 (DHCP reservation, by MAC)                        |
| pc-b                 | B       | 192.168.20.2 (static)                                          |

- The gateway has two internal interfaces: `enp0s8` on subnet A and `enp0s9` on subnet B.
- `enp0s3` is the NAT interface added by Vagrant on every VM.
- pc-a has a fixed MAC address `08:00:27:00:0a:02` so that the DHCP reservation survives a `vagrant destroy` and `vagrant up`.


### routing
----

Generally the gateway is the machine that connects to both subnets (`enp0s8: 192.168.10.1`, `enp0s9: 192.168.20.1`), and that forwards packets between the subnets and to the internet. Here the gateway acts as the router. So three things are needed:
- enable `IP forwarding` on the gateway,
- give each client a `default route to the gateway`
- also add a NAT (MASQUERADE) rule on the gateway's `enp0s3` interface to replace the source IP addresses of packets coming from both subnets with the gateway's own IP address before forwarding them to the internet. This allows both subnets to access the internet through the gateway.

By default a Linux machine only accepts packets addressed to itself, it ignores all other packets. This behavior changes when IP forwarding is enabled. When IP forwarding is turned on the machine acts like a router. It can take packets that come in through one network interface (like enp0s8) and send them out through another interface (like enp0s9). This allows the machine to pass traffic between networks.
```bash
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-forward.conf  # keep it after reboot
sysctl --system  # read all files in /etc/sysctl.d/
```


#### pc-a

The gateway runs the DHCP server (dnsmasq). It serves only subnet A.
pc-a gets its IP address by DHCP, but the address is always the same. The DHCP server links the MAC address of pc-a (`08:00:27:00:0a:02`) to the IP address `192.168.10.2`. This is called a static lease reservation.
The address `.2` is outside the DHCP pool (`.100` to `.200`). So DHCP never gives it to another host.
pc-a has a fixed MAC address in the Vagrantfile. So the reservation still works after `vagrant destroy` and `vagrant up`.
The Vagrantfile uses `auto_config: false` on the interface of pc-a, and the VirtualBox DHCP server is disabled on `subnet-a`. So our dnsmasq is the only DHCP server.

```bash
cat > /etc/dnsmasq.d/dhcp.conf <<'EOF'
# serve only subnet A
interface=enp0s8
bind-interfaces

# dynamic addresses
dhcp-range=192.168.10.100,192.168.10.200,12h

# static lease reservation
dhcp-host=08:00:27:00:0a:02,pc-a,192.168.10.2,12h

# extra information sent to the clients
dhcp-option=3,192.168.10.1   # default route (router)
dhcp-option=6,192.168.10.1   # DNS server
EOF

# check
ip -br a                          # on pc-a: enp0s8 has 192.168.10.2
cat /var/lib/misc/dnsmasq.leases  # on the gateway: the lease is listed
```


Generally vagrant adds a default route through `enp0s3` (the NAT interface).
If we keep it, `pc-a` goes to the internet without using our gateway.
So here the gateway gives `pc-a` its default route by DHCP (option 3). We tell netplan to give this route the lowest metric (0).
The lowest metric wins, so all traffic goes through the gateway. The route of `enp0s3` stays as a backup.

```bash
cat > /etc/netplan/pc-a.yaml << 'EOF'
network:
    version: 2
    renderer: networkd
    ethernets:
        enp0s3:
            dhcp4: true
            dhcp4-overrides:
                route-metric: 1
        enp0s8:
            dhcp4: true
            dhcp4-overrides:
                route-metric: 0   # give enp0s8 the priority
EOF


# Check:
ip route # default via 192.168.10.1 dev enp0s8 metric 0
```


pc-a must ask our DNS server (dnsmasq on the gateway), not the VirtualBox DNS. We use `resolvconf` and write `nameserver 192.168.10.1` in `/etc/resolvconf/resolv.conf.d/head`. This line is always at the top of `/etc/resolv.conf`.
```bash
cat /etc/resolv.conf 
```

The subnets use private addresses (192.168.x.x). The internet cannot route them. So the gateway does NAT.
When a packet from a subnet leaves by `enp0s3`, the gateway replaces the source IP with its own IP on `enp0s3`. This is called MASQUERADE. When the answer comes back, the gateway sends it to the right client.
The NAT rule is part of `/etc/nftables.conf` (see the Firewall part).

```
table ip nat {
    chain postrouting {
        type nat hook postrouting priority 100;
        ip saddr { 192.168.10.0/24, 192.168.20.0/24 } oifname "enp0s3" masquerade
    }
}
```

#### pc-b

pc-b is on subnet B. It has a static IP address, because DHCP serves only subnet A.
We write the IP and the route in netplan. The route has metric 0, so it wins over the NAT route of `enp0s3`. All traffic that is not for subnet B goes to the gateway.

```bash
cat > /etc/netplan/pc-b.yaml << 'EOF'
network:
    version: 2
    renderer: networkd
    ethernets:
        enp0s3:
            dhcp4: true
        enp0s8:
            addresses:
                - 192.168.20.2/24
            nameservers:
                addresses: [192.168.20.1]
            routes:
                - to: default
                  via: 192.168.20.1
                  metric: 0
EOF
```

pc-b must ask our DNS server, not the VirtualBox DNS. We use `resolvconf` and write `nameserver 192.168.20.1` in `/etc/resolvconf/resolv.conf.d/head` like pc-a

```bash
cat > /etc/resolvconf/resolv.conf.d/head << 'EOF'
nameserver 192.168.20.1
EOF
```

```bash
# check
ip -br a
ip route get 1.1.1.1
dig pc-b
```


### DNS
----

The gateway runs the DNS server (dnsmasq). It listens on both subnets, on port 53. Each host has a `host-record`, so the names come from our server and not from `/etc/hosts`. Other names go to `1.1.1.1`.

```bash
cat > /etc/dnsmasq.d/dns.conf <<'EOF'
port=53
interface=enp0s8
interface=enp0s9
bind-interfaces
host-record=pc-a,192.168.10.2
host-record=pc-b,192.168.20.2
host-record=gateway,192.168.10.1
host-record=gateway,192.168.20.1
server=1.1.1.1
EOF

systemctl restart dnsmasq

# check (on a client)
dig pc-b @192.168.10.1
ping -c1 pc-b
```


### Firewall
----

The firewall runs on the gateway with `nftables`. The rules are in `/etc/nftables.conf` (written by `provision/gateway.sh`).
The `forward` chain has `policy drop`. All traffic that crosses the gateway is blocked, unless a rule allows it.


| Rule                                                       | Why                                           |
| -----------------------------------------------------------| --------------------------------------------- |
| ICMP                                                       | pc-a and pc-b can ping each other             |
| TCP port 22 (SSH), from subnet A to subnet B               | the one service allowed between the subnets   |
| Replies of connections already allowed (`established`)     | without it, the answers are blocked           |
| Subnet A and B to `enp0s3`                                 | both subnets reach the internet (NAT)         |

```bash
cat > /etc/nftables.conf <<'EOF'
flush ruleset

table ip nat {
    chain postrouting {
        type nat hook postrouting priority 100;
        ip saddr { 192.168.10.0/24, 192.168.20.0/24 } oifname "enp0s3" masquerade
    }
}

table inet filter {
    chain forward {
        type filter hook forward priority 0; policy drop;
        ct state established accept
        ip protocol icmp accept
        iifname "enp0s8" oifname "enp0s9" tcp dport 22 accept
        iifname { "enp0s8", "enp0s9" } oifname "enp0s3" accept
    }
}
EOF

# check (on pc-a)
nc -zv -w3 192.168.20.2 22   # open
nc -zv -w3 192.168.20.2 80   # timeout

nft list ruleset
```
