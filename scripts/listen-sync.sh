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

get_ip $IFACE

get_netcat $APPROOT

# launch background listener for acks
(while [ true ]; do
    answer=`echo | $NC -u -l -p 3333`;
    echo $answer >> /tmp/offer.replies
    done) &

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


# loop continuously
while [ true ]; do
    lsof | grep videos > /dev/null
    sleep 3
    if [ $? == 1 ]; then

	rm -f /tmp/offer.replies
	touch /tmp/offer.replies

	offer="`echo | $NC -c -u -l -p 3332`"

	echo "offered sync by $offer"


        # repeat udp replies to offer until ack
	echo "replying with our ip until ack"
	ack=""
	while [ "$ack" = "" ]; do
	    sleep 1
	    echo "$IP" | $NC -u $offer 3331
	    echo -n "."
	    ack=`cat /tmp/offer.replies`
	done
	
	echo "ack received, we are channel $ack"

	sync
 
	echo "ready: awaiting syncstarter signal"


        # exit after connection (-e true)
	$NC -u -l -p 3336 -e true
	
        # "press play on tape"
	echo "p" > /tmp/ir_injection; sleep 0.1
        # turn off OSD
	echo "n" > /tmp/ir_injection
    fi
done

