#!/bin/bash

PASS=0
FAIL=0


# check full root access -------------------------------

if ! sudo -l -U dev1 | grep -qE "NOPASSWD: ALL|\) ALL$|\(ALL"; then
    echo "PASS: dev1 has no full root access"
    ((PASS++))
else
    echo "FAIL: dev1 has full root access"
    ((FAIL++))
fi


if ! sudo -l -U deploy1 | grep -qE "NOPASSWD: ALL|\) ALL$|\(ALL"; then
    echo "PASS: deploy1 has no full root access"
    ((PASS++))
else
    echo "FAIL: deploy1 has full root access"
    ((FAIL++))
fi


if sudo -l -U admin1 | grep -qE "\(ALL"; then
    echo "PASS: admin1 has full root access"
    ((PASS++))
else
    echo "FAIL: admin1 lacks full root access"
    ((FAIL++))
fi


# manage users -------------------------------------------

# dev1 shouldn't hava access to manage
if ! sudo -l -U dev1 | grep -qE "adduser|useradd|usermod|passwd"; then
    echo "PASS: dev1 cannot manage users"
    ((PASS++))
else
    echo "FAIL: dev1 can manage users"
    ((FAIL++))
fi


# deploy1 shoudn't have access to manage
if ! sudo -l -U deploy1 | grep -qE "adduser|useradd|usermod|passwd"; then
    echo "PASS: deploy1 cannot manage users"
    ((PASS++))
else
    echo "FAIL: deploy1 can manage users"
    ((FAIL++))
fi


# dev1 shouldn't be able to install packages
if sudo -u dev1 sudo -n -l /usr/bin/apt >/dev/null 2>&1; then
    echo "FAIL: dev1 can install packages"
    ((FAIL++))
else
    echo "PASS: dev1 cannot install packages"
    ((PASS++))
fi

# deploy1 shouldn't be able to install packages
if sudo -u deploy1 sudo -n -l /usr/bin/apt >/dev/null 2>&1; then
    echo "FAIL: deploy1 can install packages"
    ((FAIL++))
else
    echo "PASS: deploy1 cannot install packages"
    ((PASS++))
fi


# shared 'project' directory ------------------------------

# deploy1 shouldn't have access to create a file
if sudo -u deploy1 touch /srv/project/check.txt 2>/dev/null; then
    echo "FAIL: deploy1 can create files in /srv/project"
    ((FAIL++))
    rm -f /srv/project/check.txt
else
    echo "PASS: deploy1 cannot create files in /srv/project"
    ((PASS++))
fi

# dev1 should have access to create a file
if sudo -u dev1 touch /srv/project/check.txt 2>/dev/null; then
    echo "PASS: dev1 can create files in /srv/project"
    ((PASS++))
    rm -f /srv/project/check.txt
else
    echo "FAIL: dev1 cannot create files in /srv/project"
    ((FAIL++))
fi

# admin1 should have access to create a file
if sudo -u admin1 touch /srv/project/check.txt 2>/dev/null; then
    echo "PASS: admin1 can create files in /srv/project"
    ((PASS++))
    rm -f /srv/project/check.txt
else
    echo "FAIL: admin1 cannot create files in /srv/project"
    ((FAIL++))
fi

# dev1 creates a file
sudo -u dev1 bash -c 'echo hello > /srv/project/shared.txt'

# admin1 edits the dev1's file without chmod
if sudo -u admin1 bash -c 'echo ok >> /srv/project/shared.txt' 2>/dev/null; then
    echo "PASS: admin1 can edit dev1's file"
    ((PASS++))
else
    echo "FAIL: admin1 cannot edit dev1's file"
    ((FAIL++))
fi

# deploy1 can read the file 
if sudo -u deploy1 cat /srv/project/shared.txt >/dev/null 2>&1; then
    echo "PASS: deploy1 can read files in /srv/project"
    ((PASS++))
else
    echo "FAIL: deploy1 cannot read files in /srv/project"
    ((FAIL++))
fi

# deploy1 cannot write to the file
if sudo -u deploy1 bash -c 'echo x >> /srv/project/shared.txt' 2>/dev/null; then
    echo "FAIL: deploy1 can write to files in /srv/project"
    ((FAIL++))
else
    echo "PASS: deploy1 cannot write to files in /srv/project"
    ((PASS++))
fi

# ilyass has no access to the files
if sudo -u ilyass ls /srv/project >/dev/null 2>&1; then
    echo "FAIL: ilyass can read /srv/project"
    ((FAIL++))
else
    echo "PASS: ilyass cannot read /srv/project"
    ((PASS++))
fi

rm -f /srv/project/shared.txt


# scratch directory --------------------------------------

# deploy1 should have access to create a file
if sudo -u deploy1 touch /srv/scratch/from_deploy1.txt 2>/dev/null; then
    echo "PASS: deploy1 can create files in /srv/scratch"
    ((PASS++))
else
    echo "FAIL: deploy1 cannot create files in /srv/scratch"
    ((FAIL++))
fi

# dev1 shouldn't have access to remove file created by deploy1
if sudo -u dev1 rm -f /srv/scratch/from_deploy1.txt 2>/dev/null; then
    echo "FAIL: dev1 can delete deploy1's file (sticky bit broken)"
    ((FAIL++))
else
    echo "PASS: dev1 cannot delete deploy1's file (sticky bit works)"
    ((PASS++))
fi

# deploy1 should be able to remove its own file
if sudo -u deploy1 rm -f /srv/scratch/from_deploy1.txt 2>/dev/null; then
    echo "PASS: deploy1 can delete its own file (sticky bit works)"
    ((PASS++))
else
    echo "FAIL: deploy1 cannot delete its own file (sticky bit broken)"
    ((FAIL++))
fi

rm -f /srv/scratch/from_deploy1.txt

# restart services ---------------------------------------

# dev1 can restart myservice
if sudo -u dev1 sudo -n systemctl restart myservice 2>/dev/null; then
    echo "PASS: dev1 can restart myservice"
    ((PASS++))
else
    echo "FAIL: dev1 cannot restart myservice"
    ((FAIL++))
fi

# deploy1 can restart myservice
if sudo -u deploy1 sudo -n systemctl restart myservice 2>/dev/null; then
    echo "PASS: deploy1 can restart myservice"
    ((PASS++))
else
    echo "FAIL: deploy1 cannot restart myservice"
    ((FAIL++))
fi

# dev1 shouldn't have access to restart ssh
if sudo -u dev1 sudo -n systemctl restart ssh 2>/dev/null; then
    echo "FAIL: dev1 can restart other services"
    ((FAIL++))
else
    echo "PASS: dev1 cannot restart other services"
    ((PASS++))
fi

# deploy1 shouldn't have access to restart ssh
if sudo -u deploy1 sudo -n systemctl restart ssh 2>/dev/null; then
    echo "FAIL: deploy1 can restart other services"
    ((FAIL++))
else
    echo "PASS: deploy1 cannot restart other services"
    ((PASS++))
fi

# ssh test ----------------------------------------------

if sshd -T | grep -q "passwordauthentication no"; then
    echo "PASS: SSH password authentication is disabled"
    ((PASS++))
else
    echo "FAIL: SSH password authentication is enabled"
    ((FAIL++))
fi


# print the result and exit with a status code
echo
echo "--------------------------------"
echo "$PASS tests passed"
echo "$FAIL tests failed"
echo "--------------------------------"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi
exit 0