#!/usr/bin/bash

is_haproxy_stopped () {
	if [[ -z $(pgrep haproxy) ]]
	then
		echo "HAProxy is not running."
		return 0 
	else
		echo "HAProxy is running."
		return 1 
	fi
}

is_nginx_stopped () {
	if [[ -z $(pgrep nginx) ]]
	then
		echo "NGINX is not running."
		return 0 
	else
		echo "NGINX is running."
		return 1 
	fi
}

stop_nginx () {
	sudo nginx -s quit
}

stop_haproxy () {
	sudo pkill haproxy
}

start_haproxy () {
	if ! is_nginx_stopped
	then
		echo "NGINX is running, telling it to quit now."
		stop_nginx
	fi
	if ! is_haproxy_stopped
	then
		echo "HAProxy already running!"
		exit
	fi
	ulimit -n 100000
	echo "Starting HAProxy."
	sudo taskset -c 0-7 haproxy -D -f $2/haproxy-main.cfg
}

start_nginx () {
	if ! is_haproxy_stopped
	then
		echo "HAProxy is running, killing it now."
		stop_haproxy
	fi
	if ! is_nginx_stopped
	then
		echo "NGINX already running!"
		exit
	fi
	ulimit -n 100000
	ENABLED=/etc/nginx/sites-enabled/*
	for FILE in $ENABLED
	do
		echo "Removing $FILE"
		sudo rm -f $FILE
	done
	sudo cp $2/sites-available/reverse-proxy /etc/nginx/sites-available/reverse-proxy
	sudo ln -s /etc/nginx/sites-available/reverse-proxy /etc/nginx/sites-enabled/reverse-proxy
	echo "Starting NGINX"
	sudo nginx -c /etc/nginx/nginx.conf
}


start_nginx $1 $2


: 'if [ $1 == haproxy ]
then
	start_haproxy
elif [ $1 == "nginx" ] 
then
# 	echo "hello" 
	start_nginx
else
	echo "$1 not recognized."
fi
'
