#!/system/bin/sh
# OnePlus 13 All-in-One Module — service script
#
# IMS / VoWiFi package check on every boot.
# Packages may be disabled again by an OTA (Android 15->16) or by the ROM,
# so the install-time check alone is not enough.
# Root cause identified by WhiteCrow (4PDA): https://4pda.to/forum/index.php?showuser=407801
# License: GPLv3

MODDIR=${0%/*}
LOGFILE="${MODDIR}/ims-check.log"

# Wait for the package manager to be ready
until [ "$(getprop sys.boot_completed)" = "1" ]; do
  sleep 5
done
sleep 10

exec > "$LOGFILE" 2>&1

echo "=== OnePlus 13 All-in-One: IMS package check ==="
date

DISABLED=$(pm list packages -d 2>/dev/null)
INSTALLED=$(pm list packages 2>/dev/null)

for PKG in org.codeaurora.ims vendor.qti.iwlan com.qualcomm.qti.cne; do
  if ! echo "$INSTALLED" | grep -qx "package:$PKG"; then
    echo "[--] $PKG is not installed"
  elif echo "$DISABLED" | grep -qx "package:$PKG"; then
    echo "[!] $PKG is DISABLED — enabling..."
    pm enable --user 0 "$PKG"
  else
    echo "[OK] $PKG is enabled"
  fi
done
