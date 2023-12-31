#!/bin/sh

set -u
set -e

# Add a console on tty1
if [ -e ${TARGET_DIR}/etc/inittab ]; then
    grep -qE '^tty1::' ${TARGET_DIR}/etc/inittab || \
	sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/sbin/getty -L  tty1 0 vt100 # HDMI console' ${TARGET_DIR}/etc/inittab
# systemd doesn't use /etc/inittab, enable getty.tty1.service instead
elif [ -d ${TARGET_DIR}/etc/systemd ]; then
    mkdir -p "${TARGET_DIR}/etc/systemd/system/getty.target.wants"
    ln -sf /lib/systemd/system/getty@.service \
       "${TARGET_DIR}/etc/systemd/system/getty.target.wants/getty@tty1.service"
fi

# ensure overlays exists for genimage
mkdir -p "${BINARIES_DIR}/rpi-firmware/overlays"

# copy overlays for devterm
cp -v "${BUILD_DIR}/linux-custom/arch/arm/boot/dts/overlays/devterm-misc.dtbo" \
	"${BINARIES_DIR}/rpi-firmware/overlays"
cp -v "${BUILD_DIR}/linux-custom/arch/arm/boot/dts/overlays/devterm-panel.dtbo" \
	"${BINARIES_DIR}/rpi-firmware/overlays"
cp -v "${BUILD_DIR}/linux-custom/arch/arm/boot/dts/overlays/devterm-panel-uc.dtbo" \
	"${BINARIES_DIR}/rpi-firmware/overlays"
cp -v "${BUILD_DIR}/linux-custom/arch/arm/boot/dts/overlays/devterm-pmu.dtbo" \
	"${BINARIES_DIR}/rpi-firmware/overlays"
cp -v "${BUILD_DIR}/linux-custom/arch/arm/boot/dts/overlays/devterm-wifi.dtbo" \
	"${BINARIES_DIR}/rpi-firmware/overlays"

# Mount data partition
mkdir -p "${TARGET_DIR}/data"
echo "/dev/mmcblk0p3 /data ext4 defaults 0 0" >> "${TARGET_DIR}/etc/fstab"
