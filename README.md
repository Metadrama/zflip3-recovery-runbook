# Samsung Galaxy Z Flip 3 SM-F711B headless recovery runbook

Device: Samsung Galaxy Z Flip 3 SM-F711B, codename b2q.

Required starting state: the bootloader is unlocked. If the bootloader is locked, stop. This TWRP/Magisk path requires an unlocked bootloader.

Mission: turn the damaged-screen Z Flip 3 into a 24/7 headless server. The recovery path gets Android booted with authorized ADB, skips setup blockers, and prepares the device for first-class agentic framework support through Hermes, OpenClaw, or both.

Main rule: keep the operational guide linear and concise. Put explanations in the numbered appendices only.

1. Confirm the device is the Samsung Galaxy Z Flip 3 SM-F711B.
2. Confirm the bootloader is unlocked.
3. Confirm the PC has Odin, Samsung USB drivers, ADB, the stock firmware package, TWRP, multidisabler carrier package, and this repo.
4. Build the TWRP-flashable Magisk module zips from this repo:

```bash
./tools/build-flashable-modules.sh
```

5. Connect the phone to the PC by USB.
6. Force the phone off by holding Vol Down + Power until it restarts or blanks.
7. Enter Download Mode using the blind-safe method: hold Vol Up + Vol Down together, plug in USB while holding both, then release after the device is detected by Odin.
8. In Odin, flash the stock Samsung firmware first. Use HOME_CSC to preserve data; use CSC only when a wipe is intentional. [*1]
9. Keep Auto Reboot unticked for the stock firmware flash.
10. When Odin finishes, return to Download Mode again. Do not let normal Android boot yet.
11. In Odin, flash TWRP in AP and the multidisabler carrier package in USERDATA.
12. For this runbook, leave Auto Reboot ticked for this handoff.
13. On Odin PASS, immediately hold Power + Vol Up for about 15 seconds to force the phone into TWRP.
14. This first TWRP boot is for multidisabler and format data.
15. On the PC, confirm TWRP ADB is alive:

```bash
adb devices
```

16. The phone must show as recovery.
17. Run multidisabler from the recovery-side path being used.
18. If the first multidisabler pass touched partitioning, exited early, or looked incomplete, run multidisabler a second time.
19. Format /data through ADB, not through the broken-screen UI:

```bash
adb shell twrp format data
```

20. If the phone auto-reboots after format data, immediately hold Power + Vol Up again to return to TWRP.
21. If it does not auto-reboot, reboot back to recovery:

```bash
adb reboot recovery
```

22. This is the second TWRP boot.
23. On the second TWRP boot, confirm /data is mounted:

```bash
adb shell twrp mount data
adb shell ls -ld /data /data/adb /data/misc/adb
```

24. Install or restore Magisk now if Magisk is not already present in the boot image.
25. Authorize the current PC's ADB key from TWRP before the final Android boot. [*2]
26. Push the PC public ADB key to TWRP:

```bash
adb push ~/.android/adbkey.pub /tmp/adbkey.pub
```

27. Install the key into Android's trusted ADB key file:

```bash
adb shell 'mkdir -p /data/misc/adb && cat /tmp/adbkey.pub > /data/misc/adb/adb_keys && chown 1000:2000 /data/misc/adb/adb_keys && chmod 0644 /data/misc/adb/adb_keys && (restorecon /data/misc/adb/adb_keys 2>/dev/null || true)'
```

28. Push the force-ADB module zip:

```bash
adb push dist/force-adb-twrp.zip /tmp/force-adb-twrp.zip
```

29. Flash the force-ADB module zip in TWRP:

```bash
adb shell twrp install /tmp/force-adb-twrp.zip
```

30. Push the setup-wizard-disabler module zip:

```bash
adb push dist/disable-setup-wizard-twrp.zip /tmp/disable-setup-wizard-twrp.zip
```

31. Flash the setup-wizard-disabler module zip in TWRP:

```bash
adb shell twrp install /tmp/disable-setup-wizard-twrp.zip
```

32. Verify both Magisk module folders exist:

```bash
adb shell ls -la /data/adb/modules/force-adb /data/adb/modules/disable-setup-wizard
```

33. If TWRP was only temporary, restore stock recovery now.
34. Reboot into Android:

```bash
adb reboot
```

35. On the PC, restart ADB cleanly:

```bash
adb kill-server
adb start-server
adb devices -l
```

36. The phone must show as device. It must not show as recovery, offline, or unauthorized.
37. Verify ADB enablement:

```bash
adb shell settings get global adb_enabled
adb shell getprop persist.sys.usb.config
```

38. The expected result is adb_enabled=1 and a USB config containing adb.
39. Verify setup wizard is not blocking control:

```bash
adb shell settings get global device_provisioned
adb shell settings get secure user_setup_complete
```

40. The expected result is device_provisioned=1 and user_setup_complete=1.
41. If ADB shows unauthorized, return to TWRP and fix /data/misc/adb/adb_keys. Do not waste time trying to tap the hidden authorization prompt on the damaged screen.
42. Push the persistent root SSH module (MagiskSSH) to the phone:

```bash
adb push dist/magisk_ssh_v0.24.zip /data/local/tmp/magisk_ssh.zip
```

43. Install the module via Magisk CLI:

```bash
adb shell "su -c 'magisk --install-module /data/local/tmp/magisk_ssh.zip'"
```

44. Configure authorized SSH public keys for the root and shell users to prevent lockouts:

