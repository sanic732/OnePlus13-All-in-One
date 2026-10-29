#!/system/bin/sh
# OnePlus 13 Diagnostic Module — Action: collect a new report

MODDIR=${0%/*}
. "$MODDIR/diag.sh"

# APatch and KernelSU close the output window immediately
if [ -z "$MMRL" ] && [ -z "$KSU_NEXT" ] && { [ "$KSU" = "true" ] || [ "$APATCH" = "true" ]; }; then
  sleep 6
fi
