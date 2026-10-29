# OnePlus 13 Diagnostic (Data Collector)

Read-only KernelSU / Magisk / APatch module. It changes nothing on the device.

- At install it creates a report in `/sdcard/OnePlus13_Diagnostic/`.
- Press **Action** in the root manager to create a new report at any time —
  best right after a problem appears (e.g. "Phone has stopped"), while the logs still contain it.
- IMEI, IMSI, ICCID and phone numbers are masked in the report.

Build the zip with `./build.sh` in the repository root.
