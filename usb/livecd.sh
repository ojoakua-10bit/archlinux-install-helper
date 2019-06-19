#!/bin/sh
# Author : Aditya Pramana (https://github.com/ojoakua-10bit)

# Some needed variables
MOUNTPOINT="/mnt"
INFO="\033[36;1m"
WARNING="\033[33;1m"
ERROR="\033[31;1m"
RESET="\033[0m"
REPOLINK="https://github.com/ojoakua-10bit/archlinux-install-helper"

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

echo -ne "Are you sure to proceed? (y/N): "
read CONFIRM

if [ "$CONFIRM" -ne "y" -a "$CONFIRM" -ne "Y" ]; then
	echo -e ${WARNING}Setup cancelled by user. Exiting...${RESET}
	exit 1
fi

echo -e "Please enter the name of root partition (e.g sdb1):"
read ROOTPART

if [ -z "$ROOTPART" ]; then
	echo -e ${ERROR}Invalid partition name.${RESET}
	exit 1;
fi

echo -e "Please enter the custom root mountpoint (e.g /mnt/root, default /mnt):"
read MOUNTPOINT

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
if [ ! $? ] then
	echo -e ${ERROR}ERROR: An error has occurred while mounting partitions. Exiting${RESET}
	exit 1
fi

mkdir $MOUTPOINT/{efi,boot,home,var}

mount -v /dev/$EFIPART $MOUNTPOINT/efi
if [ ! $? ] then
	echo -e ${ERROR}ERROR: An error has occurred while mounting partitions. Exiting${RESET}
	exit 1
fi

if [ -n "$BOOTPART" ] then
	mount -v /dev/$HOMEPART $MOUNTPOINT/boot
	if [ ! $? ] then
		echo -e ${ERROR}ERROR: An error has occurred while mounting partitions. Exiting${RESET}
		exit 1
	fi
fi

if [ -n "$HOMEPART" ] then
	mount -v /dev/$HOMEPART $MOUNTPOINT/home
	if [ ! $? ] then
		echo -e ${ERROR}ERROR: An error has occurred while mounting partitions. Exiting${RESET}
		exit 1
	fi
fi

if [ -n "$VARPART" ] then
	mount -v /dev/$VARPART $MOUNTPOINT/var
	if [ ! $? ] then
		echo -e ${ERROR}ERROR: An error has occurred while mounting partitions. Exiting${RESET}
		exit 1
	fi
fi

echo -e ${INFO}Configuring mirrors...${RESET}
pacman -S reflector --noconfirm
reflector --latest 50 --protocol http --protocol https --sort rate --save /etc/pacman.d/mirrorlist

echo -e ${INFO}Bootstrapping base install...${RESET}
pacstrap $MOUNTPOINT base base-devel grub2 git zsh neovim wget networkmanager intel-ucode amd-ucode

echo -e ${INFO}Generating /etc/fstab...${RESET}
genfstab -U $MOUNTPOINT >> $MOUNTPOINT/etc/fstab

echo -e ${INFO}Preparing chroot...${RESET}
pacman -S wget --noconfirm
wget $REPO_LINK/raw/master/USB/chroot.sh -O $MOUNTPOINT/.chroot-install

echo -e ${INFO}Entering chroot...${RESET}
arch-chroot $MOUNTPOINT sh -c /.chroot-install