```bash
# Push your PC's public key (e.g. tunnel_key.pub) to the phone
adb push ~/.ssh/tunnel_key.pub /data/local/tmp/authorized_keys

# Copy to root and shell home directories, set strict ownership/permissions, and cleanup temp file
adb shell "su -c 'cat /data/local/tmp/authorized_keys > /data/ssh/root/.ssh/authorized_keys && cat /data/local/tmp/authorized_keys > /data/ssh/shell/.ssh/authorized_keys && chown -R 0:0 /data/ssh/root && chmod 700 /data/ssh/root/.ssh && chmod 600 /data/ssh/root/.ssh/authorized_keys && chown -R 2000:2000 /data/ssh/shell && chmod 700 /data/ssh/shell/.ssh && chmod 600 /data/ssh/shell/.ssh/authorized_keys && rm -f /data/local/tmp/authorized_keys'"
```

45. Reboot the phone to start the native SSH daemon:

```bash
adb reboot
```

46. Connect to the device as root using your private key:

```bash
ssh -i ~/.ssh/tunnel_key root@<device_ip>
```

47. Push the permissive SELinux and Gemini/Antigravity CLI systemless support modules to the phone:

```bash
# Push the SELinux permissive module
adb push dist/selinux-permissive-twrp.zip /data/local/tmp/selinux-permissive.zip

# Push the Gemini/Antigravity CLI systemless support module
adb push dist/gemini-cli-twrp.zip /data/local/tmp/gemini-cli.zip
```

48. Install both modules systemlessly via Magisk CLI:

```bash
# Install SELinux Permissive Boot
adb shell "su -c 'magisk --install-module /data/local/tmp/selinux-permissive.zip'"

# Install Gemini/Antigravity CLI Support
adb shell "su -c 'magisk --install-module /data/local/tmp/gemini-cli.zip'"
```

49. Launch Termux to unpack the bootstrap Linux environment in the background:

```bash
adb shell "am start -n com.termux/.app.TermuxActivity"
```

50. Perform a privileged Termux environment installation of Node.js, NPM, and the AI CLIs (either Gemini or Antigravity):

```bash
# Install nodejs, npm, and required dynamic link libraries offline
# (Push the offline package bundle from the repository dist/offline-nodejs/ first)
adb push dist/offline-nodejs /data/local/tmp/offline-nodejs
adb shell "su -c 'chmod -R 777 /data/local/tmp/offline-nodejs'"
adb shell "su u0_a315 -c 'env PATH=/data/data/com.termux/files/usr/bin LD_LIBRARY_PATH=/data/data/com.termux/files/usr/lib HOME=/data/data/com.termux/files/home dpkg -i /data/local/tmp/offline-nodejs/c-ares_1.34.6_aarch64.deb /data/local/tmp/offline-nodejs/libffi_3.5.2_aarch64.deb /data/local/tmp/offline-nodejs/libicu_78.3_aarch64.deb /data/local/tmp/offline-nodejs/libsqlite_3.53.1_aarch64.deb /data/local/tmp/offline-nodejs/openssl_3.6.2_aarch64.deb /data/local/tmp/offline-nodejs/nodejs_26.2.0_aarch64.deb /data/local/tmp/offline-nodejs/npm_11.15.0_all.deb'"

# Install Gemini CLI (Legacy - pre June 18th)
adb shell "su u0_a315 -c 'env PATH=/data/data/com.termux/files/usr/bin LD_LIBRARY_PATH=/data/data/com.termux/files/usr/lib HOME=/data/data/com.termux/files/home npm install -g @google/gemini-cli --ignore-scripts'"

# Install Antigravity CLI (Modern - post June 18th)
adb shell "su u0_a315 -c 'env PATH=/data/data/com.termux/files/usr/bin LD_LIBRARY_PATH=/data/data/com.termux/files/usr/lib HOME=/data/data/com.termux/files/home npm install -g @google/antigravity-cli --ignore-scripts'"
```

50.5. Deploy the robust dynamic DNS and safe auto-update wrappers from this repository to the phone:

```powershell
# From the root of this repository on your PC, run the tracked deployment helper:
.\tools\deploy-termux-bin.ps1
```

51. Reboot the device to activate the Magisk systemless overlays:

```bash
adb reboot
```

52. Log in via SSH and run either `gemini` or `antigravity` with full root autonomy from anywhere:

```bash
# Verify Gemini CLI
gemini --help

# Verify Antigravity CLI
antigravity --help
```

53. Once the AI infrastructure is authorized, continue the headless-server build: Tailscale, Termux or Debian chroot, Hermes/OpenClaw runtime, boot persistence, power management, and health checks.

## Appendices

[*1] CSC choice is destructive. HOME_CSC preserves /data. CSC wipes /data. Use CSC only when the wipe is part of the plan.

[*2] ADB authorization is not the same thing as enabling ADB. The Magisk module can force ADB settings, but Android still needs the PC's public key in /data/misc/adb/adb_keys. The second TWRP boot is the right point to install that key because /data has just been formatted and mounted, and Android has not booted far enough to lock us out again. On Windows, push the key with this command instead:

```bat
adb push %USERPROFILE%\.android\adbkey.pub /tmp/adbkey.pub
```

[*3] The TWRP-flashable module zips in this repo are recovery installers. They stage Magisk modules into /data/adb/modules/<module-id>. They do not depend on the Android package manager while in recovery. Any package disabling happens later from the module's service.sh after Android boots.

[*4] The modules are intentionally separate. force-adb owns ADB and USB-debugging state. disable-setup-wizard owns provisioning flags and setup wizard package disabling. Keeping them separate makes failures easier to isolate.

[*5] It is valid to study the phone through the PC. SSH into the PC, run adb there, inspect device state, pull logs, and patch files through TWRP when the phone is connected.

[*6] The long-term target is not just boot recovery. The target is a reliable 24/7 damaged-screen Z Flip 3 server with first-class agentic runtime support, including Hermes and/or OpenClaw.
