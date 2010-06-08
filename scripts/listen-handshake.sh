#!/bin/bash

if [ -z $1 ]; then
	echo "usage: $0 network_interface"
	echo "example: $0 eth0"
	exit 1
fi
IFACE="$1"

NC="/opt/ivysync/bin/netcat"
# check if it is openbsd netcat
NC_ver="`$NC -h 2>&1|head -n 1 | awk '{print $1}'`"
if [ "$NC_ver" = "OpenBSD" ]; then
	echo "using OpenBSD version of netcat"
	NC="$NC -q 0"
elif [ "$NC_ver" = "GNU" ]; then
	echo "using GNU version of netcat"
	NC="$NC -c"
else
	echo "error: your version of netcat is not compatible"
	echo "please install an OpenBSD or GNU netcat implementation"
	echo "found on this system: `netcat -h 2>&1|head -n1`"
	exit 1
fi

# some more version might be around that is not supported..

IP="`ifconfig $IFACE | grep 'inet addr'| awk '{print $2}'|cut -f2 -d:`"

echo "listening on $IFACE configured with address $IP ..."
master="`echo | $NC -u -l -p 3332`"

echo "contacted by master $master"
echo "$IP" | netcat -u $master 3331

echo "master replied"


exit 0
