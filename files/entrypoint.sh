#!/bin/bash

set -x

export NAGIOS_BASE_URL=`sed s./*$./. <<<${NAGIOS_BASE_URL:-/nagios/}`
export > /etc/default/docker-envs

if [ -f /etc/nginx/conf.d/nagios.conf ]; then
    sed -i "s|{{NAGIOS_BASE_URL}}|$NAGIOS_BASE_URL|g" /etc/nginx/conf.d/nagios.conf
fi

if [ "$PAGERDUTY_INTEGRATION_KEY" ]; then
    sed -i "s/YOUR-SERVICE-KEY-HERE/$PAGERDUTY_INTEGRATION_KEY/" /opt/nagios/etc/objects/pagerduty.cfg
    sed -i 's/members\s\+nagiosadmin/&,pagerduty/' /opt/nagios/etc/objects/contacts.cfg
    sed -i '/cfg_file=.\+contacts/ i cfg_file=/opt/nagios/etc/objects/pagerduty.cfg' /opt/nagios/etc/nagios.cfg
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
