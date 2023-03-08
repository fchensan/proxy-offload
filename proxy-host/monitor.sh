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

echo "datetime,TX $1 pps,TX $1 kB/s,TX $2 pps,TX $1 kB/s,RX $1 pps,RX $1 kB/s,RX $2 pps,RX $2 kB/s,TCP Established"

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
	TKBPS=$(( ($TBPS / 1024 / $INTERVAL) * 8))
	RKBPS=$(( ($RBPS / 1024 / $INTERVAL) * 8))
        TXPPS=`expr $T2 - $T1`
        RXPPS=`expr $R2 - $R1`
        TBPS2=`expr $TB22 - $TB12`
        RBPS2=`expr $RB22 - $RB12`
	TKBPS2=$(( ($TBPS2 / 1024 / $INTERVAL) * 8))
	RKBPS2=$(( ($RBPS2 / 1024 / $INTERVAL) * 8))
        TXPPS2=`expr $T22 - $T12`
        RXPPS2=`expr $R22 - $R12`

	ESTABLISHED=$(ss -s | grep TCP: | awk '{print $4}')
	DATETIME=$(date +%H:%M:%S)
        echo "$DATETIME,$TXPPS,$TKBPS,$RXPPS,$RKBPS,$TXPPS2,$TKBPS2,$RXPPS2,$RKBPS2,$ESTABLISHED"
done
