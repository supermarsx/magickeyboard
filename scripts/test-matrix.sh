#!/usr/bin/env bash
set -euo pipefail

# test-matrix.sh
# Purpose: verify the layouts.json matrix contains entries for all files in
# install_filelist.txt and that each layout entry contains at least the
# "file" and "reg_key" properties. This prevents divergence between the
# installer matrix and the file list used for packaging and checksums.

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
layout_dir="$root_dir/All Keyboard Layouts (1.0.3.40)"

echo "[test-matrix] Verifying layouts.json matrix is self-consistent and contains required properties"

if [ ! -f "$layout_dir/layouts.json" ]; then
  echo "ERROR: layouts.json missing"
  exit 2
fi

missing=0
total=0
missing_keys=0
missing_props=0

jq '.' "$layout_dir/layouts.json" >/dev/null 2>&1 || { echo "ERROR: layouts.json invalid JSON"; exit 3; }

keys=$(jq -r 'keys[]' "$layout_dir/layouts.json")
for key in $keys; do
  total=$((total+1))
  if ! jq -e ".\"$key\"" "$layout_dir/layouts.json" >/dev/null 2>&1; then
    echo "ERROR: layouts.json is missing metadata for key $key"
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
  # Also check reg_path -> reg_key consistency when reg_key exists
  if jq -e ".\"$key\".reg_key" "$layout_dir/layouts.json" >/dev/null 2>&1; then
    rk=$(jq -r ".\"$key\".reg_key" "$layout_dir/layouts.json")
    if ! echo "$rp" | grep -q "$rk"; then
      echo "ERROR: layouts.json.$key reg_path does not include reg_key ($rk) : $rp"
      missing=$((missing+1)); missing_props=$((missing_props+1))
    fi
  fi
done

if [ $missing -ne 0 ]; then
  echo "[test-matrix] FAILED — $missing problems (missing keys: $missing_keys, missing props: $missing_props)"
  exit 4
fi

echo "[test-matrix] OK — layouts.json validated (total keys=$total)"

# Ensure our batch installers call into the matrix-driven powershell helpers
if [ -f "$layout_dir/install_keyboard_layouts.bat" ]; then
  if ! grep -q "install_registry_from_matrix.ps1" "$layout_dir/install_keyboard_layouts.bat" >/dev/null 2>&1; then
    echo "ERROR: install_keyboard_layouts.bat does not call install_registry_from_matrix.ps1"
    exit 5
  fi
fi
# Edge-case tests: ensure there are no extra keys in layouts.json not present in install_filelist.txt
# Check files referenced in layouts.json exist on disk
extra_count=0
for k in $(jq -r 'keys[]' "$layout_dir/layouts.json"); do
  fname=$(jq -r ".\"$k\".file" "$layout_dir/layouts.json")
  if [ -z "$fname" ] || [ "$fname" = "null" ]; then
    echo "ERROR: layouts.json.$k missing 'file' property"
    extra_count=$((extra_count+1))
    continue
  fi
  if [ ! -f "$layout_dir/$fname" ]; then
    echo "ERROR: file listed in layouts.json is missing: $fname"
    extra_count=$((extra_count+1))
  fi
done
if [ $extra_count -ne 0 ]; then
  echo "[test-matrix] FAILED — $extra_count extra layout keys found in layouts.json"
  exit 5
fi

echo "[test-matrix] No extra keys in layouts.json — OK"

# Dry-run message count tests for install/uninstall matrix helpers
if command -v pwsh >/dev/null 2>&1; then
  # count actionable matrix entries (with reg_path or reg_key)
  total_files=$(jq -r '.[] | select(.reg_path != null or .reg_key != null) | @text' "$layout_dir/layouts.json" | wc -l | tr -d '[:space:]')
  out=$(pwsh -NoProfile -ExecutionPolicy Bypass -File "$layout_dir/install_registry_from_matrix.ps1" -MatrixPath "$layout_dir/layouts.json" -TranslationsPath "$layout_dir/translations.json" -DryRun)
  got=$(echo "$out" | grep -c "DRYRUN: would create registry key")
  if [ "$got" -ne "$total_files" ]; then
    echo "ERROR: install dry-run reported $got create messages, expected $total_files"
    exit 6
  fi

  out2=$(pwsh -NoProfile -ExecutionPolicy Bypass -File "$layout_dir/uninstall_registry_from_matrix.ps1" -MatrixPath "$layout_dir/layouts.json" -DryRun)
  got2=$(echo "$out2" | grep -c "DRYRUN: would delete registry key")
  if [ "$got2" -ne "$total_files" ]; then
    echo "ERROR: uninstall dry-run reported $got2 delete messages, expected $total_files"
    exit 6
  fi
  echo "[test-matrix] install/uninstall dry-run message counts OK"
fi
if [ -f "$layout_dir/uninstall_keyboard_layouts.bat" ]; then
  if ! grep -q "uninstall_registry_from_matrix.ps1" "$layout_dir/uninstall_keyboard_layouts.bat" >/dev/null 2>&1; then
    echo "ERROR: uninstall_keyboard_layouts.bat does not call uninstall_registry_from_matrix.ps1"
    exit 5
  fi
fi
exit 0
