# Changelog

## v1.2 (2026-10-29)
- IMS package check now also runs **on every boot** (`service.sh`), log: `ims-check.log` in the module folder.
  Packages disabled again by an OTA are re-enabled without reinstalling the module
- IMS check: exact package name match (`grep -x`), packages that are not installed are reported as such instead of "enabled"
- IMEI backup: an existing backup counts as complete only if **every** partition present on the device
  (modemst1, modemst2, fsc, fsg, persist, ocdt) has a non-empty image. Before, a backup with only
  modemst1/modemst2 was treated as complete and no new backup was made
- IMEI backup: `dd` output is saved to `backup.log` in the backup folder instead of being discarded
- README: bootloader relock warnings and `dtbo` note (adapted from K58), VoLTE/calls troubleshooting section
- `post-fs-data.sh`: restored rapperskull's comment about the loop device naming
- Diagnostic module source added to `diagnostic/` (v0.2), `build.sh` builds both zips

## v1.1 (2026-06-27)
- IMS & VoWiFi package health check added to installation (`customize.sh`)
- Auto-enables `org.codeaurora.ims`, `vendor.qti.iwlan`, `com.qualcomm.qti.cne` if disabled
- Fixes VoLTE/VoWiFi not working after Android 15→16 upgrade (root cause: disabled system packages)
- Thanks to **WhiteCrow** ([4PDA](https://4pda.to/forum/index.php?showuser=407801)) for identifying the issue
- Step counter updated: 4 steps at install instead of 3
- Version bump to v1.1 in UI print

## v1.0 (2026-04-06)
- Initial release
- Signal Fix for OnePlus 13 CN on OxygenOS 15/16 (based on [K58/fix-signal-oneplus13](https://github.com/K58/fix-signal-oneplus13))
- VoLTE & WiFi Calling Enabler (based on [symbuzzer/Volte-Wifi-Calling-Enabler](https://github.com/symbuzzer/Volte-Wifi-Calling-Enabler))
- IMEI Backup: automatic backup of modemst1, modemst2, fsc, fsg, persist, ocdt at install
- Duplicate backup prevention on reinstall
- Bootloop fix action script for OTA updates (press "Action" before reboot)
- KernelSU Manager WebUI
- Full GPLv3 compliance and attribution
