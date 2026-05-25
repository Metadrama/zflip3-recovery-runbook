#!/system/bin/sh
MODDIR=${0%/*}
LOG="$MODDIR/service.log"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"
}

(
  log "scrcpy-hacks service starting"

  # Wait for system boot to complete so display manager and input subsystem are active
  for i in $(seq 1 90); do
    [ "$(getprop sys.boot_completed 2>/dev/null)" = "1" ] && break
    sleep 2
  done

  # 1. Ensure the Device State is reset to folded (Server Mode / Cover Screen active)
  # by default on boot to prevent the damaged main screen from glowing on restart.
  cmd device_state state reset 2>>"$LOG"
  log "Forced device state to folded/server default"

  # 2. Lock screen brightness to 0 (minimum) to prevent screen glow/heat
  settings put system screen_brightness 0 2>>"$LOG"
  log "Set screen brightness to 0"

  # 3. Locate and disable the main physical touchscreen digitizer event handler
  # to completely eliminate ghost touches while keeping scrcpy input intact.
  EVENT_DEV=$(cat /proc/bus/input/devices | grep -A 8 "sec_touchscreen" | grep -oE "event[0-9]+" | head -n 1)
  if [ -n "$EVENT_DEV" ]; then
    chmod 000 /dev/input/"$EVENT_DEV" 2>>"$LOG"
    log "Disabled physical touchscreen digitizer: /dev/input/$EVENT_DEV"
  else
    log "WARNING: Main touchscreen digitizer (sec_touchscreen) not found!"
  fi

  log "scrcpy-hacks service completed"
) &
