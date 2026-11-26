#!/usr/bin/env bash
# Copies the plain framed month-view shots to www's device mockups, and letterboxes the press subset into www's press
# kit. Both come from the plain framed shots in screenshots/framed/ios/, never the captioned ones. The app picks up
# the mockups from www with make sync-assets.
#
# Requires: ImageMagick 7+ (magick).

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO/bin/image-helpers.sh"
FRAMED_DIR="$REPO/screenshots/framed/ios"

if ! command -v magick >/dev/null; then
  echo "Error: ImageMagick not found. brew install imagemagick" >&2
  exit 1
fi

letterbox() {
  local in="$1" w="$2" h="$3"
  local dims
  dims=$(magick identify -format "%wx%h" "$in")
  if [[ "$dims" == "${w}x${h}" ]]; then
    return 1
  fi
  local tmp
  tmp=$(mktemp -t letterbox.XXXXXX.png)
  magick "$in" \
    -resize "${w}x${h}" \
    -gravity center \
    -background white \
    -extent "${w}x${h}" \
    "${PNG_STABLE[@]}" "$tmp"
  mv "$tmp" "$in"
}

# ─── copy frame assets (phone/tablet mockups for www) ────────────────────────
WWW_FRAMES="$REPO/../www/src/assets/img/screenshots/frames"

copy_frame_asset() {
  local src_name="$1" www_name="$2"
  local src="$FRAMED_DIR/$src_name"
  local dst="$WWW_FRAMES/$www_name"
  [[ -f "$src" && -d "$WWW_FRAMES" ]] || return 0
  if copy_if_changed "$src" "$dst"; then
    echo "  ✓ $(basename "$dst")"
    frame_copied=$((frame_copied + 1))
  else
    echo "  ⊜ $(basename "$dst") unchanged"
  fi
}

echo "Copying frame assets ..."
frame_copied=0
copy_frame_asset "01-month-view_iphone_framed.png" "frame-phone.png"
copy_frame_asset "01-month-view_ipad_framed.png"   "frame-tablet.png"
echo "  ($frame_copied files updated)"

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
    src="$FRAMED_DIR/${entry%%:*}"
    dst="$WWW_MOBILE/${entry##*:}"
    if [[ ! -f "$src" ]]; then
      echo "  ⚠ ${entry%%:*} not in $FRAMED_DIR; skipping" >&2
      continue
    fi
    press=$(mktemp -t press.XXXXXX.png)
    cp "$src" "$press"
    case "$src" in
      *_iphone_framed.png) letterbox "$press" 1320 2868 || true ;;
      *_ipad_framed.png)   letterbox "$press" 2064 2752 || true ;;
    esac
    if replace_if_changed "$press" "$dst"; then
      echo "  ✓ ${entry##*:}"
      copied=$((copied + 1))
    else
      echo "  ⊜ ${entry##*:} unchanged"
    fi
  done
  echo "  ($copied files updated)"
else
  echo ""
  echo "⚠ $WWW_MOBILE not found; skipping press copy." >&2
fi
