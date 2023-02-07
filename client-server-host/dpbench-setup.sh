git clone https://github.com/dpbench/dpbench.git
cd dpbench
git submodule init
git submodule update
./tools/build-all.sh
cd ~
sudo apt update
sudo apt install gnuplot
