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

  # Ensure the writable config directory exists
  CONFIG_DIR="$HOME/.config/zeroclaw"
  mkdir -p "$CONFIG_DIR"

  # Copy the default config.toml if it does not already exist in the writable folder
  # This preserves any custom keys/tokens edited by the user!
  if [ ! -f "$CONFIG_DIR/config.toml" ]; then
    cp /system/etc/zeroclaw/config.toml "$CONFIG_DIR/config.toml"
    chmod 600 "$CONFIG_DIR/config.toml"
    chown -R u0_a315:u0_a315 "$HOME/.config"
    log "Initialized default config.toml in $CONFIG_DIR"
  fi

  # Launch ZeroClaw as a background daemon targeting the writeable config-dir
  /system/bin/zeroclaw --config-dir "$CONFIG_DIR" daemon >> "$MODDIR/daemon.log" 2>&1 &
  log "ZeroClaw Daemon successfully launched in background (PID: $!)"
) &
