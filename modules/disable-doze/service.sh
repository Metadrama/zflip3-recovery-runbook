#!/system/bin/sh
MODDIR=${0%/*}
LOG="$MODDIR/service.log"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"
}

(
  log "disable-doze service starting"

  # Wait for system boot to complete so dumpsys is active
  for i in $(seq 1 90); do
    [ "$(getprop sys.boot_completed 2>/dev/null)" = "1" ] && break
    sleep 2
  done

  log "Disabling Android Device Idle (Doze Mode) system-wide..."
  dumpsys deviceidle disable 2>>"$LOG"
  
  log "disable-doze service completed boot=$(getprop sys.boot_completed)"
) &
