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

REQUIRED_LOCALES=(en en-US fr-FR de-DE es-ES nl-NL it-IT pt-PT pt-BR ru-RU zh-CN zh-TW pl-PL sv-SE fi-FI nb-NO cs-CZ hu-HU tr-TR en-CA)

missing=0
while IFS= read -r file; do
  [ -z "$file" ] && continue
  key="${file%.*}"
  if ! jq -e ".\"$key\"" "$layout_dir/translations.json" >/dev/null 2>&1; then
    echo "ERROR: translations.json is missing key for $file ($key)"
    missing=1
    continue
  fi
  # Ensure translations for all required locales are present
  for locale in "${REQUIRED_LOCALES[@]}"; do
    if ! jq -e ".\"$key\".\"${locale}\"" "$layout_dir/translations.json" >/dev/null 2>&1; then
      echo "ERROR: translations.json is missing locale '$locale' for key $key"
      missing=1
    fi
  done
done < "$layout_dir/install_filelist.txt"

if [ $missing -ne 0 ]; then
  echo "[test-translations] FAILED — missing translation keys"
  exit 3
fi

echo "[test-translations] OK — translations.json contains entries for all files in install_filelist.txt (at least some locales)"
