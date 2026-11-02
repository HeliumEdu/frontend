#!/usr/bin/env bash
# Builds the Play Store feature graphic (1024x500) from www's framed-laptop
# screenshot, the same way www builds its OG card. Release uploads it with the
# other store assets when push_store_assets is set.
#
# frame-laptop.png is captured by `make screenshots` (bin/grab-screenshots-web.py),
# which runs this script when the frame changes.
#
# Requires: ImageMagick 7+ (magick).

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO/bin/image-helpers.sh"
LAPTOP="$REPO/../www/src/assets/img/screenshots/frames/frame-laptop.png"
OUT="$REPO/android/fastlane/metadata/android/en-US/images/featureGraphic.png"

[[ -f "$LAPTOP" ]] || { echo "✗ $LAPTOP not found" >&2; exit 1; }

rendered=$(mktemp -t feature-graphic.XXXXXX).png
trap 'rm -f "$rendered"' EXIT

magick -size 1024x500 "xc:#418eb9" \
  \( "$LAPTOP" -colorspace RGB -filter Lanczos2 -resize 1024x -colorspace sRGB -unsharp 0x0.5+0.6+0.01 \) \
  -gravity north -composite \
  -alpha off -depth 8 -type TrueColor -strip "${PNG_STABLE[@]}" "$rendered"

if replace_if_changed "$rendered" "$OUT"; then
  echo "  ✓ $OUT"
else
  echo "  ⊜ $OUT unchanged"
fi
