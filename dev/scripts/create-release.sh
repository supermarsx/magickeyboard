#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
layout_dir="$root_dir/All Keyboard Layouts (1.0.3.40)"
out_dir="$root_dir/dist"
mkdir -p "$out_dir"

# Usage: scripts/create-release.sh <release-number>
release_number=${1:-2}
release_tag="Release-${release_number}"
version="$release_tag"

echo "Creating release archive for $version"
chmod +x "$root_dir/scripts/package_layouts.sh"
"$root_dir/scripts/package_layouts.sh" "$version"

archive="$(ls "$out_dir"/All.Keyboard.Layouts.*${version}*.zip 2>/dev/null | head -n1 || true)"
if [ -z "$archive" ]; then
  # fallback: pick the latest archive
  archive="$(ls -t "$out_dir"/*.zip | head -n1)"
fi

if [ -z "$archive" ]; then
  echo "No archive found in $out_dir — aborting"
  exit 1
fi

echo "Archive created: $archive"

# Create git tag
if git rev-parse --git-dir >/dev/null 2>&1; then
  git tag -f "$release_tag"
  git push --tags --force 2>/dev/null || echo "Warning: failed to push tags (no credentials or remote)"
else
  echo "Not a git repo; skipping tag creation"
fi

# If gh CLI available, create GitHub release and upload the archive
if command -v gh >/dev/null 2>&1; then
  echo "gh found — creating GitHub release $release_tag"
  gh release create "$release_tag" "$archive" --title "$release_tag" --notes "Automated release $release_tag"
else
  echo "gh CLI not available — skipping GitHub release creation. Upload $archive manually if desired."
fi

echo "Release $release_tag ready. Archive: $archive"
