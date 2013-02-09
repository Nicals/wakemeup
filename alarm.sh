

####################################################################################
#
# "THE BEER-WARE LICENSE" (Revision 42):
# <nicolas.appriou@gmail.com> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return. Nicolas Appriou
#
####################################################################################
#
# This script is used to schedule alarms on a computer that will be
# switched off for the night. It will be powered on by a Wake on Lan
# signal for another computer.
#
# Several alarms are sets up and a challenge resolution is needed in
# order to kill all scheduled alarms.
#
####################################################################################


##################
# User config here

## cron
CRON_ARGS=' -M '

## wake on lan
# what to send to distant machine in order to wake up the alarm one
WOL_CMD='/usr/local/bin/wol.sh j'
# which server to join with ssh. In this case, just an alias, I've
# put connexion details in ssh config
WOL_SERVER='dino'
# how many time before the alarm do we send the wake on lan signal ?
WOL_DELAY='-10 min'

## wake program
# where is located the alarme program.
WAKE_PRG='/usr/local/bin/wakemeup'
# where to store the id of the jobs created. Do not use directory that
# are cleaned after reboot suche as /var/run or /tmp
JOBID_FILE="$HOME/.alarm_job_id"

## alarms
# how many time will we launch alarms ?
BACKUP_ALARM_LEN=30
# interval between alarms
BACKUP_ALARM_INT=5
# if we went through all those alarm, wait
# some time before launching a last one
LAST_CHANCE_ALARM="1 hour"



########################
# Real stuff starts here


# captain obvious like this one
usage() {
  echo "Usage:"
  echo "$0 HHhMM"
  echo "$0 -k"
  echo "$0 [-h]"
  echo ""
  echo "    HHhMM  program som alarms"
  echo "    -k     kill existing alarms"
  echo "    -h     print this"
}


# wake up challenge
wake_up_chall() {
  OK="nop"
  while [ "$OK" = "nop" ];do
    read -p "$1" ANSWER
    if [ "$ANSWER" = "$2" ]; then
      echo "yep"
      OK="yp"
    fi
  done
}


# prg: program the alarm
# kill: kill existing clocks
ACTION='prg'
# scheduled alarm time
SCH_HH_ALARM=''
VERBOSE='no'

# parse cmd line arguments
while getopts “:khv” OPTION;do
  case $OPTION in
    h)
      usage
      exit 0
      ;;
    k)
      ACTION='kill'
      ;;
    v)
      VERBOSE='yes'
      ;;
  esac
done

shift $(( OPTIND - 1 ))
SHC_HH_ALARM=$@


if [ "$ACTION" = "kill" ];then
  # kill remaining scheduled alarms
  # first, be sure that ware have waked up:
  # we mispell some words in order to force user to think :p
  wake_up_chall "ligths are on ? " "lights are on"
  wake_up_chall "coffe is done ? " "coffee is done"

  # remove all jobs listed in the job_id file
  JOB_NB=0
  if [ -e $JOBID_FILE ];then
    while read line; do
      atrm $line
      JOB_NB=$(( $JOB_NB + 1))
    done < $JOBID_FILE
    rm $JOBID_FILE
  else
    echo "Cannot find $JOBID_FILE" 1>2
  fi
  echo "Removed $JOB_NB jobs"
else
  # set up the alarms
  # check argument correctness
  if ! `echo $SHC_HH_ALARM | grep -E '^[[:digit:]]{1,2}h[[:digit:]]{2}$' 1>/dev/null`;then
    usage
    exit 1
  fi

  # get time zone
  TZ=`date | cut -d' ' -f6 | grep -Eo 'UTC\+[[:digit:]]+'`
  # set time to date cmd format:  hh:mm
  SHC_DATE_ALARM=`echo $SHC_HH_ALARM | sed 's/h/:/'`

  # set Wake on Lan job
  HH_WOL=`date --date "$SHC_DATE_ALARM $TZ $WOL_DELAY" | grep -Eo ' [[:digit:]]{2}:[[:digit:]]{2}' | sed 's/\:/h/'`
  WOL_CMD="echo $WOL_CMD | at $CRON_ARGS $HH_WOL"
  ssh $WOL_SERVER "$WOL_CMD"
  
  # set the beep alarms
  DELAY=0
  >$JOBID_FILE
  ALARM_TIME=$1
  while [ "$DELAY" -le "$BACKUP_ALARM_LEN" ]; do
    echo "$WAKE_PRG -r" | at $SHC_HH_ALARM +$DELAY minute -M 2>&1| grep job | awk '{print $2}' >> $JOBID_FILE 
    DELAY=$(( $DELAY + $BACKUP_ALARM_INT ))
  done;

  # last chance alarm
  echo "$WAKE_PRG -r" | at $SHC_HH_ALARM +$LAST_CHANCE_ALARM -M 2>&1| grep job | awk '{print $2}' >> $JOBID_FILE
  atq | sort
fi

