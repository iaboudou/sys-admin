#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
echo "login.sh: setup started"
###########################

apt-get update
apt-get install -y openssh-server acl passwd libpam-modules sudo curl
echo "login.sh: required packages for login are installed"
###########################


id admin1 2>/dev/null || useradd -m admin1
id dev1 2>/dev/null || useradd -m dev1
id deploy1 2>/dev/null || useradd -m deploy1
echo "login.sh: 3 users are created (admin1, dev1, deploy1)"
###########################


echo "admin1:admin1" | chpasswd
echo "dev1:dev1" | chpasswd
echo "deploy1:deploy1" | chpasswd
echo "login.sh: users passwords set"
###########################


chsh -s /bin/bash admin1
chsh -s /bin/bash dev1
chsh -s /bin/bash deploy1
echo "login.sh: bash given to new users"
###########################


getent group admin >/dev/null || addgroup admin
getent group developer >/dev/null || addgroup developer
getent group deploy >/dev/null || addgroup deploy
echo "login.sh: 3 role groups are created (admin, developer, deploy)"
# ###########################


adduser admin1 admin 2>/dev/null
adduser dev1 developer 2>/dev/null
adduser deploy1 deploy 2>/dev/null
echo "login.sh: users added to their roles"
# ###########################


echo '%admin ALL=(ALL:ALL) ALL' > /etc/sudoers.d/admin
echo '%developer ALL=(root) NOPASSWD: /usr/bin/systemctl restart myservice, /usr/bin/systemctl restart myservice.service' > /etc/sudoers.d/developer
echo '%deploy ALL=(root) NOPASSWD: /usr/bin/systemctl restart myservice, /usr/bin/systemctl restart myservice.service' > /etc/sudoers.d/deploy
echo "login.sh: permission set to (admin, developer, deploy)"
# ###########################


chmod 440 /etc/sudoers.d/admin
chmod 440 /etc/sudoers.d/developer
chmod 440 /etc/sudoers.d/deploy

echo "login.sh: sudo privileges configured"
###########################


chage -m 7 -M 90 -W 14 -I 30 admin1
chage -m 7 -M 90 -W 14 -I 30 dev1
chage -m 7 -M 90 -W 14 -I 30 deploy1

echo "login.sh: password aging configured"
###########################


echo "deny = 3
fail_interval = 900
unlock_time = 600" > /etc/security/faillock.conf
###########################

echo "# /etc/pam.d/common-auth
# Authentication settings for all services.

auth    required                    pam_faillock.so preauth silent
auth    [success=1 default=bad]      pam_unix.so nullok
auth    [default=die]                pam_faillock.so authfail
auth    sufficient                  pam_faillock.so authsucc
auth    requisite                   pam_deny.so
auth    required                    pam_permit.so" > /etc/pam.d/common-auth

echo "login.sh: account lockout configured"
###########################


echo "# /etc/pam.d/common-account
# Account settings for all services.

account required                    pam_faillock.so
account [success=1 new_authtok_reqd=done default=ignore] pam_unix.so
account requisite                   pam_deny.so
account required                    pam_permit.so" > /etc/pam.d/common-account

echo "login.sh: PAM account lockout configured"
###########################


getent group projectrolerwx >/dev/null || addgroup projectrolerwx
getent group projectroler-x >/dev/null || addgroup projectroler-x
echo "login.sh: projectrolerwx and projectroler-x are created"
###########################


adduser admin1 projectrolerwx 2>/dev/null
adduser dev1 projectrolerwx 2>/dev/null
echo "login.sh: dev1 and admin1 are added to projectrolerwx"
# ###########################


adduser deploy1 projectroler-x 2>/dev/null
echo "login.sh: deploy1 is added to projectroler-x"
# ###########################


mkdir -p /srv/project
chown root:projectrolerwx /srv/project
chmod 2770 /srv/project
echo "login.sh: project directory created"
# ###########################


setfacl -m g:projectroler-x:r-x /srv/project
setfacl -d -m g:projectrolerwx:rwx /srv/project
setfacl -d -m g:projectroler-x:r-x /srv/project
echo "login.sh: permissions set on the project directory"
# ###########################


mkdir -p /srv/scratch
chmod 1777 /srv/scratch
echo "login.sh: scratch directory configured"
# ###########################


echo "PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password" > /etc/ssh/sshd_config.d/1-disablepassword.conf

sshd -t && systemctl restart ssh
echo "login.sh: /etc/ssh/sshd_config.d/1-disablepassword.conf"
###########################

sshd -t
systemctl enable ssh
systemctl restart ssh
echo "login.sh: SSH configured and restarted"
###########################