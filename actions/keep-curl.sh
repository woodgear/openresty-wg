#!/bin/bash
while true; do
    date
 	curl -k -i -sS http://127.0.0.1:1984/t
	sleep 1
done
