#!/bin/sh
#
# Copyright (C) 2010-2011 Denis Roio <jaromil@nimk.nl>
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

. $APPROOT/bin/utils-sync.sh


# launch background listener for acks
rm -f /tmp/hdsync.reply
touch /tmp/hdsync.reply
(while [ -r /tmp/hdsync.reply ]; do
    answer=`echo | $NC -c -u -l -p 3333`;
    echo $answer >> /tmp/hdsync.reply
    done) &

# # check that the video is prepared
# while [ true ]; do
#     sleep 3
#     lsof | grep 'mnt.*video' > /dev/null
#     if [ $? == 0 ]; then	# a video is loaded
# 	break
#     fi
# done

# loop continuously
while [ true ]; do

    sync

    sleep 10

    # check the state of the video
    state=`$AV -s localhost -p $UPNPPORT get 2>&1| awk '/^TInfo:/ {print $2}'`

    if [ "$state" == "NO_MEDIA_PRESENT" ]; then

        # will get ready for sync
	prepare_play >> /tmp/hdsync.log

    elif [ "$state" == "STOPPED" ]; then

        # will get ready for sync again
	prepare_play >> /tmp/hdsync.log

    elif [ "$state" == "PAUSED_PLAYBACK" ]; then
	# will sync start
	
	rm -f /tmp/hdsync.reply
	touch /tmp/hdsync.reply
	
	echo "listening for offers on $IP"
	
	offer="`echo | $NC -c -u -l -p 3332`"
	
	echo "offered sync by $offer"
	
	
        # repeat udp replies to offer until ack
	echo "replying with our ip until ack"
	ack=""
	while [ "$ack" = "" ]; do
	    sleep 1
	    echo "$IP" | $NC -c -u $offer 3331
	    echo -n "."
	    ack=`cat /tmp/hdsync.reply`
	done
	
	echo "ack received, we are channel $ack"
	
	sync
	
	echo "ready: awaiting syncstarter signal"
	
	
        # exit after connection (-e true)
	$NC -c -u -l -p 3336 -e true
	
	if [ $HDSYNC_SLEEP ]; then
	    sleep $HDSYNC_SLEEP
	fi
	
        # "press play on tape"
	$SYNC -s localhost -p $UPNPPORT start
	
	echo "sync playback started on `date +%T`"

    fi
done


