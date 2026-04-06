#!/system/bin/sh
# OnePlus 13 All-in-One Module
# Combined: Signal Fix + VoLTE/WiFi Calling + IMEI Backup
#
# CREDITS & LICENSES:
#   Signal Fix:  K58/Fly (https://github.com/K58/fix-signal-oneplus13) — GPLv3
#                Contributors: @koaaN, @docnok63 (XDA), rapperskull (GitHub)
#   VoLTE/WiFi:  symbuzzer/Ali Beyaz (https://github.com/symbuzzer/Volte-Wifi-Calling-Enabler) — GPLv3
#   IMEI Backup: Sanic27 — based on 4PDA community guides for Qualcomm devices
#
# This combined module is licensed under GPLv3.

##########################
# Device Compatibility Check
##########################

PRJNAME=$(getprop ro.boot.prjname)

if [ "$PRJNAME" != "23821" ]; then
  ui_print ""
  ui_print "============================================"
  ui_print "  ERROR: This module is for OnePlus 13 CN only!"
  ui_print "  Your device project: $PRJNAME"
  ui_print "  Required: 23821 (OnePlus 13 CN)"
  ui_print "  DO NOT install on other devices!"
  ui_print "============================================"
  abort "> Aborting installation..."
fi

ui_print ""
ui_print "============================================"
ui_print "  OnePlus 13 All-in-One Module v1.0"
ui_print "  Signal Fix + VoLTE/WiFi + IMEI Backup"
ui_print "============================================"
ui_print ""

##########################
# IMEI Partition Backup
##########################

ui_print "[1/3] IMEI & Critical Partitions Backup"
ui_print "----------------------------------------"

BACKUP_DIR="/sdcard/OnePlus13_IMEI_Backup"

# Check if /sdcard is mounted and writable
if [ ! -d "/sdcard" ] || ! touch "/sdcard/.imei_backup_test" 2>/dev/null; then
  # Fallback: try /data/media/0
  if [ -d "/data/media/0" ] && touch "/data/media/0/.imei_backup_test" 2>/dev/null; then
    BACKUP_DIR="/data/media/0/OnePlus13_IMEI_Backup"
    rm -f "/data/media/0/.imei_backup_test"
    ui_print "  Note: /sdcard not available, using /data/media/0/"
  else
    ui_print "! WARNING: Storage not writable"
    ui_print "! IMEI backup will be SKIPPED"
    ui_print "! Backup manually after reboot (see README)"
    ui_print ""
    BACKUP_DIR=""
  fi
else
  rm -f "/sdcard/.imei_backup_test"
fi

if [ -n "$BACKUP_DIR" ]; then
  # Check if a valid backup already exists (modemst1 + modemst2 are essential)
  NEED_BACKUP=true

  if [ -d "$BACKUP_DIR" ]; then
    EXISTING_BACKUP=$(ls -1d "${BACKUP_DIR}"/20* "${BACKUP_DIR}"/backup_* 2>/dev/null | tail -1)
    if [ -n "$EXISTING_BACKUP" ] && [ -f "${EXISTING_BACKUP}/modemst1.img" ] && [ -f "${EXISTING_BACKUP}/modemst2.img" ]; then
      EXISTING_COUNT=$(ls -1d "${BACKUP_DIR}"/20* "${BACKUP_DIR}"/backup_* 2>/dev/null | wc -l)
      ui_print "  Existing backup found: ${EXISTING_BACKUP}"
      ui_print "  Backups on device: ${EXISTING_COUNT}"
      ui_print ""
      ui_print "  IMEI partitions already backed up!"
      ui_print "  Skipping backup to avoid duplicates."
      ui_print "  To force new backup, delete the folder:"
      ui_print "  ${BACKUP_DIR}"
      ui_print ""
      NEED_BACKUP=false
    elif [ -n "$EXISTING_BACKUP" ]; then
      ui_print "  Incomplete backup found, creating new one..."
    fi
  fi

  if $NEED_BACKUP; then
    # Generate timestamp with fallback
    if command -v date >/dev/null 2>&1; then
      TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    else
      # Fallback: use uptime-based identifier
      TIMESTAMP="backup_$(cat /proc/uptime 2>/dev/null | awk '{print $1}' | tr '.' '_')"
      [ -z "$TIMESTAMP" ] || [ "$TIMESTAMP" = "backup_" ] && TIMESTAMP="backup_manual"
    fi

    BACKUP_PATH="${BACKUP_DIR}/${TIMESTAMP}"
    mkdir -p "$BACKUP_PATH"

    if [ ! -d "$BACKUP_PATH" ]; then
      ui_print "! WARNING: Cannot create backup directory"
      ui_print "! IMEI backup will be skipped"
      ui_print ""
    else
      # OnePlus 13 uses Qualcomm Snapdragon 8 Elite (SM8750)
      # IMEI is stored in: modemst1, modemst2
      # Supporting partitions: fsc, fsg
      # Additional critical: persist, ocdt (device identifiers)
      #
      # Path: /dev/block/bootdevice/by-name/<partition>
      # Reference: https://droidwin.com/which-partition-does-oneplus-store-imei-number/
      # Reference: 4PDA vadimka-85 guide for OnePlus critical partition backup

      PARTITIONS="modemst1 modemst2 fsc fsg persist ocdt"
      BACKUP_OK=0
      BACKUP_FAIL=0

      for PART in $PARTITIONS; do
        PART_PATH="/dev/block/bootdevice/by-name/${PART}"

        # Resolve symlink to actual block device
        if [ -L "$PART_PATH" ]; then
          REAL_PATH=$(readlink -f "$PART_PATH" 2>/dev/null)
          [ -z "$REAL_PATH" ] && REAL_PATH="$PART_PATH"
        elif [ -e "$PART_PATH" ]; then
          REAL_PATH="$PART_PATH"
        else
          REAL_PATH=""
        fi

        if [ -n "$REAL_PATH" ] && [ -e "$REAL_PATH" ]; then
          ui_print "  > Backing up ${PART}..."
          dd if="$REAL_PATH" of="${BACKUP_PATH}/${PART}.img" bs=4096 2>/dev/null
          if [ $? -eq 0 ] && [ -f "${BACKUP_PATH}/${PART}.img" ]; then
            SIZE=$(wc -c < "${BACKUP_PATH}/${PART}.img" 2>/dev/null)
            if [ -n "$SIZE" ] && [ "$SIZE" -gt 0 ] 2>/dev/null; then
              ui_print "    OK (${SIZE} bytes)"
              BACKUP_OK=$((BACKUP_OK + 1))
            else
              ui_print "    ! WARNING: ${PART}.img is empty (0 bytes)"
              rm -f "${BACKUP_PATH}/${PART}.img"
              BACKUP_FAIL=$((BACKUP_FAIL + 1))
            fi
          else
            ui_print "    ! FAILED to backup ${PART}"
            BACKUP_FAIL=$((BACKUP_FAIL + 1))
          fi
        else
          ui_print "  > ${PART} partition not found, skipping"
        fi
      done

      ui_print ""
      ui_print "  Backup summary: ${BACKUP_OK} OK, ${BACKUP_FAIL} failed"
      ui_print "  Saved to: ${BACKUP_PATH}"
      ui_print ""

      # Validate backup — at minimum modemst1 and modemst2 must be present
      if [ ! -f "${BACKUP_PATH}/modemst1.img" ] || [ ! -f "${BACKUP_PATH}/modemst2.img" ]; then
        ui_print "  !! WARNING: IMEI backup is INCOMPLETE !!"
        ui_print "  !! modemst1/modemst2 are required     !!"
        ui_print "  !! Backup manually after reboot!       !!"
        ui_print ""
      fi

      # Create restore instructions file
      cat > "${BACKUP_PATH}/RESTORE_INSTRUCTIONS.txt" << 'RESTORE_EOF'
