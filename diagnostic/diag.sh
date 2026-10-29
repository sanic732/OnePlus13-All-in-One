#!/system/bin/sh
# OnePlus 13 Diagnostic — collector (sourced by customize.sh and action.sh)
# Read-only: collects information, changes nothing.
# Long digit sequences (IMEI, IMSI, ICCID, phone numbers) are masked in the report.

DIAG_VER="v0.4"
BYNAME_DIR="/dev/block/bootdevice/by-name"
AIO_DIR="/data/adb/modules/oneplus13-all-in-one"

command -v ui_print >/dev/null 2>&1 || ui_print() { echo "$1"; }

# Output directory: /sdcard first, fallback to /data/media/0
DIAG_DIR=""
for D in /sdcard /data/media/0; do
  if touch "$D/.diag_test" 2>/dev/null; then
    rm -f "$D/.diag_test"
    DIAG_DIR="$D/OnePlus13_Diagnostic"
    break
  fi
done

if [ -n "$DIAG_DIR" ]; then
  mkdir -p "$DIAG_DIR"
  REPORT="${DIAG_DIR}/report_$(date +%Y%m%d_%H%M%S 2>/dev/null || echo latest).txt"
else
  REPORT="/dev/null"
fi

# Keep the first 4 digits of any run of 10+ digits
mask() { sed -E 's/([0-9]{4})[0-9]{6,}/\1******/g'; }

# Screen + file
log() {
  ui_print "$1"
  echo "$1" | mask >> "$REPORT" 2>/dev/null
}

# File only
log_file() { echo "$1" | mask >> "$REPORT" 2>/dev/null; }

# File only: command output, masked, indented, limited to $1 lines
dump() {
  LIMIT=$1; shift
  log_file "  \$ $*"
  "$@" 2>&1 | head -n "$LIMIT" | mask | sed 's/^/    /' >> "$REPORT" 2>/dev/null
  log_file ""
}

section() {
  log ""
  log "[$1] $2"
  log "----------------------------------------"
}

ui_print ""
ui_print "============================================"
ui_print "  OnePlus 13 Diagnostic $DIAG_VER"
ui_print "  Data Collection — NO modifications"
ui_print "============================================"
[ "$REPORT" = "/dev/null" ] && ui_print "! Storage not writable, screen output only"

log_file "============================================"
log_file "  OnePlus 13 Diagnostic Report $DIAG_VER"
log_file "  Generated: $(date)"
log_file "============================================"

##########################
# 1. Device Identity
##########################

section 1/10 "Device Identity"

PRJNAME=$(getprop ro.boot.prjname)
log "  Project:       $PRJNAME"
log "  Model:         $(getprop ro.product.model)"
log "  Device:        $(getprop ro.product.device)"
log "  SoC:           $(getprop ro.soc.model)"
log "  Android:       $(getprop ro.build.version.release) (SDK $(getprop ro.build.version.sdk))"
log "  Build:         $(getprop ro.build.display.id)"
log "  Security:      $(getprop ro.build.version.security_patch)"
log "  Baseband:      $(getprop gsm.version.baseband)"
log "  Region:        $(getprop persist.sys.oplus.region) (regionmark $(getprop ro.vendor.oplus.regionmark), my_region $(getprop ro.oplus.image.my_region.type), country $(getprop sys.region.switch.country))"
log_file "  Fingerprint:   $(getprop ro.build.fingerprint)"
log_file "  OTA version:   $(getprop ro.build.version.ota)"

if [ "$PRJNAME" = "23821" ]; then
  log "  >> OnePlus 13 CN hardware (23821)"
else
  log "  >> WARNING: Project $PRJNAME != 23821 (not CN hardware?)"
fi

log_file ""
log_file "  --- Region / carrier related properties ---"
getprop | grep -iE 'region|regionmark|euex|operator|nv_id|carrier|country|\.sku|hw_region' \
  | grep -viE 'gsm\.sim\.operator\.numeric$' | head -n 80 | while IFS= read -r line; do
  log_file "  $line"
done

##########################
# 2. Root & Modules
##########################

section 2/10 "Root Environment & Modules"

