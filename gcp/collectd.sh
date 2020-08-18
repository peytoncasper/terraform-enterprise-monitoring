#!/bin/bash
HOSTNAME="$(hostname -f)"
INTERVAL="${COLLECTD_INTERVAL:-5}"

while sleep "$INTERVAL"
do
    for container in $(docker stats --no-stream --format "{{json .}"); do
        jq container
    done

  for disk in sda sdb sdc sdd sde sdf
  do
    STATE=$(sudo smartctl -i -n standby /dev/$disk | grep -e "Device is in STANDBY mode" -e "Power mode is:    ACTIVE or IDLE" 2>/dev/null)
    if [ "$STATE" = "Device is in STANDBY mode, exit(2)" ]
      then
        # STANBY
        VALUE="0"
      else
        if [ "$STATE" = "Power mode is:    ACTIVE or IDLE" ]
          then
            # ACTIVE or IDLE
            VALUE="1"
          else
            # ERROR
            VALUE="U"
        fi
    fi
    echo "PUTVAL $HOSTNAME/disk-$disk/disk-state interval=$INTERVAL N:$VALUE" | tee -a /tmp/hddpwrstate.log
  done
done


HOSTNAME="$(hostname)"
INTERVAL="${COLLECTD_INTERVAL:-10}"
IFS='
'


while sleep "$INTERVAL"
do
    for container in $(docker stats --no-stream --format "{{json .}}"); do
        name=$(echo $container | jq ".Name")
        cpu=$(echo $container | jq ".CPUPerc" | sed 's/\%//g')
        
        echo "PUTVAL $HOSTNAME/exec-docker/guage-cpu_$name interval=$INTERVAL N:$cpu"
    done
done