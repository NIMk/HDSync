#!/bin/sh
# here below only auxiliary functions

get_ip() {
    echo "checking for a network address"
    IFACE=$1
    IP="`ifconfig $IFACE | grep 'inet addr'| awk '{print $2}'|cut -f2 -d:`"
    # make sure dhcp has assigned an address, else wait and retry
    while [ "$IP" = "" ]; do
	IP="`ifconfig $IFACE | grep 'inet addr'| awk '{print $2}'|cut -f2 -d:`"
	sleep 1
    done
    echo "listening on $IFACE configured with address $IP ..." 
}

get_netcat() {
    if [ -z $1 ]; then
	NC="../src/netcat -c"
	BC="../src/broadcaster"
    else
	NC="$APPROOT/bin/netcat -c"
	BC="$APPROOT/bin/broadcaster"
    fi
}
