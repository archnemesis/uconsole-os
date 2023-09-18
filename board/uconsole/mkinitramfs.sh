#!/bin/sh
#
# Create an initramfs for minimal bootable environment.
#

set -e

script_dir="$(CDPATH= cd -- $(dirname -- $0) && pwd)"

BOARD_DIR="$(dirname $0)"
DESTDIR="${BINARIES_DIR}/initramfs"
INITRAMFS_CPIO="${BINARIES_DIR}/initramfs.cpio.gz"

#############################################################################
# Function: copy_file
# arg1 = file to copy to ramdisk
# arg2 = (optional) name for the file on the ramdisk
# returns - 0 on success (file successfully copied); 1 on error
# Description:
#  Copy file from source root directory into ramdisk root directory.
#  If file is a symbolic link, copy the link target as well.

copy_file ()
{
    local src="$1"
    local dest="${2:-${src#${TARGET_DIR}}}"

    if [ ! -f "${src}" ]; then
        echo "ERROR: ${src} is not a regular file"
        return 1
    fi

    # match cp behavior; if dest is a directory, copy src to dest/.
    if [ -d "${DESTDIR}/${dest}" ]; then
            dest="${dest}/${src##*/}"
    fi

    # TBD: should we fail if dest already exists?

    mkdir -pv "${DESTDIR}/${dest%/*}"

    if [ -h "${src}" ]
    then
        # get resolved path, and add a relative link in DESTDIR
        if ! local link_target="$(readlink -f "${src}")"; then
            echo "ERROR: could not resolve ${src}"
            return 1
        fi
        ln -sfv -r "${DESTDIR}/${link_target#${TARGET_DIR}}" \
            "${DESTDIR}/${dest}"

        # copy the link target
        copy_file "${link_target}" && return 0 || return 1
    fi

    [ -n "${DEBUG}" ] && \
    echo "DEBUG: adding ${src} to initramfs"
    cp -fv "${src}" "${DESTDIR}/${dest}" || return 1
}

#############################################################################
# Function: copy_exec
# arg1 = executable to copy to ramdisk (with library dependencies)
# arg2 = (optional) name for the executable on the ramdisk
# returns - 0 on success (executable successfully copied); 1 on error
# Description:
#  Copy executable from source root directory into ramdisk root directory.
#  If executable has any dynamic library dependencies, copy these as well.

copy_exec ()
{
    local src="$1"
    local dest="${2:-${src#${TARGET_DIR}}}"

    # add the executable
    copy_file "${src}" "${dest}" || return 1

    # add any dynamic libs "NEEDED" by this executable
    readelf -d "${src}" | grep '(NEEDED)' | \
        sed 's/^.*Shared library:[[:space:]]*\[\(.*\)\]$/\1/;' | \
    while read needed
    do
        lib="$(PATH=${TARGET_DIR}/lib:${TARGET_DIR}/usr/lib command -v ${needed})"
        if [ -n "${lib}" ]; then
            # perform the same dependency check recursively for each library
            copy_exec "${lib}" || return 1
        else
            echo "ERROR: could not find ${needed} in ${TARGET_DIR}"
            return 1
        fi
    done

    # add the interpreter listed in the INTERP field (contains the linker)
    interp="$(readelf -Wl "${src}" | \
        sed -n 's/^.*\[Requesting program interpreter:[[:space:]]*\(.*\)\].*$/\1/p;')"

    if [ -n "${interp}" ]; then
        copy_file "${TARGET_DIR}/${interp}" || return 1
    fi
}

# create a clean ramdisk root directory
rm -rfv "${DESTDIR}" && mkdir -p "${DESTDIR}"

# add rootfs skeleton
for i in etc var dev proc sys run tmp bin lib sbin media mnt; do
    mkdir -pv "${DESTDIR}/${i}"
done

for i in bin lib sbin; do
    mkdir -pv "${DESTDIR}/usr/${i}"
