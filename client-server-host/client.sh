ulimit -n 100000
if [[ $1 == nginx-host ]]
then
	ssh ubuntu@10.10.1.3 "rm /tmp/proxy-logs.txt; nohup vmstat 1 60 > /tmp/proxy-logs.txt 2> /dev/null < /dev/null &"
	sudo taskset -c 32-63 dpbench/bin/h1load -e -ll -P -t 32 -s 60 -d 60 -c 1024 -v http://10.10.1.3:80 | tee data/nginx-host.dat
	ssh ubuntu@10.10.1.3 "cat /tmp/proxy-logs.txt" | tee data-vmstat/nginx-host.dat
fi


