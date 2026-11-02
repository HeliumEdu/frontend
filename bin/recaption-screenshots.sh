#!/usr/bin/env bash
# Regenerates the captioned store screenshots from the plain framed shots in
# screenshots/framed/, without capturing anything. Run after changing
# bin/screenshot-captions.tsv or bin/caption-screenshot.sh.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TARGETS=(
  "ios:ios/fastlane/screenshots/en-US"
  "android-phone:android/fastlane/metadata/android/en-US/images/phoneScreenshots"
  "android-tablet:android/fastlane/metadata/android/en-US/images/tenInchScreenshots"
)

count=0
for target in "${TARGETS[@]}"; do
  framed_dir="$REPO/screenshots/framed/${target%%:*}"
  dest="$REPO/${target#*:}"
  for framed in "$framed_dir"/*_framed.png; do
    [[ -f "$framed" ]] || continue
    name="$(basename "$framed")"
    "$REPO/bin/caption-screenshot.sh" "$framed" "$dest/$name" "${name%_framed.png}"
    count=$((count + 1))
  done
done

echo "Checked $count screenshot(s)."
