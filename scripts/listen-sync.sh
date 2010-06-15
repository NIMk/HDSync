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

# go to the video
Echo "r" > /tmp/ir_injection; sleep 0.333
Echo "r" > /tmp/ir_injection; sleep 0.333
Echo "r" > /tmp/ir_injection; sleep 0.333
# play it
Echo "p" > /tmp/ir_injection; sleep 1
Echo "# be sure we restart the video"
Echo "n" > /tmp/ir_injection; sleep 1
Echo "# wait 5 secs"
Sleep 5
Echo "# pause it"
Echo "p" > /tmp/ir_injection
 
# exit after connection
$NC -u -l -p 3333 -e true
 
# "press play on tape"
Echo "p" > /tmp/ir_injection; sleep 0.1
# take off OSD
Echo "n" > /tmp/ir_injection
 


exit 0
