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

# The version of the Xilinx Linux kernel, U-Boot and Open MPI to use.
# It is recommended to change the Vivado version to that used for building the hardware.
VIVADO_VERSION=2017.2
OMPI_VERSION=3.0.0

# The following are generated from the versions specified above, but can be customised if required.
KERNEL_TAG=xilinx-v${VIVADO_VERSION}
UBOOT_TAG=xilinx-v${VIVADO_VERSION}
OMPI_URL=https://www.open-mpi.org/software/ompi/v${OMPI_VERSION%.*}/downloads/openmpi-${OMPI_VERSION}.tar.bz2


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
	cd ..
}

function copy_api {
	sudo cp -v phantom_api/libphantom.so rootfs/rootfs/usr/lib/
	sudo cp -v phantom_api/*.h rootfs/rootfs/usr/include/
}

function build_multistrap {
	cd rootfs
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
	echo "Copying Open MPI to rootfs..."
	sudo rm -rf rootfs/rootfs/opt/openmpi
	sudo cp -af --no-preserve=ownership ompi/build rootfs/rootfs/opt/openmpi
}

function check_sources {
	if [ ! "$1" == "sources" ]; then
		if [ ! -d "linux-xlnx" ] || [ ! -d "u-boot-xlnx" ] || [ ! -d "ompi" ]; then
			echo "Run '$0 sources' first to grab the kernel, U-Boot and Open MPI sources."
			exit
		fi
	fi
}



case "$1" in
	'prebuilt' )
		echo "Copying pre-built outputs to images folder..."
		mkdir -p images
		cp -rf prebuilt/* images
	;;

	'sources' )
		echo "Checking out sources..."
		git clone --branch $KERNEL_TAG --depth 1 https://github.com/Xilinx/linux-xlnx.git
		git clone --branch $UBOOT_TAG --depth 1 https://github.com/Xilinx/u-boot-xlnx.git
		wget -O ompi.tar.bz2 $OMPI_URL
		tar -xf ompi.tar.bz2
		rm -f ompi.tar.bz2
		mv openmpi-${OMPI_VERSION} ompi
	;;

	'kernel' )
		check_sources
		mkdir -p images
		cd linux-xlnx
		compile_environment
		make xilinx_zynq_defconfig
		cat ../custom/kernel_config >> .config
		make uImage
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
		build_multistrap
		build_api
		copy_api
		copy_ompi

		echo "Building and installing kernel modules..."
		check_sources
		cd linux-xlnx
		compile_environment
		make modules
		sudo make ARCH=arm modules_install INSTALL_MOD_PATH=`pwd`/../rootfs/rootfs/
		cd ..
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
		echo "Setting up boot partition..."
		cp images/BOOT.bin $SDCARD_BOOT
		cp images/devicetree.dtb $SDCARD_BOOT
		cp images/uImage $SDCARD_BOOT
		cp arch/uEnv.txt $SDCARD_BOOT

		mkdir -p $SDCARD_BOOT/fpga/conf
		mkdir -p $SDCARD_BOOT/fpga/bitfile

		cp images/bitstream.bit $SDCARD_BOOT/fpga/bitfile
		cp images/phantom_fpga_conf.xml $SDCARD_BOOT/fpga/conf

		echo "Copying root file system (may ask for root)..."
		TARGETDIR=$SDCARD_ROOTFS
		sudo cp -a rootfs/rootfs/* $TARGETDIR
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
			sudo umount -lf rootfs/rootfs/dev
			sudo rm -rf rootfs/rootfs
			rm -rf linux-xlnx u-boot-xlnx ompi
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
