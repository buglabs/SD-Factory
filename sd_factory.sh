#!/bin/bash
#set -x

WRITERS=4
#SINGLETHREAD=1
if [ ! $1 ]; then
  echo "Please specify image to write as command parameter #1."
  exit -1
fi

if [ ! $2 ]; then
  echo "Please specify image label as parameter #2."
  exit -1
fi

echo md5sum -c ${1}.md5 
md5sum -c ${1}.md5 > /dev/null 2>&1
if [ "$?" -eq "0" ]; then
        echo "image check success"
else
        echo "source image failed md5 check, exiting"
        exit -1
fi
IMAGE=$1
LABEL=$2
rm sd*.log > /dev/null 2>&1
while [ 1 ]; do
  # DISK_COUNT=`fdisk -l | grep ^/dev/sd | wc | sed 's/ *//' | sed 's/ .*$//'`
  DISK_COUNT=$(grep 1931264 /proc/partitions | wc -l)
  if [ $DISK_COUNT == $WRITERS ]; then
    echo "$WRITERS SD disks detected...Beginning Write Operation!";
    echo "Writing Image: $1";
    #for d in `/sbin/fdisk -l | grep -v sda | grep 957 | grep ^/dev/sd | sed 's/1 .*$//'`; do
    for d in $(grep 1931264 /proc/partitions | sed 's/.*1931264//' | grep -v sda); do
      echo "./sd_write.sh /dev/$d $1"
      if [[ $IMAGE == *ext3* ]]
      then
	./sd_write-ext3.sh /dev/$d $IMAGE $LABEL &
      elif [[ $IMAGE == *tar* ]]
      then
	./sd_write.sh /dev/$d $IMAGE $LABEL &
      else
        echo "I can haz ext3 image or tar file plz"
        exit -1
      fi
      # wait before done wait singlethreads the operation
      if [ "$SINGLETHREAD" == "1" ]
      then
	echo Singlethreadding
	wait
      fi
    done
    # wait after done does the writes parallel
    if [ "$SINGLETHREAD" == "" ]
    then
	echo "I can haz parallel?"
	    wait
    fi
    echo "************* SD CARD WRITE COMPLETE YO ******************"
    cat *.log
    echo "************* PRESS [ENTER] AFTER REPLACING CARDS ***"
    echo "************* FOR IMAGE: $1 *********"
    ./irc_message.sh "I could use some fresh cards over here. $(date)" &
    ./beep_notify.sh
    read answer
    rm sd*.log
  else
    echo "$WRITERS disks not detected, $DISK_COUNT were.  There may be a bad or improperly inserted card, or you may need to run as root."
    echo "Repair the issue and type ./sd_multi.sh to restart this program."
    exit
  fi
done


