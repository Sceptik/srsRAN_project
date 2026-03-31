#!/bin/bash

NUM_UES=3

echo $CFG_PATH
echo $CURRENT_DIR

pids=()

# Очистка
sudo pkill iperf3
for ue_id in $(seq 1 $NUM_UES); do
    sudo ip netns del "ue${ue_id}" 2>/dev/null || true
done

# Создаем network namespace для UE
for ue_id in $(seq 1 $NUM_UES); do
    sudo ip netns add "ue${ue_id}"
    sleep 0.5
done

# Запускаем ОДИН сервер на стандартном порту
iperf3 -s -i 1 -p 5201 &
pids+=($!)
sleep 2

# Проверяем сервер
if netstat -tln | grep -q "5201"; then
    echo "✓ Основной сервер запущен на порту 5201"
else
    echo "✗ Не удалось запустить сервер"
    exit 1
fi

# Запускаем клиентов (все подключаются к одному серверу)
for ue_id in $(seq 1 $NUM_UES); do
    sudo xterm -hold -e "sudo ip netns exec ue${ue_id} iperf3 -c 10.53.1.1 -R -i 1 -t 60 -b 30M -p 5201" &
    pids+=($!)
    sleep 1
    echo "Клиент UE${ue_id} запущен"
done

echo "Все $NUM_UES UE запущены. Нажмите Ctrl+C для остановки."

cleanup() {
    echo "Останавливаем все процессы..."
    sudo kill ${pids[@]} 2>/dev/null
    sudo pkill iperf3
    for ue_id in $(seq 1 $NUM_UES); do
        sudo ip netns del "ue${ue_id}" 2>/dev/null
    done
    exit
}

trap cleanup INT TERM
wait
