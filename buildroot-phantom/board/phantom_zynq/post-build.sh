#!/bin/sh

#
# Allow root login over SSH with password
#
SSHD_CONFIG=$1/etc/ssh/sshd_config
echo "" >> $SSHD_CONFIG
echo "# Enable root login over SSH" >> $SSHD_CONFIG
echo "PermitRootLogin yes" >> $SSHD_CONFIG
