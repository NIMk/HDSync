#!/bin/sh
#
# Copyright (C) 2011 Michael van Rosmalen <mvanrosmalen@zya.nl>
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
. $USBROOT/hdsync.conf

watchdogtimer=`expr $WATCHDOGTIMER + 30`    #timeout in seconds, movielength + some
timer=0

echo "`date +%T` watchdog started, timeout is $watchdogtimer"

# loop continuously
while [ true ]; do

    sleep 5
    timer=`expr $timer + 5`

    # check the state of the video
    state=`$AV -s localhost -p $UPNPPORT get 2>&1| awk '/^TInfo:/ {print $2}'`

    if [ "$state" != $laststate ]; then
	echo "`date +%T` watchdog timer reset after state change to $state"
	timer=0     # reset timer
    fi

    if [ $timer -gt $watchdogtimer ]; then
	echo "`date +%T` watchdog timer exceeded, trying to resolve"
	$AV -s localhost -p $UPNPPORT stop
	sleep 5
	$AV -s localhost -p $UPNPPORT stop
	timer=`expr $watchdogtimer - 60`
    fi
laststate="$state"

done
