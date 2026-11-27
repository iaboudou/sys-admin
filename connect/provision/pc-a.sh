apt-get update
apt-get install -y resolvconf traceroute netplan.io


cat > /etc/netplan/pc-a.yaml << 'EOF'
network:
    version: 2
    renderer: networkd
    ethernets:
        enp0s3:
            dhcp4: true
            dhcp4-overrides:
                route-metric: 1
                use-routes: false
                use-dns: false
        enp0s8:
            dhcp4: true
            dhcp4-overrides:
                route-metric: 0
EOF

chmod 600 /etc/netplan/pc-a.yaml
resolvconf -u
netplan apply

cat > /etc/resolvconf/resolv.conf.d/head << 'EOF'
nameserver 192.168.10.1
EOF