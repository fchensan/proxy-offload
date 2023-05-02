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
	SERVER_PORT_START=30000
	SERVER_PORT_END=$((29999+PROCESSES))
	for PORT in $(seq $SERVER_PORT_START $SERVER_PORT_END)
	do
	 	echo -ne "$PORT/$SERVER_PORT_END                         \r\c"
		nohup ~/iperf/src/iperf3 -s -p $PORT -i 0 --verbose --timestamp > logs-server/server-$PORT.log 2> logs-server/server-$PORT.err &
	done
	echo "$SERVER_PORT_END/$SERVER_PORT_END [Done]"
fi
