This repository contains configuration files and instructions to set up a sandboxed system, which can be used to play music from local sources and the web.

The UI consists of a Firefox browser that has various capabilities stripped away, so that it should be hard for the user to accidentally break it.
An [`mpd` client](https://github.com/jcorporation/myMPD/) runs in the background and can be accessed via its web UI.

Tested with a RaspberryPi 2 and ArchlinuxARM.

# Installation
The following steps are how to setup a "thekenrechner".
Some require interaction, so it's best to read them before copy-pasting.

## Format SD card
In general you can probably follow the steps from your desired image, these are based on [Archlinux Arm for Raspberry Pi 2](https://archlinuxarm.org/platforms/armv7/broadcom/raspberry-pi-2).

```
fdisk /dev/mmcblk1
#input: o n p 1 [ENTER] +200M t c n p 2 [ENTER] [ENTER] w

mkdir raspi
cd raspi
mkdir boot
mkdir root
# replace with image for your favorite board
wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-2-latest.tar.gz
sudo mount /dev/mmcblk0p2 root/
sudo mount /dev/mmcblk0p1 boot/
sudo bsdtar -xpf ArchLinuxARM-rpi-2-latest.tar.gz -C root
sync
sudo mv root/boot/* boot
sync
# copy config_files
sudo cp -r config_files/* root/
```


## Chroot (optional)
To proceed from the comfort of your current computer you can do the rest of the setup via a chroot.
That is easiest if you already are on ARM hardware, otherwise you will need to use qemu.
If you don't want to jump through all these hoops it might be best to just boot the image at this point and continue from there on.

### Different Architecture from Board (e.g. x86)
```
yay -S qemu-user-static-bin
cp /usr/bin/qemu-arm-static root/usr/bin/
sudo umount /dev/mmcblk1p1
sudo mount /dev/mmcblk1p1 root/boot/
sudo arch-chroot root /bin/qemu-arm-static /bin/bash
```

__NOTE:__ You might need to restart for qemu to work.

### Same Architecture as Board
```
sudo umount /dev/mmcblk1p1
sudo mount /dev/mmcblk1p1 root/boot/
sudo arch-chroot root
```

## Internet Connection
If you are not in a chroot and don't have Ethernet available, you can use an Android phone for tethering.
Just connect it via USB, allow USB tethering on the phone.
You might need to adapt the vendor id in `/etc/udev/rules.d/51-android.rules` to match the one of your phone (check with `udevadm info /sys/class/net/usb0`) and then restart udev with `sudo systemctl restart systemd-udevd`.


## System Setup (as root)
These commands assume you are root. If you are not, use `su`.

### Install Packages
```
# set keyboard layout
localectl set-keymap de-latin1
pacman-key --init
pacman-key --populate
# uncomment servers close to you
nano /etc/pacman.d/mirrorlist
pacman -Syu
pacman -S base base-devel xorg xorg-xinit openbox wget htop git iputils firefox firefox-ublock-origin alsa-utils mpd feh fish --noconfirm
systemctl enable mpd.socket
```
### Basic System Configuration
```
timedatectl set-ntp true
timedatectl set-timezone Europe/Berlin
systemctl enable systemd-timesyncd
hwclock --systohc
echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen 
echo thekenrechner > /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       thekenrechner.localdomain   thekenrechner" >> /etc/hosts
# to supress noisy audit messages
sed -i '$ s/$/ audit=0/' /boot/cmdline.txt
```

### Create Users
```
# remove default user
userdel -r alarm

useradd -m -G wheel admin
# uncomment sudo permissions for group wheel
visudo /etc/sudoers
# set admin passwd
passwd admin
# use better TM shell
chsh -s /bin/fish admin
# disable root
sudo passwd -l root
```

## Install AUR packages
__NOTE:__ This cannot be done as root

```
# change to be admin
su admin
mkdir ~/yay_build
cd ~/yay_build
wget "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=yay-bin" -O PKGBUILD
makepkg -si

yay -S --noconfirm systemd-guest-user mympd
sudo systemctl enable mpd.socket mympd
```

## SSH reachability

```
mkdir ~/.ssh
# paste your favorite key here
nano ~/.ssh/authorized_keys
# disable password login
echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config
sudo systemctl enable sshd
```

## Configure Sound Card
You will want to configure your sound card in case it does not work. Edit `/etc/mpd.conf`.
Useful commands:

*`aplay -l` to list devices

*`aplay -L` to list device names

*`sudo aplay -D default:CARD=ALSA test.wav  &` to play a sound via a specified device

```
abbr -a rwmount 'sudo mount -o rw,remount /'
abbr -a romount 'sudo mount -o ro,remount /'
```

# Utilities
Helpful commands for maintaing a setup

### Take a screenshot via ssh
`DISPLAY=:0.0 XAUTHORITY=/home/guest/.Xauthority sudo xwd -out screenshot.xwd -root`
