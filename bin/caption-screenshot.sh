#!/usr/bin/env bash
# Composites one framed screenshot onto a brand-colored canvas at its store's
# dimensions, with the shot's heading and subline above the device.
#
# Usage: caption-screenshot.sh <framed.png> <out.png> <slug> [captions.csv]
#   slug: NN-<shot>_<device>, e.g. 01-month-view_iphone
#   captions.csv: defaults to the English bin/screenshot-captions.csv; Crowdin
#     writes each language's copy as bin/screenshot-captions.<lang>.csv
#
# Captions are <shot>.heading and <shot>.subline rows (<key>,<text>), taken from
# the store listing's feature sections.
#
# Requires: ImageMagick 7+ (magick).

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO/bin/image-helpers.sh"
HEADING_FONT="$REPO/assets/fonts/Poppins-SemiBold.ttf"
SUBLINE_FONT="$REPO/assets/fonts/Poppins-Regular.ttf"
BG_COLOR="#418eb9"
TEXT_COLOR="#ffffff"

framed="$1"
out="$2"
slug="$3"
captions="${4:-$REPO/bin/screenshot-captions.csv}"

device="${slug##*_}"
shot="${slug%_*}"
shot="${shot#*-}"

# Store canvases: App Store 6.9" iPhone, iPhone Duo inner screen and 13" iPad;
# Play phone at its 2:1 aspect limit and a 10" tablet at 10:16.
case "$device" in
  iphone)       width=1320; height=2868; text_scale=64 ;;
  duo)          width=2007; height=2853; text_scale=46 ;;
  ipad)         width=2064; height=2752; text_scale=46 ;;
  pixel-phone)  width=1290; height=2580; text_scale=64 ;;
  pixel-tablet) width=1800; height=2880; text_scale=50 ;;
  *) echo "✗ Unknown device '$device' in slug '$slug'" >&2; exit 1 ;;
esac

caption() {
  python3 -c 'import csv, sys; print(next((row[1] for row in csv.reader(open(sys.argv[1], encoding="utf-8")) if row and row[0] == sys.argv[2]), ""))' "$captions" "$1"
}

heading=$(caption "$shot.heading")
subline=$(caption "$shot.subline")
if [[ -z "$heading" || -z "$subline" ]]; then
  echo "✗ No heading and subline for '$shot' in $captions" >&2
  exit 1
fi

heading_size=$(( width * text_scale / 1000 ))
subline_size=$(( heading_size * 55 / 100 ))
side_margin=$(( width * 8 / 100 ))
text_width=$(( width - 2 * side_margin ))
top_margin=$(( height * 5 / 100 ))
caption_gap=$(( height * 3 / 100 ))
bottom_margin=$(( height * 3 / 100 ))

heading_png=$(mktemp -t caption-heading.XXXXXX).png
subline_png=$(mktemp -t caption-subline.XXXXXX).png
text_png=$(mktemp -t caption-text.XXXXXX).png
rendered_png=$(mktemp -t caption-out.XXXXXX).png
trap 'rm -f "$heading_png" "$subline_png" "$text_png" "$rendered_png"' EXIT

# Rendered at the font's full line height, not trimmed to the ink, so every shot's
# caption block, and the device under it, sits at the same height.
render_text() {
  local font="$1" size="$2" text="$3" out_png="$4"
  magick -background none -fill "$TEXT_COLOR" -font "$font" -pointsize "$size" \
    -size "${text_width}x" -gravity center caption:"$text" "$out_png"
  local line_height
  line_height=$(magick -background none -font "$font" -pointsize "$size" label:"Hg" -format "%h" info:)
  if (( $(magick identify -format "%h" "$out_png") > line_height )); then
    echo "⚠ '$text' wraps onto a second line for $device; shots with wrapped captions sit lower" >&2
  fi
}

render_text "$HEADING_FONT" "$heading_size" "$heading" "$heading_png"
render_text "$SUBLINE_FONT" "$subline_size" "$subline" "$subline_png"
magick -background none "$heading_png" \
  \( -size "1x$(( subline_size * 6 / 10 ))" xc:none \) "$subline_png" \
  -gravity center -append "$text_png"
text_height=$(magick identify -format "%h" "$text_png")

device_top=$(( top_margin + text_height + caption_gap ))
device_box_width=$(( width - 2 * side_margin ))
device_box_height=$(( height - device_top - bottom_margin ))

magick -size "${width}x${height}" "xc:$BG_COLOR" \
  "$text_png" -gravity north -geometry "+0+${top_margin}" -composite \
  \( "$framed" -resize "${device_box_width}x${device_box_height}" \) \
  -gravity north -geometry "+0+${device_top}" -composite \
  -alpha off "${PNG_STABLE[@]}" "$rendered_png"

if replace_if_changed "$rendered_png" "$out"; then
  echo "  ✓ $out"
else
  echo "  ⊜ $out unchanged"
fi
