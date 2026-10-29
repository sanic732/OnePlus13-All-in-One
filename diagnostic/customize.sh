#!/system/bin/sh
# OnePlus 13 Diagnostic Module — install script
# Runs the collector once at install. Press "Action" later to collect a new report.
# Does NOT modify any partitions or system files.

. "$MODPATH/diag.sh"

ui_print ""
ui_print "  The module does nothing at boot."
ui_print "  Press 'Action' to create a new report,"
ui_print "  e.g. right after an error appears."
ui_print ""
