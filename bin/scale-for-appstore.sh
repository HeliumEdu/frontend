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
  IM_IDENTIFY=(magick identify)
elif command -v convert >/dev/null; then
  IM=(convert)
  IM_IDENTIFY=(identify)
else
  echo "Error: ImageMagick not found. brew install imagemagick" >&2
  exit 1
fi

letterbox() {
  local in="$1" w="$2" h="$3"
  local dims
  dims=$("${IM_IDENTIFY[@]}" -format "%wx%h" "$in")
  if [[ "$dims" == "${w}x${h}" ]]; then
    return 1
  fi
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

# ─── copy pre-letterbox frame assets (phone/tablet mockups for app and www) ──
FLUTTER_ASSETS="$REPO/assets/img"
WWW_FRAMES="$REPO/../www/src/assets/img/screenshots/frames"

copy_frame_asset() {
  local src_name="$1" flutter_name="$2" www_name="$3" target_w="$4" target_h="$5"
  local src="$DIR/$src_name"
  [[ -f "$src" ]] || return 0
  local dims
  dims=$("${IM_IDENTIFY[@]}" -format "%wx%h" "$src")
  if [[ "$dims" == "${target_w}x${target_h}" ]]; then
    echo "  ⊜ $(basename "$src") already at App Store dims; skipping"
    return 0
  fi
  local dsts=("$FLUTTER_ASSETS/$flutter_name" "$WWW_FRAMES/$www_name")
  for dst in "${dsts[@]}"; do
    [[ -d "$(dirname "$dst")" ]] || continue
    if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
      echo "  ⊜ $(basename "$dst") unchanged"
    else
      cp "$src" "$dst"
      echo "  ✓ $(basename "$dst")"
      ((frame_copied++))
    fi
  done
}

echo "Copying pre-letterbox frame assets ..."
frame_copied=0
copy_frame_asset "01-month-view_iphone_framed.png" "frame_phone.png"  "frame-phone.png"  1320 2868
copy_frame_asset "01-month-view_ipad_framed.png"   "frame_tablet.png" "frame-tablet.png" 2064 2752
echo "  ($frame_copied files updated)"

echo ""
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
  PRESS_MAP=(
    "01-month-view_iphone_framed.png:helium-phone-month-view.png"
    "02-grades_iphone_framed.png:helium-phone-grades.png"
    "03-edit-note_iphone_framed.png:helium-phone-edit-note.png"
    "04-todos_iphone_framed.png:helium-phone-todos.png"
    "01-month-view_ipad_framed.png:helium-tablet-month-view.png"
    "02-grades_ipad_framed.png:helium-tablet-grades.png"
    "03-edit-note_ipad_framed.png:helium-tablet-edit-note.png"
    "04-todos_ipad_framed.png:helium-tablet-todos.png"
  )
  copied=0
  for entry in "${PRESS_MAP[@]}"; do
    src="$DIR/${entry%%:*}"
    dst="$WWW_MOBILE/${entry##*:}"
    if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
      echo "  ⊜ ${entry##*:} unchanged"
    else
      cp "$src" "$dst"
      echo "  ✓ ${entry##*:}"
      ((copied++))
    fi
  done
  echo "  ($copied files updated)"
else
  echo ""
  echo "⚠ $WWW_MOBILE not found; skipping press copy."
fi
