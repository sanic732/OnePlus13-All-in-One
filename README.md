# OnePlus 13 All-in-One KernelSU/Magisk Module

Combined module for **OnePlus 13 CN** (project code 23821) that includes:
1. **Signal Fix** — fixes signal issues on OxygenOS 15/16
2. **VoLTE & WiFi Calling** — enables VoLTE, VoWiFi, VT, RCS
3. **IMEI Backup** — automatic backup of critical Qualcomm modem partitions

> This is a derivative work combining several open-source projects.
> All original licenses and copyrights are preserved as required by GPLv3.

## Requirements

- OnePlus 13 CN (23821) only
- Root: KernelSU / KernelSU Next / Magisk v20.4+ / APatch
- OxygenOS 15 or 16

## Installation

1. Download the latest ZIP from [Releases](https://github.com/sanic732/OnePlus13-All-in-One/releases)
2. Install via your root manager (KernelSU Manager / Magisk / MMRL)
3. During installation, IMEI partitions will be backed up automatically
4. Reboot

## What Gets Backed Up (IMEI)

The module backs up these Qualcomm partitions to `/sdcard/OnePlus13_IMEI_Backup/`:

| Partition | Purpose |
|-----------|---------|
| `modemst1` | Primary IMEI/NV storage |
| `modemst2` | Backup IMEI storage |
| `fsc` | File System Cache (modem metadata) |
| `fsg` | File System Group (modem NV config) |
| `persist` | Device calibration & identifiers |
| `ocdt` | Device configuration/identifiers |

**IMPORTANT:** Copy the backup folder to your PC or cloud storage immediately!
A factory reset will erase `/sdcard/`.

On reinstall the module detects existing backups and skips duplicate creation.

## Restoring IMEI (if needed)

### Method 1: Fastboot (recommended)
```
adb reboot fastboot
fastboot flash modemst1 modemst1.img
fastboot flash modemst2 modemst2.img
fastboot flash fsc fsc.img
fastboot flash fsg fsg.img
fastboot flash persist persist.img
fastboot flash ocdt ocdt.img
fastboot reboot
```

### Method 2: Root shell (dd)
```
su -c dd if=/path/to/modemst1.img of=/dev/block/bootdevice/by-name/modemst1
su -c dd if=/path/to/modemst2.img of=/dev/block/bootdevice/by-name/modemst2
su -c dd if=/path/to/fsc.img of=/dev/block/bootdevice/by-name/fsc
su -c dd if=/path/to/fsg.img of=/dev/block/bootdevice/by-name/fsg
su -c dd if=/path/to/persist.img of=/dev/block/bootdevice/by-name/persist
su -c dd if=/path/to/ocdt.img of=/dev/block/bootdevice/by-name/ocdt
```

## OTA Update (Bootloop Fix)

When updating OxygenOS via OTA:
1. Download and install the OTA update (**DO NOT** reboot yet)
2. Open your root manager
3. Press the **"Action"** button on this module
4. Install root to Inactive Slot
5. Then reboot

> **Note:** OxygenOS 16 (kernel 6.6.89+) does not require DTBO patching —
> the script detects this automatically.

## Warnings

- **DO NOT** install this module on devices other than OnePlus 13 CN
- **DO NOT** lock the bootloader with this module installed
- **DO NOT** downgrade from OxygenOS 16.0.3.50x or higher — anti-rollback will **hard brick** your device
- **DO NOT** restore IMEI backups from a different device

## Based On

This module is a combined fork of the following projects:

| Component | Author | License | Original Repository |
|-----------|--------|---------|---------------------|
| Signal Fix | K58 (Fly) | GPLv3 | [K58/fix-signal-oneplus13](https://github.com/K58/fix-signal-oneplus13) |
| Signal Fix (post-fs-data) | rapperskull | Apache-2.0 | [K58/fix-signal-oneplus13](https://github.com/K58/fix-signal-oneplus13) |
| VoLTE/WiFi Calling | Ali Beyaz (symbuzzer) | GPLv3 | [symbuzzer/Volte-Wifi-Calling-Enabler](https://github.com/symbuzzer/Volte-Wifi-Calling-Enabler) |
| IMEI Backup | [Sanic732](https://github.com/sanic732) | GPLv3 | This project |

### Thanks

- **@koaaN** (XDA Forums) — contribution to signal fix
- **@docnok63** (XDA Forums) — contribution to signal fix
- **[vadimka-85](https://4pda.to/forum/index.php?showuser=1435250)** (4PDA) — guide ["Резервное копирование критических разделов"](https://4pda.to/forum/index.php?showtopic=1096928&view=findpost&p=135328236)
- **[DroidWin](https://droidwin.com/which-partition-does-oneplus-store-imei-number/)** — IMEI partition research

## License

This project is licensed under **GNU General Public License v3.0** — see [LICENSE](LICENSE) for details.

Full attribution is available in [CREDITS.md](CREDITS.md).

`nvbk/` folder may contain proprietary files NOT covered by GPLv3.

---

4PDA: [Sanic27](https://4pda.to/forum/index.php?showuser=1382159)
