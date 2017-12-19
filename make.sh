#!/bin/bash

# These variables must be set correctly for your target board

# This is the devicetree file to use from the Linux kernel source tree.
# Xilinx provides these for all of its boards in the `/arch/arm/boot/dts/` and `/arch/arm64/boot/dts/` folders.
# Common examples are: zynq-zc706.dtb zynq-zed.dtb zynq-zybo.dtb
DEVICETREE=zynq-zc706.dtb

# The target to use for U-Boot, these are in the `u-boot-xlnx/configs` directory.
# Common examples are: zynq_zc706 zynq_zed zynq_zybo
UBOOT_TARGET=zynq_zc706

# The Xilinx name for the target board.
# You can list all of the board parts that your Xilinx installation supports by entering the command `get_board_parts` into the TCL console of Vivado.
# Common examples are: xilinx.com:zc706:part0:1.3 digilentinc.com:zedboard:part0:1.0 digilentinc.com:zybo:part0:1.0
BOARD_PART=xilinx.com:zc706:part0:1.3

# These are the boot and rootfs partitions of your target SD card
# Set up the SD card with two partitions:
#   The first, called BOOT, a small FAT32 partition of 30MB
#   The rest, called Linux, as ext4
# An Ubuntu-based system will automount such a card at the following locations
SDCARD_BOOT=/media/$USER/BOOT/
SDCARD_ROOTFS=/media/$USER/Linux/

# The version of the Xilinx Linux kernel and U-Boot to use.
# It is recommended to change the Vivado version to that used to build the hardware.
VIVADO_VERSION=2017.2
KERNEL_TAG=xilinx-v${VIVADO_VERSION}
UBOOT_TAG=xilinx-v${VIVADO_VERSION}


function compile_environment {
	export ARCH=arm
	export UIMAGE_LOADADDR=0x2080000
	export LOADADDR=0x2080000
	export CROSS_COMPILE="arm-linux-gnueabihf-"
	export LD_LIBRARY_PATH=
}

function build_api {
	cd phantom_api
	make DEFINES="-DSD_CARD_PHANTOM_LOC=\\\"/boot/\\\" -DTARGET_BOARD=\\\"$BOARD_PART\\\" -DTARGET_FPGA=0"
	cp libphantom.so ../rootfs/rootfs/usr/lib/
	cp *.h ../rootfs/rootfs/usr/include/
	cd ..
}

function build_multistrap {
	cd rootfs
	multistrap -f multistrap.conf
	sudo ./zynq_setup.sh
	cd ..
}

function build_devicetree {
	cd linux-xlnx
	cp ../arch/*.dtsi arch/arm/boot/dts/
	make ARCH=arm $DEVICETREE
	cp arch/arm/boot/dts/$DEVICETREE ../images/devicetree.dtb
	cd ..
}


if [ ! "$1" == "sources" ]; then
	if [ ! -d "linux-xlnx" ]; then
		echo "Run ./make.sh sources first to grab the kernel and U-Boot sources."
		exit
	fi

	if [ ! -d "u-boot-xlnx" ]; then
		echo "Run ./make.sh sources first to grab the kernel and U-Boot sources."
		exit
	fi
fi



case "$1" in
	'sources' )
		echo "Checking out sources..."
		git clone --branch $KERNEL_TAG --depth 1 https://github.com/Xilinx/linux-xlnx.git
		git clone --branch $UBOOT_TAG --depth 1 https://github.com/Xilinx/u-boot-xlnx.git
	;;

	'kernel' )
		cd linux-xlnx
		compile_environment
		make xilinx_zynq_defconfig
		make uImage
		cp arch/arm/boot/uImage ../images/
		cd ..

		build_devicetree
	;;

	'uboot' )
		cd u-boot-xlnx
		compile_environment
		make ${UBOOT_TARGET}_defconfig
		make
 		cp u-boot ../images/u-boot.elf
	;;

	'rootfs' )
		build_multistrap
		build_api

		echo "Building and installing kernel modules..."
		cd linux-xlnx
		compile_environment
		make modules
		make modules_install INSTALL_MOD_PATH=`pwd`/../rootfs/rootfs/
		cd ..
	;;

	'api' )
		build_api
	;;

	'hwproject' )
		cd arch
		vivado -mode batch -source build_project.tcl -quiet -notrace -tclargs hwproj `pwd`/../ $BOARD_PART ${@:2}
	;;

	'sdcard' )
		echo "Setting up boot partition..."
		cp images/BOOT.bin $SDCARD_BOOT
		cp images/devicetree.dtb $SDCARD_BOOT
		cp images/uImage $SDCARD_BOOT
		cp arch/uEnv.txt $SDCARD_BOOT

		mkdir -p $SDCARD_BOOT/fpga/conf
		mkdir -p $SDCARD_BOOT/fpga/bitfile

		cp images/bitstream.bit $SDCARD_BOOT/fpga/bitfile
		cp hwproj/phantom_fpga_conf.xml $SDCARD_BOOT/fpga/conf

		echo "Copying root filesystem (may ask for root)..."
		TARGETDIR=$SDCARD_ROOTFS
		sudo cp -r rootfs/rootfs/* $TARGETDIR

		echo "Done."
	;;

	'implement' )
		cd arch
		vivado -mode batch -source implement_project.tcl -notrace
		cp ../hwproj/hwproj.runs/impl_1/design_1_wrapper.bit ../images/bitstream.bit
		cp ../hwproj/phantom_fpga_conf.xml ../images/phantom_fpga_conf.xml
	;;

	'devicetree' )
		build_devicetree
	;;

	'clean' )
	read -r -p "Are you sure? [y/N] " response
		if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
		then
			rm -rf linux-xlnx u-boot-xlnx
			rm -rf images/uImage images/devicetree.dtb images/bitstream.bit images/u-boot.elf
			rm -rf rootfs/rootfs
			rm -rf hwproj
		fi
	;;

	'' )
		echo "Usage: $0 [sources | kernel | uboot | rootfs | hwproject | devicetree | implement | clean]"
	;;

esac
