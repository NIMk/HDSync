#!/bin/sh

PATH=/usr/bin:/bin:/usr/sbin:/sbin

if [ -z $1 ]; then
        echo "usage: $0 network_interface"
        echo "example: $0 eth0"
        exit 1
fi
IFACE="$1"

IP="`ifconfig $IFACE | grep 'inet addr'| awk '{print $2}'|cut -f2 -d:`"

if [ -z $APPROOT ]; then
    NC="../src/netcat -c"
    BC="../src/broadcaster"
else
    NC="$APPROOT/bin/netcat -c"
    BC="$APPROOT/bin/broadcaster"
fi

ready=false

rm -f /tmp/handshake.ok
echo "broadcasting sync signal"

# background listener
(answer=`echo | $NC -u -l -p 3331`;
    echo $answer > /tmp/handshake.ok) &

while ! [ -r /tmp/handshake.ok ]; do
    sleep 1
    echo -n "[`date +%X`] "
    $BC 255.255.255.255 3332 $IP
done

echo -n " answer: `cat /tmp/handshake.ok`"
echo


