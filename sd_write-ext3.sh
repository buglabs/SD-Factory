#!/bin/bash

#set -x 

DEVNAME=$1
DEVSNAME=${1/\/dev\//}
/bin/umount $DEVNAME\1
sleep 2
echo "Partitioning Disk $DEVNAME"
echo "d
n
p
1


a
1
w
" | fdisk $DEVNAME > /dev/null
/bin/umount $DEVNAME\1
sleep 2
echo "Writing BUG image $2 to $DEVNAME"
/bin/cp $2 $DEVNAME\1
if [ "$?" -ne "0" ] ; then
  ./errorlognotify.sh $DEVSNAME "Failed writing the image to $DEVNAME.  Aborting."
  exit -1
fi
echo "Checking image"
/sbin/e2fsck -f -y $DEVNAME\1
echo "Resizing filesystem"
/bin/umount $DEVNAME\1
/sbin/resize2fs $DEVNAME\1
if [ "$?" -ne "0" ] ; then
  ./errorlognotify.sh $DEVSNAME "resize2fs on $DEVNAME freaking failed.  Aborting."
  exit -1
fi
/sbin/e2label $DEVNAME\1 "$3 `date +%m%d%y`"
if [ "$?" -ne "0" ] ; then
  ./errorlognotify.sh $DEVSNAME "setting the label on $DEVNAME failed.  Aborting."
  exit -1
fi

echo "Verifying $DEVNAME file list against master"
sleep 1
if [ ! -d /mnt/verify-$DEVSNAME ]; then mkdir -p /mnt/verify-$DEVSNAME; fi
/bin/mount -r $DEVNAME\1 /mnt/verify-$DEVSNAME
PREVDIR=$(pwd)
cd /mnt/verify-$DEVSNAME
FILE_LIST=$(tempfile -d $PREVDIR)
find . -type f | xargs file | sort > $FILE_LIST
cd $PREVDIR
/bin/umount $DEVNAME\1
diff -bE master_file_list.txt $FILE_LIST > /dev/null
if [ "$?" -ne "0" ] ; then
  ./errorlognotify.sh $DEVSNAME "The file image on $DEVNAME is not consistent with master image. Check the file $FILE_LIST for details. Aborting."
  exit -1
fi
rm $FILE_LIST
echo "W00t!  Factory image complete on $DEVNAME" >> ${DEVSNAME}.log