log "  Active slot:   $(getprop ro.boot.slot_suffix)"
if [ "$KSU" = "true" ]; then
  log "  Root:          KernelSU ${KSU_VER:-?} (${KSU_VER_CODE:-?}, kernel ${KSU_KERNEL_VER_CODE:-?})"
elif [ "$APATCH" = "true" ]; then
  log "  Root:          APatch ${APATCH_VER:-} ${APATCH_VER_CODE:-}"
elif [ -n "$MAGISK_VER" ]; then
  log "  Root:          Magisk $MAGISK_VER ($MAGISK_VER_CODE)"
else
  log "  Root:          Unknown"
fi
log "  Kernel:        $(uname -r 2>/dev/null)"
log "  SELinux:       $(getenforce 2>/dev/null)"

log ""
log "  Installed modules:"
VOLTE_MODS=0
for M in /data/adb/modules/*/; do
  [ -f "${M}module.prop" ] || continue
  ID=$(grep -m1 '^id=' "${M}module.prop" | cut -d= -f2-)
  NAME=$(grep -m1 '^name=' "${M}module.prop" | cut -d= -f2-)
  VER=$(grep -m1 '^version=' "${M}module.prop" | cut -d= -f2-)
  FLAGS=""
  [ -f "${M}disable" ] && FLAGS=" [DISABLED]"
  [ -f "${M}remove" ] && FLAGS="${FLAGS} [REMOVE]"
  log "    - $ID ($VER)$FLAGS"
  log_file "      $NAME"
  if [ -z "$FLAGS" ] && [ -f "${M}system.prop" ] && grep -q 'persist.dbg.volte_avail_ovr' "${M}system.prop"; then
    VOLTE_MODS=$((VOLTE_MODS + 1))
  fi
done
if [ "$VOLTE_MODS" -gt 1 ]; then
  log "  >> WARNING: $VOLTE_MODS active modules set VoLTE properties."
  log "  >> Keep only one (All-in-One already includes them)."
fi

##########################
# 3. Critical Partitions & Signal Fix
##########################

section 3/10 "IMEI Partitions & Signal Fix"

for PART in modemst1 modemst2 fsc fsg persist ocdt; do
  PART_PATH="${BYNAME_DIR}/${PART}"
  if [ -e "$PART_PATH" ]; then
    TARGET=$(readlink -f "$PART_PATH" 2>/dev/null)
    SIZE=$(blockdev --getsize64 "$TARGET" 2>/dev/null)
    log "  $PART: OK -> $TARGET (${SIZE:-?} bytes)"
  else
    log "  $PART: NOT FOUND"
  fi
done

log ""
SLOT=$(getprop ro.boot.slot_suffix)
for SL in _a _b; do
  TARGET=$(readlink "${BYNAME_DIR}/oplusstanvbk${SL}" 2>/dev/null)
  log "  oplusstanvbk${SL} -> ${TARGET:-NOT FOUND}"
done
case "$(readlink "${BYNAME_DIR}/oplusstanvbk${SLOT}" 2>/dev/null)" in
  *_mod) log "  >> Signal fix: ACTIVE on slot ${SLOT}" ;;
  *)     log "  >> Signal fix: NOT active on slot ${SLOT}" ;;
esac

if [ -f "${AIO_DIR}/post-fs-data.log" ]; then
  log_file ""
  log_file "  --- All-in-One post-fs-data.log ---"
  dump 40 cat "${AIO_DIR}/post-fs-data.log"
fi

##########################
# 4. Full Partition List
##########################

section 4/10 "All Partitions (by-name)"

if [ -d "$BYNAME_DIR" ]; then
  log "  Total partitions: $(ls -1 "$BYNAME_DIR" 2>/dev/null | wc -l) (full list in report)"
  dump 300 ls -la "$BYNAME_DIR"
else
  log "  $BYNAME_DIR NOT FOUND"
fi

##########################
# 5. Radio Properties
##########################

section 5/10 "Radio & IMS Properties"

for PROP in \
  persist.dbg.ims_volte_enable persist.dbg.volte_avail_ovr persist.dbg.vt_avail_ovr \
  persist.dbg.wfc_avail_ovr persist.radio.calls.on.ims persist.data.iwlan.enable \
  ro.vendor.oplus.radio.sar_regionmark ro.telephony.default_network \
  gsm.sim.state gsm.operator.alpha gsm.network.type; do
  VAL=$(getprop "$PROP")
  log "  $PROP = ${VAL:-(not set)}"
done

log_file ""
log_file "  --- All ims/volte/wfc/iwlan/radio/mbn properties ---"
getprop | grep -iE 'ims|volte|vowifi|wfc|iwlan|mbn|mcfg|radio|telephony|ril\.' | head -n 250 | while IFS= read -r line; do
  log_file "  $line"
done

##########################
# 6. IMEI & SIM
##########################

section 6/10 "IMEI & SIM"

# getDeviceId via service call; parcel text is split over several lines
read_imei() {
  service call iphonesubinfo "$1" s16 com.android.shell 2>/dev/null \
    | sed -n "s/.*'\(.*\)'.*/\1/p" | tr -d '. \n' | grep -oE '[0-9]{14,16}' | head -1
}
IMEI1=$(read_imei 1)
if [ -n "$IMEI1" ]; then
  log "  IMEI:          present (${IMEI1%??????????}**********)"
