#!/bin/sh

PATH=/usr/bin:/bin:/usr/sbin:/sbin

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



IP="`ifconfig $IFACE | grep 'inet addr'| awk '{print $2}'|cut -f2 -d:`"

echo "listening on $IFACE configured with address $IP ..." 
master="`echo | $NC -c -u -l -p 3332`"

echo "contacted by master $master"
echo "$IP" | $NC -u $master 3331

# poor man's syncstarting:
# emulating remote control commands
#
# we could do much better if this damn Sigma SDK would be open
# but so far, so good.

echo "preparing playback"
# go to the video
echo "r" > /tmp/ir_injection; sleep 0.333
echo "r" > /tmp/ir_injection; sleep 0.333
echo "r" > /tmp/ir_injection; sleep 0.333
# play it
echo "p" > /tmp/ir_injection; sleep 1
# be sure we restart the video
echo "n" > /tmp/ir_injection; sleep 1
# wait 5 secs
sleep 5
# pause it
echo "p" > /tmp/ir_injection
 
echo "awaiting syncstarter signal..."
# exit after connection
$NC -u -l -p 3333 -e true
 
# "press play on tape"
echo "p" > /tmp/ir_injection; sleep 0.1
# take off OSD
echo "n" > /tmp/ir_injection

echo "synced playback started."



exit 0
