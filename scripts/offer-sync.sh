#!/bin/sh

if [ -z $1 ]; then
        echo "usage: $0 network_interface"
        echo "example: $0 eth0"
        exit 1
fi
IFACE="$1"

IP="`/sbin/ifconfig $IFACE | grep 'inet addr'| awk '{print $2}'|cut -f2 -d:`"

if [ -z $APPROOT ]; then
    NC="../src/netcat -c"
    BC="../src/broadcaster"
else
    NC="$APPROOT/bin/netcat -c"
    BC="$APPROOT/bin/broadcaster"
fi




ready=false

# background listener
(answer=`echo | $NC -u -l -p 3331`;
    echo $answer > /tmp/handshake.$i.ok) &

while ! [ -r /tmp/handshake.$i.ok ]; do
    sleep 1
    $BC 255.255.255.255 3332 $IP 1>&2 > /dev/null
    echo -n "."
done	
echo -n " answer: `cat /tmp/handshake.$i.ok`"
rm /tmp/handshake.$i.ok
echo


