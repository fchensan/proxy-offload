for i in {1..59}
do 
#	DATE=$(date)
	STATS=$(vmstat -s | awk '{print $1}' | tr '\n' ' ')
	for NUM in $STATS
	do
		echo $NUM
	done
	sleep 1 
done
