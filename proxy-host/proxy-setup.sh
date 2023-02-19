#!/usr/bin/bash

MODE=$1
PROXY=$2
CONFIG_PATH=$3

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
	sudo systemctl stop nginx
	sudo nginx -s quit
}

stop_haproxy () {
	sudo systemctl stop haproxy
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
		stop_haproxy
	fi
	ulimit -n 100000
	echo "Starting HAProxy."
	if [[ $MODE == "tcp" ]]
	then 
		sudo taskset -c 0-7 haproxy -D -f $CONFIG_PATH/haproxy-tcp.cfg
	elif [[ $MODE == "http" ]]
	then
		sudo taskset -c 0-7 haproxy -D -f $CONFIG_PATH/haproxy-main.cfg
	fi
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
		stop_nginx
	fi
	ulimit -n 100000
	ENABLED=/etc/nginx/sites-enabled/*
	for FILE in $ENABLED
	do
		echo "Removing $FILE"
		sudo rm -f $FILE
	done
	if [[ $MODE == "tcp" ]]
	then
		echo "Setting up TCP mode"
		sudo cp $CONFIG_PATH/sites-available/tcp-proxy /etc/nginx/sites-available/tcp-proxy
		sudo ln -s /etc/nginx/sites-available/tcp-proxy /etc/nginx/sites-enabled/tcp-proxy
		sudo cp $CONFIG_PATH/nginx-tcp.conf /etc/nginx/nginx.conf
	elif [[ $MODE == "http" ]]
	then
		sudo cp $CONFIG_PATH/sites-available/reverse-proxy /etc/nginx/sites-available/reverse-proxy
		sudo ln -s /etc/nginx/sites-available/reverse-proxy /etc/nginx/sites-enabled/reverse-proxy
		sudo cp $CONFIG_PATH/nginx-main-host.conf /etc/nginx/nginx.conf
	fi
	echo "Starting NGINX"
	sudo nginx -c /etc/nginx/nginx.conf
}

if [[ $PROXY == "haproxy" ]]
then
	start_haproxy 
elif [[ $PROXY == "nginx" ]]
then
	start_nginx
else
	echo "$1 not recognized."
fi

