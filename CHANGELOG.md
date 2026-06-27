# Changelog

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
