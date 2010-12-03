#!/bin/sh

# OptWare for WDLXTV activation script
# (C) 2010 Denis Roio <jaromil@dyne.org>
# GNU GPL v3

. /tmp/optware.env

mount | grep '^.dev.sd.*opt.*rw' > /dev/null
if [ $? != 0 ]; then
    mount -o bind $USBROOT/opt /opt    
else
    echo "optware filesystem is already mounted"
fi

# update the shell profile
mount | grep 'etc.profile.*rw' > /dev/null
if [ $? != 0 ]; then
    cp /etc/profile /tmp/profile
    cat /tmp/optware.env >> /tmp/profile
    cat <<EOF >> /tmp/profile
export PATH=/apps/wdlxtv_optware/bin:/opt/bin:/opt/sbin:/opt/usr/bin:/opt/usr/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export LD_LIBRARY_PATH=/opt/lib:/opt/usr/lib:/lib:/usr/lib
EOF
    mount -o bind /tmp/profile /etc/profile

    . /tmp/profile
else
    echo "shell profile already initialized by optware"
fi
