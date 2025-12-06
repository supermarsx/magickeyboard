#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
layout_dir="$root_dir/All Keyboard Layouts (1.0.3.40)"

echo "[test-translations] Verifying translations.json coverage for files in install_filelist.txt"

if [ ! -f "$layout_dir/install_filelist.txt" ]; then
  echo "ERROR: install_filelist.txt not found"
  exit 2
fi
if [ ! -f "$layout_dir/translations.json" ]; then
  echo "ERROR: translations.json not found"
  exit 2
fi

missing=0
while IFS= read -r file; do
  [ -z "$file" ] && continue
  key="${file%.*}"
  if ! jq -e ".\"$key\"" "$layout_dir/translations.json" >/dev/null 2>&1; then
    echo "ERROR: translations.json is missing key for $file ($key)"
    missing=1
    continue
  fi
  # Ensure there is at least an English fallback
  if ! jq -e ".\"$key\".en" "$layout_dir/translations.json" >/dev/null 2>&1; then
    echo "WARN: no 'en' fallback for $key (translations.json) — tests will still pass but translation fallback may be inconsistent"
  fi
done < "$layout_dir/install_filelist.txt"

if [ $missing -ne 0 ]; then
  echo "[test-translations] FAILED — missing translation keys"
  exit 3
fi

echo "[test-translations] OK — translations.json contains entries for all files in install_filelist.txt (at least some locales)"
