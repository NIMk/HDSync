#!/bin/sh

# poor man's syncstarting
# emulating remote control commands
#
# we could do much better if this damn Sigma SDK would be open
# but so far, so good.

if [ -z $APPROOT ]; then
    NC="../src/netcat -c"
else
    NC="$APPROOT/bin/netcat -c"
fi

# go to the video
echo "r" > /tmp/ir_injection
echo "r" > /tmp/ir_injection
echo "r" > /tmp/ir_injection
# play it
echo "p" > /tmp/ir_injection
# wait 1 sec
sleep 1
# pause it
echo "p" > /tmp/ir_injection

# exit after connection
$NC -u -l -p 3333 -e true

# "press play on tape"
echo "p" > /tmp/ir_injection

