#!/system/bin/sh

# Boot-time recovery helper for damaged-screen/headless Android access.
# Intended to run as a Magisk service script from /data/adb/modules/force-adb/service.sh.

MODDIR=${0%/*}
LOG="$MODDIR/service.log"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"
}

log "force-adb service starting"

# Wait for Android userspace to settle enough for settings/pm commands.
for i in $(seq 1 60); do
  BOOT_COMPLETED=$(getprop sys.boot_completed 2>/dev/null)
  [ "$BOOT_COMPLETED" = "1" ] && break
  sleep 2
done

# Force ADB-related settings. Some keys may not exist on every build; failures are non-fatal.
settings put global adb_enabled 1 2>>"$LOG"
settings put secure adb_enabled 1 2>>"$LOG"
setprop persist.sys.usb.config mtp,adb 2>>"$LOG"
setprop sys.usb.config mtp,adb 2>>"$LOG"

# Disable setup wizard packages that can block headless access.
for pkg in \
  com.google.android.setupwizard \
  com.sec.android.app.SecSetupWizard \
  com.samsung.android.app.setupwizard \
  com.samsung.android.oneconnect \
  com.android.provision; do
  if pm path "$pkg" >/dev/null 2>&1; then
    pm disable-user --user 0 "$pkg" >>"$LOG" 2>&1 || true
    pm hide "$pkg" >>"$LOG" 2>&1 || true
    log "attempted disable for $pkg"
  fi
done

log "force-adb service finished"
