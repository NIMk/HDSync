#!/bin/sh

PATH=/usr/bin:/bin:/usr/sbin:/sbin

. $APPROOT/bin/utils-sync.sh

watchdogtimer=1641    #timeout in seconds, movielength + some
timer=0

# loop continuously
while [ true ]; do

    sleep 5
    timer=`expr $timer + 5`

    # check the state of the video
    state=`upnp-cmd GetTransportInfo | awk '/CurrentTransportState/ {print $3}'`

    if [ "$state" != $laststate ]; then
	echo "`date +%T` watchdog timer reset after state change to $state"
	timer=0     # reset timer
    fi

    if [ $timer -gt $watchdogtimer ]; then
	echo "`date +%T` watchdog timer exceeded, trying to resolve"
	upnp-cmd stop
	sleep 5
	upnp-cmd stop
	timer=watchdogtime-60
    fi
    laststate="$state"
done

