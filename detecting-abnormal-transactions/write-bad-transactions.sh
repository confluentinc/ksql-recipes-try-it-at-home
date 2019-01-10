#!/usr/bin/env bash

COUNTER=0
TXN_ID=9900
# the set of suspicious accounts
declare -a RECIPIENTS=('verizon' 'alcatel' 'best buy');

# default scenario only makes 1 bad account ;) -
declare -a NAMES=('alan jones');

while [  $COUNTER -lt 2 ]; do
    for RECIPIENT in "${RECIPIENTS[@]}"
    do
        for NAME in "${NAMES[@]}"
        do
            # Set the key to ensure the detault partition assigner sends the records to the same partition
            MSG="$TXN_ID:{\"txn_id\":$TXN_ID,\"username\":\"$NAME\",\"recipient\":\"$RECIPIENT\", \"amount\":$((RANDOM % 100))}"
            echo $MSG | kafkacat -b kafka:29092 -P -t txns-1 -K: 
            let TXN_ID=TXN_ID+1
            sleep 1
        done
    done
 let COUNTER=COUNTER+1
done