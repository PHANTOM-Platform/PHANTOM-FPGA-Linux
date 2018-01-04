# Supporting files for Linux/U-Boot/Vivado builds

This folder contains various supporting file for building PHANTOM FPGA projects, including patches, device trees, configs, and non-standard board support files.


## Linux kernel

The [`linux/`](linux/) folder contains files for the Linux kernel build.

### Device trees

The [`linux/dts/`](linux/dts/) folder contains device tree files (and associated Makefile) for additional boards.

To use these files, copy them to `linux-xlnx/arch/arm/boot/dts/` after fetching kernel sources, but before building the kernel/device tree.

Currently supported boards are:
* [MYIR Z-turn board](http://www.myirtech.com/list.asp?id=502) - `zynq-zturn.dts`

### Configuration options

The [`linux/config/`](linux/config/) folder contains additional kernel configuration parameters for certain hardware.

To use these, copy the required lines from these files to the end of `custom/kernel_config` before building the kernel.

Current files are:
* Required drivers for USB Ethernet to an [Intel Edison](https://software.intel.com/en-us/connecting-to-intel-edison-board-using-ethernet-over-usb) board - `edison_ethernet`

### Patches

The [`linux/patches/`](linux/patches/) folder contains patches to kernel code that are not included in the Xilinx repository.

To use these files, copy them to `linux-xlnx/` after fetching kernel sources, and apply manually using a standard `patch` tool.

Currently included patches are:
* [Fix for issue with Zynq memory regions](https://forums.xilinx.com/t5/Embedded-Linux/Problem-w-USB-mass-storage-on-ZC702-using-linux-xlnx-4-9/td-p/748865) (not needed for 2017.3 and later) - `0001-zynq-kernel-mempry-reserve-issue.patch`


## U-Boot

The [`u-boot/`](u-boot/) folder contains files for the U-Boot build.

### Configs

The [`u-boot/configs/`](u-boot/configs/) folder contains configuration files for additional boards.

To use these files, copy them to `u-boot-xlnx/configs/` after fetching U-Boot sources, but before building.
Any referenced device tree files must also be copied (see below).

Currently supported boards are:
* [MYIR Z-turn board](http://www.myirtech.com/list.asp?id=502) - `zynq_zturn_defconfig`

### Device trees

The [`u-boot/dts/`](u-boot/dts/) folder contains device tree files (and associated Makefile) for additional boards.

To use these files, copy them to `u-boot-xlnx/arch/arm/dts/` after fetching U-Boot sources, but before building.

Currently supported boards are:
* [MYIR Z-turn board](http://www.myirtech.com/list.asp?id=502) - `zynq-zturn.dts`


## Vivado board files

The [`board_files/`](board_files/) folder contains board definitions for Vivado hardware/FSBL builds.

To use these files, copy each board folder to `<vivado_install_dir>/data/boards/board_files/`, where `<vivado_install_dir>` is the location on the system that Vivado is installed to.
This will need to be repeated for all Vivado versions used.

Currently supported boards are:
* [MYIR Z-turn board (Z-7020 version)](http://www.myirtech.com/list.asp?id=502) - `z-turn_7020` (`myirtech.com:z-turn_7020:part0:1.0`)
