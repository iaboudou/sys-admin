
#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
echo "login.sh: setup started"
###########################

apt update
apt install -y openssh-server acl passwd libpam-modules sudo
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
echo "linux.sh: bash gived to new users "
###########################


addgroup admin
addgroup developer
addgroup deploy
echo "login.sh: 3 role groups are created (admin, developer, deploy)"
###########################

adduser admin1 admin
adduser dev1 developer
adduser deploy1 deploy
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

echo "# 
# /etc/pam.d/common-auth - authentication settings common to all services
#
# This file is included from other service-specific PAM config files,
# and should contain a list of the authentication modules that define
# the central authentication scheme for use on the system
# (e.g., /etc/shadow, LDAP, Kerberos, etc.).  The default is to use the
# traditional Unix authentication mechanisms.
#
# As of pam 1.0.1-6, this file is managed by pam-auth-update by default.
# To take advantage of this, it is recommended that you configure any
# local modules either before or after the default block, and use
# pam-auth-update to manage selection of other modules.  See
# pam-auth-update(8) for details.
#

# here are the per-package modules (the Primary block)
auth    [success=1 default=ignore]  pam_unix.so nullok
auth    [default=die]       pam_faillock.so authfail
auth    sufficient      pam_faillock.so authsucc
auth    required        pam_faillock.so preauth
# here'\''s the fallback if no module succeeds
auth    requisite           pam_deny.so
# prime the stack with a positive return value if there isn'\''t one already;
# this avoids us returning an error just because nothing sets a success code
# since the modules above will each just jump around
auth    required            pam_permit.so
# and here are more per-package modules (the Additional block)
# end of pam-auth-update config" > /etc/pam.d/common-auth

echo "login.sh: account lockout configured"
###########################


echo '# 
# /etc/pam.d/common-account - authorization settings common to all services
#
# This file is included from other service-specific PAM config files,
# and should contain a list of the authorization modules that define
# the central access policy for use on the system.  The default is to
# only deny service to users whose accounts are expired in /etc/shadow.
#
# As of pam 1.0.1-6, this file is managed by pam-auth-update by default.
# To take advantage of this, it is recommended that you configure any
# local modules either before or after the default block, and use
# pam-auth-update to manage selection of other modules.  See
# pam-auth-update(8) for details.
#

# here are the per-package modules (the "Primary" block)
account required            pam_faillock.so
account [success=1 new_authtok_reqd=done default=ignore]    pam_unix.so
# here'\''s the fallback if no module succeeds
account requisite           pam_deny.so
# prime the stack with a positive return value if there isn'\''t one already;
# this avoids us returning an error code
# since the modules above will each just jump around
account required            pam_permit.so
# and here are more per-package modules (the "Additional" block)
# end of pam-auth-update config' > /etc/pam.d/common-account

echo "login.sh: PAM account lockout configured"
###########################


getent group projectrolerwx >/dev/null || addgroup projectrolerwx
getent group projectroler-x >/dev/null || addgroup projectroler-x
echo "login.sh: projectrolerwx and projectroler-x are created"
###########################


adduser admin1 projectrolerwx
adduser dev1 projectrolerwx
echo "dev1 and admin1 are added to the group (projectrolerwx)"
###########################


adduser deploy1 projectroler-x
echo "deploy1 is added to group (projectroler-x)"
###########################


mkdir -p /srv/project
chown root:projectrolerwx /srv/project
chmod 2770 /srv/project
echo "project directory created"
###########################


setfacl -m g:projectroler-x:r-x /srv/project
setfacl -d -m g:projectrolerwx:rwx /srv/project
setfacl -d -m g:projectroler-x:r-x /srv/project
echo "set permission to the project directory"
###########################


mkdir -p /srv/scratch
chmod 1777 /srv/scratch
echo "linux.sh: scratch directory configured"
###########################



echo "# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/usr/local/bin:/usr/bin:/bin:/usr/games

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

Include /etc/ssh/sshd_config.d/*.conf

#Port 22
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

#HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_ecdsa_key
#HostKey /etc/ssh/ssh_host_ed25519_key

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
#AuthorizedKeysFile	.ssh/authorized_keys .ssh/authorized_keys2

#AuthorizedPrincipalsFile none

#AuthorizedKeysCommand none
#AuthorizedKeysCommandUser nobody

# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
#IgnoreUserKnownHosts no
# Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
PasswordAuthentication no
#PermitEmptyPasswords no

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
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

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the KbdInteractiveAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via KbdInteractiveAuthentication may bypass
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and KbdInteractiveAuthentication to 'no'.
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

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*


# override default of no subsystems
Subsystem	sftp	/usr/lib/openssh/sftp-server

# Example of overriding settings on a per-user basis
#Match User anoncvs
#	X11Forwarding no
#	AllowTcpForwarding no
#	PermitTTY no
#	ForceCommand cvs server" > /etc/ssh/sshd_config
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
echo "login.sh: users becomes owners of the ssh files"