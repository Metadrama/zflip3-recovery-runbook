#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT/dist"
WORK="$ROOT/.build/module-zips"

if command -v python3 >/dev/null 2>&1; then
  PYTHON="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON="python"
else
  echo "Python is required for portable zipping" >&2
  exit 1
fi

rm -rf "$WORK"
mkdir -p "$DIST" "$WORK"

build_one() {
  local id="$1"
  local src="$ROOT/modules/$id"
  local pkg="$WORK/$id"
  local out="$DIST/$id-twrp.zip"

  test -f "$src/module.prop" || { echo "missing $src/module.prop" >&2; exit 1; }
  test -f "$src/service.sh" || { echo "missing $src/service.sh" >&2; exit 1; }

  mkdir -p "$pkg/module" "$pkg/META-INF/com/google/android"
  
  # Copy to root (for Magisk in-OS installer compatibility)
  cp -a "$src/." "$pkg/"
  
  # Copy to module/ (for TWRP update-binary installer compatibility)
  cp -a "$src/." "$pkg/module/"
  
  cp "$ROOT/installer/update-binary" "$pkg/META-INF/com/google/android/update-binary"
  printf '#MAGISK\n' > "$pkg/META-INF/com/google/android/updater-script"
  
  chmod 0755 "$pkg/META-INF/com/google/android/update-binary" "$pkg/service.sh" "$pkg/module/service.sh"
  if [ -d "$pkg/system/bin" ]; then
    chmod 0755 "$pkg/system/bin"/*
  fi
  if [ -d "$pkg/module/system/bin" ]; then
    chmod 0755 "$pkg/module/system/bin"/*
  fi

  rm -f "$out"
  "$PYTHON" "$ROOT/tools/zip_helper.py" "$pkg" "$out"
  echo "built $out"
}

build_one force-adb
build_one disable-setup-wizard
build_one gemini-cli
build_one selinux-permissive
build_one disable-doze
build_one scrcpy-hacks


