#!/system/bin/sh

MODDIR=${0%/*}
LOG="$MODDIR/service.log"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"
}

(
  log "gemini-cli service starting"

  # Force early boot permissive SELinux for advanced tool execution
  setenforce 0 2>>"$LOG"
  log "SELinux set to Permissive"

  for i in $(seq 1 90); do
    [ "$(getprop sys.boot_completed 2>/dev/null)" = "1" ] && break
    sleep 2
  done

  # Setup systemless DNS bypass for unprivileged Termux package managers
  mkdir -p /data/local/tmp
  echo "127.0.0.1 localhost" > /data/local/tmp/hosts
  echo "::1 localhost" >> /data/local/tmp/hosts
  echo "104.21.44.149 packages-cf.termux.dev" >> /data/local/tmp/hosts
  echo "104.16.8.34 registry.npmjs.org" >> /data/local/tmp/hosts
  echo "172.217.25.46 google.com" >> /data/local/tmp/hosts
  chmod 644 /data/local/tmp/hosts

  mount -o bind /data/local/tmp/hosts /system/etc/hosts 2>>"$LOG"
  log "Systemless hosts bind-mounted"

  log "gemini-cli service finished"
) &
