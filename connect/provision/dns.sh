cat > /etc/dnsmasq.d/dns.conf <<'EOF'
interface=eth2
host-record=pc-2,192.168.20.2 
server=1.1.1.1
EOF

systemctl restart dnsmasq