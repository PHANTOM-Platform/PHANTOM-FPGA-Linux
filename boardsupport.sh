#!/bin/bash

# This script sets up the variables required for the target board. It is sourced by make.sh.

# The target FPGA board to use (taken from 'phantom_fpga_config.json').
BOARD=`arch/config.py --board phantom_fpga_config.json`

# DEVICETREE
# This is the devicetree file to use from the Linux kernel source tree.
# Xilinx provides these for all of its boards in the `/arch/arm/boot/dts/` and `/arch/arm64/boot/dts/` folders.
# Common examples are: zynq-zc706.dtb zynq-zed.dtb zynq-zybo.dtb

# UBOOT_TARGET
# The target to use for uBoot, these are in the `u-boot-xlnx/configs` directory.
# Common examples are: zynq_zc706 zynq_zed zynq_zybo

# BOARD_PART
# The Xilinx name for the target board.
# You can list all of the board parts that your Xilinx installation supports by entering the command `get_board_parts` into the TCL console of Vivado.
# Common examples are: xilinx.com:zc706:part0:1.3 digilentinc.com:zedboard:part0:1.0 digilentinc.com:zybo:part0:1.0

case "$BOARD" in
	'zc706' )
		DEVICETREE=zynq-zc706.dtb
		UBOOT_TARGET=zynq_zc706
		BOARD_PART=xilinx.com:zc706:part0:1.3
	;;

	'zybo' )
		DEVICETREE=zynq-zybo.dtb
		UBOOT_TARGET=zynq_zybo
		BOARD_PART=digilentinc.com:zybo:part0:1.0
	;;

	'zedboard' )
		DEVICETREE=zynq-zed.dtb
		UBOOT_TARGET=zynq_zed
		BOARD_PART=digilentinc.com:zedboard:part0:1.0
	;;

	'z-turn_7020' )
		DEVICETREE=zynq-zturn.dtb
		UBOOT_TARGET=zynq_zturn
		BOARD_PART=myirtech.com:z-turn_7020:part0:1.0
	;;

	* )
		echo "Unsupported board type: $BOARD"
		return 1
	;;
esac


# The target root file system type to generate (taken from 'phantom_fpga_config.json').
# Options are:
#   'multistrap' -- a full Debian-based system, to be installed to the second SD card partition
#   'buildroot' -- a minimal BusyBox-based system, to be run as a RAM disk
ROOTFS=`arch/config.py --rootfs phantom_fpga_config.json`

# The list of IP cores and shared memory sizes to include in the design (taken from 'phantom_fpga_config.json').
# Format is:
#   ipcore1 memsize1 ipcore2 memsize2 ...
IPCORES=`arch/config.py --ipcores phantom_fpga_config.json`

# The version of the Xilinx Linux kernel, U-Boot, Open MPI and Buildroot to use.
# It is recommended to change the Vivado version to that used for building the hardware.
VIVADO_VERSION=2018.2
OMPI_VERSION=3.0.0
BUILDROOT_VERSION=2018.08.2

# The following are generated from the versions specified above, but can be customised if required.
KERNEL_URL=https://github.com/Xilinx/linux-xlnx/archive/xilinx-v${VIVADO_VERSION}.tar.gz
UBOOT_URL=https://github.com/Xilinx/u-boot-xlnx/archive/xilinx-v${VIVADO_VERSION}.tar.gz
OMPI_URL=https://www.open-mpi.org/software/ompi/v${OMPI_VERSION%.*}/downloads/openmpi-${OMPI_VERSION}.tar.bz2
BUILDROOT_URL=https://buildroot.org/downloads/buildroot-${BUILDROOT_VERSION}.tar.bz2
