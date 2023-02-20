#!/bin/bash

INTERVAL="1"  # update interval in seconds

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

echo "TX $1 pps,TX $1 kB/s,TX $2 pps,TX $1 kB/s,RX $1 pps,RX $1 kB/s,RX $2 pps,RX $2 kB/s,CPU user percent,CPU system percent,CPU idle percent,"

while true
do
        R1=`cat /sys/class/net/$1/statistics/rx_packets`
        T1=`cat /sys/class/net/$1/statistics/tx_packets`
	RB1=`cat /sys/class/net/$1/statistics/rx_bytes`
        TB1=`cat /sys/class/net/$1/statistics/tx_bytes`
        R12=`cat /sys/class/net/$2/statistics/rx_packets`
        T12=`cat /sys/class/net/$2/statistics/tx_packets`
	RB12=`cat /sys/class/net/$2/statistics/rx_bytes`
        TB12=`cat /sys/class/net/$2/statistics/tx_bytes`

        sleep $INTERVAL
        R2=`cat /sys/class/net/$1/statistics/rx_packets`
        T2=`cat /sys/class/net/$1/statistics/tx_packets`
	RB2=`cat /sys/class/net/$1/statistics/rx_bytes`
        TB2=`cat /sys/class/net/$1/statistics/tx_bytes`
        R22=`cat /sys/class/net/$2/statistics/rx_packets`
        T22=`cat /sys/class/net/$2/statistics/tx_packets`
	RB22=`cat /sys/class/net/$2/statistics/rx_bytes`
        TB22=`cat /sys/class/net/$2/statistics/tx_bytes`

        TBPS=`expr $TB2 - $TB1`
        RBPS=`expr $RB2 - $RB1`
        TKBPS=`expr $TBPS / 1024`
        RKBPS=`expr $RBPS / 1024`
        TXPPS=`expr $T2 - $T1`
        RXPPS=`expr $R2 - $R1`
        TBPS2=`expr $TB22 - $TB12`
        RBPS2=`expr $RB22 - $RB12`
        TKBPS2=`expr $TBPS2 / 1024`
        RKBPS2=`expr $RBPS2 / 1024`
        TXPPS2=`expr $T22 - $T12`
        RXPPS2=`expr $R22 - $R12`

	CPU=$(vmstat | tail -1 | awk '{print $13,$14,$15}' | tr -s '[:blank:]' ',')
        echo "$TXPPS,$TKBPS,$RXPPS,$RKBPS,$TXPPS2,$TKBPS2,$RXPPS2,$RKBPS2,$CPU"
done
