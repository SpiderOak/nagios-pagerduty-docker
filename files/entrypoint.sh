#!/bin/bash

set -x

export NAGIOS_BASE_URL=`sed s./*$./. <<<${NAGIOS_BASE_URL:-/nagios/}`
export > /etc/default/docker-envs

if [ -f /etc/nginx/conf.d/nagios/nagios.conf ]; then
    sed -i "s|{{NAGIOS_BASE_URL}}|$NAGIOS_BASE_URL|g" /etc/nginx/conf.d/nagios/nagios.conf
fi

if [ "$LETSENCRYPT_DOMAINS" ]; then
    mv /etc/nginx/conf.d/default-http.conf{,.disabled}
    mv /etc/nginx/conf.d/le-http.conf{.disabled,}
    for domain in $LETSENCRYPT_DOMAINS; do
        if [ -e /etc/nginx/certs/live/$domain/fullchain.pem ]; then
            sed "s/{{DOMAIN_NAME}}/$domain/g" /etc/nginx/conf.d/le-https.conf.tmpl > /etc/nginx/conf.d/$domain.conf
        fi
    done
fi

if [ "$PAGERDUTY_INTEGRATION_KEY" ]; then
    sed -i "s/YOUR-SERVICE-KEY-HERE/$PAGERDUTY_INTEGRATION_KEY/" /opt/nagios/etc/objects/pagerduty.cfg
    sed -i 's/members\s\+nagiosadmin/&,pagerduty/' /opt/nagios/etc/objects/contacts.cfg
    sed -i '/cfg_file=.\+contacts/ i cfg_file=/opt/nagios/etc/objects/pagerduty.cfg' /opt/nagios/etc/nagios.cfg
fi

if [ "$NAGIOSADMIN_PASSWORD" ]; then
    echo "nagiosadmin:$(openssl passwd -crypt "$NAGIOSADMIN_PASSWORD")" > /etc/nginx/nagios.htpasswd
    sed -i 's/#auth_basic/auth_basic/' /etc/nginx/conf.d/nagios/nagios.conf
fi

if [ "$PROXY_ALLOW_REMOTE_USER" ]; then
    sed -i 's/$remote_user/$http_remote_user/' /etc/nginx/conf.d/nagios/nagios.conf
    echo 'underscores_in_headers on;' > /etc/nginx/conf.d/underscores_in_headers.conf
fi

if [ "$NGINX_HTTP_PORT" ]; then
    valid_port=$(echo $NGINX_HTTP_PORT | grep "^-\?[0-9]*$")
    if [[  $? -eq 0 && $valid_port -lt 65535 ]]; then
        sed -i "s/\<80\>/$NGINX_HTTP_PORT/" /etc/nginx/conf.d/default-http.conf
    else
        echo "'$NGINX_HTTP_PORT' not a valid port, skipping"
    fi
fi

shutdown() {
    sv -w 60 force-stop /etc/service/*
    if [ -e "/proc/$RUNSVDIR" ]; then
        kill -HUP "$RUNSVDIR"
        wait "$RUNSVDIR"
    fi
    exit
}

exec runsvdir -P /etc/service &
RUNSVDIR=$!

trap shutdown SIGTERM SIGHUP SIGINT
wait "$RUNSVDIR"
