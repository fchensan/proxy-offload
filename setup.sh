#!/usr/bin/bash
cd
sudo apt-get update
sudo apt-get install haproxy sysstat
sudo systemctl stop haproxy
git clone https://github.com/esnet/iperf.git
cd iperf
./configure
sudo make
sudo make install
cd
echo 1024 65535 | sudo tee /proc/sys/net/ipv4/ip_local_port_range
