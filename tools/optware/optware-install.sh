#!/bin/sh

# OptWare for WDLXTV installation script
# (C) 2010 Denis Roio <jaromil@dyne.org>
# GNU GPL v3

TMP=/tmp

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/opt/bin:/opt/sbin
unset LD_PRELOAD
unset LD_LIBRARY_PATH

REPOSITORY=http://ipkg.nslu2-linux.org/feeds/optware/wdtv/cross/unstable

install_package() {
# install_package from the Optware pre-installation script
# (C) 2006 - 2008 Leon Kos

    PACKAGE=$1
    echo "Installing package ${PACKAGE} ..."
    wget -q -O ${TMP}/${PACKAGE} ${REPOSITORY}/${PACKAGE}
    cd  ${TMP} 
    tar xzf ${TMP}/${PACKAGE} 
    tar xzf ${TMP}/control.tar.gz
    cd /
    if [ -f ${TMP}/preinst ] ; then
	sh ${TMP}/preinst
	rm -f ${TMP}/preints
    fi
    tar xzf ${TMP}/data.tar.gz
    if [ -f ${TMP}/postinst ] ; then
	sh ${TMP}/postinst
	rm -f ${TMP}/postinst
    fi
    rm -f ${TMP}/data.tar.gz
    rm -f ${TMP}/control.tar.gz
    rm -f ${TMP}/control
    rm -f ${TMP}/${PACKAGE}
}

if ! [ -r /tmp/optware.env ]; then
    echo "Optware not correctly setup on USB"
    exit 1
fi

. /tmp/optware.env

ping -c 1 ipkg.nslu2-linux.org > /dev/null
if [ $? != 0 ]; then
    echo "Your WDTV device is not connected to the Internet:"
    echo "the online repository ipkg.nslu2-linux.org is not reachable."
    echo "Optware installation requires connecting to it."
    exit 1
fi

if [ -r $OPTWARE_ROOT/etc/ipkg.conf ]; then
    echo "Optware already installed on $OPTWARE_ROOT"
    echo "to force activation, run optware-mount.sh"
    echo "to re-install first delete /opt from USB"
    exit 1
else
    mkdir -p $USBROOT/opt
    mount -o bind $USBROOT/opt /opt
fi

install_package uclibc-opt_0.9.28-2_mipsel.ipk
install_package ipkg-opt_0.99.163-10_mipsel.ipk

cp /apps/wdlxtv_optware/etc/ipkg.conf /opt/etc/ipkg.conf

export PATH=/apps/wdlxtv_optware/bin:/opt/bin:/opt/sbin:/bin
export LD_LIBRARY_PATH=/opt/lib:/opt/usr/lib

/opt/bin/ipkg update 
/opt/bin/ipkg -force-reinstall install uclibc-opt
/opt/bin/ipkg -force-reinstall -force-defaults install ipkg-opt

optware-mount.sh

optware-binwrap.sh

. /etc/profile

echo "Installation succesfull!"
echo "type 'ipkg list' for a list of software now available for install"
echo "send your feedback on the WDLXTV forum"
echo " http://forum.wdlxtv.com/viewtopic.php?f=40&t=2637"
echo "enjoy, may the source be with you! :^)"


