#!/bin/sh

echo "Processing firmware image ${TAR_REALNAME}..."

case "${TAR_REALNAME}" in
	"boot.tar.gz")
		mkfs.vfat -n "boot" /dev/mmcblk0p1
		mount -t auto /dev/mmcblk0p1 /mnt
		gunzip -c | tar x -f - -C /mnt
		sync
		umount /mnt
		;;
	"rootfs.tar.gz")
		mkfs.ext4 -L "rootfs" -O ^64bit -F /dev/mmcblk0p2
		mount -t auto /dev/mmcblk0p2 /mnt
		gunzip -c | tar x -f - -C /mnt
		sync
		umount /mnt
		;;
	"data.tar.gz")
		if [ -n "${ERASE_USER_DATA}" ]; then
			mkfs.ext4 -L "data" -O ^64bit -F /dev/mmcblk0p3
			mount -t auto /dev/mmcblk0p3 /mnt
			gunzip -c | tar x -f - -C /mnt
			sync
			umount /mnt
		fi
		;;
	"sdcard.img.xz")
		xzcat - | dd bs=4096 of=/dev/mmcblk0
		;;
	*)
		echo "Warning: unsupported file ${TAR_REALNAME}"
		;;
esac
