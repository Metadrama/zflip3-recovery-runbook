#!/system/bin/sh

MODDIR=${0%/*}
LOG="$MODDIR/service.log"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"
}

(
  log "disable-setup-wizard service starting"

  for i in $(seq 1 90); do
    [ "$(getprop sys.boot_completed 2>/dev/null)" = "1" ] && break
    sleep 2
  done

  settings put global device_provisioned 1 2>>"$LOG"
  settings put secure user_setup_complete 1 2>>"$LOG"
  settings put secure setup_wizard_has_run 1 2>>"$LOG"
  settings put global setup_wizard_has_run 1 2>>"$LOG"

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

  log "disable-setup-wizard service finished"
) &
