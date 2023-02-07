ulimit -n 100000
for i in {0..31}
	do sudo taskset -c 0-31 dpbench/bin/httpterm -D -L :80
done
