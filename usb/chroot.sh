#!/bin/bash
# Author: Aditya Pramana (https://github.com/ojoakua-10bit)
# This script is intended to run on chroot environment. Don't run it on live CD
# This script should be automatically invoked from livecd script

# Abort script if something went wrong
set -e

# Some needed variables
INFO="\033[36;1m"
WARNING="\033[33;1m"
ERROR="\033[31;1m"
RESET="\033[0m"

HOSTNAME="archlinux"
USERNAME="arch"

# Make sure that the script is executed as superuser
if [ $UID -ne 0 ]; then
	echo ${ERROR}ERROR: Please run this script as root/superuser!${RESET}
	exit 1
fi

# Most of these scripts are still hardcoded: locale, language.
echo -e "${INFO}Setting up hostname...${RESET}"
read -p "Enter the hostname (default=archlinux): " _HOSTNAME

if [ -n "$_HOSTNAME" ]; then
	HOSTNAME=$_HOSTNAME
fi

echo "$HOSTNAME" > /etc/hostname
cat >> /etc/hosts << EOF
127.0.0.1	localhost
::1		localhost
127.0.1.1	$HOSTNAME.localdomain	$HOSTNAME
EOF

echo -e "${INFO}Setting up locales...${RESET}"
mv /etc/locale.gen{,.bak}
cat > /etc/locale << EOF
# Original file backed-up at locale.gen.bak

en_US.UTF-8 UTF-8
id_ID.UTF-8 UTF-8
ja_JP.UTF-8 UTF-8
EOF
locale-gen

echo -e "${INFO}Setting up language...${RESET}"
echo 'LANG=en_US.UTF-8 UTF-8' > /etc/locale.conf

echo -e "${INFO}Setting up bootloader...${RESET}"
USB_DISK=$(findmnt -Recvruno SOURCE / | awk 'NR==1' | sed 's/[0-9]//g')
grub-install --target=x86_64-efi --recheck --removable --efi-directory=/efi --boot-directory=/boot
# Always place partition for grub.img on /dev/sdX1, it will fail otherwise
grub-install --target=i386-pc --recheck --boot-directory=/mnt/c/boot $USB_DISK
grub-mkconfig -o /boot/grub/grub.cfg

echo -e "${INFO}Setting up users...${RESET}"
cat << EOF
Available user options:
1) Locked root account with a sudo user account
2) Password-protected root account with a non-sudo user account
3) Password-protected root account with a sudo user account

Choose an option (default=1):
EOF
read OPTS

echo -ne "Enter the username (default=arch): "
read _USERNAME
if [ -n $_USERNAME ]; then
	USERNAME=$_USERNAME
fi

case $OPTS in
	2)
		echo -e "${INFO}Password for 'root'...${RESET}"
		passwd
		useradd -m -G audio -s /usr/bin/zsh $USERNAME
		echo -e "${INFO}Password for '${USERNAME}'...${RESET}"
		passwd $USERNAME
		;;
	3) 
		echo -e "${INFO}Password for 'root'...${RESET}"
		passwd
		useradd -m -G audio,wheel -s /usr/bin/zsh $USERNAME
		echo -e "${INFO}Password for '${USERNAME}'...${RESET}"
		passwd $USERNAME
		;;
	*)
		passwd -l
		useradd -m -G audio,wheel -s /usr/bin/zsh $USERNAME
		echo -e "${INFO}Password for '${USERNAME}'...${RESET}"
		passwd $USERNAME
		;;
esac

sed -i 's/# root ALL=(ALL) ALL/root ALL=(ALL) ALL/g' /etc/sudoers
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers

echo -e ${INFO}Configuring custom initramfs...${RESET}
sed -i 's/MODULES=()/MODULES=(xhci_hcd xhci_pci usb_storage roles intel_xhci_usb_role_switch)/g' /etc/mkinitcpio.conf
mkinitcpio -p linux

echo -e "${INFO}Refreshing packages...${RESET}"
sed -i 's/#\[multilib]/\[multilib]/g' /etc/pacman.conf
sed -i '/^#\[multilib]/{N;s/\n#/\n/}' /etc/pacman.conf
pacman -Syyu --noconfirm

echo -e "${INFO}Graphical environment...${RESET}"
read -p "Install graphical environment? (Y/n): " 

if [ "$CONFIRM" -eq "n" -o "$CONFIRM" -eq "N" ]; then
	systemctl enable NetworkManager
	echo "Done..."
	exit 0
fi

echo -e "${INFO}Installing X server...${RESET}"
pacman -S --noconfirm xorg xorg-xinit xorg-drivers

echo '1. Xfce  2. Cinnamon  3. MATE  4. LXDE  (1-4, default=1): '
read OPTS

case $OPTS in
	2)
		pacman -S --noconfirm cinnamon gnome-terminal
		;;
	3)
		pacman -S --noconfirm mate mate-terminal network-manager-applet
		;;
	4)
		pacman -S --noconfirm lxde
		pacman -R --noconfirm lxdm
		;;
	*)
		pacman -S --noconfirm xfce4 network-manager-applet
esac

read -p "Install extra packages? (Y/n)"

if [ "$CONFIRM" -ne "n" -a "$CONFIRM" -ne "N" ]; then
	case $OPTS in
		2)
			pacman -S --noconfirm file-roller nemo-fileroller xed xreader eog gnome-mpv firefox
			;;
		3)
			pacman -S --noconfirm mate-extra gnome-mpv firefox
			;;
		4)
			pacman -S --noconfirm atril mpv firefox
			;;
		*)
			pacman -S --noconfirm xfce4-goodies xarchiver xreader
			;;
	esac
fi

read -p "Install display manager (LightDM)? (Y/n) " CONFIRM

if [ "$CONFIRM" -ne "n" -a "$CONFIRM" -ne "N" ]; then
	case $OPTS in
		2)
			XINIT_CMD="cinnamon-session"
			;;
		3)
			XINIT_CMD="mate-session"
			;;
		4)
			XINIT_CMD="startlxde"
			;;
		*)
			XINIT_CMD="startxfce4"
			;;
	esac
	echo "exec $XINIT_CMD" >> /home/$USERNAME/.xinitrc
	chown $USERNAME:$USERNAME /home/$USERNAME/.xinitrc

	systemctl enable NetworkManager
	echo "Done..."
	exit 0
fi

echo -e "${INFO}Installing LightDM...${RESET}"
pacman -S --noconfirm lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings

echo -e "${INFO}Finishing install...${RESET}"
systemctl enable lightdm
systemctl enable NetworkManager

echo "Done..."

