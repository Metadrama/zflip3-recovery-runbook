#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT/dist"
WORK="$ROOT/.build/module-zips"

command -v zip >/dev/null 2>&1 || { echo "zip is required" >&2; exit 1; }

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
  cp -a "$src/." "$pkg/module/"
  cp "$ROOT/installer/update-binary" "$pkg/META-INF/com/google/android/update-binary"
  printf '#MAGISK\n' > "$pkg/META-INF/com/google/android/updater-script"
  chmod 0755 "$pkg/META-INF/com/google/android/update-binary" "$pkg/module/service.sh"

  rm -f "$out"
  (cd "$pkg" && zip -qr "$out" .)
  unzip -t "$out" >/dev/null
  echo "built $out"
}

build_one force-adb
build_one disable-setup-wizard
build_one gemini-cli
build_one selinux-permissive


