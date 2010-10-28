#!/bin/bash

#set -x 


if [ "$1" == "--help" ] || [[ $# -lt 3 ]]; then
	echo "$0 devname rootfs.tar volume-label"
	echo "But that is just the beginning, you also need"
	echo "a rootfs.tar.list.md5 which is a md5sum of every file in"
	echo "the tarball, so we can verify the filesystem is created correctly"
	exit 1
elif [[ $EUID -ne 0 ]]; then
	echo "You need superuser privs to do anything constructive, sudo please"
	exit 1
fi

if [ ! -b $1 ]; then
	echo "The first argument has to be the block device we're writing to"
	exit
fi

if [ ! -e $2 ]; then
	echo "The second argument is the uncompressed tarball you want to load on the sd card"
	exit
fi


DEVNAME=$1
DEVSNAME=${1/\/dev\//}
sleep 5
/bin/umount ${DEVNAME}* > /dev/null 2>&1
dd if=/dev/zero of=$DEVNAME bs=1024 count=1024
if [ $? != "0" ];then
	echo "Partition table wipe \(dd\) failed"
	./errorlognotify.sh $DEVSNAME "partition wipe on $DEVNAME failed.  Aborting."
	exit -1
	fi
echo "Partitioning Disk $DEVNAME"
echo "d
n
p
1


a
1
w
" | fdisk $DEVNAME > /dev/null 2>&1
/bin/umount $DEVNAME\1
sleep 5
echo "Formatting $DEVNAME"
/sbin/mkfs.ext3 $DEVNAME\1 > /dev/null 2>&1
if [ "$?" -ne "0" ] ; then
  ./errorlognotify.sh $DEVSNAME "mkfs.ext3 on $DEVNAME freaking failed.  Aborting."
  exit -1
fi
/sbin/e2label $DEVNAME\1 "$3 `date +%m%d%y`"
if [ "$?" -ne "0" ] ; then
  ./errorlognotify.sh $DEVSNAME "setting the label on $DEVNAME failed.  Aborting."
  exit -1
fi

if [ ! -d /mnt/verify-$DEVSNAME ]; then mkdir -p /mnt/verify-$DEVSNAME; fi
/bin/mount $DEVNAME\1 /mnt/verify-$DEVSNAME
if [ "$?" -ne "0" ] ; then
  ./errorlognotify.sh $DEVSNAME "Unable to mount $DEVNAME.  Aborting."
  exit -1
fi
PREVDIR=$(pwd)
cd /mnt/verify-$DEVSNAME
echo "Writing BUG image $2 to $DEVNAME"
/bin/tar xf ${PREVDIR}/$2 
if [ "$?" -ne "0" ] ; then
  ./errorlognotify.sh $DEVSNAME "Failed writing the image to $DEVNAME.  Aborting."
  exit -1
fi
sleep 1
echo "Flushing and umounting $DEVNAME"
cd $PREVDIR
/bin/umount $DEVNAME\1
if [ "$?" -ne "0" ] ; then
  ./errorlognotify.sh $DEVSNAME "umount fail on $DEVNAME  Aborting."
  exit -1
fi

echo "Checking Filesystem Consistency $DEVNAME"
/sbin/e2fsck -f -y $DEVNAME\1
if [ "$?" -ne "0" ] ; then
  ./errorlognotify.sh $DEVSNAME "e2fsck exited with $? on $DEVNAME , screw it, it is toast"
  exit -1
fi

echo "Verifying $DEVNAME file list against master"
sleep 1
if [ ! -d /mnt/verify-$DEVSNAME ]; then mkdir -p /mnt/verify-$DEVSNAME; fi
/bin/mount -r $DEVNAME\1 /mnt/verify-$DEVSNAME
PREVDIR=$(pwd)
cd /mnt/verify-$DEVSNAME
md5sum --quiet -c $PREVDIR/${2}.list.md5
if [ "$?" -ne "0" ] ; then
  ./errorlognotify.sh $DEVSNAME "The file image on $DEVNAME is not consistent with master image."
  cd $PREVDIR
  /bin/umount $DEVNAME\1
  exit -1
fi
cd $PREVDIR
/bin/umount $DEVNAME\1

echo "W00t!  Factory image complete on $DEVNAME" >> ${DEVSNAME}.log
#echo "W00t!  Factory image complete on $DEVNAME"

