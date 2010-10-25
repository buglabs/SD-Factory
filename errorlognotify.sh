#!/bin/bash
echo $2 >> ${1}.log
./irc_message.sh "$2"
