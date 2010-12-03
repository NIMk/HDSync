#!/bin/sh

# OptWare for WDLXTV bin wrapper script
# (C) 2010 Denis Roio <jaromil@dyne.org>
# GNU GPL v3

# this scrips scans for all binaries present in /bin and /usr/bin
# and generates execution wrappers in /apps/wdlxtv_optware/bin
# so that the correct libraries are linked to them


. /tmp/optware.env

wrap_bins() {
    echo -n "building binary wrappers for $1 "
    for x in `ls $1 | grep -v '.sh$'`; do
	rm -f $USBROOT/opt/bin/$x
	cat <<EOF > $USBROOT/opt/bin/$x
#!/bin/sh
LD_LIBRARY_PATH=/lib:/usr/lib
$1/$x \$@
EOF
	chmod +x $USBROOT/opt/bin/$x
	echo -n .
    done
    echo
}

wrap_bins /bin
wrap_bins /sbin
wrap_bins /usr/bin
wrap_bins /usr/sbin

