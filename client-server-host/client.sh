#!/bin/bash
ulimit -n 1048576
if [[ $1 == http ]]
then
	if [[ $1 == nginx-host ]]
	then
		ssh $4@$2 "rm /tmp/proxy-logs.txt; nohup vmstat 1 60 > /tmp/proxy-logs.txt 2> /dev/null < /dev/null &"
		sudo taskset -c 32-63 dpbench/bin/h1load -e -ll -P -t 32 -s 60 -d 60 -c 3000 -v http://$2:80/?s=1g | tee data/$3.dat
		ssh $4@$2 "cat /tmp/proxy-logs.txt" | tee data-vmstat/$3.dat
	fi
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
	 	echo $PORT
		~/iperf/src/iperf3 -s -p $PORT -i 0 -D --snd-timeout 300000
	done
	sleep 3
	echo "Starting clients."
	DURATION=$3
	CLIENT_PORT_START=30000
	SERVER_PORT_END=$((29999+PROCESSES))
	for PORT in $(seq $CLIENT_PORT_START $SERVER_PORT_END) 
	do
		echo $PORT
		nohup ~/iperf/src/iperf3 -c 10.10.1.3 -f m -p $PORT -i 1 -t $DURATION --snd-timeout 300000 > logs/iperf3-$PORT.log 2> logs/iperf3-$PORT.err &
		sleep 1s
	done
	echo "Letting experiment run..."
	sleep $DURATION 
	sleep 5
	echo "Printing reports after waiting for $DURATION"
	for PORT in $(seq $CLIENT_PORT_START $SERVER_PORT_END)
	do
		tail -n 3 logs/iperf3-$PORT.log | head -n 1
	done
fi
