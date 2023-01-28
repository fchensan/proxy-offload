is_haproxy_stopped () {
	if [ -z $(pgrep haproxy) ]
	then
		echo "HAProxy is not running."
		return 0 
	else
		echo "HAProxy is running."
		return 1 
	fi
}

is_nginx_stopped () {
	if [ -z $(pgrep nginx) ]
	then
		echo "NGINX is not running."
		return 0 
	else
		echo "NGINX is running."
		return 1 
	fi
}

echo $(is_nginx_stopped)
