for i in {1..59}
do 
	DATE=$(date)
	STATS=$(vmstat -s | awk '{print $1}' | tr '\n' ' ')
	echo "$DATE $STATS" >> /tmp/proxy-sys-stats.log
	sleep 1 
done
