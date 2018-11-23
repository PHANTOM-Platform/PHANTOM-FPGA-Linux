#!/bin/bash
#
# This is the main build script for the PHANTOM FPGA Linux platform.
#
# Before running, ensure that the $TARGET environment variable is set to a
# target board (as listed in boardsupport.sh)
#
# Also, if your SD card partitions are mounted at non-standard locations set
# $SDCARD_BOOT and $SDCARD_ROOTFS
# Set up the SD card with two partitions:
#   The first, called BOOT, a small FAT32 partition of 30MB
#   The rest, called Linux, as ext4
# An Ubuntu-based system will automount such a card at the default locations below:
if [[ -z "${SDCARD_BOOT}" ]]; then
	SDCARD_BOOT=/media/$USER/BOOT/
fi
if [[ -z "${SDCARD_ROOTFS}" ]]; then
	SDCARD_ROOTFS=/media/$USER/Linux/
fi


# boadsupport.sh sets variables based on the target board
if [[ -z "${TARGET}" ]]; then
	echo "The environment variable TARGET is not set."
	echo "Set it to the desired target board, as listed in boardsupport.sh"
	exit 1
fi
. ./boardsupport.sh $TARGET




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
	make ARCH=arm $DEVICETREE
	cp arch/arm/boot/dts/$DEVICETREE ../images/devicetree.dtb
	cd ..
	cd arch
	dtc -I dts -O dtb -W no-unit_address_vs_reg -o ../images/phantom_uio_devices.dtbo phantom_uio_devices_overlay.dts
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

function fetch_sources {
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

	if [ "$ROOTFS" == "buildroot" ] && [ ! -d "buildroot" ]; then
		echo "Fetching Buildroot (${BUILDROOT_VERSION})..."
		wget -O buildroot.tar.bz2 $BUILDROOT_URL
		tar -xf buildroot.tar.bz2
		rm -f buildroot.tar.bz2
		mv buildroot-${BUILDROOT_VERSION} buildroot
	fi

	echo "Done."
}

function create_rootfs {
	if [ "$ROOTFS" == "multistrap" ]; then
			build_multistrap
			build_api
			copy_api
			copy_ompi
			echo "Installing kernel modules..."
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
}

function create_sdcard {
	echo "Setting up boot partition..."
		cp images/BOOT.bin $SDCARD_BOOT
		cp images/devicetree.dtb $SDCARD_BOOT
		cp images/phantom_uio_devices.dtbo $SDCARD_BOOT
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
}



case "$1" in
	'prebuilt' )
		echo "Copying pre-built outputs to images folder..."
		mkdir -p images
		cp -rf prebuilt/* images
	;;

	'sources' )
		fetch_sources
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
		cat ../arch/u-boot_config >> .config
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
		check_sources
		create_rootfs
	;;

	'api' )
		build_api
		copy_api
	;;

	'hwproject' )
		cd arch
		vivado -mode batch -source build_project.tcl -quiet -notrace -tclargs hwproj `(cd ..; pwd)` $BOARD_PART ${@:2}
	;;

	'hwxml' )
		xml=`realpath $2`
		echo "Building Vivado project from deployment $2..."
		cd arch
		python3 archbuild.py `pwd`/../hwproj $xml $BOARD_PART
	;;

	'sdcard' )
		check_rootfs_valid
		create_sdcard
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
		compile_environment
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

	'all' )
		check_rootfs_valid
		mkdir -p images
		mkdir -p fsbl
		# sources
		fetch_sources
		check_sources
		# hwproj
		cd arch
		vivado -mode batch -source build_project.tcl -quiet -notrace -tclargs hwproj `(cd ..; pwd)` $BOARD_PART ${@:2}
		# implement
		vivado -mode batch -source implement_project.tcl -notrace
		cp ../hwproj/hwproj.runs/impl_1/design_1_wrapper.bit ../images/bitstream.bit
		cp ../hwproj/phantom_fpga_conf.xml ../images/phantom_fpga_conf.xml
		# fsbl
		hsi -nojournal -nolog -source generate_fsbl.tcl
		cp ../fsbl/executable.elf ../images/fsbl.elf
		# uboot
		cd ../u-boot-xlnx
		compile_environment
		make ${UBOOT_TARGET}_defconfig
		cat ../arch/u-boot_config >> .config
		make
		cp u-boot ../images/u-boot.elf
		# bootimage
		cd ../arch
		bootgen -image bootimage.bif -arch zynq -w -o i ../images/BOOT.bin
		# kernel
		cd ../linux-xlnx
		make xilinx_zynq_defconfig
		cat ../custom/kernel_config >> .config
		make uImage modules
		cp arch/arm/boot/uImage ../images/
		make $DEVICETREE
		cp arch/arm/boot/dts/$DEVICETREE ../images/devicetree.dtb
		# ompi
		cd ..
		build_ompi
		# rootfs
		create_rootfs
		# sdcard
		read -r -p "Copy to mounted SD card now? [y/N] " response
		if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
		then
			create_sdcard
		fi
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
		echo "Usage: $0 [prebuilt|sources|kernel|uboot|ompi|rootfs|api|hwproject|sdcard|devicetree|implement|fsbl|bootimage|clean|hwxml|all]"
	;;

esac
