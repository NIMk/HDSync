#!/bin/sh

if [ -z $1 ]; then
	echo "usage: $0 network_interface"
	echo "example: $0 eth0"
	exit 1
fi
IFACE="$1"

NC="../src/netcat -c"

# some more version might be around that is not supported..

IP="`/sbin/ifconfig $IFACE | grep 'inet addr'| awk '{print $2}'|cut -f2 -d:`"

echo "listening on $IFACE configured with address $IP ..."
master="`echo | $NC -u -l -p 3332`"

echo "contacted by master $master"
echo "$IP" | netcat -u $master 3331

echo "master replied"


exit 0
