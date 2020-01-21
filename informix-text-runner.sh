#!/bin/bash

source /etc/default/node_exporter

nummetrics=$( jq '. | length' < ${INFORMIX_EXPORTER_PATH}/metrics.json )
mins=$( date +%M )
cnt=0

while IFS=',' read -ra INSTANCES; do
      for instance in "${INSTANCES[@]}"; do
            source /etc/informix/${instance}.env
	    while [ "$cnt" -lt "$nummetrics" ]
                do
        		frequency=$( jq --argjson cnt "$cnt" '.[$cnt] | .frequency' < ${INFORMIX_EXPORTER_PATH}/metrics.json | tr -d \" )
        		isnow=$(( mins % ( 60 / frequency ) ))
        
        		if [ "$isnow" -eq 0 ]
        		then
        			if [ -f "./.${instance}.${frequency}.lock" ]
        			then
        				:
        			else
        				${INFORMIX_EXPORTER_PATH}/informix-text-exporter.sh "$instance" "$frequency"
        				touch ".${instance}.${frequency}.lock"
        			fi
        		fi
        
        		cnt=$(( cnt + 1 ))
            done
      done
done <<< "${INFORMIX_EXPORTER_INSTANCES}"
