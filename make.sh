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

# The root file system type to generate.
# Options are:
#   'multistrap' -- a full Debian-based system, to be installed to the second SD card partition
#   'buildroot' -- a minimal BusyBox-based system, to be run as a RAM disk
ROOTFS=buildroot

# These are the boot and rootfs partitions of your target SD card
# Set up the SD card with two partitions:
#   The first, called BOOT, a small FAT32 partition of 30MB
#   The rest, called Linux, as ext4
# An Ubuntu-based system will automount such a card at the following locations
SDCARD_BOOT=/media/$USER/BOOT/
SDCARD_ROOTFS=/media/$USER/Linux/

# The version of the Xilinx Linux kernel, U-Boot, Open MPI and Buildroot to use.
# It is recommended to change the Vivado version to that used for building the hardware.
VIVADO_VERSION=2017.4
OMPI_VERSION=3.0.0
BUILDROOT_VERSION=2018.02

# The following are generated from the versions specified above, but can be customised if required.
KERNEL_URL=https://github.com/Xilinx/linux-xlnx/archive/xilinx-v${VIVADO_VERSION}.tar.gz
UBOOT_URL=https://github.com/Xilinx/u-boot-xlnx/archive/xilinx-v${VIVADO_VERSION}.tar.gz
OMPI_URL=https://www.open-mpi.org/software/ompi/v${OMPI_VERSION%.*}/downloads/openmpi-${OMPI_VERSION}.tar.bz2
BUILDROOT_URL=https://buildroot.org/downloads/buildroot-${BUILDROOT_VERSION}.tar.bz2


function compile_environment {
	export ARCH=arm
	export UIMAGE_LOADADDR=0x2080000
	export LOADADDR=0x2080000
	export CROSS_COMPILE="arm-linux-gnueabihf-"
	export LD_LIBRARY_PATH=
}

function clear_compile_environment {
	unset ARCH
	unset UIMAGE_LOADADDR
	unset LOADADDR
	unset CROSS_COMPILE
	unset LD_LIBRARY_PATH
}

function build_api {
	cd phantom_api
	make DEFINES="-DSD_CARD_PHANTOM_LOC=\\\"/boot/\\\" -DTARGET_BOARD=\\\"$BOARD_PART\\\" -DTARGET_FPGA=0"
	cd ..
}

