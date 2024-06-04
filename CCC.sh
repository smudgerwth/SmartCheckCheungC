#!/bin/bash
while true; do
    HOUR="$(date +'%H')"
    if [ "$HOUR" -ge 7 ]; then
	    time python3 main.py | tee debug.log
    fi
    sleep 300
done
