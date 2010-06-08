#!/bin/bash

# here configure the file with the list of IP or hostnames, one per line
LISTFILE=/root/list

if [ -z $1 ]; then
        echo "usage: $0 network_interface"
        echo "example: $0 eth0"
        exit 1
fi
IFACE="$1"

IP="`ifconfig $IFACE | grep 'inet addr'| awk '{print $2}'|cut -f2 -d:`"


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



ready=false

for i in `cat $LISTFILE`; do
	rm -f /tmp/handshake.$i.ok
	echo -n "handshaking $i"

	# background listener
	(answer=`echo | $NC -u -l -p 3331`;
	 echo $answer > /tmp/handshake.$i.ok) &

	while ! [ -r /tmp/handshake.$i.ok ]; do
		sleep 1
		udpbroadcast $i 3332 $IP 1>&2 > /dev/null
		echo -n "."
	done	
	echo -n " answer: `cat /tmp/handshake.$i.ok`"
	rm /tmp/handshake.$i.ok
	echo
done 

