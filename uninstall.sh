#!/system/bin/sh
# OnePlus 13 All-in-One Module — Uninstall script
#
# NOTE: IMEI backups in /sdcard/OnePlus13_IMEI_Backup/ are NOT deleted.
#       They are your safety net — keep them!

MODDIR=${0%/*}

# Clean up module working files
rm -f "${MODDIR}/nvbk/mounted"
rm -f "${MODDIR}/post-fs-data.log"
rm -f "${MODDIR}/dtbo.img"
