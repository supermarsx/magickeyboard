#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root_dir"

version="$(jq -r '.version' bucket/magickeyboard.json)"

chmod +x scripts/package_layouts.sh
scripts/package_layouts.sh "$version"

zip -r MagicKeyboard-all.zip . \
  --exclude dist/ \
  --exclude .git/ \
  --exclude .github/ \
  --exclude bucket/ \
  --exclude winget/ \
  --exclude tests/ \
  --exclude .gitattributes \
  --exclude .gitignore

mkdir -p dist
cp "All.Keyboard.Layouts.${version}.zip" dist/ || true
cp MagicKeyboard-all.zip dist/ || true
cp magickeyboard1_AppleKeyboardInstaller64.exe dist/ || true
cp magickeyboard2_AppleKeyboardInstaller64.exe dist/ || true
