#!/bin/bash
set -euo pipefail

command -v vagrant >/dev/null || exit 1
command -v VBoxManage >/dev/null || exit 1

rm -rf "$HOME/VirtualBox VMs/hostilyass" 2>/dev/null

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ ! -f "$HOME/.ssh/vm_vagrant" ] || [ ! -f "$HOME/.ssh/vm_vagrant.pub" ]; then
    ssh-keygen -t ed25519 -N "" -f "$HOME/.ssh/vm_vagrant"
fi

ssh-keygen -f ~/.ssh/known_hosts -R '[127.0.0.1]:2222'
echo "run.sh: successfully completed"

