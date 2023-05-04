#!/bin/bash

INTERVAL=$3  # update interval in seconds

if [ -z "$1" ]; then
        echo
        echo usage: $0 [network-interface]
        echo
        echo e.g. $0 eth0
        echo
        echo shows packets-per-second
        exit
fi

IF=$1

echo "datetime,TX $1 pps,TX $1 kbps,RX $1 pps,RX $1 kB/s,TCP Established,"

while true
do
        R1=`cat /sys/class/net/$1/statistics/rx_packets`
        T1=`cat /sys/class/net/$1/statistics/tx_packets`
	RB1=`cat /sys/class/net/$1/statistics/rx_bytes`
        TB1=`cat /sys/class/net/$1/statistics/tx_bytes`

        sleep $INTERVAL
        R2=`cat /sys/class/net/$1/statistics/rx_packets`
        T2=`cat /sys/class/net/$1/statistics/tx_packets`
	RB2=`cat /sys/class/net/$1/statistics/rx_bytes`
        TB2=`cat /sys/class/net/$1/statistics/tx_bytes`

        TBPS=`expr $TB2 - $TB1`
        RBPS=`expr $RB2 - $RB1`
	TKBPS=$(( ($TBPS / 1024 / $INTERVAL) * 8))
	RKBPS=$(( ($RBPS / 1024 / $INTERVAL) * 8))
        TXPPS=`expr $T2 - $T1`
        RXPPS=`expr $R2 - $R1`

	ESTABLISHED=$(ss -s | grep TCP: | awk '{print $4}')
	DATETIME=$(date +%H:%M:%S)
        echo "$DATETIME,$TXPPS,$TKBPS,$RXPPS,$RKBPS,$ESTABLISHED"
done
