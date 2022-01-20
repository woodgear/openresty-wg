#!/bin/bash
function _set_path() {
    echo "base is " $OPENRESTY_BASE
    if  [[ "$PATH" != "$OPENRESTY_BASE"* ]] ; then
        echo "use nginx in $OPENRESTY_BASE"
        export PATH="$OPENRESTY_BASE/nginx/sbin:$PATH"
    fi
    echo $PATH
    which nginx
}

_set_path
function md5() {
	local p=$1
	md5sum $p | awk '{ print $1 }'
}
function reload() {
    nginx_path=/home/cong/sm/temp/openresty-wg/nginx/sbin/nginx
    old_nginx_md5=$(md5 $nginx_path)
    while true; do
        new_nginx_md5=$(md5 $nginx_path)
        echo $old_nginx_md5 $new_nginx_md5
        if [[ "$old_nginx_md5" != "$new_nginx_md5" || "$RESTART" == "true" ]]; then
            echo "binary change detected kill and restart"
            ps -aux |grep nginx
            pkill nginx
            sleep 3
            ps -aux |grep nginx
            echo nginx -p $PWD/t/servroot -c $PWD/t/nginx.sample.conf
            nginx -p $PWD/t/servroot -c $PWD/t/nginx.sample.conf
			old_nginx_md5=$new_nginx_md5
			echo update old_nginx_md5 $old_nginx_md5 $new_nginx_md5
        else
            echo "no change reload"
            kill -HUP `cat ./t/servroot/logs/nginx.pid`
        fi
        sleep 5
    done
}

reload