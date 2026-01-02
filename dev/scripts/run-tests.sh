#!/usr/bin/env bash
set -euo pipefail

# run-tests.sh
# Purpose: Run the project's packaging and validation tests for the "All Keyboard Layouts"
# collection. This includes file existence checks, checksum verification, translation
# coverage tests and the new layouts.json -> install_filelist consistency test.

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
layout_dir="$root_dir/All Keyboard Layouts (1.0.3.40)"

echo "Running tests for layout packaging and checksums (layouts.json + embedded sha256)"

if [ ! -f "$layout_dir/layouts.json" ]; then
  echo "ERROR: layouts.json missing"
  exit 2
fi

missing=0
cd "$layout_dir"

# build file list and check files exist + validate sha256 against embedded layouts.json
jq -e '. | type == "object"' layouts.json >/dev/null 2>&1 || { echo "ERROR: layouts.json invalid JSON"; exit 3; }

files=$(jq -r '.[] | .file' layouts.json)
for f in $files; do
  if [ -z "$f" ]; then continue; fi
  if [ ! -f "$f" ]; then
    echo "ERROR: referenced file missing: $f"
    missing=1
    continue
  fi
  expected=$(jq -r "[.[] | select(.file==\"$f\") | .sha256] | .[0]" layouts.json)
  if [ -z "$expected" ] || [ "$expected" = "null" ]; then
    echo "ERROR: no sha256 embedded for $f in layouts.json"
    missing=1
    continue
  fi
  actual=$(shasum -a 256 "$f" | awk '{print $1}')
  if [ "$actual" != "$expected" ]; then
    echo "ERROR: checksum mismatch for $f"
    echo "  expected: $expected"
    echo "  actual:   $actual"
    missing=1
  fi
done

if [ $missing -ne 0 ]; then
  echo "Checksum/file presence tests failed"
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

echo
echo "[test] Running PowerShell uninstall matrix dry-run (POSIX)"
if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -ExecutionPolicy Bypass -File "$layout_dir/uninstall_registry_from_matrix.ps1" -MatrixPath "$layout_dir/layouts.json" -DryRun >/dev/null 2>&1 || { echo "ERROR: PowerShell uninstall dry-run failed"; exit 9; }
  echo "[test] PowerShell uninstall matrix dry-run OK"
else
  echo "[test] pwsh (PowerShell) not available — skipping uninstall matrix dry-run"
fi

echo
echo "[test] Running unit tests in tests/posix (POSIX)"
if [ -x "$root_dir/tests/posix/test_get_system_locale.sh" ]; then
  "$root_dir/tests/posix/test_get_system_locale.sh"
else
  echo "[test] No POSIX unit tests found or not executable - skipping"
fi

echo
echo "[test] Running PowerShell unit tests (POSIX host)"
if command -v pwsh >/dev/null 2>&1; then
  # run Pester v5 tests (all tests under tests/powershell/pester)
  echo
  echo "[test] Running Pester tests (PowerShell assertions)"
  # Run Pester tests in the pester folder. If Pester isn't available, attempt to import or skip.
  pwsh -NoProfile -ExecutionPolicy Bypass -File "$root_dir/scripts/run-pester.ps1" -PesterPath "$root_dir/tests/powershell/pester" || { echo "ERROR: Pester tests failed"; exit 12; }
else
  echo "[test] pwsh (PowerShell) not available — skipping PowerShell unit tests"
fi
