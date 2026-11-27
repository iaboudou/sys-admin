#!/bin/bash

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
echo "linux.sh: setup started"
###########################

echo 'iface enp0s3 inet static
    address 10.0.2.15
    netmask 255.255.255.0
    gateway 10.0.2.2' > /etc/network/interfaces.d/enp0s3

echo 'nameserver 1.1.1.1' > /etc/resolv.conf
echo "linux.sh: static IP and DNS configured"
###########################


echo '#!/bin/bash
FILE="/home/myservice_check.txt"
while true; do
  if [ ! -f "$FILE" ]; then
    touch "$FILE"
    echo "$(date "+%Y-%m-%d %H:%M:%S") - file recreated"
  else
    echo "$(date "+%Y-%m-%d %H:%M:%S") - file exists"
  fi
  sleep 2
done' > "/home/myservice.sh"

chmod +x /home/myservice.sh
echo "linux.sh: myservice program written to /home/myservice.sh"
###########################


echo "[Unit]
Description=myservice
StartLimitIntervalSec=0

[Service]
Type=simple
ExecStart=/home/myservice.sh
Restart=always

[Install]
WantedBy=multi-user.target" > "/etc/systemd/system/myservice.service"

echo "linux.sh: myservice.service written to /etc/systemd/system/myservice.service"
###########################

systemctl daemon-reload
systemctl enable myservice.service
systemctl reset-failed myservice.service 2>/dev/null || true
systemctl restart myservice.service

echo "linux.sh: myservice is started"
###########################