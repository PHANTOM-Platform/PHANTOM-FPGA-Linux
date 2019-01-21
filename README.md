
# PHANTOM FPGA Linux Software Distribution

The PHANTOM Linux software distribution contains scripts to build a full Linux environment for Zynq-7000 SoCs based on a platform definition.

The built platform includes:
* Linux kernel
* Linux root file system (either BusyBox or Debian/Ubuntu)
* Bootloaders (Zynq FSBL and U-Boot)
* Zynq boot image
* FPGA bitstream
* Customised Linux device tree
* PHANTOM communications API (including Open MPI)
* PHANTOM component definition XML file

Prebuilt images are provided for the [Xilinx ZC706 board](https://www.xilinx.com/products/boards-and-kits/ek-z7-zc706-g.html), which just require copying to an SD card in order to boot the system.


## Installation

To begin, clone the repository:

    git clone https://github.com/PHANTOM-Platform/PHANTOM-FPGA-Linux.git

### Prerequisites

Before running the build script you will need:
 * [Multistrap](https://wiki.debian.org/Multistrap) (if using the Debian-based file system)
 * [The Device Tree Compiler](https://git.kernel.org/pub/scm/utils/dtc/dtc.git) (dtc)
 * [mkimage](https://linux.die.net/man/1/mkimage)
 * libssl
 * QEMU
 * Python 3
 * [Xilinx Vivado tools](https://www.xilinx.com/support/download.html) with Zynq-7000 support (tested with version 2018.2)

On Debian or Ubuntu-based distributions you can install these with the following command:

	sudo apt-get install multistrap device-tree-compiler u-boot-tools libssl-dev dpkg-dev qemu-user-static python3

To install the Xilinx tools, consult the documentation that comes with Vivado. The tools must be imported into the current environment, so that the `vivado`, `hsi` and `bootgen` commands are runnable from the command line.


## Quick start with prebuilt images

The [`prebuilt`](prebuilt) folder contains a ready-built set of images that can be used to boot a [Xilinx ZC706 board](https://www.xilinx.com/products/boards-and-kits/ek-z7-zc706-g.html), including a default set of dummy components on the FPGA logic and in the Linux device tree, and a BusyBox-based root file system.

To create a system with these images, first, copy the included prebuilt kernel, file system, bitstream and boot images to be used on the board:

	./make.sh prebuilt

Next, format an SD card with a FAT32 file system of at least 30MB, and ensure it is mounted at `/media/$USER/BOOT`.

To copy the images to the SD card, run:

	./make.sh sdcard

Insert this SD card into the ZC706 board, set the boot select switches (SW11) to 0-0-1-1-0 for SD boot, and turn on the board with a console connected to the USB UART at 115200 bps. Once booted, login with user "root" and password "phantom". The FPGA components should be accessible at `/dev/phantom/`.


## Quick start with custom configuration

Before using the build scripts, you must create a configuration describing which FPGA board to target, which root file system type to use, and which FPGA components to include in the design.

These options are set in the [`phantom_fpga_config.json`](phantom_fpga_config.json) file, with the following format:

```json
{
	"target": {
		"board": "board_name",
		"rootfs": "rootfstype"
	},
	"ipcores": [
		{
			"ipname": "vendorname:libraryname:ipcore:1.0",
			"memory": 4096
		}
	]
}
```

* `target` describes the deployment target of the design being generated, as follows:
	* `board` should be set to the target board type, as defined in [`boardsupport.sh`](boardsupport.sh) (e.g. `zc706`, `zybo`, `zedboard`)
	* `rootfs` should be set to the desired root file system type, either `buildroot` or `multistrap`
* `ipcores` should contain a list of the IP cores to include in the design, along with their shared memory requirements, as follows:
	* `ipname` is the name of a PHANTOM IP core available in [`arch/phantom_ip/`](arch/phantom_ip/), as recognised by Vivado (the standard format of this field in Vivado is `vendor:library:name:version`)
	* `memory` is the amount of shared memory (in bytes) to reserve for access by the IP core's master interface and associated Linux driver. The build scripts will round this number to the next power of two, and at least 4KiB. A value of `0` means no shared memory will be available.

### Building the hardware project

Ensure your PHANTOM-compatible IP cores (see later) are in [`arch/phantom_ip/`](arch/phantom_ip/) and run the following:

	./make.sh hwproject
	./make.sh implement

### Multistrap (Debian-based) root file system

If using the Debian-based root file system, set `rootfs` to `multistrap` in [`phantom_fpga_config.json`](phantom_fpga_config.json) and generate with:

	./make.sh rootfs

The script will ask for root permissions after downloading packages, to allow it to chroot into the new file system to complete package set-up and set the root password (the user will be prompted for this).

If Linux kernel modules or Open MPI libraries are required in the file system, these must be built beforehand so they can be copied in. Therefore, for a complete file system, run the following:

	./make.sh sources
	./make.sh kernel
	./make.sh ompi
	./make.sh rootfs

_Note: if you get unusual errors whilst compiling, (such as that the compiler is not C and C++ link compatible) ensure that you have sourced Xilinx's setup scripts and that you are therefore compiling using their toolchain._

### Set up an SD card (or alternative storage device)

If using the BusyBox-based root file system, the images can be copied directly to flash memory (using a third-party tool), or to a single FAT partition on an SD card, using the instructions below.

If using the Debian-based file system, an SD card (or similar storage) is required to hold the boot images and root file system on separate partitions.

Format an SD card with two partitions:

 * The first, a small FAT32 partition called `BOOT`. This is just to hold the bootloaders, kernel, and FPGA bitstream, so 30MB is typically plenty of space.
 * The rest of the card as an ext4 partition called `Linux`.

Ensure that the SD card partitions are mounted and that the `SDCARD_BOOT` and `SDCARD_ROOTFS` variables at the top of `make.sh` are correctly set.

Finally copy all boot files and the root file system to the SD card, using:

	./make.sh sdcard

The FPGA board can now be programmed and booted to Linux using this SD card.


## PHANTOM-compatible IP Cores

The architecture scripts build an FPGA design from a set of PHANTOM-compatible IP cores in [`arch/phantom_ip/`](arch/phantom_ip/). A PHANTOM-compatible IP core has the following characteristics:

 * Exactly one AXI Slave interface, which is used to control the core via UIO-mapped registers.
 * Zero or more AXI Master interfaces which are used for high-speed access to main memory.
 * An optional interrupt line for triggering interrupt handlers in Linux userland (not currently implemented).

The IP core should also be an IP core as generated by the Xilinx tools (such as from Vivado HLS or packaged by Vivado).


## Building images from sources

### Setting-up board support and build variables

To build the images, the first task is to ensure the target board is defined in [`boardsupport.sh`](boardsupport.sh), along with appropriate build variables.

To support a non-default board, the following variables should be used in [`boardsupport.sh`](boardsupport.sh), copying the format of existing entries:
* `DEVICETREE` should be the name of the device tree in the Linux kernel tree to use. Xilinx provides these for all of its boards in the [`arch/arm/boot/dts/`](https://github.com/Xilinx/linux-xlnx/tree/master/arch/arm/boot/dts) folder of the [kernel source](https://github.com/Xilinx/linux-xlnx).
* `UBOOT_TARGET` should be the target board to build U-Boot for. The available configurations are in the [`configs`](https://github.com/Xilinx/u-boot-xlnx/tree/master/configs) directory of the [U-Boot source](https://github.com/Xilinx/u-boot-xlnx).
* `BOARD_PART` should be the Xilinx name for the target board. You can list all of the board parts that your Xilinx installation supports by entering the command `get_board_parts` into the TCL console of Vivado.

The `VIVADO_VERSION`, `OMPI_VERSION` and `BUILDROOT_VERSION` variables can be customised to match the desired source versions to download and build. In particular, `VIVADO_VERSION` should be set to match the version of Vivado used to build the hardware. The default Vivado version is `2018.2`.

If any extra customisation is needed to the Linux kernel build, configuration parameters can be added to the [`custom/kernel_config`](custom/kernel_config) file, whose contents will be appended to the default config (`xilinx_zynq_defconfig`) before the kernel is built.

The board type to use when building the system should then be set in [`phantom_fpga_config.json`](phantom_fpga_config.json) (see above).

### Building U-Boot and the Linux kernel

Once the board is defined, the Linux kernel and U-Boot sources can be downloaded and built with the following:

	./make.sh sources
	./make.sh uboot
	./make.sh kernel

These commands also copy the built products to the `images/` folder. The U-Boot runtime environment is generated separately based on the specific FPGA hardware design, and can be found in `images/uEnv.txt` after the hardware project is created.

### Creating an FPGA hardware design

The PHANTOM distribution also contains the scripts that create PHANTOM-compatible FPGA designs. A PHANTOM hardware design encapsulates a set of IP cores, makes them available to the software running in the Linux distribution, and includes the various security and monitoring requirements of the PHANTOM platform.

To build a hardware project, first check ensure that the IP cores you are using are in the [`arch/phantom_ip/`](arch/phantom_ip/) directory. This directory already contains two dummy IP cores, which can be used for testing.

Next, edit [`phantom_fpga_config.json`](phantom_fpga_config.json) to describe the specific hardware design requirements, including FPGA board type, the IP cores to include, and the shared memory requirements of those IP cores (see above for a description of the file structure).

Once set, execute the following to create the hardware project and then perform Vivado implementation on the design to produce a bitstream:

	./make.sh hwproject
	./make.sh implement

The resulting hardware project will be created in the `hwproj/` directory. Alongside the hardware project itself, the scripts will generate a matching PHANTOM component definition XML file, Linux device tree overlay describing the hardware, and a compatible U-Boot environment definition, all output to `images/`.

### Device tree generation

You must have a suitable device tree for U-Boot and the Linux kernel to work on your target board. Xilinx's [Linux kernel repository](https://github.com/Xilinx/linux-xlnx) contains device trees for many boards in the [`arch/arm/boot/dts/`](https://github.com/Xilinx/linux-xlnx/tree/master/arch/arm/boot/dts) folder. These all reference a base tree called `zynq-7000.dtsi` which describes the generic Zynq SoC architecture. If your target board requires a custom device tree, ensure it is copied into the kernel and U-Boot source tree and matches the associated definitions in [`boardsupport.sh`](boardsupport.sh).

In order to leave the board's Linux kernel device tree untouched, PHANTOM components are described in a device tree _overlay_, which is dynamically applied to the base device tree on each boot by U-Boot. The build scripts create this device tree overlay based on the PHANTOM component definition XML output from the hardware project creation. See [`arch/generate_environment.py`](arch/generate_environment.py) for how this overlay is generated.

The base device tree and device tree overlay are generated when building the kernel and hardware project respectively, but if required they can be built separately using:

	./make.sh devicetree

### Generating an FSBL

An FSBL (first stage bootloader) is required to start the boot process, and sets up various components of the Zynq-7000 device.

You can generate an FSBL based on the current hardware design and board type, using:

	./make.sh fsbl

This will create `images/fsbl.elf`. Alternatively, an FSBL can be created using Xilinx SDK.


### Creating a boot image

The FSBL and U-Boot must be combined into a single boot image in order to boot a board from an SD card.

After the FSBL and U-Boot executables are generated, of if they change, the boot image can be created using:

	./make.sh bootimage

This will create `images/BOOT.bin`. Alternatively, a boot image can be created using Xilinx SDK.


### Building Open MPI

[Open MPI](https://www.open-mpi.org) can be downloaded and built for Linux on the Zynq using the build scripts, and will be installed to `/opt` on the created root file system by default.

Set the `OMPI_VERSION` variable in [`boardsupport.sh`](boardsupport.sh) as required (the default is to use v3.0.0). If needed, the download URL can also be customised by changing `OMPI_URL`.

Open MPI can then be built and installed with the following:

	./make.sh sources
	./make.sh ompi

Open MPI must be built _before_ creating the root filesystem, if it is to be included.

### Creating a root file system

The make script can create either a [Debian](https://www.debian.org)-based root file system using [Multistrap](https://wiki.debian.org/Multistrap), or a [BusyBox](https://busybox.net)-based root file system using [Buildroot](https://buildroot.org). The Debian file system is designed to be mounted as the system's main persistent storage (e.g. from an SD card), whereas the BusyBox system is better suited to running as an ephemeral RAM disk.

The file system can be generated by setting the `rootfs` type in [`phantom_fpga_config.json`](phantom_fpga_config.json) to either `multistrap` or `buildroot`, then running:

	./make.sh sources # (if using Buildroot)
	./make.sh rootfs

If the appropriate sources have been downloaded and built beforehand, this will also copy Open MPI, Linux kernel modules and the PHANTOM API libraries into the file system.

Alternative Linux file systems can be used, but are not supported by these scripts.

#### Buildroot file system customisation

The Buildroot-generated file system can be modified using the configuration file, post-build script and file system overlay in the [`buildroot-phantom`](buildroot-phantom) folder.

More information is available in the [Buildroot manual](https://buildroot.org/downloads/manual/manual.html).

#### Multistrap file system customisation

The basic contents of the file system can be customised by editing [`multistrap/multistrap.conf`](multistrap/multistrap.conf) before building. This file defines the packages included, as well as the Debian version to use (both Debian 8 (Jessie) and 9 (Stretch) should work). The default configuration uses Debian 9 (Stretch), and includes a selection of useful packages for a fairly full-featured system.

As an alternative to Debian, an optional Ubuntu 18.04 LTS (Bionic Beaver) configuration is also included, in [`multistrap/multistrap-ubuntu.conf`](multistrap/multistrap-ubuntu.conf). To use this, replace [`multistrap/multistrap.conf`](multistrap/multistrap.conf) with this file.

The [`multistrap/rootfs_setup.sh`](multistrap/rootfs_setup.sh) script is run to set-up the Multistrap system after packages have been downloaded. This file can be modified to customise this process.

Additional files can be added to the root file system automatically by the make script by placing them in the [`multistrap/overlay/`](multistrap/overlay/) folder.

#### File system size

The Debian root file system created by the scripts is designed to be copied to an SD card and mounted as the system's main storage, so can be quite large.

The following are estimated sizes for the built file system, where 'complete' is the full default included `multistrap.conf` and 'minimal' is only the base Debian packages required for booting:

* Jessie (complete) - 388MB
* Jessie (minimal) - 186MB
* Stretch (complete) - 395MB
* Stretch (minimal) - 169MB

This includes around 13MB for Open MPI, kernel modules and the PHANTOM API on top of the Debian system.

The compressed image of the BusyBox file system is around 10MB by default (with Open MPI, kernel modules and PHANTOM API included).


## Support files for additional boards, etc.

The [`support/`](support/) folder contains a range of additional files that can be installed for working with non-standard boards, as well as potentially useful kernel patches and optional configuration options.

See [`support/README.md`](support/README.md) for more information.


## Running a full build from sources

The following series of make script commands will run a typical full build and install of all components from sources.
This is equivalent to `./make.sh all`.

The contents of [`phantom_fpga_config.json`](phantom_fpga_config.json) should be set before starting the build process, and the SD card partitioned and mounted ready for use.

If any Linux kernel, U-Boot or Buildroot customisations are required (patches, overlays, etc.), these should be applied after fetching sources but before building these components.

	./make.sh sources
	./make.sh hwproject
	./make.sh implement
	./make.sh fsbl
	./make.sh uboot
	./make.sh bootimage
	./make.sh kernel
	./make.sh ompi
	./make.sh rootfs
	./make.sh sdcard
