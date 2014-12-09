#! /bin/bash

MY_IP=`curl -s http://ipecho.net/plain ; echo`
NOT_OK=`echo $MY_IP | sed 's|[0-9\.]*||'`

if [[ -n "$NOT_OK" ]]; then
    MY_IP=`curl -s http://checkip.dyndns.org | sed 's/[a-zA-Z/<> :]//g'`
    NOT_OK=`echo $MY_IP | sed 's|[^0-9\.]||'`

    if [[ -n "$NOT_OK" ]]; then
        echo "true"
        exit 0
    fi
fi

VPN_IP="50.18.217.135"

if [ "$MY_IP" == "$VPN_IP" ] || [ "$MY_IP" == `host vpn.ops.clever.com | sed 's/vpn.ops.clever.com has address //'` ]; then
    echo "true"
    exit 0
else
    echo "false"
    exit 1
fi
