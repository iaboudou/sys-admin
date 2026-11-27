apt-get update
apt-get install -y resolvconf traceroute netplan.io


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

chmod 600 /etc/netplan/pc-b.yaml
resolvconf -u

systemctl restart systemd-networkd
netplan apply

cat > /etc/resolvconf/resolv.conf.d/head << 'EOF'
nameserver 192.168.20.1
EOF