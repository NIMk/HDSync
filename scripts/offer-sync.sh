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

rm -f /tmp/listener.replies
touch /tmp/listener.replies

echo "broadcasting sync signals"

# background listener
(while [ true ]; do
    answer=`echo | $NC -u -l -p 3331`;
    echo $answer >> /tmp/listener.replies
    done) &

# send broadcast signals
for b in 1 2 3 4 5; do
    echo -n "$b: `date +%X` "
    $BC 255.255.255.255 3332 $IP
    sleep 1
done

echo "harvesting replies"
cat /tmp/listener.replies | sort | uniq > /tmp/listeners

echo "sending acks"
c=1
for l in `cat /tmp/listeners`; do
    echo "$c: $l"
    echo "$c" | $NC -u $l 3333
done

echo "waiting for players to get ready"
sleep 10
echo "syncstart!"
$BC 255.255.255.255 3336 s



