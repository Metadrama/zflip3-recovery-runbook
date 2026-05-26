#!/system/bin/sh
# OpenClaw AI Agent Daemon systemless startup service
MODDIR=${0%/*}
LOG="$MODDIR/service.log"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"
}

(
  log "OpenClaw Daemon service starting..."

  # Wait for boot completion
  for i in $(seq 1 90); do
    [ "$(getprop sys.boot_completed 2>/dev/null)" = "1" ] && break
    sleep 2
  done

  log "Boot completed. Starting OpenClaw..."

  # Inject Termux paths into the daemon's environment
  export HOME="/data/ssh/root"
  export PREFIX="/data/data/com.termux/files/usr"
  export PATH="$PREFIX/bin:/system/bin:/system/xbin:$PATH"
  export LD_LIBRARY_PATH="$PREFIX/lib"
  export USER="root"

  # Ensure the writable config directory exists
  CONFIG_DIR="$HOME/.openclaw"
  mkdir -p "$CONFIG_DIR"

  # 1. Dynamically install OpenClaw globally via Termux NPM if it is missing
  if ! command -v openclaw >/dev/null 2>&1; then
    log "OpenClaw binary not found. Installing globally via Termux NPM..."
    npm install -g openclaw@latest --ignore-scripts >> "$MODDIR/install.log" 2>&1
    log "OpenClaw installed successfully."
  fi

  # 2. Automatically fix the Android /usr/bin/env shebang issue on boot
  if [ -f "$PREFIX/lib/node_modules/openclaw/openclaw.mjs" ]; then
    log "Fixing executable shebang..."
    termux-fix-shebang "$PREFIX/lib/node_modules/openclaw/openclaw.mjs" >> "$MODDIR/shebang.log" 2>&1
  fi

  # 3. Copy the default openclaw.json if it does not already exist in the writable folder
  # This preserves any custom tokens, ports, or API keys edited by the user!
  if [ ! -f "$CONFIG_DIR/openclaw.json" ]; then
    cp /system/etc/openclaw/openclaw.json "$CONFIG_DIR/openclaw.json"
    chmod 600 "$CONFIG_DIR/openclaw.json"
    log "Initialized default openclaw.json in $CONFIG_DIR"
  fi

  # 4. Launch the OpenClaw Gateway daemon
  log "Launching OpenClaw Gateway..."
  openclaw gateway start >> "$MODDIR/gateway.log" 2>&1
  log "OpenClaw Gateway successfully launched."
) &
