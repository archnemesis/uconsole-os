#!/bin/sh

MOUNT_ROOT="/media"
MOUNT_OPTS="ro"

mount_dev ()
{
    local DEVICE="$1"
    local MOUNTPOINT="$2"

    if ! [ -b "${DEVICE}" ] ; then return 1 ; fi

    echo "Mounting ${DEVICE} at ${MOUNTPOINT}"

    mkdir -p "${MOUNTPOINT}"

    if ! mount -t auto -o "${MOUNT_OPTS}" "${DEVICE}" \
        "${MOUNTPOINT}" > /dev/null 2>&1
    then
        echo "Failed to mount ${DEVICE}"
        rmdir "${MOUNTPOINT}"
        return 1
    fi

    return 0
}

unmount_dev ()
{
    local DEVICE="$1"
    local umount_force=""

    # if device is already gone, force the unmount
    if ! [ -b "${DEVICE}" ] ; then umount_force="-f" ; fi

    # ensure device is mounted before attempting to unmount
    for mountpoint in $(grep "^${DEVICE} " /proc/mounts | cut -d' ' -f 2)
    do
        echo "Unmounting ${mountpoint}"
        # lazy unmount (-l) because files may still be open in other processes
        if ! umount -l ${umount_force} "${mountpoint}" > /dev/null 2>&1
        then
            echo "Failed to unmount ${mountpoint}"
        fi
    done

    # walk through mounts directory and remove all directories that don't show
    # up in /proc/mounts

    for dir in ${MOUNT_ROOT}/*
    do
        if [ -d "${dir}" ] && ! grep " ${dir} " /proc/mounts > /dev/null 2>&1
        then
            echo "Cleaning up ${dir}"
            rmdir "${dir}"
        fi
    done

    return 0
}

# Re-open standard descriptors closed by mdev
0< /dev/null
1> /dev/null
2> /dev/null

case "${ACTION}" in
    'add')
        mount_dev "/dev/${MDEV}" "${MOUNT_ROOT}/${MDEV}"
        ;;
    'remove')
        unmount_dev "/dev/${MDEV}"
        ;;
     *)
        log_error "unknown action ${ACTION}"
        ;;
esac

exit $?