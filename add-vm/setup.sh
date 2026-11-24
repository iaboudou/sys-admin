#!/bin/bash

# install vagrant
mkdir -p "$HOME/.local/bin"
wget "https://releases.hashicorp.com/vagrant/2.4.9/vagrant_2.4.9_linux_amd64.zip" -O /tmp/vagrant.zip
unzip -o /tmp/vagrant.zip -d "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"

# 
echo "run.sh: vagrant successfully completed installation"

