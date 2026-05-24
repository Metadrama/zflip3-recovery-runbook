#!/system/bin/sh

MODDIR=${0%/*}
LOG="$MODDIR/service.log"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"
}

(
  log "force-adb service starting"

  # Reassert USB/ADB properties early and again after boot completes.
  setprop persist.service.adb.enable 1 2>>"$LOG"
  setprop persist.service.debuggable 1 2>>"$LOG"
  setprop persist.sys.usb.config mtp,adb 2>>"$LOG"
  setprop sys.usb.config mtp,adb 2>>"$LOG"

  for i in $(seq 1 90); do
    [ "$(getprop sys.boot_completed 2>/dev/null)" = "1" ] && break
    sleep 2
  done

  settings put global adb_enabled 1 2>>"$LOG"
  settings put secure adb_enabled 1 2>>"$LOG"
  setprop persist.service.adb.enable 1 2>>"$LOG"
  setprop persist.service.debuggable 1 2>>"$LOG"
  setprop persist.sys.usb.config mtp,adb 2>>"$LOG"
  setprop sys.usb.config mtp,adb 2>>"$LOG"
  setprop ctl.restart adbd 2>>"$LOG"

  if [ -s /data/misc/adb/adb_keys ]; then
    chown 1000:2000 /data/misc/adb/adb_keys 2>>"$LOG"
    chmod 0644 /data/misc/adb/adb_keys 2>>"$LOG"
    restorecon /data/misc/adb/adb_keys 2>>"$LOG"
    log "adb_keys present"
  else
    log "WARNING: /data/misc/adb/adb_keys missing or empty; ADB may show unauthorized"
  fi

  log "force-adb service finished"
) &
