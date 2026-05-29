#!/usr/bin/env bash
# Letterbox-pads framed iOS device screenshots to App Store Connect's
# accepted dimensions, preserving the device-frame proportions. Writes back
# to ios/fastlane/screenshots/en-US/ in place — operation is idempotent
# (re-running on already-scaled files is a no-op).
#
# Override background color (e.g. brand blue):
#   BG_COLOR='#418eb9' ./bin/scale-for-appstore.sh
#
# Targets:
#   *_iphone_framed.png  →  1320 × 2868  (App Store 6.9")
#   *_ipad_framed.png    →  2064 × 2752  (App Store 13")
#
# Requires: ImageMagick 7+ (magick) or ImageMagick 6 (convert).

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="$REPO/ios/fastlane/screenshots/en-US"
BG_COLOR="${BG_COLOR:-white}"

if command -v magick >/dev/null; then
  IM=(magick)
elif command -v convert >/dev/null; then
  IM=(convert)
else
  echo "Error: ImageMagick not found. brew install imagemagick" >&2
  exit 1
fi

letterbox() {
  local in="$1" w="$2" h="$3"
  local tmp
  tmp=$(mktemp -t letterbox.XXXXXX.png)
  "${IM[@]}" "$in" \
    -resize "${w}x${h}" \
    -gravity center \
    -background "$BG_COLOR" \
    -extent "${w}x${h}" \
    "$tmp"
  mv "$tmp" "$in"
}

echo "Background: $BG_COLOR"
echo ""
echo "iPhone → 1320 × 2868 (App Store 6.9\")"
count=0
for f in "$DIR"/*_iphone_framed.png; do
  [[ -f "$f" ]] || continue
  letterbox "$f" 1320 2868
  echo "  ✓ $(basename "$f")"
  ((count++))
done
echo "  ($count files)"

echo ""
echo "iPad → 2064 × 2752 (App Store 13\")"
count=0
for f in "$DIR"/*_ipad_framed.png; do
  [[ -f "$f" ]] || continue
  letterbox "$f" 2064 2752
  echo "  ✓ $(basename "$f")"
  ((count++))
done
echo "  ($count files)"

echo ""
echo "Done. Files updated in place at $DIR"
