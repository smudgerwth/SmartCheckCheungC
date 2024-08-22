#!/bin/bash
source .venv/bin/activate
while true; do
    HOUR="$(date +'%H')"
    if [ "$HOUR" -ge 7 ]; then
	    time python3 main.py | tee debug.log
    fi
    sleep 300
    sudo sh -c "/usr/bin/echo 3 > /proc/sys/vm/drop_caches"
done
