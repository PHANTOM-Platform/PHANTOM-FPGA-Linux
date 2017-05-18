#!/bin/bash

DEVICETREE=zynq-zc706.dts
UBOOT_TARGET=zynq_zc706

if [ ! "$1" == "sources" ]; then
	if [ ! -d "linux-xlnx" ]; then
		echo "Run ./make.sh sources first to grab the kernel and uboot sources."
		exit
	fi

	if [ ! -d "u-boot-xlnx" ]; then
		echo "Run ./make.sh sources first to grab the kernel and uboot sources."
		exit
	fi
fi

case "$1" in

	'sources' )
		echo "Checking out sources..."
		git clone --depth 1 https://github.com/Xilinx/linux-xlnx.git
		git clone --depth 1 https://github.com/Xilinx/u-boot-xlnx.git	
	;;

	'kernel' )
		cd linux-xlnx
		export ARCH=arm
		export UIMAGE_LOADADDR=0x2080000
		export LOADADDR=0x2080000
		export CROSS_COMPILE="arm-linux-gnueabihf-"
		export LD_LIBRARY_PATH=
		make xilinx_zynq_defconfig
		make uImage
		cp arch/arm/boot/uImage ../images/
		make ARCH=arm zynq-zc706.dtb
		cp arch/arm/boot/dts/zynq-zc706.dtb ../images/devicetree.dtb
	;;

	'uboot' )
		cd u-boot-xlnx
		export ARCH=arm
		export UIMAGE_LOADADDR=0x2080000
		export LOADADDR=0x2080000
		export CROSS_COMPILE="arm-linux-gnueabihf-"
		export LD_LIBRARY_PATH=
		make $UBOOT_TARGET_defconfig
		make
 		cp u-boot ../images/u-boot.elf
	;;

	'rootfs' )
		cd rootfs
		multistrap -f multistrap.conf
		sudo ./zynq_setup.sh
	;;

	'' )
		echo "Usage: $0 [sources | kernel | uboot | rootfs ]"
	;;

esac

