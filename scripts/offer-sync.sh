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
    answer=`echo | $NC -c -u -l -p 3331 | awk '{print $1}'`;
    echo $answer >> /tmp/hdsync.reply
    echo $answer | $NC -c -u $answer 3333
    echo "`date +%T` ack sent to $answer"
    done) &

# loop continuously
while [ true ]; do

    sleep 10

    # check the state of the video
    state=`$AV -s localhost -p $UPNPPORT get 2>&1| awk '/^TInfo:/ {print $2}'`
    echo "`date +%T` state (avremote) is $state"

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

	echo "`date +%T` broadcasting offer signals from $IP"
	# we do broadcast only on class C
	# must always make sure also listener expects on class C
	bcast=`echo $IP | awk 'BEGIN { FS="." } {print $1 "." $2 "." $3 }'`.255
	echo "to netmask $bcast"

	# send broadcast signals until somebody listens
	listeners=0
	expected=`expr $TOTAL_CHANNELS - 1`
	while [ $listeners -lt $expected ]; do
	    echo -n "`date +%X` "
	    $BC $bcast 3332 $IP
	    listeners=`cat /tmp/hdsync.reply | sort | uniq | wc -w`
	sleep 1
	done

#	echo "harvesting replies"
#	cat /tmp/hdsync.reply | sort | uniq > /tmp/hdsync.listeners
#
#	echo "sending acks"
#	c=1
#	for l in `cat /tmp/hdsync.listeners`; do
#	    echo "$c: $l"
#	    echo "$c" | $NC -c -u $l 3333
#	done


	echo "`date +%T` waiting for other players to get ready..."
    sync

	# sync start in 2 seconds!
    (sleep 2
	$BC $bcast 3336 s >> /dev/null) &

	# exit after connection (-e true)
    $NC -c -u -l -p 3336 -e true

    if [ $HDSYNC_SLEEP ]; then
	usleep $HDSYNC_SLEEP
    fi

	# "press play on tape"
	$SYNC -s localhost -p $UPNPPORT start
	echo "`date +%T` sync playback started"
    fi

# $BC $bcast 3336 s >> /dev/null   # keep broadcasting in case someone didnt get the message

done
