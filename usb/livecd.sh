#!/bin/bash
# Author: Aditya Pramana (https://github.com/ojoakua-10bit)
# This script is intended to run on live CD or another linux installation

# Abort script if something went wrong
set -e

# Some needed variables
MOUNTPOINT="/mnt"
INFO="\033[36;1m"
WARNING="\033[33;1m"
ERROR="\033[31;1m"
RESET="\033[0m"
REPO_NAME="ojoakua-10bit/archlinux-install-helper"

# Make sure that the script is executed as superuser
if [ $UID -ne 0 ]; then
	echo ${ERROR}ERROR: Please run this script as root/superuser!${RESET}
	exit 1
fi

# Make sure that the partition is already made manually
cat << EOF
This Arch Install Helper is intended to be installed on USB storage.
Please set up the partition first before proceeding.
Read <link> for more information.

EOF

read -p "Are you sure to proceed? (y/N): " CONFIRM

if [ "$CONFIRM" -ne "y" -a "$CONFIRM" -ne "Y" ]; then
	echo -e ${WARNING}Setup cancelled by user. Exiting...${RESET}
	exit 1
fi

echo -e "Please enter the name of root partition (e.g sdb1):"
read ROOTPART

if [ -b /dev/"$ROOTPART" ]; then
	echo -e ${ERROR}Invalid partition name.${RESET}
	exit 1;
fi

echo -e "Please enter the custom root mountpoint (e.g /mnt/root, default /mnt):"
read _MOUNTPOINT

if [ -n "$_MOUNTPOINT" ]; then
	MOUNTPOINT=$_MOUNTPOINT
fi

echo -e "Please enter the name of EFI partition (e.g sdb1):"
read EFIPART

if [ -z "$EFIPART" ]; then
	echo -e ${ERROR}Invalid partition name.${RESET}
	exit 1
fi

echo -e "Please enter the name of partition for /boot (e.g sdb1, empty if not available):"
read BOOTPART

echo -e "Please enter the name of partition for /home (e.g sdb1, empty if not available):"
read HOMEPART

echo -e "Please enter the name of partition for /var (e.g sdb1, empty if not available):"
read VARPART

echo -e "${INFO}Mounting devices...${RESET}"
mount -v /dev/$ROOTPART $MOUNTPOINT
mkdir $MOUTPOINT/{efi,boot,home,var}
mount -v /dev/$EFIPART $MOUNTPOINT/efi

if [ -n "$BOOTPART" ] then
	mount -v /dev/$HOMEPART $MOUNTPOINT/boot
fi

if [ -n "$HOMEPART" ] then
	mount -v /dev/$HOMEPART $MOUNTPOINT/home
fi

if [ -n "$VARPART" ] then
	mount -v /dev/$VARPART $MOUNTPOINT/var
fi

echo -e ${INFO}Configuring mirrors...${RESET}
pacman -S reflector --noconfirm
reflector --latest 50 --protocol http --protocol https --sort rate --save /etc/pacman.d/mirrorlist

echo -e ${INFO}Bootstrapping base install...${RESET}
pacstrap $MOUNTPOINT base base-devel grub2 git zsh neovim wget networkmanager intel-ucode amd-ucode

echo -e ${INFO}Generating /etc/fstab...${RESET}
genfstab -U $MOUNTPOINT >> $MOUNTPOINT/etc/fstab
# We don't need swap here...
grep -Fv 'swap' /etc/fstab > tmp && mv tmp /etc/fstab

echo -e ${INFO}Preparing chroot...${RESET}
curl -sSL https://raw.githubusercontent.com/$REPO_NAME/master/usb/chroot.sh -O $MOUNTPOINT/.chroot-install

echo -e ${INFO}Entering chroot...${RESET}
arch-chroot $MOUNTPOINT sh -c /.chroot-install

