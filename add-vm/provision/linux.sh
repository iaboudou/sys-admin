#!/bin/bash

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
echo "linux.sh: setup error detecter"
###########################


echo "root:123"| chpasswd
echo "linux.sh: root password setted"
###########################


id ilyass 2>/dev/null || useradd -m ilyass
echo "linux.sh: ilyass added as user with /home/ilyass"
###########################


sudo chsh -s /bin/bash ilyass
echo "linux.sh: bash gived to ilyass"
###########################


echo ilyass:ilyass | chpasswd
echo "linux.sh: ilyass password changed"
###########################


sudo echo 'auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.0.2.15
    netmask 255.255.255.0
    gateway 10.0.2.2' > /etc/network/interfaces


sudo rm -f /etc/resolv.conf
echo 'nameserver 1.1.1.1' >>  /etc/resolv.conf
echo "linux.sh: static ip address setted"
###########################


sudo echo '#!/bin/bash
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

sudo chmod +x "/home/myservice.sh"
echo "linux.sh: myservice program is writted to /home/myservice.sh"
###########################


sudo echo "[Unit]
Description=myservice

[Service]
Type=simple
ExecStart=/home/myservice.sh
Restart=always

[Install]
WantedBy=multi-user.target" > "/etc/systemd/system/myservice.service"
echo "linux.sh: myservice.service is writted to /etc/systemd/system/myservice.service"
###########################


sudo systemctl daemon-reload
sudo systemctl enable "myservice.service"
sudo systemctl start "myservice.service"

echo "linux.sh: myservice is started"
###########################