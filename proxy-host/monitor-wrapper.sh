#!/usr/bin/bash

nohup ~/proxy-offload/proxy-host/monitor.sh $1 $2 $3 < /dev/null > ~/proxy-offload/proxy-host/data.log 2>&1 &