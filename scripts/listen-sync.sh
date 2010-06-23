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

. /apps/hdsync/bin/utils-sync.sh

# wait that boot up is done
sleep 20

get_ip $ETH_IFACE

get_netcat $APPROOT

# launch background listener for acks
(while [ true ]; do
    answer=`echo | $NC -u -l -p 3333`;
    echo $answer >> /tmp/offer.replies
    done) &

# will get ready for play button
prepare_play

# loop continuously
while [ true ]; do
    sleep 3
    lsof | grep videos > /dev/null
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

