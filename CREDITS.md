# Credits & Attribution

This module is a combined derivative work incorporating code from multiple
open-source projects. All original licenses and copyrights are preserved.

## Signal Fix for OnePlus 13

- **Original project:** [K58/fix-signal-oneplus13](https://github.com/K58/fix-signal-oneplus13)
- **Author:** K58 (Fly)
- **License:** GNU General Public License v3.0 (GPLv3)
- **Contributors:** @koaaN (XDA), @docnok63 (XDA), rapperskull (GitHub)
- **Files used:** `post-fs-data.sh`, `action.sh`, `system.prop` (ro.vendor.oplus.radio.sar_regionmark),
  `customize.sh` (device check logic), `nvbk/oplusstanvbk.img`
- **Note:** `post-fs-data.sh` is licensed under Apache-2.0 as specified by rapperskull.
  `nvbk/` folder contains proprietary files NOT covered by GPLv3.

## VoLTE & WiFi Calling Enabler

- **Original project:** [symbuzzer/Volte-Wifi-Calling-Enabler](https://github.com/symbuzzer/Volte-Wifi-Calling-Enabler)
- **Author:** Ali Beyaz (symbuzzer) — [avalibeyaz.com](https://avalibeyaz.com)
- **License:** GNU General Public License v3.0 (GPLv3)
- **Files used:** `system.prop` (VoLTE/WiFi calling properties)
- **Community fix:** WhiteCrow ([4PDA profile](https://4pda.to/forum/index.php?showuser=407801)) —
  identified that `org.codeaurora.ims`, `vendor.qti.iwlan` and `com.qualcomm.qti.cne` may be
  disabled after Android 15→16 upgrade, causing VoLTE/VoWiFi failure on OnePlus 13 (Kyivstar).
  Auto-enable check added to `customize.sh` based on his findings.

## IMEI Backup

- **Author:** Sanic27
- **Based on:** Community guides from 4PDA (vadimka-85) and
  [DroidWin](https://droidwin.com/which-partition-does-oneplus-store-imei-number/)
- **License:** GNU General Public License v3.0 (GPLv3)
- **Note:** Complete rewrite for Qualcomm Snapdragon 8 Elite (SM8750) platform.
  Original MTK-based IMEI backup module was incompatible with OnePlus 13.

## Combined Module

- **Author:** Sanic27 (https://github.com/sanic732)
- **License:** GNU General Public License v3.0 (GPLv3)
- **This is a derivative work (fork) combining the above projects.**
  As required by GPLv3, the complete source code is available, and all
  original copyright notices and licenses are preserved.
