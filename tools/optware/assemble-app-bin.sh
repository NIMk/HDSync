#!/bin/sh
#
# This file was part of WDTV Tools (http://wdtvtools.sourceforge.net/).
# Copyright (C) 2009 Elmar Weber <wdtv@elmarweber.org>
#
# adaptation to wdlxtv_optware by Denis Roio <jaromil@dyne.org>
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
#

# assembly script for application images
                 
appname=wdlxtv_optware

    # no argument, create fresh

imagefile=./$appname.app.bin
loopdir=./$appname.app.loop

# create and fill in appdir
appdir=$appname.app

sudo rm -rf $appdir $imagefile $loopdir

mkdir -p $appdir
mkdir -p $appdir/bin
mkdir -p $appdir/etc/init.d

cp -v optware-install.sh $appdir/bin &&
cp -v optware-mount.sh $appdir/bin &&
cp -v wget $appdir/bin &&
cp -v ipkg.conf $appdir/etc &&
cp -v S99optware $appdir/etc/init.d &&
chmod a+x $appdir/etc/init.d/S99optware &&
cp -v README $appdir &&

sudo chown -R root:root $appdir

dd if=/dev/zero of=$imagefile bs=1K count=256 &&
/sbin/mkfs.ext3 -F $imagefile &&
/sbin/tune2fs -c 0 -i 0 $imagefile &&
mkdir -p $loopdir &&
sudo mount -o loop $imagefile $loopdir &&
sudo rm -rf $loopdir/lost+found &&
sudo cp -ra $appdir/* $loopdir/ &&
sudo chown root:root -R $loopdir &&
sudo umount $loopdir &&
sudo rm -rf $loopdir $appdir && 
sudo /sbin/fsck.ext3 $imagefile
