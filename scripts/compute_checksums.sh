#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
layout_dir="$root_dir/All Keyboard Layouts (1.0.3.40)"

cd "$layout_dir"
echo "NOTE: install_filelist.txt/install_checksums.txt are deprecated. layouts.json contains authoritative sha256 checksums.
This helper will compute fresh SHA256 values for the files and write a helper JSON file 'layouts.checksums.json' for review.
You can copy the values into layouts.json if updating the canonical matrix."

rm -f layouts.checksums.json
echo "{" > layouts.checksums.json
first=1
for f in *.dll; do
  [ -z "$f" ] && continue
  if [ ! -f "$f" ]; then
    continue
  fi
  hash=$(shasum -a 256 "$f" | awk '{print $1}')
  if [ $first -eq 1 ]; then
    first=0
  else
    echo "," >> layouts.checksums.json
  fi
  printf '  "%s": "%s"' "$f" "$hash" >> layouts.checksums.json
done
echo
echo "}" >> layouts.checksums.json

echo "Wrote layouts.checksums.json (review and merge into layouts.json if desired)"
