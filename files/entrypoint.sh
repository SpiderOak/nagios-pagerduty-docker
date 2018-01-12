#!/bin/bash

export > /etc/default/docker-envs

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