else
  log "  IMEI:          could not read via service call (check *#06#)"
fi

log "  SIM state:     $(getprop gsm.sim.state)"
log "  Operator:      $(getprop gsm.operator.alpha) ($(getprop gsm.operator.numeric))"
log "  SIM operator:  $(getprop gsm.sim.operator.alpha) ($(getprop gsm.sim.operator.numeric))"
log "  Network type:  $(getprop gsm.network.type)"

log ""
log "  Existing IMEI backups:"
FOUND_BACKUP=false
for BD in /sdcard/OnePlus13_IMEI_Backup /data/media/0/OnePlus13_IMEI_Backup; do
  [ -d "$BD" ] || continue
  for B in "$BD"/*/; do
    [ -d "$B" ] || continue
    FOUND_BACKUP=true
    log "    $B"
    for PART in modemst1 modemst2 fsc fsg persist ocdt; do
      if [ -s "${B}${PART}.img" ]; then
        log "      $PART.img: $(wc -c < "${B}${PART}.img") bytes"
      else
        log "      $PART.img: MISSING"
      fi
    done
  done
  break
done
$FOUND_BACKUP || log "    (none)"

##########################
# 7. IMS / VoLTE status
##########################

section 7/10 "IMS / VoLTE Status"

# Slots with a SIM
SIM_SLOTS=""
I=0
for ST in $(getprop gsm.sim.state | tr ',' ' '); do
  case "$ST" in ABSENT|NOT_READY|UNKNOWN|"") ;; *) SIM_SLOTS="$SIM_SLOTS $I" ;; esac
  I=$((I + 1))
done
[ -z "$SIM_SLOTS" ] && SIM_SLOTS=" 0"
log "  SIM slots checked:$SIM_SLOTS"

# Per-SIM carrier config values from dumpsys (cmd phone cc is denied even for root).
# Section "Default" = AOSP defaults; mConfigFromDefaultApp / CarrierApp / Override = real values for the SIM
CC_RE2='^(carrier_volte_available_bool|carrier_wfc_ims_available_bool|carrier_vt_available_bool|carrier_volte_provisioning_required_bool|hide_enhanced_4g_lte_bool|editable_enhanced_4g_lte_bool)$'
CC_DUMP=$(dumpsys carrier_config 2>/dev/null)

for S in $SIM_SLOTS; do
  log ""
  log "  Slot $S carrier config (non-default sections):"
  echo "$CC_DUMP" | awk -v ph="$S" -v re="$CC_RE2" '
    /Phone Id = / { p = $NF; next }
    /^ *(Default Values|mConfigFrom|mRusConfigs|mPersistentOverrideConfigs|mOverrideConfigs|mNoSimConfig)/ { sec = $1; next }
    p == ph && sec != "Default" && $1 ~ re && $2 == "=" { print sec ": " $1 " = " $3 }' \
    | while IFS= read -r line; do log "    $line"; done
  log_file ""
  dump 20 cmd phone ims get-ims-service -s "$S" -c
  dump 20 cmd phone ims get-ims-service -s "$S" -d
done

# APNs: IMS registration needs an APN of type "ims" for the SIM operator
SIM_NUMERIC=$(getprop gsm.sim.operator.numeric | cut -d, -f1)
if [ -n "$SIM_NUMERIC" ]; then
  APNS=$(content query --uri content://telephony/carriers --where "numeric='${SIM_NUMERIC}'" \
    --projection name:apn:type:protocol:roaming_protocol:carrier_enabled:edited_status 2>&1)
  log ""
  if echo "$APNS" | grep -qiE 'type=[^,]*ims'; then
    log "  APN of type ims for ${SIM_NUMERIC}: present"
  else
    log "  APN of type ims for ${SIM_NUMERIC}: NOT FOUND"
  fi
  log_file "  --- APNs for ${SIM_NUMERIC} ---"
  echo "$APNS" | head -n 40 | mask | sed 's/^/    /' >> "$REPORT" 2>/dev/null
  log_file ""
fi

log_file ""

log_file ""
log_file "  --- SIM info (VoLTE/VoWiFi user toggles) ---"
dump 20 content query --uri content://telephony/siminfo \
  --projection _id:sim_id:carrier_name:mcc_string:mnc_string:carrier_id:volte_vt_enabled:vt_ims_enabled:wfc_ims_enabled:wfc_ims_mode:wfc_ims_roaming_enabled

log_file "  --- Settings ---"
for NS in global system secure; do
  settings list "$NS" 2>/dev/null | grep -iE 'volte|vowifi|wfc|ims|enhanced_4g|4g_mode|preferred_network' | while IFS= read -r line; do
    log_file "    [$NS] $line"
  done
done
log_file ""

log_file "  --- telephony.registry (service state) ---"
dumpsys telephony.registry 2>/dev/null | grep -iE 'mServiceState|mVoiceRegState|mDataRegState|ims|volte|mCallState|mPhoneCapability' \
  | head -n 60 | mask | sed 's/^/    /' >> "$REPORT" 2>/dev/null
log_file ""

log_file "  --- telephony_ims (ImsResolver) ---"
dump 120 dumpsys telephony_ims

# The dump starts with the AOSP default values; section headers (lines without "=")
# show which values are defaults and which are the per-SIM configs / overrides
log_file "  --- carrier_config (key VoLTE values per section) ---"
CC_RE='carrier_volte_available_bool|carrier_wfc_ims_available_bool|carrier_vt_available_bool|carrier_volte_provisioning_required_bool|hide_enhanced_4g_lte_bool|editable_enhanced_4g_lte_bool|carrier_config_version_string'
dumpsys carrier_config 2>/dev/null | grep -nE "(${CC_RE}) =|[Pp]hone ?[Ii]d|^[^=]{3,100}$" \
  | head -n 250 | mask | sed 's/^/    /' >> "$REPORT" 2>/dev/null
log_file ""

##########################
# 8. IMS packages
##########################

section 8/10 "IMS / VoWiFi Packages"

INSTALLED=$(pm list packages 2>/dev/null)
DISABLED=$(pm list packages -d 2>/dev/null)
for PKG in org.codeaurora.ims vendor.qti.iwlan com.qualcomm.qti.cne com.android.phone; do
  if ! echo "$INSTALLED" | grep -qx "package:$PKG"; then
    log "  [--] $PKG not installed"
  elif echo "$DISABLED" | grep -qx "package:$PKG"; then
    log "  [!!] $PKG DISABLED"
  else
    log "  [OK] $PKG"
  fi
done

log_file ""
log_file "  --- All disabled packages related to telephony ---"
echo "$DISABLED" | grep -iE 'ims|iwlan|cne|qti|qualcomm|telephony|phone|radio|carrier|oplus\.(sim|telephony|network)' \
  | sed 's/^/    /' >> "$REPORT" 2>/dev/null
log_file ""

# In-call UI reads the wallpaper; with READ_MEDIA_IMAGES set to "ignore" it crashes ("Phone has stopped")
INCALL_OP=$(appops get com.android.incallui READ_MEDIA_IMAGES 2>/dev/null | head -n 1)
log "  com.android.incallui ${INCALL_OP:-READ_MEDIA_IMAGES: ?}"

if [ -f "${AIO_DIR}/ims-check.log" ]; then
  log_file "  --- All-in-One ims-check.log ---"
  dump 20 cat "${AIO_DIR}/ims-check.log"
fi

##########################
# 9. Modem MBN profiles
##########################

section 9/10 "Modem MBN Profiles"

MCFG_DIR=""
for D in /vendor/firmware_mnt/image/modem_pr/mcfg/configs/mcfg_sw \
         /vendor/rfs/msm/mpss/readonly/vendor/mbn/mcfg_sw \
         /mnt/vendor/firmware_mnt/image/modem_pr/mcfg/configs/mcfg_sw; do
  [ -d "$D" ] && { MCFG_DIR="$D"; break; }
done

if [ -n "$MCFG_DIR" ]; then
  MBN_COUNT=$(find "$MCFG_DIR" -name '*.mbn' 2>/dev/null | wc -l)
  log "  MBN directory: $MCFG_DIR"
  log "  Total MBN profiles: $MBN_COUNT"
  find "$MCFG_DIR" -name '*.mbn' 2>/dev/null | grep -iE 'ukr|vodafone|kyivstar|lifecell|/eu/|europe' | head -n 20 | while IFS= read -r f; do
    log "    ${f#$MCFG_DIR/}"
  done
  log_file ""
  log_file "  --- Full MBN list ---"
  find "$MCFG_DIR" -name '*.mbn' 2>/dev/null | sed "s|^$MCFG_DIR/|    |" | head -n 600 >> "$REPORT" 2>/dev/null
else
  log "  mcfg_sw directory not found"
  dump 30 ls -la /vendor/firmware_mnt/image
fi

##########################
# 10. Crashes
##########################

section 10/10 "Crash Logs"

DROPBOX_LIST=$(dumpsys dropbox 2>/dev/null | grep -E 'app_crash|app_anr|native_crash|TOMBSTONE|system_server_crash|wtf' | tail -n 60)
log "  Dropbox crash/ANR entries (last 60): $(echo "$DROPBOX_LIST" | grep -c .)"

log_file ""
log_file "  --- Dropbox entries (time + tag) ---"
echo "$DROPBOX_LIST" | mask | sed 's/^/    /' >> "$REPORT" 2>/dev/null
log_file ""

# Every crash/ANR entry: time + process on screen, first lines of each entry in the file
for TAG in system_app_crash data_app_crash system_app_anr data_app_anr system_app_native_crash data_app_native_crash; do
  ENTRIES=$(dumpsys dropbox --print "$TAG" 2>/dev/null)
  [ -n "$ENTRIES" ] || continue
  echo "$ENTRIES" | grep -E "^[0-9]{4}-[0-9]{2}-[0-9]{2} .*${TAG}|^Process: " | tail -n 20 \
    | while IFS= read -r line; do log "    $line"; done
  log_file "  --- dropbox $TAG ---"
  echo "$ENTRIES" | awk '/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] / { n = 0 } { if (n++ < 30) print }' \
    | tail -n 300 | mask | sed 's/^/    /' >> "$REPORT" 2>/dev/null
  log_file ""
done

log_file "  --- logcat crash buffer ---"
dump 400 logcat -b crash -d

log_file "  --- logcat (radio/IMS errors, current buffer) ---"
logcat -d -b main,system,radio -v time '*:E' 2>/dev/null | grep -iE 'ims|volte|telephony|ril|phone' \
  | tail -n 200 | mask | sed 's/^/    /' >> "$REPORT" 2>/dev/null

##########################
# Summary
##########################

log ""
log "============================================"
log "  Diagnostic complete!"
if [ "$REPORT" != "/dev/null" ]; then
  log "  Report: $REPORT"
  log "  IMEI/IMSI/numbers are masked."
  log "  Send this file for analysis."
fi
log "============================================"
