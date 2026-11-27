# dhcp
cat > /etc/dnsmasq.d/dhcp.conf <<'EOF'
interface=enp0s8
dhcp-host=08:00:27:00:0a:02,pc-a,192.168.10.2,12h
dhcp-range=192.168.10.100,192.168.10.200,12h
EOF

systemctl restart dnsmasq