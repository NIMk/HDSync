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
    echo "getting a network address"
    IFACE=$1
    IP="192.168.0.$HDSYNC_CHANNEL"
    config_tool -c LAN_TYPE=s
    config_tool -c IP2=$IP
    config_tool -c NETMASK2=255.0.0.0
    ifconfig $IFACE $IP netmask 255.0.0.0
    echo "network interface $IFACE configured with address $IP ..." 
    export IP
}

get_netcat() {
    if [ -z $1 ]; then
	NC="../src/netcat"
	BC="../src/broadcaster"
    else
	NC="$APPROOT/bin/netcat"
	BC="$APPROOT/bin/broadcaster"
    fi
    echo "netcat binaries found:"
    echo "$BC"
    echo "$NC"
    export BC NC
}

prepare_play() {
    file=`ls $USBROOT/sync`
    upnp.sh load "$USBROOT/sync/$file"
    upnp.sh play
    upnp.sh pause
}

