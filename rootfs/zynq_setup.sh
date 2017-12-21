#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run this script as root"
  exit
fi

#Directory contains the target rootfs
TARGET_ROOTFS_DIR="rootfs"

#Copy a QEMU ARM binary for us to use in the environment
cp /usr/bin/qemu-arm-static $TARGET_ROOTFS_DIR/usr/bin

#Mount dev in the chroot
mount -o bind /dev/ $TARGET_ROOTFS_DIR/dev/

#Board hostname
filename=$TARGET_ROOTFS_DIR/etc/hostname
echo phantomfpga > $filename

# Add PS UART to secure TTYs
filename=$TARGET_ROOTFS_DIR/etc/securetty
echo ttyPS0 >> $filename

#Default network interfaces
filename=$TARGET_ROOTFS_DIR/etc/network/interfaces
echo auto eth0 >> $filename

# Mount the boot partition
echo "/dev/mmcblk0p1 /boot vfat defaults 0 0" >> $TARGET_ROOTFS_DIR/etc/fstab

# dhcp
echo allow-hotplug eth0 >> $filename
echo iface eth0 inet dhcp >> $filename
#eth0 MAC address

# Make some files
touch $TARGET_ROOTFS_DIR/etc/fstab
touch $TARGET_ROOTFS_DIR/etc/rc.conf

# Configure the installed packages
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C
chroot $TARGET_ROOTFS_DIR /var/lib/dpkg/info/dash.preinst install
chroot $TARGET_ROOTFS_DIR dpkg --configure -a

# Fix some ownership issues
chroot $TARGET_ROOTFS_DIR chown root:root -R /bin /usr/bin /sbin /usr/sbin

# Set root password
echo "Changing password for the rootfs root user:"
chroot $TARGET_ROOTFS_DIR passwd root

umount -lf $TARGET_ROOTFS_DIR/dev/
