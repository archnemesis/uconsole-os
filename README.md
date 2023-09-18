# uConsole-OS

A Buildroot-based Linux OS for the [ClockworkPi uConsole](https://www.clockworkpi.com/uconsole).

## Getting Started

1. Install [Docker](https://docs.docker.com/get-docker/)
2. Build the project

```
./dmake uconsole_defconfig
./dmake all
```

3. Use RaspberryPi Imager to write `buildroot/output/images/sdcard.img.xz` to either an SDCard or the eMMC.

## Firmware Update

One of the main goals of this Linux OS is the ability to upgrade easily after making changes to the Buildroot configuration. A firmware update image is created during the build and can be easily written to a USB thumb drive and used to update the target. A user data partition is preserved through subsequent updates.

1. Build the project as normal
2. Copy `buildroot/output/images/firmware.img` to the root of a USB thumb drive, formatted as FAT32 (can be vfat or ext4, but FAT32 is the more common case).
3. Connect the USB thumb drive to the target and power on or restart.
4. The firmware update file will be found and installed to the target.
5. After the update is finished, you will be prompted to remove the USB thumb drive. The target will then reboot.
