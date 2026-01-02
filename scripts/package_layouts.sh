#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
layout_dir="$root_dir/All Keyboard Layouts (1.0.3.40)"
out_dir="$root_dir/dist"
mkdir -p "$out_dir"

version="$(date +%Y%m%d%H%M%S)"
if [ "$#" -ge 1 ]; then
  version="$1"
fi

archive_name="All.Keyboard.Layouts.$version.zip"
cd "$layout_dir"

if ! jq -e '[.[] | select(.sha256)] | length > 0' layouts.json >/dev/null 2>&1; then
  echo "Warning: layouts.json has no embedded sha256 values — generating helper checksums.json"
  ../../dev/scripts/compute_checksums.sh || true
fi

zip -r "$out_dir/$archive_name" . -x "*.DS_Store"
echo "Created archive: $out_dir/$archive_name"
