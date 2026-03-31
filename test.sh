#!/bin/bash

NUM_UES=3

echo $CFG_PATH
echo $CURRENT_DIR

start_program() {
    sudo xterm -hold -e "$1" -c "$2" &
    pids+=($!)
    sleep 0.2
}



for ue_id in $(seq 1 3); do
    sudo ip netns exec "ue${ue_id}" ip route add default via 10.45.1.1 dev tun_srsue
    sleep 0.2
done

for ue_id in $(seq 1 3); do
    sudo xterm -hold -e "iperf3 -s -i 1 -p 520${ue_id}" &
    sleep 0.2
done

for ue_id in $(seq 1 3); do
    #sudo xterm -hold -e "sudo ip netns exec ue${ue_id} iperf3 -c 10.53.1.1 -R -i 1 -t 60 -b 30M -p 520${ue_id}" &
    sudo xterm -hold -e "sudo ip netns exec ue${ue_id} iperf3 -c 10.53.1.1 -R -i 1 -t 300 -p 520${ue_id}" &
    pids+=($!)
    sleep 0.2
done
