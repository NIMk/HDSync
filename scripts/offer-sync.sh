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

# launch background listener
rm -f /tmp/hdsync.reply
touch /tmp/hdsync.reply
(while [ true ]; do
    answer=`echo | $NC -c -u -l -p 3331`;
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
    sleep 3

    # check that the video is not already playing
    state=`$AV -s localhost -p $UPNPPORT get 2>&1| awk '/^TInfo:/ {print $2}'`
    if [ "$state" == "PAUSED_PLAYBACK" ]; then

	rm -f /tmp/hdsync.reply
	touch /tmp/hdsync.reply

	echo "broadcasting offer signals from $IP"
	# we do broadcast only on class C
	# must always make sure also listener expects on class C
	bcast=`echo $IP | awk 'BEGIN { FS="." } {print $1 "." $2 "." $3 }'`.255
	echo "to netmask $bcast"
	
        # send broadcast signals until somebody listens
	listeners=0
	expected=`expr $TOTAL_CHANNELS - 1`
	while [ "$listeners" != "$expected" ]; do
	    echo -n "$b: `date +%X` "
	    $BC $bcast 3332 $IP
	    sleep 2
	    listeners=`cat /tmp/hdsync.reply | sort | uniq | wc -w`
	done

	echo "harvesting replies"
	cat /tmp/hdsync.reply | sort | uniq > /tmp/hdsync.listeners
	
	echo "sending acks"
	c=1
	for l in `cat /tmp/hdsync.listeners`; do
	    echo "$c: $l"
	    echo "$c" | $NC -c -u $l 3333
	done
	
	
	echo "waiting for other players to get ready..."
	sync
	sleep 10
	
	
	
        # sync start!
	$BC $bcast 3336 s
	
	if [ $HDSYNC_SLEEP ]; then
	    sleep $HDSYNC_SLEEP
	fi

        # "press play on tape"
	echo "$SYNC -s localhost -p $UPNPPORT start"
	$SYNC -s localhost -p $UPNPPORT start
		
	echo "sync playback started on `date +%T`"
	sleep 3
    fi
done