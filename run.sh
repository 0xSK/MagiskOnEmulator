#!/bin/sh
set -e
set -x

BLOCK_DEVICE=/dev/block/sda2
WORK_DIR=/data/local/tmp
MOUNT_DIR=$WORK_DIR/root

adb root
adb wait-for-device

# make a copy of initrd.img and ramdisk.img
adb -e shell "mkdir -p $WORK_DIR/root"
adb -e shell "mount $BLOCK_DEVICE $WORK_DIR/root"
adb -e shell "cp $MOUNT_DIR/*/initrd.img $WORK_DIR/initrd.img.gz"
adb -e shell "cp $MOUNT_DIR/*/ramdisk.img $WORK_DIR/ramdisk.img.gz"

# download latest Magisk manager
LATEST_TAG=$(curl -s https://api.github.com/repos/topjohnwu/Magisk/releases/latest | grep tag_name | cut -d '"' -f 4)
DOWNLOAD_URL="https://github.com/topjohnwu/Magisk/releases/download/$LATEST_TAG/Magisk-$LATEST_TAG.apk"
wget -O magisk.apk $DOWNLOAD_URL

# copy and run magisk script
adb -e push magisk.apk $WORK_DIR/magisk.zip
adb -e push busybox $WORK_DIR
adb -e push process.sh $WORK_DIR
adb -e push initrd.patch $WORK_DIR
adb -e shell "dos2unix $WORK_DIR/process.sh"
adb -e shell "sh $WORK_DIR/process.sh $WORK_DIR"
adb install magisk.apk

INITRD=`adb -e shell "ls $MOUNT_DIR/*/initrd.img"`
RAMDISK=`adb -e shell "ls $MOUNT_DIR/*/ramdisk.img"`

adb -e shell "cp $WORK_DIR/initrd.img $INITRD"
adb -e shell "cp $WORK_DIR/ramdisk.img $RAMDISK"
adb -e shell "sync"
adb -e shell "umount $MOUNT_DIR"
adb -e shell "rm -rf $WORK_DIR"
adb -e shell "reboot"
