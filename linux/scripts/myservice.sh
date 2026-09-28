#!/bin/bash

FILE="/home/myservice_check.txt"

while true; do
    if [ ! -f "$FILE" ]; then
        touch "$FILE"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - file recreated" 
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - file exists"
    fi
    sleep 2
done