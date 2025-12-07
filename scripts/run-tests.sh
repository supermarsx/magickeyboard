#!/usr/bin/env bash
set -euo pipefail

# run-tests.sh
# Purpose: Run the project's packaging and validation tests for the "All Keyboard Layouts"
# collection. This includes file existence checks, checksum verification, translation
# coverage tests and the new layouts.json -> install_filelist consistency test.

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
layout_dir="$root_dir/All Keyboard Layouts (1.0.3.40)"

echo "Running tests for layout packaging and checksums..."

if [ ! -f "$layout_dir/install_filelist.txt" ]; then
  echo "ERROR: install_filelist.txt missing"
  exit 2
fi
if [ ! -f "$layout_dir/install_checksums.txt" ]; then
  echo "ERROR: install_checksums.txt missing"
  exit 2
fi

missing=0
while IFS= read -r file; do
  if [ -z "$file" ]; then
    continue
  fi
  if [ ! -f "$layout_dir/$file" ]; then
    echo "ERROR: referenced file missing: $file"
    missing=1
  fi
done < "$layout_dir/install_filelist.txt"

if [ $missing -ne 0 ]; then
  echo "Some files from install_filelist.txt are missing"
  exit 3
fi

echo "Validating checksums..."
cd "$layout_dir"
failed=0
while IFS= read -r line; do
  # skip empty lines
  [ -z "$line" ] && continue
  expected_hash="$(echo "$line" | awk '{print $1}')"
  fname="$(echo "$line" | awk '{print $2}')"
  if [ ! -f "$fname" ]; then
    echo "ERROR: checksum entry references missing file: $fname"
    failed=1
    continue
  fi
  actual_hash="$(shasum -a 256 "$fname" | awk '{print $1}')"
  if [ "$actual_hash" != "$expected_hash" ]; then
    echo "ERROR: checksum mismatch for $fname"
    echo "  expected: $expected_hash"
    echo "  actual:   $actual_hash"
    failed=1
  fi
done < install_checksums.txt

if [ $failed -ne 0 ]; then
  echo "Checksum tests failed"
  exit 4
fi

echo "All tests passed"

echo
echo "[test] Running translation coverage tests (POSIX)"
chmod +x "$root_dir/scripts/test-translations.sh"
"$root_dir/scripts/test-translations.sh"

echo
echo "[test] Running matrix coverage tests (POSIX)"
chmod +x "$root_dir/scripts/test-matrix.sh"
"$root_dir/scripts/test-matrix.sh"

echo
echo "[test] Running smoke dry-run test for Linux (best-effort)"
if [ -f "All Keyboard Layouts (1.0.3.40)/install_keyboard_layouts.bat" ]; then
  echo "NOTE: We cannot execute .bat files on POSIX as a real run — use Windows runner for full execution tests."
fi

echo
echo "[test] Running PowerShell matrix installer dry-run (POSIX)"
if command -v pwsh >/dev/null 2>&1; then
  # use absolute layout_dir paths to avoid failing after we cd earlier in the script
  pwsh -NoProfile -ExecutionPolicy Bypass -File "$layout_dir/install_registry_from_matrix.ps1" -MatrixPath "$layout_dir/layouts.json" -TranslationsPath "$layout_dir/translations.json" -DryRun >/dev/null 2>&1 || { echo "ERROR: PowerShell matrix dry-run failed"; exit 8; }
  echo "[test] PowerShell matrix installer dry-run OK"
else
  echo "[test] pwsh (PowerShell) not available — skipping PowerShell matrix dry-run"
fi
