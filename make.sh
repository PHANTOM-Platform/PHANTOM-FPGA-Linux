#!/bin/bash

DEVICETREE=zynq-zc706.dts
UBOOT_TARGET=zynq_zc706
BOARD_PART=xilinx.com:zc706:part0:1.3

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
		cd ..

		cd phantom_api
		make
		cp phantom_api.so ../rootfs/rootfs/usr/lib/
		cp *.h ../rootfs/rootfs/usr/include/
		cd ..
	;;

	'hwproject' )
		cd arch
		vivado -mode batch -source build_project.tcl -quiet -notrace -tclargs hwproj `pwd`/../ $BOARD_PART ${@:2}
	;;

	'implement' )
		cd arch
		vivado -mode batch -source implement_project.tcl -notrace
		cp ../hwproj/hwproj.runs/impl_1/design_1_wrapper.bit ../images/bitstream.bit
	;;

	'clean' )
	read -r -p "Are you sure? [y/N] " response
		if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
		then
			rf -rf linux-xlnx u-boot-xlnx
			rf -rf images/uImage images/devicetree.dtb images/bitstream.bit images/u-boot.elf
			rf -rf rootfs/rootfs
		fi
	;;

	'' )
		echo "Usage: $0 [sources | kernel | uboot | rootfs | hwproject | implement | clean]"
	;;

esac
