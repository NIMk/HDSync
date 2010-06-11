#!/bin/sh

if [ -z $1 ]; then
	echo "usage: $0 network_interface"
	echo "example: $0 eth0"
	exit 1
fi
IFACE="$1"

if [ -z $APPROOT ]; then
    NC="../src/netcat -c"
    BC="../src/broadcaster"
else
    NC="$APPROOT/bin/netcat -c"
    BC="$APPROOT/bin/broadcaster"
fi

# some more version might be around that is not supported..

IP="`/sbin/ifconfig $IFACE | grep 'inet addr'| awk '{print $2}'|cut -f2 -d:`"

echo "listening on $IFACE configured with address $IP ..."
master="`echo | $NC -c -u -l -p 3332`"

echo "contacted by master $master"
echo "$IP" | $NC -u $master 3331

echo "master replied"


exit 0
