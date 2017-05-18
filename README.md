# PHANTOM Linux Software Distribution

The PHANTOM Linux software distribution contains prebuilt binaries for the ZC706 board, but also full instructions to create images for other Xilinx-supported boards.

If you are using the ZC706, you only need set up an SD card, copy over the images, and build a root file system. 


### Building the Root Filesystem

The Linux rootfs is built using [multistrap](https://wiki.debian.org/Multistrap) and QEMU which you should install first.

	sudo apt-get install multistrap dpkg-dev qemu-user-static

Run multistrap, and then execute the PHANTOM setup script as follows:

	./make.sh rootfs

The script will ask for root permissions after downloading the packages to allow it to chroot into the new filesystem. It will also ask you to change the root password of the new root filesystem.


### Set up an SD card

Now we can create an SD card to contain the compiled boot image and root filesystem. Format an SD card with two partitions. 

 * The first, a small FAT32 partition. This is just to hold the boot image so around 10MB is plenty of space.
 * The rest of the card as a Linux filesystem, ext4 is a good choice.

Ensure that the target board is set to boot from the SD card. This usually involves setting jumpers to select the boot target. Consult the manual for your board.

Copy `images/BOOT.bin` to the small FAT32 partition. 

Copy the entire contents of the `rootfs/rootfs` folder to the ext4 partition of the SD card. For example, if it is mounted at `/media/youruser/rootfs`:

	cp -r rootfs/rootfs/* /media/youruser/rootfs


## Building for other boards

To rebuild the images, the first task is to edit options at the top of `make.sh` to ensure that everything is ready for your target board. The `DEVICETREE` and `UBOOT_TARGET` variables are currently set for the ZC706 board. 

`DEVICETREE` should be the name of the device tree in the Linux kernel tree to use. Xilinx provides these for all of its boards in the `/arch/arm/boot/dts/` and `/arch/arm64/boot/dts/` folders.

`UBOOT_TARGET` should be the target board to build u-boot for. The available configurations are in the `u-boot-xlnx/configs` directory.

Grab the sources and build them with the following:

	./make.sh sources
	./make.sh uboot
	./make.sh kernel


### Get an FSBL

An FSBL (first stage bootloader) is required to start the boot process. The `images` folder contains a prebuilt FSBL for the ZC706. For other boards you should use Xilinx SDK to create and compile an FSBL. Consult the Xilinx documentation for this.


### Create a boot image

We now need to combine the FSBL, u-boot, and the kernel, all into a single image. Again this is done using Xilinx SDK. 

In the SDK menus, select Xilinx Tools -> Create Boot Image.

Select Create new BIF file, and set the output paths to where you want the image to be built. Now in the boot image partitions click add, select `images/fsbl.elf` and ensure Partition type is set to `bootloader`. Click OK.

Then add `images/u-boot.elf`, `images/uImage`, and `images/devicetree.dtb` as a `datafile` partitions. Click create image.

