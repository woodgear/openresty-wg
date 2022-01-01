#!/bin/bash
nginx_path=/home/cong/sm/temp/openresty-wg/nginx/sbin/nginx
old_nginx_md5=`md5sum $nginx_path`
while true; do
	new_nginx_md5=`md5sum $nginx_path
	if [ "$old_nginx_md5" != "$new_nginx_md5" ]; then
		echo "binary change detected"

	fi
	ps -aux |grep nginx
	kill -HUP `cat ./t/servroot/logs/nginx.pid`
	sleep 5
done
