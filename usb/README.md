# Installation script to USB

This Arch Linux installation script is intended to install Arch Linux into USB storage. This script is considered experimental and need to be improved. Feel free to open an issue and make a pull request if you have any ideas to improve this script.

## Prerequisites

Arch Linux Live CD/USB or any linux distro (preferrably existing Arch Linux Installation) which has these packages installed:
```
gptfdisk (or gdisk)
arch-install-scripts
pacman
```

Please follow the instruction below to set up the partition on USB before installing.

## Set up hybrid MBR for USB

Under Construction

## Run the installation script

Run this command from Arch Live CD/USB or existing Linux install.

```
$ curl -sSL https://raw.githubusercontent.com/ojoakua-10bit/archlinux-install-helper/master/usb/livecd.sh -o install
$ chmod +x install
# ./install
```
or one-liner version (not recommended due to security issues)
```
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/ojoakua-10bit/archlinux-install-helper/master/usb/livecd.sh)"
```

