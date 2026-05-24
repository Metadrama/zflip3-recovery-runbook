# Z Flip 3 recovery runbook

This repo is a practical recovery runbook for the damaged-screen Samsung Z Flip 3 path: stock firmware, temporary TWRP, multidisabler, data format, Magisk, and a boot-time force-ADB module.

The flow is intentionally linear. Do not treat this as a generic Android rooting guide. It is written for the specific broken-UI/headless-control situation where recovery, download mode, Odin, ADB, and file-based operations are more reliable than tapping through Android.

1. Connect the USB cable.
2. Hold Vol Down + Power until the phone shuts off.
3. Immediately hold Vol Up + Vol Down.
4. When the teal warning appears on the cover screen, press Vol Up to enter Download Mode.
5. In Odin, flash the stock Samsung firmware first.
6. Keep Auto Reboot unticked for that first clean flash.
7. When Odin finishes, go back into Download Mode again instead of letting normal Android boot.
8. In Odin this time, flash TWRP in AP and the multidisabler carrier package in USERDATA.
9. If that is the path that reliably lands on this device, leave Auto Reboot ticked for this handoff; on PASS, immediately hold Power + Vol Up for about 15 seconds to force the phone into TWRP.
10. This first TWRP boot is only for multidisabler plus format data.
11. On the PC, confirm TWRP ADB is alive:

```bash
adb devices
```

12. The phone should show as recovery.
13. Run multidisabler from the recovery-side path you are using.
14. If the first multidisabler pass may have stopped early during partition work, run it a second time.
15. Format /data without using the broken screen. Use the recovery-side command path instead of the UI prompt:

```bash
adb shell twrp format data
```

16. If the phone auto-reboots after format data, immediately hold Power + Vol Up again to get back into TWRP.
17. If it does not auto-reboot, reboot back to recovery:

```bash
adb reboot recovery
```

18. That puts you on the second TWRP boot.
19. On this second TWRP boot, install or restore Magisk if needed.
20. Still on this second TWRP boot, stage the force-adb Magisk module into:

```text
/data/adb/modules/force-adb/
```

21. That module is one module, and it does both jobs: forces ADB / USB-debugging state on boot, and disables the Samsung/Google setup wizard packages on boot.
22. The module should contain module.prop and service.sh.
23. Make sure service.sh is executable.
24. If TWRP was only temporary, restore stock recovery now.
25. Reboot into normal Android.
26. On the PC, verify:

```bash
adb devices -l
```

27. The phone should show as device, not recovery and not unauthorized.
28. Also check:

```bash
adb shell settings get global adb_enabled
adb shell getprop persist.sys.usb.config
```

29. The expected result is adb_enabled=1 and a USB config that includes adb.
30. If ADB comes up but later drops, first check whether /data/misc/adb/adb_keys still contains the current host key.
