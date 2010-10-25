#!/bin/bash
MSGTXT=$(tempfile)
echo "USER sdfctry x x :sdfctry" > $MSGTXT
echo "NICK sdfctry" >> $MSGTXT
echo "JOIN #testing" >> $MSGTXT
echo "PRIVMSG #testing :$1" >> $MSGTXT
echo "QUIT" >> $MSGTXT
cat $MSGTXT | nc -i 2 bugcamp.net 6667 &> /dev/null
rm -f $MSGTXT
