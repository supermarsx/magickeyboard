#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
echo "Running lightweight lint checks for batch files..."

fail=0
shopt -s nullglob
for f in "$root_dir"/All\ Keyboard\ Layouts\ \(1.0.3.40\)/*.bat; do
  echo "Checking $f"
  if ! grep -q "Purpose:" "$f"; then
    echo "ERROR: $f is missing a 'Purpose:' header doc line"
    fail=1
  fi
  if grep -q -E "del\s+C:\\Windows\\System32" "$f"; then
    echo "ERROR: $f contains direct 'del C:\Windows\System32' statements — rejected"
    fail=1
  fi
done

if [ $fail -ne 0 ]; then
  echo "Lint failed"
  exit 1
fi
echo "Lint OK"
