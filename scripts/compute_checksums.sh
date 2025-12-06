#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
layout_dir="$root_dir/All Keyboard Layouts (1.0.3.40)"

cd "$layout_dir"
if [ ! -f install_filelist.txt ]; then
  echo "install_filelist.txt not found in $layout_dir"
  exit 2
fi

echo "Computing SHA256 checksums for files listed in install_filelist.txt"
rm -f install_checksums.txt
while IFS= read -r file; do
  [ -z "$file" ] && continue
  if [ ! -f "$file" ]; then
    echo "WARN: $file not found — skipping"
    continue
  fi
  shasum -a 256 "$file" >> install_checksums.txt
done < install_filelist.txt

echo "Wrote install_checksums.txt ($(wc -l < install_checksums.txt) entries)"
