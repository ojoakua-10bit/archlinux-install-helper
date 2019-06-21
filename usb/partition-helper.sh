#!/bin/bash
# Author: Aditya Pramana (https://github.com/ojoakua-10bit)
# This script is intended to run on Live CD or existing linux installation

# Abort script if something went wrong
set -e

# Some needed variables
INFO="\033[36;1m"
WARNING="\033[33;1m"
ERROR="\033[31;1m"
BOLD="\033[1m"
RESET="\033[0m"

# Make sure that the script is executed as superuser
if [ $UID -ne 0 ]; then
	echo ${ERROR}ERROR: Please run this script as root/superuser!${RESET}
	exit 1
fi

read -p "Please enter the name of your USB device (e.g sdb)" USBPART

if [ ! -b "/dev/$USBPART" ]; then
	echo -e ${ERROR}Invalid partition name.${RESET}
	exit 1;
fi

cat << EOF
${WARNING}WARNING${RESET}: This process will ${BOLD}wipe${RESET} all of your data on your USB device.
Make sure you've entered the correct device name of your USB.
We will create a partition for BIOS, a partition for EFI and a partition for rootfs.
${BOLD}Target device${RESET}: /dev/${USBPART}
EOF

read -p "Are you sure to continue? (y/N): " PROMPT

if [ "$CONFIRM" -ne "y" -a "$CONFIRM" -ne "Y" ]; then
	echo -e ${WARNING}Setup cancelled by user. Exiting...${RESET}
	exit 1
fi

echo -e ${INFO}Setting up hybrid MBR paartition table...${RESET}

cat << EOF | gdisk /dev/${USBPART}
o
y
n


+1M
EF02
n


+50M
EF00
n




w
y
EOF

cat << EOF | gdisk /dev/${USBPART}
r
h
1 2 3
n
EF02
n
EF00
n

y
w
y
EOF

echo -e ${INFO}Formatting partition...${RESET}

mkfs.fat -F16 /dev/${USBPART}2
mkfs.ext4 /dev/${USBPART}3

echo "Done..."

