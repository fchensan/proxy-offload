ulimit -n 100000
if [[ $1 == nginx-host ]]
then
	sudo taskset -c 32-63 dpbench/bin/h1load -e -ll -P -t 32 -s 120 -d 120 -c 1024 -v http://10.10.1.3:80?K=1 | tee data/nginx-host.dat
fi


