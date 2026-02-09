#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root_dir"

chmod +x scripts/run-tests.sh
scripts/run-tests.sh

chmod +x scripts/test-translations.sh
scripts/test-translations.sh
