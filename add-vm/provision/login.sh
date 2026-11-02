#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
echo "login.sh: setup started"
###########################

apt-get update
apt-get install -y openssh-server acl passwd libpam-modules sudo
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
echo "vagrant:123" | chpasswd
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
###########################


usermod -aG admin admin1
usermod -aG developer dev1
usermod -aG deploy deploy1
echo "login.sh: users added to their roles"
###########################


echo '%admin ALL=(ALL:ALL) ALL' > /etc/sudoers.d/admin
echo '%developer ALL=(root) NOPASSWD: /usr/bin/systemctl restart myservice, /usr/bin/systemctl restart myservice.service' > /etc/sudoers.d/developer
echo '%deploy ALL=(root) NOPASSWD: /usr/bin/systemctl restart myservice, /usr/bin/systemctl restart myservice.service' > /etc/sudoers.d/deploy
echo "login.sh: permission set to (admin, developer, deploy)"
###########################


chmod 440 /etc/sudoers.d/admin
chmod 440 /etc/sudoers.d/developer
chmod 440 /etc/sudoers.d/deploy

visudo -cf /etc/sudoers.d/admin
visudo -cf /etc/sudoers.d/developer
visudo -cf /etc/sudoers.d/deploy
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


usermod -aG projectrolerwx admin1
usermod -aG projectrolerwx dev1
echo "login.sh: dev1 and admin1 are added to projectrolerwx"
###########################


usermod -aG projectroler-x deploy1
echo "login.sh: deploy1 is added to projectroler-x"
###########################


mkdir -p /srv/project
chown root:projectrolerwx /srv/project
chmod 2770 /srv/project
echo "login.sh: project directory created"
###########################


setfacl -m g:projectroler-x:r-x /srv/project
setfacl -d -m g:projectrolerwx:rwx /srv/project
setfacl -d -m g:projectroler-x:r-x /srv/project
echo "login.sh: permissions set on the project directory"
###########################


mkdir -p /srv/scratch
chmod 1777 /srv/scratch
echo "login.sh: scratch directory configured"
###########################


echo "# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/usr/local/bin:/usr/bin:/bin:/usr/games

# The strategy here is to specify options with their default value
# where possible, but leave them commented.

Include /etc/ssh/sshd_config.d/*.conf

#Port 22
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# Logging
#SyslogFacility AUTH
#LogLevel INFO

# Authentication:

#LoginGraceTime 2m
PermitRootLogin prohibit-password
#StrictModes yes
#MaxAuthTries 6
#MaxSessions 10

PubkeyAuthentication yes

# Expect .ssh/authorized_keys2 to be disregarded by default in future.
#AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2

#AuthorizedPrincipalsFile none

#AuthorizedKeysCommand none
#AuthorizedKeysCommandUser nobody

# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
#IgnoreUserKnownHosts no
#IgnoreRhosts yes

PasswordAuthentication no
#PermitEmptyPasswords no

KbdInteractiveAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes
#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no

UsePAM yes

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
X11Forwarding yes
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
PrintMotd no
#PrintLastLog yes
#TCPKeepAlive yes
#PermitUserEnvironment no
#Compression delayed
#ClientAliveInterval 0
#ClientAliveCountMax 3
#UseDNS no
#PidFile /run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

# no default banner path
#Banner none

AcceptEnv LANG LC_*

Subsystem sftp /usr/lib/openssh/sftp-server

#Match User anoncvs
# X11Forwarding no
# AllowTcpForwarding no
# PermitTTY no
# ForceCommand cvs server" > /etc/ssh/sshd_config
echo "login.sh: /etc/ssh/sshd_config configured"
###########################


mkdir -p /home/admin1/.ssh /home/dev1/.ssh /home/deploy1/.ssh

echo "$PUBLIC_KEY" > /home/admin1/.ssh/authorized_keys
echo "$PUBLIC_KEY" > /home/dev1/.ssh/authorized_keys
echo "$PUBLIC_KEY" > /home/deploy1/.ssh/authorized_keys
echo "login.sh: PUBLIC_KEY inserted to the users"

chmod 700 /home/admin1/.ssh /home/dev1/.ssh /home/deploy1/.ssh
chmod 600 /home/admin1/.ssh/authorized_keys /home/dev1/.ssh/authorized_keys /home/deploy1/.ssh/authorized_keys

chown -R admin1:admin1 /home/admin1/.ssh
chown -R dev1:dev1 /home/dev1/.ssh
chown -R deploy1:deploy1 /home/deploy1/.ssh

echo "login.sh: users are owners of their SSH files"
###########################


sshd -t
systemctl enable ssh
systemctl restart ssh
echo "login.sh: SSH configured and restarted"
###########################