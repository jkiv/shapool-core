#!/bin/bash

# Provisioning script for setting up shapool-core build environment
# - Assumes Ubuntu 18.04
# - Run from shapool-core repo base directory

# ... Icestorm dependencies
sudo apt-get install build-essential clang bison flex libreadline-dev \
    gawk tcl-dev libffi-dev git mercurial graphviz   \
    xdot pkg-config python python3 libftdi-dev \
    qt5-default python3-dev libboost-all-dev cmake

# ... Yosys dependencies
sudo apt-get install build-essential clang bison flex \
	libreadline-dev gawk tcl-dev libffi-dev git \
	graphviz xdot pkg-config python3 libboost-system-dev \
	libboost-python-dev libboost-filesystem-dev zlib1g-dev

sudo apt-get install iverilog
sudo apt-get install verilator

mkdir external
cd external

# Clone all necessary repos
git clone git@github.com:cliffordwolf/icestorm.git icestorm
git clone git@github.com:cseed/arachne-pnr.git arachne-pnr
#git clone git@github.com:YosysHQ/nextpnr nextpnr
git clone git@github.com:cliffordwolf/yosys.git yosys

# Build and install icestorm
cd icestorm
make -j$(nproc)
sudo make install
cd -

# Build and install arachne-pnr
cd arachne-pnr
make -j$(nproc)
sudo make install
cd -

# Build and install nextpnr
echo '(Skipping nextpnr...)'
#cd nextpnr
#cmake -DARCH=ice40 -DCMAKE_INSTALL_PREFIX=/usr/local .
#make -j$(nproc)
#sudo make install
#cd -

# Build and install yosys
cd yosys
make -j$(nproc)
sudo make install
cd -

# Add lattice development board to USB rules
sudo cp 53-lattice-ftdi.rules /etc/udev/rules.d/53-lattice-ftdi.rules
