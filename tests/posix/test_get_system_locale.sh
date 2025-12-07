#!/usr/bin/env bash
set -euo pipefail

# tests/posix/test_get_system_locale.sh
# Simple unit tests for scripts/get_system_locale.sh

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
helper="$script_dir/scripts/get_system_locale.sh"

if [ ! -x "$helper" ]; then
  echo "ERROR: helper not found or not executable: $helper"
  exit 2
fi

check() {
  lang="$1"
  expected="$2"
  export LANG="$lang"
  out="$($helper)"
  if [ "$out" != "$expected" ]; then
    echo "FAIL: LANG='$lang' -> got '$out' expected '$expected'"
    exit 1
  fi
  echo "OK: LANG='$lang' -> $out"
}

check en_US.UTF-8 en-US
check fr_FR.ISO8859-1 fr-FR
check zh_TW.UTF-8 zh-TW
check en en-US
unset LANG || true
out="$($helper)"
if [ "$out" != "en-US" ]; then
  echo "FAIL: empty LANG -> got '$out' expected 'en-US'"
  exit 1
fi
echo "All POSIX locale detection tests passed"
