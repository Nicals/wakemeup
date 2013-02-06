#!/bin/sh
#
# The file is licenced under Revision 42 of the Beerware Licence.
# 
# I wrote this file. As long as you retain this notice you can do whatever you 
# want with this stuff. If we meet some day, and you think this stuff is worth 
# it, you can buy me a beer in return. Nicolas Appriou
#
# This is an example script for using wakemeup as a morning alarm.
# I use on my main computer, in conjonction with a wake-on-lan signal
# from a home server.
#

WAKE_PRG=/usr/local/bin/wakemeup -r
JOBID_FILE=/tmp/alarm_job_id

# multiples alarms. In this case, we wan't 30 minutes of alarms launching evry 5
# minutes.
BACKUP_ALARM_LEN=30
BACKUP_ALARM_INT=5

# Ok we haven't waked up with the previous alarms,
# let's hope this one will finish the job.
LAST_CHANCE_ALARM="1 hour"

if [ "$#" -lt "1" ];then
  echo "Need the time"
  exit 1
fi


# Remove existings jobs
if [ "$1" = "-k" ];then
  # first, be sure that ware have waked up:
  # TODO: use the following as a function. Use it to ask for lights, then coffee
  OK="nop"
  while [ "$OK" = "nop" ];do
    read -p "Coffe is done ? " ANSWER
    echo --$ANSWER--
    if [ "$ANSWER" = "coffee is done" ];then
      echo "yep"
      OK="yep"
    fi
  done

  JOB_NB=0
  if [ -e $JOBID_FILE ];then
    while read line; do
      atrm $line
      JOB_NB=$(( $JOB_NB + 1))
    done < $JOBID_FILE
    rm $JOBID_FILE
  fi
  echo "Removed $JOB_NB jobs"
  exit 0
fi

# check time format
if [ -z $(echo $1 | grep -E '^[[:digit:]]{1,2}h[[:digit:]]{2}$') ];then
  echo "Bad time format $1"
  exit 2
fi


# Send jobs
>$JOBID_FILE

DELAY=0
ALARM_TIME=$1
while [ "$DELAY" -le "$BACKUP_ALARM_LEN" ]; do
  echo "$WAKE_PRG" | at $ALARM_TIME +$DELAY minute -M 2>&1| grep job | awk '{print $2}' >> $JOBID_FILE
  DELAY=$(( $DELAY + $BACKUP_ALARM_INT ))
done;

echo "$WAKE_PRG" | at $ALARM_TIME +$LAST_CHANCE_ALARM -M 2>&1| grep job | awk '{print $2}' >> $JOBID_FILE
# check if all went well
atq | sort

