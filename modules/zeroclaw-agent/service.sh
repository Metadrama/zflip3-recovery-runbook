#!/system/bin/sh
# ZeroClaw AI Agent Daemon systemless startup service
MODDIR=${0%/*}
LOG="$MODDIR/service.log"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"
}

(
  log "ZeroClaw Daemon service starting..."

  # Wait for boot completion
  for i in $(seq 1 90); do
    [ "$(getprop sys.boot_completed 2>/dev/null)" = "1" ] && break
    sleep 2
  done

  log "Boot completed. Starting ZeroClaw..."

  # Inject Termux paths into the daemon's environment
  export HOME="/data/data/com.termux/files/home"
  export PATH="/data/data/com.termux/files/usr/bin:/system/bin:/system/xbin:$PATH"
  export LD_LIBRARY_PATH="/data/data/com.termux/files/usr/lib"
  export USER="root"

  # Launch ZeroClaw as a background daemon
  /system/bin/zeroclaw --config-dir /system/etc/zeroclaw daemon >> "$MODDIR/daemon.log" 2>&1 &
  log "ZeroClaw Daemon successfully launched in background (PID: $!)"
) &
