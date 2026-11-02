#!/usr/bin/env bash
# Fans the generated app icons (web/icons, from `flutter_launcher_icons`) out to
# the web favicon, the Play Store listing icon and www's icons and favicons.
# Platform and connector then copy theirs from www with their sync-assets.
#
# Requires: ImageMagick 7+ (magick) or ImageMagick 6 (convert).

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO/bin/image-helpers.sh"
WWW_PUBLIC="$REPO/../www/public"
ICON_192="$REPO/web/icons/Icon-192.png"
ICON_512="$REPO/web/icons/Icon-512.png"

if command -v magick >/dev/null; then
  IM=(magick)
else
  IM=(convert)
fi

report() {
  local dst="$1" changed="$2"
  if [[ "$changed" == true ]]; then
    echo "  ✓ $dst"
  else
    echo "  ⊜ $dst unchanged"
  fi
}

# Resizing the same icon with another tool shifts a few pixels, so outputs within
# resampling noise of the existing file count as unchanged.
looks_unchanged() {
  local candidate="$1" dst="$2"
  [[ -f "$dst" ]] || return 1
  local rmse
  rmse=$("${IM_COMPARE[@]}" -metric RMSE "${candidate}[-1]" "${dst}[-1]" null: 2>&1) || true
  [[ "$rmse" =~ \(([0-9.e-]+)\) ]] || return 1
  awk -v normalized="${BASH_REMATCH[1]}" 'BEGIN { exit !(normalized < 0.06) }'
}

copy() {
  local src="$1" dst="$2"
  if looks_unchanged "$src" "$dst"; then
    report "$dst" false
  else
    cp -f "$src" "$dst"
    report "$dst" true
  fi
}

install_rendered() {
  local rendered="$1" dst="$2"
  if looks_unchanged "$rendered" "$dst"; then
    rm -f "$rendered"
    report "$dst" false
  else
    chmod 644 "$rendered"
    mv -f "$rendered" "$dst"
    report "$dst" true
  fi
}

resize() {
  local size="$1" dst="$2"
  local rendered
  rendered=$(mktemp -t icon.XXXXXX).png
  "${IM[@]}" "$ICON_512" -resize "${size}x${size}" "${PNG_STABLE[@]}" "$rendered"
  install_rendered "$rendered" "$dst"
}

# Cropped in to the calendar so it stays legible at tab size.
favicon_ico() {
  local dst="$1"
  local rendered
  rendered=$(mktemp -t favicon.XXXXXX).ico
  "${IM[@]}" "$ICON_512" -crop 472x472+20+28 +repage -define icon:auto-resize=16,32 "$rendered"
  install_rendered "$rendered" "$dst"
}

echo "Fanning out app icons ..."
copy "$ICON_192" "$REPO/web/favicon.png"
copy "$ICON_512" "$REPO/android/fastlane/metadata/android/en-US/images/icon.png"

if [[ -d "$WWW_PUBLIC" ]]; then
  copy "$ICON_192" "$WWW_PUBLIC/icon-192.png"
  copy "$ICON_512" "$WWW_PUBLIC/icon-512.png"
  resize 32 "$WWW_PUBLIC/favicon.png"
  resize 180 "$WWW_PUBLIC/apple-touch-icon.png"
  favicon_ico "$WWW_PUBLIC/favicon.ico"
  echo "Run 'make sync-assets' in platform and connector to pick up the www icons."
else
  echo "⚠ $WWW_PUBLIC not found; skipping the www icons"
fi
