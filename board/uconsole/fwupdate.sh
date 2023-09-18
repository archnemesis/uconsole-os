#!/bin/sh
#
# Firmware Update Installation Script
#

set -e

MOUNT_ROOT="/media"
USB_DEVICE="/dev/sda1"

do_update()
{
	local firmware_file="$1"
	local install_script="/tmp/install.sh"

	echo "Extracting installation script..."
	if ! tar -xf "${firmware_file}" -C /tmp install.sh; then
		echo "Unable to extract installation script"
		rm -f "${firmware_file}"
		return 1
	fi

	chmod +x "${install_script}"

	echo "Extracting firmware update..."
	if ! tar -xf "${firmware_file}" --to-command="${install_script}"; then
		echo "Unable to install firmware update"
		rm -f "${firmware_file}"
		rm -f "${install_script}"
		return 1
	fi

	rm -f "${install_script}"

	return 0

}

echo "Looking for firmware update..."

for fwimage in /media/*/firmware.img; do
	if [ -e "${fwimage}" ]; then
		echo "Found firmware update file ${fwimage}"

		if do_update "${fwimage}"; then
			echo "Firmware update complete"
		else
			echo "Firmware update failed"
		fi

		echo "Remove USB drive to reboot..."
		while [ -e "${fwimage}" ]; do
			sleep 1
		done

		echo "Rebooting in 5 seconds..."
		sleep 5
		reboot -f
	fi
done

echo "Firmware update check complete"
