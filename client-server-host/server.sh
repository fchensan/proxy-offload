#!/bin/bash
ulimit -n 1048576
if [[ $1 == http ]]
then
	for i in {0..31}
		do sudo taskset -c 0-31 dpbench/bin/httpterm -D -L :80
	done
elif [[ $1 == tcp ]]
then
	sudo pkill iperf
	sleep 2
	echo "Starting servers."
	PROCESSES=$2
	SERVER_PORT_START=40000
	SERVER_PORT_END=$((39999+PROCESSES))
	for PORT in $(seq $SERVER_PORT_START $SERVER_PORT_END)
	do
	 	echo -ne "$PORT/$SERVER_PORT_END                         \r\c"
		~/iperf/src/iperf3 -s -p $PORT -i 0 -D --rcv-timeout 300000 
	done
	echo "$SERVER_PORT_END/$SERVER_PORT_END [Done]"
fi
