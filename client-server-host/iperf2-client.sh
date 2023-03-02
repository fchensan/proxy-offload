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
	sudo iperf -s -p 40001 -D -o iperf-server.log 2> iperf-server.err
	# sudo iperf -s -p 5004 -D -o iperf-server2.log 2> iperf-server2.err
	# sudo iperf -s -p 5006 -D -o iperf-server3.log 2> iperf-server3.err
	# sudo iperf -s -p 5008 -D -o iperf-server4.log 2> iperf-server4.err
	# sudo iperf -s -p 5010 -D -o iperf-server5.log 2> iperf-server5.err
	# sudo iperf -s -p 5012 -D -o iperf-server6.log 2> iperf-server6.err
	# sudo iperf -s -p 5014 -D -o iperf-server7.log 2> iperf-server7.err
	# sudo iperf -s -p 5016 -D -o iperf-server8.log 2> iperf-server8.err
	sleep 3
	for ITERATION in {0..3}
	echo $ITERATION
	nohup iperf -c $2 -p $ITERATION -o iperf-logs/iperf.log -P $3 -t 1000 2> test.log &
	sleep 20
	# echo "Starting second one"
	# nohup iperf -c $2 -p 5003 -o iperf-logs/iperf2.log -P $3 -t 1000 2> test2.log &
	# sleep 20
	# echo "Starting third one"
	# nohup iperf -c $2 -p 5005 -o iperf-logs/iperf3.log -P $3 -t 1000 2> test3.log &
	# sleep 20
	# echo "Starting fourth one"
	# nohup iperf -c $2 -p 5007 -o iperf-logs/iperf4.log -P $3 -t 1000 2> test4.log &
	# sleep 20
	# echo "Starting fourth one"
	# nohup iperf -c $2 -p 5009 -o iperf-logs/iperf5.log -P $3 -t 1000 2> test5.log &
	# sleep 20
	# echo "Starting fourth one"
	# nohup iperf -c $2 -p 5011 -o iperf-logs/iperf6.log -P $3 -t 1000 2> test6.log &
	# sleep 20
	# echo "Starting fourth one"
	# nohup iperf -c $2 -p 5013 -o iperf-logs/iperf7.log -P $3 -t 1000 2> test7.log &
	# sleep 20
	# echo "Starting fourth one"
	# nohup iperf -c $2 -p 5015 -o iperf-logs/iperf8.log -P $3 -t 1000 2> test8.log &
	# sleep 20
fi