done

# add lib64 symlink(s)
ln -sv lib "${DESTDIR}/lib64"
ln -sv lib "${DESTDIR}/usr/lib64"

# add busybox binary and "applets" (if any)
if [ -f "${TARGET_DIR}/bin/busybox" ]; then
    copy_exec "${TARGET_DIR}/bin/busybox"

    for f in $(find "${TARGET_DIR}" -type l); do
        if readlink -f "${f}" | grep -q "busybox"; then
            copy_file "${f}"
        fi
    done
fi

# glibc uses dlopen() to load some modules (e.g. libnss, gconv); we cannot
# detect these dependencies with ldd/readelf, so we must list them here
for lib in "${TARGET_DIR}/lib/libnss_"*; do
    [ -e "${lib}" ] && copy_exec "${lib}"
done

# add contents of var
cp -Rv "${TARGET_DIR}/var" "${DESTDIR}/."

# add required files from /etc
mkdir -pv "${DESTDIR}/etc"
copy_file "${TARGET_DIR}/etc/fstab"
copy_file "${TARGET_DIR}/etc/group"
copy_file "${TARGET_DIR}/etc/hostname"
copy_file "${TARGET_DIR}/etc/hosts"
copy_file "${TARGET_DIR}/etc/inittab"
copy_file "${TARGET_DIR}/etc/issue"
copy_file "${TARGET_DIR}/etc/nsswitch.conf"
copy_file "${TARGET_DIR}/etc/passwd"
copy_file "${TARGET_DIR}/etc/services"
copy_file "${TARGET_DIR}/etc/shells"
copy_file "${TARGET_DIR}/etc/mdev.conf"
copy_file "${TARGET_DIR}/etc/mdev-scripts/usbmount.sh"
ln -s "../proc/self/mounts" "${DESTDIR}/etc/mtab"

# we must have /dev/console very early, even before /init runs,
# for stdin/stdout/stderr
mkdir -pv "${DESTDIR}/dev"
cp -Rv "${TARGET_DIR}/dev" "${DESTDIR}/."
fakeroot mknod -m 0622 "${DESTDIR}/dev/console" c 5 1

# TBD: mark our custom initramfs
echo "initramfs built on $(date)" > "${DESTDIR}/VERSION"

# replace default pre-init script with our custom script
[ -f "${BOARD_DIR}/init" ] && \
    cp -v "${BOARD_DIR}/init" "${DESTDIR}/init"

chmod -v 0755 "${DESTDIR}/init"

# add our firmware update script
[ -f "${BOARD_DIR}/fwupdate.sh" ] && \
    cp -v "${BOARD_DIR}/fwupdate.sh" "${DESTDIR}/sbin/fwupdate.sh" && \
    chmod -v 0755 "${DESTDIR}/sbin/fwupdate.sh"

# add necessary utilities
copy_exec "${TARGET_DIR}/bin/tar"
copy_exec "${TARGET_DIR}/sbin/e2fsck"
copy_exec "${TARGET_DIR}/sbin/mke2fs"
copy_exec "${TARGET_DIR}/usr/bin/curl"
copy_exec "${TARGET_DIR}/usr/bin/unxz"
copy_exec "${TARGET_DIR}/usr/bin/xz"
copy_exec "${TARGET_DIR}/usr/bin/xzcat"
copy_exec "${TARGET_DIR}/sbin/mkfs.ext2"
copy_exec "${TARGET_DIR}/sbin/mkfs.ext3"
copy_exec "${TARGET_DIR}/sbin/mkfs.ext4"
copy_exec "${TARGET_DIR}/sbin/mkfs.vfat"

# finally, create our initramfs cpio archive
( cd "${DESTDIR}" && \
    find . | \
    LC_ALL=C sort | \
    cpio --quiet -o -H newc | \
    gzip -9 \
    > "${INITRAMFS_CPIO}"
)
