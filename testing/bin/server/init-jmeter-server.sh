#!/bin/bash


function killJMeter {

	IFS=$'\n'
	for p in $(ps axu | grep -i jmeter-server | grep -v $0); do
	   JMETER_PID=$(echo $p | awk '{print $2}')
           echo "Finalizando processo $JMETER_PID"
	   kill -9 $JMETER_PID 
	done 
        exit 
}

./jmeter-server &

while [ 1 ]; do
  THREADS_STARTED=$(cat jmeter-server.log | grep -i thread | grep -i started | wc -l) 
  THREADS_ENDING=$(cat jmeter-server.log | grep -i thread | grep -i ending | wc -l) 
  THREADS_ENDED=$(cat jmeter-server.log | grep -i thread | grep -i done | wc -l) 
  echo "${THREADS_STARTED} started threads, ${THREADS_ENDING} ending threads, ${THREADS_ENDED} ended threads"

  trap "killJMeter" HUP 
  trap "killJMeter" INT 
  trap "killJMeter" QUIT 
  trap "killJMeter" PIPE 
  trap "killJMeter" TERM 
  trap "killJMeter" KILL 

  sleep 5
done

