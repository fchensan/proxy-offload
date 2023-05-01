#!/bin/bash
ulimit -n 1048576
PROXY_ADDR=$2
PROXY_USERNAME=$3
EXPERIMENT_TITLE=$4
if [[ $1 == http ]]
then
	if [[ $1 == nginx-host ]]
	then
		ssh $PROXY_USERNAME@$PROXY_ADDR "rm /tmp/proxy-logs.txt; nohup vmstat 1 60 > /tmp/proxy-logs.txt 2> /dev/null < /dev/null &"
		sudo taskset -c 32-63 dpbench/bin/h1load -e -ll -P -t 32 -s 60 -d 60 -c 3000 -v http://$PROXY_ADDR:80/?s=1g | tee data/$EXPERIMENT_TITLE.dat
		ssh $PROXY_USERNAME@$PROXY_ADDR "cat /tmp/proxy-logs.txt" | tee data-vmstat/$EXPERIMENT_TITLE.dat
	fi
elif [[ $1 == tcp ]]
then
	# echo "Copying over config file"
	scp -r ~/proxy-offload/proxy-host/ $PROXY_USERNAME@$PROXY_ADDR:~/proxy-offload

	# echo "Bootstrap NGINX files"
	# ssh $PROXY_USERNAME@$PROXY_ADDR "~/proxy-offload/proxy-host/nginx-conf/sites-available/generate-tcp-proxy.sh > ~/proxy-offload/proxy-host/nginx-conf/sites-available/tcp-proxy"
	# ssh $PROXY_USERNAME@$PROXY_ADDR "~/proxy-offload/proxy-host/haproxy-conf/generate-haproxy-tcp.sh > ~/proxy-offload/proxy-host/haproxy-conf/haproxy-tcp.cfg"

	ssh $PROXY_USERNAME@$PROXY_ADDR "sudo pkill monitor.sh"
	# ssh $PROXY_USERNAME@$PROXY_ADDR "sudo pkill haproxy"
	# ssh $PROXY_USERNAME@$PROXY_ADDR "sudo pkill nginx"

	# echo "Restarting NGINX in proxy host"
	# ssh $PROXY_USERNAME@$PROXY_ADDR "sudo rm /var/log/nginx/error.log"
	# ssh $PROXY_USERNAME@$PROXY_ADDR "~/proxy-offload/proxy-host/proxy-setup.sh tcp haproxy ~/proxy-offload/proxy-host/haproxy-conf"

	PORT_ONE=$8
	PORT_TWO=$9

	# echo "Starting monitor.sh in proxy host"
	ssh $PROXY_USERNAME@$PROXY_ADDR "~/proxy-offload/proxy-host/monitor-wrapper.sh $PORT_ONE $PORT_TWO 20"

	sleep 3

	PROCESSES=$5
	DURATION=$6
	CLIENT_PORT_START=30000
	SERVER_PORT_END=$((29999+PROCESSES))
	STREAMS_PER_PROCESS=100
	TARGET_BITRATE=$7
	SPAWN_NEW_PROCESS_RATE=1

	# cd /mydata
	mkdir -p $EXPERIMENT_TITLE
	cd $EXPERIMENT_TITLE
	mkdir -p logs-$PROCESSES

	echo "Starting clients."

	echo "Experiment basic data:"
	echo "Title: $EXPERIMENT_TITLE" | tee README.txt
	echo "Datetime: $(date)" | tee -a README.txt
	echo "Iperf processes target: $PROCESSES" | tee -a README.txt
	echo "Duration: $DURATION" | tee -a README.txt
	echo "Streams per process: $STREAMS_PER_PROCESS" | tee -a README.txt
	echo "Target bitrate: $TARGET_BITRATE" | tee -a README.txt
	echo "Sleep between spawning new process: $SPAWN_NEW_PROCESS_RATE sec" | tee -a README.txt

	nohup ~/proxy-offload/proxy-host/monitor.sh $PORT_ONE $PORT_TWO 20 > monitor-client.log 2> /dev/null &
	nohup sar 20 > sar-client.log 2> /dev/null &
	
	START_TIME=$(date +%s)

	for PORT in $(seq $CLIENT_PORT_START $SERVER_PORT_END) 
	do
		echo -ne "$PORT/$SERVER_PORT_END                         \r\c"
		CURR_TIME=$(date +%s)
		ELAPSED_TIME=$(( CURR_TIME-START_TIME ))
		nohup ~/iperf/src/iperf3 -c $PROXY_ADDR -f m -p $PORT -P $STREAMS_PER_PROCESS -b $TARGET_BITRATE -i 0 -t $(( DURATION - ELAPSED_TIME )) > logs-$PROCESSES/iperf3-$PORT.json 2> logs-$PROCESSES/iperf3-$PORT.err &
		sleep $SPAWN_NEW_PROCESS_RATE
		# if [ $PORT -ne $CLIENT_PORT_START ] && [ $((PORT % 200)) -eq 0 ]; then
		# 	sleep 300
		# fi
	done
	echo "$SERVER_PORT_END/$SERVER_PORT_END [Done]"

	sleep 15
	echo "Letting experiment run for another $(( DURATION - ELAPSED_TIME + 10)) second(s). It's currently $(date)"
	sleep $(( DURATION - ELAPSED_TIME + 1210)) 
	echo "Done!"

	# echo "Stopping monitor.sh and retrieving data"
	ssh $PROXY_USERNAME@$PROXY_ADDR "sudo pkill monitor.sh"
	ssh $PROXY_USERNAME@$PROXY_ADDR "sudo pkill sar"
	# sleep 2
	ssh $PROXY_USERNAME@$PROXY_ADDR "cat ~/proxy-offload/proxy-host/data.log" > monitor-server.log
	ssh $PROXY_USERNAME@$PROXY_ADDR "cat ~/proxy-offload/proxy-host/sar-server.log" > sar-server.log
	# ssh $PROXY_USERNAME@$PROXY_ADDR "sudo cat /var/log/nginx/error.log" > nginx-error.log
	# ssh $PROXY_USERNAME@$PROXY_ADDR "sudo pkill haproxy"

	sudo pkill monitor
	sudo pkill sar
fi
