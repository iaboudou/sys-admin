apt-get install -y dnsmasq

cat > /etc/dnsmasq.d/dhcp.conf <<'EOF'
interface=eth1
bind-interfaces
dhcp-range=192.168.10.100,192.168.10.200,12h
dhcp-host=08:00:27:00:0a:02,pc-1,192.168.10.2
dhcp-option=121,192.168.20.0/24,192.168.10.1,0.0.0.0/0,192.168.10.1
EOF

systemctl restart dnsmasq