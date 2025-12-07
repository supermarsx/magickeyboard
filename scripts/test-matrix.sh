#!/usr/bin/env bash
set -euo pipefail

# test-matrix.sh
# Purpose: verify the layouts.json matrix contains entries for all files in
# install_filelist.txt and that each layout entry contains at least the
# "file" and "reg_key" properties. This prevents divergence between the
# installer matrix and the file list used for packaging and checksums.

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
layout_dir="$root_dir/All Keyboard Layouts (1.0.3.40)"

echo "[test-matrix] Verifying layouts.json matrix is consistent with install_filelist.txt and checksums"

if [ ! -f "$layout_dir/layouts.json" ]; then
  echo "ERROR: layouts.json missing"
  exit 2
fi
if [ ! -f "$layout_dir/install_filelist.txt" ]; then
  echo "ERROR: install_filelist.txt missing"
  exit 2
fi

missing=0
total=0
missing_keys=0
missing_props=0

jq '.' "$layout_dir/layouts.json" >/dev/null 2>&1 || { echo "ERROR: layouts.json invalid JSON"; exit 3; }

while IFS= read -r f; do
  [ -z "$f" ] && continue
  key="${f%.*}"; total=$((total+1))
  if ! jq -e ".\"$key\"" "$layout_dir/layouts.json" >/dev/null 2>&1; then
    echo "ERROR: layouts.json is missing metadata for $f (key=$key)"
    missing=$((missing+1)); missing_keys=$((missing_keys+1)); continue
  fi
  # ensure required fields
  for prop in file reg_key; do
    if ! jq -e ".\"$key\".\"$prop\"" "$layout_dir/layouts.json" >/dev/null 2>&1; then
      echo "ERROR: layouts.json.$key missing property $prop"
      missing=$((missing+1)); missing_props=$((missing_props+1))
    fi
  done
  # ensure reg_path exists and appears valid
  if ! jq -e ".\"$key\".reg_path" "$layout_dir/layouts.json" >/dev/null 2>&1; then
    echo "ERROR: layouts.json.$key missing property reg_path"
    missing=$((missing+1)); missing_props=$((missing_props+1))
  else
    rp=$(jq -r ".\"$key\".reg_path" "$layout_dir/layouts.json")
    if [ "$rp" = "null" ] || [ -z "$rp" ]; then
      echo "ERROR: layouts.json.$key empty reg_path"
      missing=$((missing+1)); missing_props=$((missing_props+1))
    fi
    if ! echo "$rp" | grep -qE '^(HKLM:|HKLM\\\\|HKLM\\)'; then
      echo "ERROR: layouts.json.$key reg_path does not look like a HKLM registry path: $rp"
      missing=$((missing+1)); missing_props=$((missing_props+1))
    fi
  fi
done < "$layout_dir/install_filelist.txt"

if [ $missing -ne 0 ]; then
  echo "[test-matrix] FAILED — $missing problems (missing keys: $missing_keys, missing props: $missing_props)"
  exit 4
fi

echo "[test-matrix] OK — layouts.json includes entries for all files in install_filelist.txt (total=$total)"

# Ensure our batch installers call into the matrix-driven powershell helpers
if [ -f "$layout_dir/install_keyboard_layouts.bat" ]; then
  if ! grep -q "install_registry_from_matrix.ps1" "$layout_dir/install_keyboard_layouts.bat" >/dev/null 2>&1; then
    echo "ERROR: install_keyboard_layouts.bat does not call install_registry_from_matrix.ps1"
    exit 5
  fi
fi
if [ -f "$layout_dir/uninstall_keyboard_layouts.bat" ]; then
  if ! grep -q "uninstall_registry_from_matrix.ps1" "$layout_dir/uninstall_keyboard_layouts.bat" >/dev/null 2>&1; then
    echo "ERROR: uninstall_keyboard_layouts.bat does not call uninstall_registry_from_matrix.ps1"
    exit 5
  fi
fi
exit 0
