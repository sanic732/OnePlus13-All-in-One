# Changelog — OnePlus 13 Diagnostic

### v0.5-diag (2026-10-29)
- APN check fixed: a filtered `content query --where numeric=...` returns no rows on OxygenOS,
  so the whole APN table is read and filtered in the script; preferred APN added.
  "could not read" is reported instead of a false "NOT FOUND" when the table is not readable

### v0.4-diag (2026-10-29)
- Per-SIM carrier config values (VoLTE / VoWiFi / VT available) parsed from `dumpsys carrier_config`
  and shown on screen; removed `cmd phone cc get-value` (denied even for root) and the empty `dumpsys phone` check
- APN check: is there an APN of type `ims` for the SIM operator; all APNs of the operator in the report
- `com.android.incallui` READ_MEDIA_IMAGES app-op: "ignore" makes the in-call UI crash
  ("Phone has stopped") when it reads the wallpaper

### v0.3-diag (2026-10-29)
- Crash logs: **every** dropbox crash/ANR entry is shown (time + process on screen, first 30 lines in the report).
  v0.2 only showed phone/IMS processes and missed the daily `data_app_crash` at 00:00
- IMS registration state from `dumpsys phone` on screen
- carrier config: only the key VoLTE values, with section headers, so AOSP defaults
  can be told apart from the per-SIM config (v0.2 showed only the default values)
- Raw output of `cmd phone cc get-value` and `cmd phone ims get-ims-service -c/-d` in the report
- Region line on screen (`persist.sys.oplus.region`, regionmark, my_region, country)

### v0.2-diag (2026-10-29)
- **Action button**: create a new report at any time (e.g. right after a "Phone has stopped" error)
- New: IMS / VoLTE status — carrier config keys per SIM slot, `cmd phone ims`, SIM VoLTE/VoWiFi toggles, telephony registry, ImsResolver
- New: IMS packages state (`org.codeaurora.ims`, `vendor.qti.iwlan`, `com.qualcomm.qti.cne`, `com.android.phone`) and All-in-One `ims-check.log`
- New: modem MBN profile list (looks for Ukraine / Vodafone / EU profiles)
- New: crash logs — dropbox `system_app_crash` / ANR for phone/IMS processes and `logcat -b crash`
- New: installed modules list, warning if several modules set VoLTE properties
- New: region / carrier properties, all ims/radio/mbn properties
- Signal fix status: shows whether `oplusstanvbk` of the active slot points to the `_mod` loop device, includes All-in-One `post-fs-data.log`
- IMEI backups: per-partition sizes, MISSING marked
- Fixed: KernelSU version was empty; IMEI could not be read (multi-line parcel parsing)
- Removed misleading `oplusstanvbk: NOT FOUND` (the partition only exists per slot)
- IMEI, IMSI, ICCID and phone numbers are masked in the report

### v0.1-diag (2026-04-06)
- Initial diagnostic release
