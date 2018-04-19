#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run this script as root"
  exit
fi

# Directory contains the target rootfs
TARGET_ROOTFS_DIR="rootfs"

# Copy a QEMU ARM binary for us to use in the environment
cp /usr/bin/qemu-arm-static $TARGET_ROOTFS_DIR/usr/bin

# Mount dev in the chroot
mount -o bind /dev/ $TARGET_ROOTFS_DIR/dev/

# Make some required files
touch $TARGET_ROOTFS_DIR/etc/fstab
touch $TARGET_ROOTFS_DIR/etc/rc.conf

# Set the board hostname
filename=$TARGET_ROOTFS_DIR/etc/hostname
echo phantomfpga > $filename

# Add Zynq PS UART to secure TTYs
filename=$TARGET_ROOTFS_DIR/etc/securetty
echo ttyPS0 >> $filename

# Add eth0 as a network interface, and use DHCP
# (if needed, set the eth0 MAC address here too)
filename=$TARGET_ROOTFS_DIR/etc/network/interfaces
echo auto eth0 >> $filename
echo allow-hotplug eth0 >> $filename
echo iface eth0 inet dhcp >> $filename

# Mount the SD card FAT partition to /boot
filename=$TARGET_ROOTFS_DIR/etc/fstab
echo "/dev/mmcblk0p1 /boot vfat defaults 0 0" >> $filename

# Configure the installed Debian packages
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C
chroot $TARGET_ROOTFS_DIR /var/lib/dpkg/info/dash.preinst install
chroot $TARGET_ROOTFS_DIR dpkg --configure -a

# Fix some ownership issues
chroot $TARGET_ROOTFS_DIR chown root:root -R /bin /usr/bin /sbin /usr/sbin

for i in `seq 0 31`;
do
  echo Creating user \'phantom$i\'
  chroot $TARGET_ROOTFS_DIR adduser --quiet --disabled-login --shell /bin/false --gecos "" phantom$i
done

# Set root password (loop until set correctly)
echo "******************************************"
echo "Enter password for the new root user:"
until chroot $TARGET_ROOTFS_DIR passwd root
do
  echo "Error setting password, try again..."
  sleep 1
done

# Unmount the temporary /dev
umount -lf $TARGET_ROOTFS_DIR/dev/

# Remove the QEMU binary that we copied in earlier
rm -f $TARGET_ROOTFS_DIR/usr/bin/qemu-arm-static
