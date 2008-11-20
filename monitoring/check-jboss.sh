#!/bin/bash
############################################################
#
# A very simple BASH script to keep tracking of JBoss 
# runtime environment.
# Based on JVM monitoring tools
# http://java.sun.com/javase/6/docs/technotes/tools/index.html#monitor
#
# @author Hygo Reinaldo
# @author Alexandre Gomes (alegomes@gmail.com)
# @version 0.1
#
############################################################

function header() {
  echo
  echo "-------------------------------------------"
  echo "--    Mega script for JBoss monitoring   --"
  echo "-------------------------------------------"
  echo
  echo "This data is also being saved at $1"
  echo
}

function usage() {
  echo "Use: check-jboss <ip> [-j]"
  echo
  echo "Where:"
  echo "--------------------------------------"
  echo "ip     JBoss instance IP bound address."
  echo "--------------------------------------"
  echo "Supported on Linux only."
  echo "--------------------------------------"

}

function error() {
  echo
  echo "ERROR $1"
  echo
  exit -1
}

function finalize() {
  echo 
  echo "-------------------------------------------------------------------------------------"
  echo "Thanks for using check-jboss."
  echo "All collected data has been saved at $1"
  echo "Enjoy ;-P"
  echo "-------------------------------------------------------------------------------------"
  echo
  exit 0
}

function verifyEnvironment() {

  JBOSS_USER=$1
  JBOSS_PID=$2

  # Check if there is a JBoss running
  if [ -z "$JBOSS_PID" ]; then
     error "No JBoss bound at IP address [$JBOSS_PID]"
     usage
  fi

  # Check if user running this script is allowed to collec data from JBoss
  # MYUSER=$(whoami)
  # if ! [ "$JBOSS_USER" = "$MYUSER" ]; then
  #   error "Please, log in as $JBOSS_USER (you are currently logged as $MYUSER)"
  # fi

  # TODO [ALE] How to verify is the script has set UID?
}


#############################################################
#
# Script Begin
#
#############################################################

JBOSS_ADDRESS=$1
JBOSS=$(ps aux | grep -i jboss.main | grep -i $JBOSS_ADDRESS)
JBOSS_USER=$(echo $JBOSS | awk '{print $1}')
JBOSS_PID=$(echo $JBOSS | awk '{print $2}')

CHECKJBOSSFILE="/var/log/jboss/check-jboss-${JBOSS_ADDRESS}-$(date +'%Y%m%d-%H%M%S').csv"
touch $CHECKJBOSSFILE

clear
verifyEnvironment ${JBOSS_USER} ${JBOSS_PID}

header $CHECKJBOSSFILE

trap "finalize $CHECKJBOSSFILE" HUP 
trap "finalize $CHECKJBOSSFILE" INT 
trap "finalize $CHECKJBOSSFILE" QUIT 
trap "finalize $CHECKJBOSSFILE" PIPE 
trap "finalize $CHECKJBOSSFILE" TERM 
trap "finalize $CHECKJBOSSFILE" KILL

# Header
echo "# timestamp,"\
     "# of sockets listening on port 80," \
     "# of non-listeting sockets on port 80," \
     "# of established sockest on port 80," \
     "# of connections to port 1521 (Oracle)," \
     "server load," \
     "server memory used (GB)," \
     "survivor space 0 usage (%) (S0)," \
     "survivor space 1 usage (%) (S1)," \
	 "eden space usage (%) (E)," \
	 "old space usage (%) (O)," \
	 "permanent space usage (%) (P)," \
	 "# of young generation GC events (YGC)," \
	 "young generation gargabe collection time (YGCT)," \
	 "# of full GC events (FGC)," \
	 "full GC time (FGCT)," \
	 "total GC time (GCT)," \
	 "# total of threads," \
	 "# of total blocked threads," \
	 "# of HTTP threads," \
	 "# of HTTP blocked threads," \
	 "# of HTTP waiting threads," \
	 "# of HTTP time_waiting threads," \
	 "# of HTTP runnable threads," | tee -a $CHECKJBOSSFILE
	
while true; do

  # ..............
  # Get jStat data
  # ..............
  IFS=$'\n'
  ((i=0))
  for l in $(jstat -gcutil $JBOSS_PID); do
	if [ $i == 1 ]; then JSTAT_DATA=${l}; fi
    ((i += 1))
  done

  # ................
  # Get jStack data
  # ................
  TMPFILE="/tmp/check-jboss-jtack-ip${JBOSS_ADDRESS}pid${JBOSS_PID}date$(date +'%Y%m%d%H%M%S')"
  `jstack -l $JBOSS_PID > $TMPFILE`

  TOTAL_THREADS="$(cat $TMPFILE | grep -i prio | wc -l)"
  TOTAL_BLOCKED_THREADS="$(cat $TMPFILE | grep -i thread.state | grep -i block | wc -l)"
  HTTP_THREADS="$(cat $TMPFILE | grep -i http | wc -l)"
  HTTP_BLOCKED_THREADS="$(cat $TMPFILE | grep -A1 "^\"http.*$" | grep -i thread.state | grep -i block | wc -l)"
  HTTP_WAITING_THREADS="$(cat $TMPFILE | grep -A1 -B0 http | grep -i thread.state | grep -i waiting | wc -l)"
  HTTP_TIMEWAITING_THREADS="$(cat $TMPFILE | grep -A1 -B0 http | grep -i thread.state | grep -i time_waiting | wc -l)"
  HTTP_RUNNABLE_THREADS="$(cat $TMPFILE | grep -A1 -B0 http | grep -i thread.state | grep -i runnable | wc -l)"

  rm $TMPFILE

  # ................
  # Print data
  # ................
  echo "$(date +'%d/%m/%Y %H:%M:%S')," \
       "`netstat -tan | grep $1:80 | grep -i LISTEN | grep -v $1:800 | grep -v $1:808 | wc -l `," \
       "`netstat -tan  | grep $1:80 | grep -v LISTEN | grep -v $1:800 | grep -v $1:808 | wc -l`," \
       "`netstat -tan  | grep $1:80 | grep -i ESTABLISHED | grep -v LISTEN | grep -v $1:800 | grep -v $1:808 | wc -l`," \
       "`netstat -tan  | grep :1521 | grep -v LISTEN | wc -l`," \
	   "`uptime | awk '{print $10}' | cut -d, -f1`," \
	   "`free -g | grep Mem: | awk '{print $3}'`," \
       "`echo "${JSTAT_DATA}" | awk '{print $1", "$2", "$3", "$4", "$5", "$6", "$7", "$8", "$9", "$10}'`," \
       "${TOTAL_THREADS}," \
       "${TOTAL_BLOCKED_THREADS}," \
       "${HTTP_THREADS}," \
       "${HTTP_BLOCKED_THREADS}," \
       "${HTTP_WAITING_THREADS}," \
       "${HTTP_TIMEWAITING_THREADS}," \
       "${HTTP_RUNNABLE_THREADS}" | tee -a $CHECKJBOSSFILE
      
    sleep 5 

done