========================================
  OnePlus 13 IMEI Partition Restore Guide
========================================

IMPORTANT: These are RAW partition images.
           Only restore if your IMEI is lost/corrupted!

Method 1: Via Fastboot
-----------------------
1. Copy backup files to your PC
2. Reboot to fastboot:
   adb reboot fastboot

3. Flash partitions:
   fastboot flash modemst1 modemst1.img
   fastboot flash modemst2 modemst2.img
   fastboot flash fsc fsc.img
   fastboot flash fsg fsg.img
   fastboot flash persist persist.img
   fastboot flash ocdt ocdt.img

4. Reboot:
   fastboot reboot

Method 2: Via Root Shell (dd)
------------------------------
su -c dd if=/sdcard/OnePlus13_IMEI_Backup/<timestamp>/modemst1.img of=/dev/block/bootdevice/by-name/modemst1
su -c dd if=/sdcard/OnePlus13_IMEI_Backup/<timestamp>/modemst2.img of=/dev/block/bootdevice/by-name/modemst2
su -c dd if=/sdcard/OnePlus13_IMEI_Backup/<timestamp>/fsc.img of=/dev/block/bootdevice/by-name/fsc
su -c dd if=/sdcard/OnePlus13_IMEI_Backup/<timestamp>/fsg.img of=/dev/block/bootdevice/by-name/fsg
su -c dd if=/sdcard/OnePlus13_IMEI_Backup/<timestamp>/persist.img of=/dev/block/bootdevice/by-name/persist
su -c dd if=/sdcard/OnePlus13_IMEI_Backup/<timestamp>/ocdt.img of=/dev/block/bootdevice/by-name/ocdt

WARNING: Restoring wrong images can brick your modem!
         Only use YOUR OWN backup files!
========================================
RESTORE_EOF

      ui_print "  Restore instructions saved."
      ui_print ""
      ui_print "  !! IMPORTANT: Copy backup to PC/cloud !!"
      ui_print "  !! Factory reset will erase /sdcard    !!"
      ui_print ""
    fi
  fi
fi

##########################
# Signal Fix Setup
##########################

ui_print "[2/3] Signal Fix (by K58/Fly)"
ui_print "----------------------------------------"
ui_print "  Installing oplusstanvbk partition fix..."
ui_print "  Will be applied on next boot (post-fs-data)"
ui_print ""

##########################
# VoLTE & WiFi Calling
##########################

ui_print "[3/3] VoLTE & WiFi Calling (by symbuzzer)"
ui_print "----------------------------------------"
ui_print "  System properties will be applied on boot"
ui_print ""

##########################
# Finish
##########################

ui_print "============================================"
ui_print "  Installation complete!"
ui_print ""
ui_print "  > Signal Fix:    active after reboot"
ui_print "  > VoLTE/WiFi:    active after reboot"
ui_print "  > IMEI Backup:   check /sdcard/"
ui_print ""
ui_print "  OTA UPDATE: Press 'Action' button in"
ui_print "  module manager BEFORE rebooting after OTA!"
ui_print "============================================"
ui_print ""
