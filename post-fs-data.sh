#!/system/bin/sh
# OnePlus 13 All-in-One Module — post-fs-data script
#
# Signal Fix component
# Original author: K58/Fly (https://github.com/K58/fix-signal-oneplus13)
# Credit: rapperskull
# License of this file: Apache-2.0 License (as per original)

MODDIR=${0%/*}

# Preserve system PATH for command resolution (critical for KernelSU compatibility)
export PATH="/system/bin:/vendor/bin:/system/xbin:${PATH}"

LOGFILE="${MODDIR}/post-fs-data.log"
MODFILE="${MODDIR}/nvbk/oplusstanvbk.img"
MODFILEMOUNTED="${MODDIR}/nvbk/mounted"

SLOT="$(resetprop ro.boot.slot_suffix)"
PART_LINK="/dev/block/bootdevice/by-name/oplusstanvbk${SLOT}"

exec > "$LOGFILE"
exec 2>&1

echo "=== OnePlus 13 All-in-One: Signal Fix ==="
echo "Slot: ${SLOT}"
echo

ls -laZ "$PART_LINK"
echo

if [ -L "$PART_LINK" ]; then
  rm -f "$MODFILEMOUNTED"
  cp "$MODFILE" "$MODFILEMOUNTED"

  ORIG="$(readlink -fn "$PART_LINK")"
  DEV="${ORIG}_mod"

  if [ -e "$MODFILEMOUNTED" ]; then
    # The loop device path must be in the form '/dev/block/sdX...' because mark_boot_successful()
    # will ultimately call gpt_get_header() in gpt-utils and it will try to open the device name
    # truncated to length 'sizeof("/dev/block/sda") - 1'. This means that if the original partition
    # is '/dev/block/sdX00', it will try to open '/dev/block/sdX', so if we just use the next available
    # loop device, it will fail opening '/dev/block/loo'. Using the same prefix as the original
    # partition will solve the issue, but requires a "hack" to work.
    # We first associate our patched file with the next available loop device, then we rename it.
    # (comment by rapperskull, kept from the original)
    LOOP_DEV="$(/system/bin/losetup -sf "$MODFILEMOUNTED")"
    if [ -z "$LOOP_DEV" ]; then
      echo "ERROR: Cannot create loop device"
    else
      mv -f "$LOOP_DEV" "$DEV"
      ret=$?
      if [ $ret -ne 0 ]; then
        echo "ERROR: Cannot rename loop device"
      else
        chcon -v "u:object_r:vendor_custom_ab_block_device:s0" "$DEV"
        echo "Created loop device ${DEV}"
        ls -laZ "$DEV"
        echo
        ln -sfv "$DEV" "$PART_LINK"
        echo
        ls -laZ "$PART_LINK"
      fi
    fi
  else
    echo "ERROR: ${MODFILEMOUNTED} doesn't exist!!!"
  fi
else
  echo "ERROR: ${PART_LINK} doesn't exist!!!"
fi
