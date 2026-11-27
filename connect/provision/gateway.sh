#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# enable getway to route packets between subnets (so that packets can be send between interfaces) 
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-forward.conf 
sysctl --system 


apt-get update
apt-get install -y nftables

# write the rules 
cat > /etc/nftables.conf <<'EOF'
flush ruleset

table ip nat {
    chain postrouting {
        type nat hook postrouting priority 1;
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

systemctl restart nftables