#!/bin/sh
#
# Copyright (C) 2010 Denis Roio <jaromil@nimk.nl>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or 
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
    sleep 2
done

echo "harvesting replies"
cat /tmp/listener.replies | sort | uniq > /tmp/listeners

echo "sending acks"
c=1
for l in `cat /tmp/listeners`; do
    echo "$c: $l"
    echo "$c" | $NC -u $l 3333
done

# poor man's syncstarting:
# emulating remote control commands
#
# we could do much better if this damn Sigma SDK would be open
# but so far, so good.

echo "handshake completed, preparing for playback"
# go to the video
echo "r" > /tmp/ir_injection; sleep 0.333
echo "r" > /tmp/ir_injection; sleep 0.333
echo "r" > /tmp/ir_injection; sleep 2
# play it
echo "p" > /tmp/ir_injection; sleep 1
# be sure we restart the video
echo "n" > /tmp/ir_injection; sleep 1
# wait 5 secs
sleep 5
# pause it
echo "p" > /tmp/ir_injection

echo "waiting for other players to get ready..."
sleep 20
echo "syncstart!"
$BC 255.255.255.255 3336 s
  
# "press play on tape"
echo "p" > /tmp/ir_injection; sleep 0.1
# take off OSD
echo "n" > /tmp/ir_injection

echo "synced playback started."



