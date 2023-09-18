#!/bin/bash

set -e

BOARD_DIR="$(dirname $0)"
BOARD_NAME="$(basename ${BOARD_DIR})"
GENIMAGE_CFG="${BOARD_DIR}/genimage-${BOARD_NAME}.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
SDCARD_IMG="${BINARIES_DIR}/sdcard.img"
RELEASE_DIR="${BINARIES_DIR}/release"

# Pass an empty rootpath. genimage makes a full copy of the given rootpath to
# ${GENIMAGE_TMP}/root so passing TARGET_DIR would be a waste of time and disk
# space. We don't rely on genimage to build the rootfs image, just to insert a
# pre-built one in the disk image.

trap 'rm -rf "${ROOTPATH_TMP}"' EXIT
ROOTPATH_TMP="$(mktemp -d)"

rm -rf "${GENIMAGE_TMP}"

genimage \
	--rootpath "${ROOTPATH_TMP}"   \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENIMAGE_CFG}"

xz -c -9 -T 0 "${SDCARD_IMG}" > "${SDCARD_IMG}.xz"

# Compress rootfs archive
gzip -c -9 "${BINARIES_DIR}/rootfs.tar" > "${BINARIES_DIR}/rootfs.tar.gz"

rm -rf "${RELEASE_DIR}" && mkdir -p "${RELEASE_DIR}"
cp "${BOARD_DIR}/install.sh" "${RELEASE_DIR}"
cp "${BINARIES_DIR}/boot.tar.gz" "${RELEASE_DIR}"
cp "${BINARIES_DIR}/rootfs.tar.gz" "${RELEASE_DIR}"
cp "${BINARIES_DIR}/data.tar.gz" "${RELEASE_DIR}"

tar -C "${RELEASE_DIR}" -cf \
	"${BINARIES_DIR}/firmware.img" \
	"install.sh" \
	"boot.tar.gz" \
	"rootfs.tar.gz" \
	"data.tar.gz"
