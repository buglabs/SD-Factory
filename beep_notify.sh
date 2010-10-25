#!/bin/sh

for i in 300 600 900 1200 900 600 300; do 
  beep -f $i -l 100
done
sleep 1
beep -f 1200
beep -f 1200