function copy_api {
	check_rootfs_valid
	if [ "$ROOTFS" == "multistrap" ]; then
		sudo cp -v phantom_api/libphantom.so multistrap/rootfs/usr/lib/
		sudo cp -v phantom_api/*.h multistrap/rootfs/usr/include/
	elif [ "$ROOTFS" == "buildroot" ]; then
		mkdir -p buildroot-phantom/board/phantom_zynq/overlay/usr/lib
		mkdir -p buildroot-phantom/board/phantom_zynq/overlay/usr/include
		cp -v phantom_api/libphantom.so buildroot-phantom/board/phantom_zynq/overlay/usr/lib/
		cp -v phantom_api/*.h buildroot-phantom/board/phantom_zynq/overlay/usr/include/
	fi
}

function build_multistrap {
	cd multistrap
	sudo multistrap -f multistrap.conf
	sudo ./rootfs_setup.sh
	sudo cp -afv --no-preserve=ownership overlay/. rootfs/
	sudo rm -f rootfs/README.md
	cd ..
}

function build_devicetree {
	mkdir -p images
	cd linux-xlnx
	cp ../arch/*.dtsi arch/arm/boot/dts/
	make ARCH=arm $DEVICETREE
	cp arch/arm/boot/dts/$DEVICETREE ../images/devicetree.dtb
	cd ..
}

function build_ompi {
	cd ompi
	mkdir -p build
	./configure --prefix=`pwd`/build --disable-mpi-fortran --host=arm-linux-gnueabihf
	make all install
	cd ..
}

function copy_ompi {
	check_rootfs_valid
	echo "Copying Open MPI to rootfs..."

	if [ "$ROOTFS" == "multistrap" ]; then
		sudo rm -rf multistrap/rootfs/opt/openmpi
		sudo cp -af --no-preserve=ownership ompi/build multistrap/rootfs/opt/openmpi
	elif [ "$ROOTFS" == "buildroot" ]; then
		rm -rf buildroot-phantom/board/phantom_zynq/overlay/opt/openmpi
		mkdir -p buildroot-phantom/board/phantom_zynq/overlay/opt
		cp -af ompi/build buildroot-phantom/board/phantom_zynq/overlay/opt/openmpi
	fi
}

function check_sources {
	if [ ! "$1" == "sources" ]; then
		if [ ! -d "linux-xlnx" ] || [ ! -d "u-boot-xlnx" ] || [ ! -d "ompi" ] || ([ "$ROOTFS" == "buildroot" ] && [ ! -d "buildroot" ]); then
			echo "Run '$0 sources' first to grab the kernel, U-Boot, Open MPI and (optionally) Buildroot sources."
			exit
		fi
	fi
}

function check_rootfs_valid {
	if [ ! "$ROOTFS" == "multistrap" ] && [ ! "$ROOTFS" == "buildroot" ]; then
		echo "Invalid rootfs type, $ROOTFS"
		exit
	fi
}



case "$1" in
	'prebuilt' )
		echo "Copying pre-built outputs to images folder..."
		mkdir -p images
		cp -rf prebuilt/* images
	;;

	'sources' )
		echo "Fetching sources..."

		if [ ! -d "linux-xlnx" ]; then
			echo "Fetching Xilinx Linux kernel (${VIVADO_VERSION})..."
			wget -O linux-xlnx.tar.gz $KERNEL_URL
			tar -xzf linux-xlnx.tar.gz
			rm -f linux-xlnx.tar.gz
			mv linux-xlnx-xilinx-v${VIVADO_VERSION} linux-xlnx
		fi

		if [ ! -d "u-boot-xlnx" ]; then
			echo "Fetching Xilinx U-Boot (${VIVADO_VERSION})..."
			wget -O u-boot-xlnx.tar.gz $UBOOT_URL
			tar -xzf u-boot-xlnx.tar.gz
			rm -f u-boot-xlnx.tar.gz
			mv u-boot-xlnx-xilinx-v${VIVADO_VERSION} u-boot-xlnx
		fi

		if [ ! -d "ompi" ]; then
			echo "Fetching Open MPI (${OMPI_VERSION})..."
			wget -O ompi.tar.bz2 $OMPI_URL
			tar -xf ompi.tar.bz2
			rm -f ompi.tar.bz2
			mv openmpi-${OMPI_VERSION} ompi
		fi

		if [ ! -d "buildroot" ]; then
			echo "Fetching Buildroot (${BUILDROOT_VERSION})..."
			wget -O buildroot.tar.bz2 $BUILDROOT_URL
			tar -xf buildroot.tar.bz2
			rm -f buildroot.tar.bz2
			mv buildroot-${BUILDROOT_VERSION} buildroot
		fi

		echo "Done."
	;;

	'kernel' )
		check_sources
		mkdir -p images
		cd linux-xlnx
		compile_environment
		make xilinx_zynq_defconfig
		cat ../custom/kernel_config >> .config
		make uImage modules
		cp arch/arm/boot/uImage ../images/
		cd ..

		build_devicetree
	;;

	'uboot' )
		check_sources
		mkdir -p images
		cd u-boot-xlnx
		compile_environment
		make ${UBOOT_TARGET}_defconfig
		make
 		cp u-boot ../images/u-boot.elf
	;;

	'ompi' )
		check_sources
		build_ompi
		copy_ompi
	;;

	'rootfs' )
		check_rootfs_valid
		if [ "$ROOTFS" == "multistrap" ]; then
			build_multistrap
			build_api
			copy_api
			copy_ompi
			echo "Installing kernel modules..."
			check_sources
			cd linux-xlnx
			sudo make ARCH=arm modules_install INSTALL_MOD_PATH=`pwd`/../multistrap/rootfs/
			cd ..
		elif [ "$ROOTFS" == "buildroot" ]; then
			build_api
			copy_api
			copy_ompi
			echo "Installing kernel modules..."
			cd linux-xlnx
			make ARCH=arm modules_install INSTALL_MOD_PATH=`pwd`/../buildroot-phantom/board/phantom_zynq/overlay/
			cd ..
			echo "Running Buildroot to generate rootfs..."
			cd buildroot
			make BR2_EXTERNAL=../buildroot-phantom phantom_zynq_defconfig
			make
			mkdir -p ../images
			cp -fv output/images/rootfs.cpio.uboot ../images/
			cd ..
		fi
	;;

	'api' )
		build_api
		copy_api
	;;

	'hwproject' )
		cd arch
		vivado -mode batch -source build_project.tcl -quiet -notrace -tclargs hwproj `pwd`/../ $BOARD_PART ${@:2}
	;;

	'sdcard' )
		check_rootfs_valid

		echo "Setting up boot partition..."
		cp images/BOOT.bin $SDCARD_BOOT
		cp images/devicetree.dtb $SDCARD_BOOT
		cp images/uImage $SDCARD_BOOT

		mkdir -p $SDCARD_BOOT/fpga/conf
		mkdir -p $SDCARD_BOOT/fpga/bitfile

		cp images/bitstream.bit $SDCARD_BOOT/fpga/bitfile
		cp images/phantom_fpga_conf.xml $SDCARD_BOOT/fpga/conf

		if [ "$ROOTFS" == "multistrap" ]; then
			cp arch/uEnv-multistrap.txt $SDCARD_BOOT/uEnv.txt
			echo "Copying root file system (may ask for root)..."
			sudo cp -a multistrap/rootfs/* $SDCARD_ROOTFS
		elif [ "$ROOTFS" == "buildroot" ]; then
			cp arch/uEnv-buildroot.txt $SDCARD_BOOT/uEnv.txt
			cp images/rootfs.cpio.uboot $SDCARD_BOOT
		fi
		
		sync

		echo "Done."
	;;

	'implement' )
		mkdir -p images
		cd arch
		vivado -mode batch -source implement_project.tcl -notrace
		cp ../hwproj/hwproj.runs/impl_1/design_1_wrapper.bit ../images/bitstream.bit
		cp ../hwproj/phantom_fpga_conf.xml ../images/phantom_fpga_conf.xml
	;;

	'devicetree' )
		check_sources
		build_devicetree
	;;

	'fsbl' )
		mkdir -p images
		mkdir -p fsbl
		cd arch
		hsi -nojournal -nolog -source generate_fsbl.tcl
		cd ..
		cp fsbl/executable.elf images/fsbl.elf
	;;

	'bootimage' )
		mkdir -p images
		cd arch
		bootgen -image bootimage.bif -arch zynq -w -o i ../images/BOOT.bin
	;;

	'clean' )
	read -r -p "Are you sure? [y/N] " response
		if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
		then
			sudo umount -lf multistrap/rootfs/dev
			sudo rm -rf multistrap/rootfs
			rm -rf linux-xlnx u-boot-xlnx ompi buildroot
			rm -rf images
			rm -rf hwproj
			rm -rf fsbl
		fi
	;;

	* )
		echo "Unknown option: '$1'"
		echo "Usage: $0 [prebuilt|sources|kernel|uboot|ompi|rootfs|api|hwproject|sdcard|devicetree|implement|fsbl|bootimage|clean]"
	;;

esac
