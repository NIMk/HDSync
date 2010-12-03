#!/bin/sh

# OptWare for WDLXTV bin wrapper script
# (C) 2010 Denis Roio <jaromil@dyne.org>
# GNU GPL v3

# this scrips scans for all binaries present in /bin and /usr/bin
# and generates execution wrappers in /apps/wdlxtv_optware/bin
# so that the correct libraries are linked to them


. /tmp/optware.env

rm -rf $USBROOT/opt/wrappers
mkdir $USBROOT/opt/wrappers

wrap_bins() {
    echo -n "building binary wrappers for $1 "
    for x in `ls $1 | grep -v '.sh$'`; do
	cat <<EOF > $USBROOT/opt/wrappers/$x
#!/bin/sh
LD_LIBRARY_PATH=/lib:/usr/lib
$1/$x \$@
EOF
	chmod +x $USBROOT/opt/wrappers/$x
	echo -n .
    done
    echo
}

wrap_bins /bin
wrap_bins /sbin
wrap_bins /usr/bin
wrap_bins /usr/sbin

