#!/usr/bin/env bash
set -euo pipefail

# get_system_locale.sh
# Purpose: detect best-effort system UI locale on POSIX systems and print a canonical code
# Output examples: en-US, fr-FR, de-DE, zh-CN, zh-TW

# Prefer LANG env var, fall back to locale
locale_raw="${LANG:-$(locale 2>/dev/null | sed -n 's/^LANG=//p' || true)}"
if [ -z "$locale_raw" ]; then
  # macOS: defaults
  locale_raw=$(defaults read -g AppleLocale 2>/dev/null || true)
fi

if [ -z "$locale_raw" ]; then
  # Unknown: default to en-US
  echo "en-US"
  exit 0
fi

# Normalize common separators and shorten to language-region
locale_clean=$(echo "$locale_raw" | sed 's/\..*$//; s/_/-/; s/\@.*$//')

# If we have language only (eg "en") map to en-US for consistency
if ! echo "$locale_clean" | grep -qE '^[a-z]{2}(-|$)'; then
  echo "en-US"
  exit 0
fi

# If already language-region, normalize country to uppercase
lang=$(echo "$locale_clean" | awk -F- '{print $1}')
region=$(echo "$locale_clean" | awk -F- '{print $2}' || true)
if [ -z "$region" ]; then
  # map plain language to a common default
  case "$lang" in
    en) region="US";;
    fr) region="FR";;
    de) region="DE";;
    es) region="ES";;
    it) region="IT";;
    pt) region="PT";;
    ru) region="RU";;
    zh) region="CN";;
    pl) region="PL";;
    sv) region="SE";;
    fi) region="FI";;
    nb) region="NO";;
    cs) region="CZ";;
    hu) region="HU";;
    tr) region="TR";;
    *) region="US";;
  esac
fi

region=$(echo "$region" | tr '[:lower:]' '[:upper:]')
echo "${lang}-${region}"
