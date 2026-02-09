#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Running format checks (trailing spaces, final newline)"

fail=0
shopt -s globstar
for f in "$root_dir"/**/*.bat; do
  echo "Checking $f"
  if grep -q "[[:space:]]$" "$f"; then
    echo "ERROR: $f has trailing whitespace"
    fail=1
  fi
  if [ -n "$(tail -c1 "$f")" ]; then
    echo "ERROR: $f does not end with a newline"
    fail=1
  fi
done

if [ $fail -ne 0 ]; then
  echo "Format checks failed"
  exit 1
fi

echo "Format OK"
