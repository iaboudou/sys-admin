cat >> /etc/network/interfaces <<'EOF'

auto eth1
iface eth1 inet static
    address 192.168.10.1
    netmask 255.255.255.0

auto eth2
iface eth2 inet static
    address 192.168.20.1
    netmask 255.255.255.0
EOF

# enable getway to route packets between subnets (so that packets can be send between interfaces) 
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-forward.conf 
sysctl --system 


# install nftables
apt-get install -y nftables

# write the rules 
cat > /etc/nftables.conf <<'EOF'
#!/usr/sbin/nft -f

flush ruleset
EOF

systemctl enable nftables
systemctl restart nftables


apt-get install -y tcpdump