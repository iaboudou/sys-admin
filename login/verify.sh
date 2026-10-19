#!/bin/bash

PASS=0
FAIL=0


# check full root access

if ! sudo -l -U dev1 | grep -qE "\(ALL"; then
    echo "PASS: dev1 has no full root access"
    ((PASS++))
else
    echo "FAIL: dev1 has full root access"
    ((FAIL++))
fi


if ! sudo -l -U deploy1 | grep -qE "\(ALL"; then
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


# manage users
if ! sudo -l -U dev1 | grep -qE "adduser|useradd|usermod|passwd"; then
    echo "PASS: dev1 cannot manage users"
    ((PASS++))
else
    echo "FAIL: dev1 can manage users"
    ((FAIL++))
fi


if ! sudo -l -U deploy1 | grep -qE "adduser|useradd|usermod|passwd"; then
    echo "PASS: deploy1 cannot manage users"
    ((PASS++))
else
    echo "FAIL: deploy1 can manage users"
    ((FAIL++))
fi


# shared 'project' directory
if sudo -u deploy1 touch /srv/project/check.txt 2>/dev/null; then
    echo "FAIL: deploy1 can create files in /srv/project"
    ((FAIL++))
    rm -f /srv/project/check.txt
else
    echo "PASS: deploy1 cannot create files in /srv/project"
    ((PASS++))
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