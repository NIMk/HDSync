#!/bin/sh

# small upnp player in shell script, for WDLXTV
# this is supposed to work faster than the upnp-cmd
# needed to lower latency of operation in hdsync.app.bin

# (C) 2011 by Jaromil - GNU GPL v3

if [ -z $1 ]; then
    echo "usage: $0 [command]"
    echo "commands: load filename, play, stop, pause"
    exit 0
fi

# make cmd case insensitive
cmd="`echo $1 | tr '[:upper:]' '[:lower:]'`"

case $cmd in

    load)
	file="$2"
	if ! [ -r "$file" ]; then
	    echo "file not found: $file"
	    echo "operation aborted."; exit 1
	fi
	uri="file://$file"
	upnp-cmd SetAVTransportURI "$uri"
	# allowed NewPlayMode = "NORMAL", "REPEAT_ONE", "REPEAT_ALL", "RANDOM"
	upnp-cmd SetPlayMode REPEAT_ONE
	;;

    play)
	upnp-cmd Play
	;;

    stop)
	upnp-cmd Stop
	;;

    pause)
	upnp-cmd Pause
	;;

    *)
	echo "unrecognized command: $cmd"
	exit 1
	;;

esac

echo "command $cmd executed succesfully"
exit 0
