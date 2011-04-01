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

# here below only auxiliary functions

get_conf() {
    grep "^$1" /conf/config |  perl -F\' -anale 'print $F[1]'
}

get_ip() {
    if [ "$HDSYNC_NETWORK" = "DYNAMIC" ]; then
	echo "listening for DHCP assigned IP on the network"
	config_tool -c LAN_TYPE='d'
	IP=`get_conf IP2`
    else
	echo "setting a static network address"
	IP="192.168.0.$HDSYNC_CHANNEL"
	config_tool -c LAN_TYPE='s'
	config_tool -c IP2=$IP
	config_tool -c NETMASK2=255.255.255.0
	ifconfig eth0 $IP netmask 255.255.255.0
	echo "network interface configured with address $IP ..." 
    fi
    export IP
}


get_bins() {
    # wrapper to test in development on local paths
    if [ -z $1 ]; then
	NC="../src/netcat"
	BC="../src/broadcaster"
	UP="../scripts/upnp.sh"
    else
	NC="$APPROOT/bin/netcat"
	BC="$APPROOT/bin/broadcaster"
	UP="$APPROOT/bin/upnp.sh"
    fi
    echo "hdsync binaries found:"
    echo "$BC"
    echo "$NC"
    echo "$UP"
    export BC NC UP
}

prepare_play() {
    # turn off screensaver
    config_tool -c DMA_ENABLE_SCREENSAVER='0'
    config_tool -c DMA_SCREENSAVER='0'

    file=`ls $USBROOT/sync`
    state=`upnp-cmd GetTransportInfo | awk '/^.CurrentTransportState/ { print $3 }'`
    $UP load "$USBROOT/sync/$file"
    while [ "$state" = "NO_MEDIA_PRESENT" ]; do
	state=`upnp-cmd GetTransportInfo | awk '/^.CurrentTransportState/ { print $3 }'`
    done

    sync

    $UP play
    state=`upnp-cmd GetTransportInfo | awk '/^.CurrentTransportState/ { print $3 }'`
    while [ "$state" = "TRANSITIONING" ]; do
	state=`upnp-cmd GetTransportInfo | awk '/^.CurrentTransportState/ { print $3 }'`
    done

    sync

    $UP pause
    state=`upnp-cmd GetTransportInfo | awk '/^.CurrentTransportStatus/ { print $3 }'`
    while [ "$state" = "PREBUFFING" ]; do
	state=`upnp-cmd GetTransportInfo | awk '/^.CurrentTransportStatus/ { print $3 }'`
    done

    sync

    echo "ready to play on `date +%T`"
}
