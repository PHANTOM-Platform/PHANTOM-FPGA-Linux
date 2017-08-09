# PHANTOM Linux Software Distribution

The PHANTOM Linux software distribution contains prebuilt binaries for the ZC706 board, but also full instructions to create images for other Xilinx-supported boards.

If you are using the ZC706, you only need set up an SD card, copy over the images, and build a root file system.

Note that many of these commands require that the Xilinx tools are in your `$PATH` so ensure that they are correctly installed.

## Required packages

Before running the build script you will need:
 * [multistrap](https://wiki.debian.org/Multistrap) and associated ARM compilers
 * [The Device Tree Compiler](https://git.kernel.org/pub/scm/utils/dtc/dtc.git)
 * [mkimage](https://linux.die.net/man/1/mkimage)
 * libssl
 * QEmu

On Debian or Ubuntu-based distributions you can simply do the following:

	sudo apt-get install multistrap device-tree-compiler u-boot-tools libssl-dev dpkg-dev qemu-user-static

## Quick Start

If you are using the ZC706 and so are happy to use the pre-built kernel, you can simply do the following:

	./make.sh rootfs

The script will ask for root permissions after downloading the packages to allow it to chroot into the new filesystem in order to change the root password.

Now ensure your PHANTOM-compatible IP cores are in `arch/phantom_ip` and run the following, where `ipcore1` and `ipcore2` are IP cores to build into the project:

	./make hwproject ipcore1 ipcore2
	./make implement

Now create an SD card for the board.

### Set up an SD card

Now we can create an SD card to contain the compiled boot image and root filesystem. Format an SD card with two partitions.

 * The first, a small FAT32 partition called `BOOT`. This is just to hold the bootloader, kernel, and a bitstream, so 30MB is plenty of space.
 * The rest of the card as an ext4 partition called `Linux`.

Ensure that the SD card partitions are mounted and that the `SDCARD_BOOT` and `SDCARD_ROOTFS` variables at the top of `make.sh` are correctly set. Now copy all the files to the SD card:

	./make sdcard

You are now ready to go!


## Building for other boards

To rebuild the images, the first task is to edit options at the top of `make.sh` to ensure that everything is ready for your target board. The `DEVICETREE`, `UBOOT_TARGET`, and `BOARD_PART` variables are currently set for the ZC706 board.

`DEVICETREE` should be the name of the device tree in the Linux kernel tree to use. Xilinx provides these for all of its boards in the `/arch/arm/boot/dts/` and `/arch/arm64/boot/dts/` folders.

`UBOOT_TARGET` should be the target board to build u-boot for. The available configurations are in the `u-boot-xlnx/configs` directory.

`BOARD_PART` should be the Xilinx name for the target board. You can list all of the board parts that your Xilinx installation supports by entering the command `get_board_parts` into the TCL console of Vivado.

There are examples in `make.sh` itself of what these variables should be set to for other common boards.

Once set, grab the kernel and uBoot sources and build them with the following:

	./make.sh sources
	./make.sh uboot
	./make.sh kernel


### Get an FSBL

An FSBL (first stage bootloader) is required to start the boot process. The `images` folder contains a prebuilt FSBL for the ZC706. For other boards you should use Xilinx SDK to create and compile an FSBL. Using SDK, create a New Application Project using the 'Zynq FSBL' template. [Consult the Xilinx documentation](http://www.wiki.xilinx.com/Build+FSBL) for how to do this. Use SDK to compile the FSBL project to an ELF file.


### Create a boot image

We now need to combine the FSBL, uBoot, and the kernel, all into a single image. Again this is done using Xilinx SDK. In the SDK menus, select `Xilinx Tools -> Create Boot Image`.

Select `Create new BIF file`, and set the output paths to where you want the image to be built. Now in the boot image partitions click add, select `images/fsbl.elf` and ensure Partition type is set to `bootloader`. Click OK.

Then add `images/u-boot.elf`, `images/uImage`, and `images/devicetree.dtb` as `datafile` partitions. Click `create image`. This will create `BOOT.bin` which you should place in the `images` directory.


## Creating an FPGA hardware design

The PHANTOM distribution also contains the scripts which create PHANTOM-compatible FPGA designs. A PHANTOM hardware design encapsulates a set of IP cores, makes them available to the software running in the Linux distribution, and includes the various security and monitoring requirements of the PHANTOM platform.

To build a hardware project, first check ensure that the IP cores you are using are in the `arch/phantom_ip` directory. This directory already contains two dummy IP cores which can be used for testing. Ensure that the `BOARD_PART` option at the top of `make.sh` is set for your target board. `BOARD_PART` is the Xilinx part name for the development board being used. For the ZC706 this is `xilinx.com:zc706:part0:1.3`. You can list all of the board parts that your Xilinx installation supports by entering the command `get_board_parts` into the TCL console of Vivado.

Once set, execute the following:

	./make.sh hwproject ipcore1 ipcore2

where `ipcore1` and `ipcore2` are the PHANTOM IP cores to add to this project. This will create a Vivado project at `/hwproject` which you can build using Vivado as normal, or implement from the command line with:

	./make.sh implement


## Note on Device Trees

You must have a suitable device tree for the kernel to work on your target board. Xilinx's repository contains device trees for many boards in the `/arch/arm/boot/dts/` and `/arch/arm64/boot/dts/` folders. These all include a base tree called `zynq-7000.dtsi` which describes the generic Zynq SoC architecture. This project includes a customised `zynq-7000.dtsi`, the only difference being that the customised version includes the file `arch/phantom_uio_devices.dtsi` to inform the kernel about the PHANTOM architecture infrastructure. This is all handled by `./make.sh`.

If your target board requires an entirely custom device tree that is not included in the Xilinx repository, ensure that it includes the line:

 	#include "phantom_uio_devices.dtsi"

Then compile your device tree to a `.dtb` file called `images/devicetree.dtb` before running `./make.sh sdcard`.
