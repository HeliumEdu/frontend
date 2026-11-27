#!/usr/bin/env bash
# Regenerates the captioned store screenshots from the plain framed shots in
# screenshots/framed/, without capturing anything, for English and every
# language with a bin/screenshot-captions.<lang>.csv. Run after changing the
# captions or bin/caption-screenshot.sh.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Store listing folders per caption language: App Store, then Google Play
# (the same regions crowdin.yml maps the listing text to).
store_locales() {
  case "$1" in
    es) echo "es-MX es-419" ;;
    *) echo "✗ No store listing folders for captions language '$1'" >&2; exit 1 ;;
  esac
}

count=0
caption_shots() {
  local captions="$1" ios_locale="$2" android_locale="$3"
  local targets=(
    "ios:ios/fastlane/screenshots/$ios_locale"
    "android-phone:android/fastlane/metadata/android/$android_locale/images/phoneScreenshots"
    "android-tablet:android/fastlane/metadata/android/$android_locale/images/tenInchScreenshots"
  )
  for target in "${targets[@]}"; do
    local framed_dir="$REPO/screenshots/framed/${target%%:*}"
    local dest="$REPO/${target#*:}"
    mkdir -p "$dest"
    for framed in "$framed_dir"/*_framed.png; do
      [[ -f "$framed" ]] || continue
      local name
      name="$(basename "$framed")"
      "$REPO/bin/caption-screenshot.sh" "$framed" "$dest/$name" "${name%_framed.png}" "$captions"
      count=$((count + 1))
    done
  done
}

caption_shots "$REPO/bin/screenshot-captions.csv" en-US en-US
for captions in "$REPO"/bin/screenshot-captions.*.csv; do
  [[ -f "$captions" ]] || continue
  language="${captions%.csv}"
  language="${language##*.}"
  locales=$(store_locales "$language")
  caption_shots "$captions" $locales
done

echo "Checked $count screenshot(s)."
