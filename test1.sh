#!/bin/bash

NUM_UES=3

echo $CFG_PATH
echo $CURRENT_DIR

# === ДОБАВЛЕНО: Устанавливаем безопасный MTU для туннелей ===
# Это предотвращает потерю пакетов из-за оверхеда туннеля
for ue_id in $(seq 1 $NUM_UES); do
    sudo ip netns exec "ue${ue_id}" ip link set dev tun_srsue mtu 1400
    echo "Set MTU 1400 on ue${ue_id}:tun_srsue"
    sleep 0.1
done

# Также желательно на хосте (если tun_srsue виден в root ns)
# sudo ip link set dev tun_srsue mtu 1400 2>/dev/null

start_program() {
    sudo xterm -hold -e "$1" -c "$2" &
    pids+=($!)
    sleep 0.2
}

# Маршруты
for ue_id in $(seq 1 $NUM_UES); do
    sudo ip netns exec "ue${ue_id}" ip route add default via 10.45.1.1 dev tun_srsue 2>/dev/null
    sleep 0.2
done

# Серверы iperf3
for ue_id in $(seq 1 $NUM_UES); do
    sudo xterm -hold -e "iperf3 -s -i 1 -p 520${ue_id}" &
    sleep 0.2
done

# Клиенты iperf3
# ДОБАВЛЕНО: -M 1360 для явного ограничения размера сегмента
for ue_id in $(seq 1 $NUM_UES); do
    sudo xterm -hold -e "sudo ip netns exec ue${ue_id} iperf3 -c 10.53.1.1 -R -i 1 -t 300 -p 520${ue_id} -M 1360" &
    pids+=($!)
    sleep 0.2
done

# Ожидание завершения клиентов
wait "${pids[@]}"
