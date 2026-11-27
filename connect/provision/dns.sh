apt-get install -y dnsmasq

cat > /etc/dnsmasq.d/dns.conf <<'EOF'
interface=enp0s8
interface=enp0s9
host-record=pc-a,192.168.10.2
host-record=pc-b,192.168.20.2
host-record=gateway,192.168.10.1
host-record=gateway,192.168.20.1
server=1.1.1.1
EOF