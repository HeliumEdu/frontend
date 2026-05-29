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
  if cmp -s "$tmp" "$in"; then
    rm -f "$tmp"
    return 1
  fi
  mv "$tmp" "$in"
}

echo "Background: $BG_COLOR"
echo ""
echo "iPhone → 1320 × 2868 (App Store 6.9\")"
count=0
for f in "$DIR"/*_iphone_framed.png; do
  [[ -f "$f" ]] || continue
  if letterbox "$f" 1320 2868; then
    echo "  ✓ $(basename "$f")"
    ((count++))
  else
    echo "  ⊜ $(basename "$f") unchanged"
  fi
done
echo "  ($count files updated)"

echo ""
echo "iPad → 2064 × 2752 (App Store 13\")"
count=0
for f in "$DIR"/*_ipad_framed.png; do
  [[ -f "$f" ]] || continue
  if letterbox "$f" 2064 2752; then
    echo "  ✓ $(basename "$f")"
    ((count++))
  else
    echo "  ⊜ $(basename "$f") unchanged"
  fi
done
echo "  ($count files updated)"

echo ""
echo "Done. Files updated in place at $DIR"

# ─── copy press subset to ../www ─────────────────────────────────────────
WWW_MOBILE="$REPO/../www/public/press/screenshots/mobile"
if [[ -d "$WWW_MOBILE" ]]; then
  echo ""
  echo "Copying press screenshots → $WWW_MOBILE"
  cp "$DIR/01-month-view_iphone_framed.png" "$WWW_MOBILE/helium-phone-month-view.png"
  cp "$DIR/02-grades_iphone_framed.png"     "$WWW_MOBILE/helium-phone-grades.png"
  cp "$DIR/03-todos_iphone_framed.png"      "$WWW_MOBILE/helium-phone-todos.png"
  cp "$DIR/06-edit-note_iphone_framed.png"  "$WWW_MOBILE/helium-phone-note-editor.png"
  cp "$DIR/01-month-view_ipad_framed.png"   "$WWW_MOBILE/helium-tablet-month-view.png"
  cp "$DIR/02-grades_ipad_framed.png"       "$WWW_MOBILE/helium-tablet-grades.png"
  cp "$DIR/03-todos_ipad_framed.png"        "$WWW_MOBILE/helium-tablet-todos.png"
  cp "$DIR/04-edit-note_ipad_framed.png"    "$WWW_MOBILE/helium-tablet-note-editor.png"
  echo "  ✓ 8 screenshots copied"
else
  echo ""
  echo "⚠ $WWW_MOBILE not found; skipping press copy."
fi
