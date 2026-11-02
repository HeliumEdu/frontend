#!/usr/bin/env bash
# Captures Helium marketing screenshots directly from the booted iOS Simulator
# or Android Emulator and frames each via fastlane frameit. The plain framed
# PNG goes to screenshots/framed/ (the device mockups and press kit come from
# there), and a captioned copy for the store listing (bin/caption-screenshot.sh)
# goes into the relevant fastlane directory:
#
#   ios/fastlane/screenshots/en-US/
#   android/fastlane/metadata/android/en-US/images/phoneScreenshots/
#   android/fastlane/metadata/android/en-US/images/tenInchScreenshots/
#
# Captions live in bin/screenshot-captions.tsv, keyed by shot name.
#
# Filenames are prefixed with a 2-digit ordinal (01-, 02-, ...) matching each
# shot's position in the PHONE_SHOTS / TABLET_SHOTS arrays — fastlane uploads
# screenshots in alphabetical filename order, so the prefix preserves display
# order in the App Store and Play Store listings.
#
# For each device you take, the script boots the simulator or emulator, builds
# and launches Helium on it with `flutter run --no-resident`, and shuts the
# device down after its shots. You sign in (first run only) and navigate; the script
# prompts at every step.
#
# Requires:
#   - xcrun simctl (Xcode CLT)        for iOS capture
#   - adb (Android Platform Tools)    for Android capture
#   - fastlane frameit                for device framing
#   - ImageMagick 7+ (magick) or 6 (convert) for Pixel Tablet composite
#   - flutter, and the "iPhone 15 Pro" / "iPad Pro 13-inch (M5)" simulators and
#     Pixel_5 / Pixel_Tablet AVDs

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO/bin/image-helpers.sh"
IOS_DEST="$REPO/ios/fastlane/screenshots/en-US"
ANDROID_PHONE_DEST="$REPO/android/fastlane/metadata/android/en-US/images/phoneScreenshots"
ANDROID_TABLET_DEST="$REPO/android/fastlane/metadata/android/en-US/images/tenInchScreenshots"
FRAMED_ROOT="$REPO/screenshots/framed"
WORKDIR=$(mktemp -d)

mkdir -p "$IOS_DEST" "$ANDROID_PHONE_DEST" "$ANDROID_TABLET_DEST" \
  "$FRAMED_ROOT/ios" "$FRAMED_ROOT/android-phone" "$FRAMED_ROOT/android-tablet"
trap 'stop_device; rm -rf "$WORKDIR"' EXIT

# ─── pre-flight: frameit frames must be downloaded ───────────────────────
FRAMEIT_DIR="${HOME}/.fastlane/frameit/latest"
if [[ ! -d "$FRAMEIT_DIR" ]] || [[ -z "$(ls "$FRAMEIT_DIR"/*.png 2>/dev/null)" ]]; then
  echo "✗ Device frames not found at $FRAMEIT_DIR" >&2
  echo "  Run: make screenshots" >&2
  exit 1
fi

# ─── shot lists per device class ─────────────────────────────────────────
PHONE_SHOTS=(month-view grades edit-note todos agenda edit-assignment create-account)
TABLET_SHOTS=(month-view grades edit-note todos week-view classes)
# One shot per listing shows dark mode; the rest stay light.
DARK_SHOTS=(agenda week-view)
# Only this shot shows the notification bell's count; the rest are taken with it cleared.
BELL_SHOT=month-view

# ─── capture helpers ─────────────────────────────────────────────────────
# Captures from the booted simulator of the step's kind (iPhone or iPad), so an
# iPhone and an iPad can both stay booted; `simctl io booted` would pick one of
# them arbitrarily.
capture_ios() {
  local out="$1"
  local device_slug="$2"
  if ! command -v xcrun >/dev/null; then
    echo "  ✗ xcrun not found; install Xcode Command Line Tools." >&2
    return 1
  fi
  local kind="iPhone"
  [[ "$device_slug" == "ipad" ]] && kind="iPad"
  local udids
  udids=$(xcrun simctl list devices booted | awk -v kind="$kind" '
    index($1, kind) == 1 && /\(Booted\)/ {
      if (match($0, /\([0-9A-F-]{36}\)/)) print substr($0, RSTART + 1, RLENGTH - 2)
    }')
  local count
  count=$(printf '%s' "$udids" | grep -c . || true)
  if [[ "$count" -eq 0 ]]; then
    echo "  ✗ No booted $kind simulator." >&2
    return 1
  fi
  if [[ "$count" -gt 1 ]]; then
    echo "  ✗ Multiple booted $kind simulators; shut down all but one." >&2
    return 1
  fi
  xcrun simctl io "$udids" screenshot "$out" >/dev/null 2>&1
}

# Captures from the connected device of the step's kind (phone or tablet, by
# Android's own tablet flag), so a phone and a tablet emulator can both run.
capture_android() {
  local out="$1"
  local device_slug="$2"
  if ! command -v adb >/dev/null; then
    echo "  ✗ adb not found; install Android Platform Tools." >&2
    return 1
  fi
  local want_tablet=false
  [[ "$device_slug" == "pixel-tablet" ]] && want_tablet=true
  local kind="phone"
  $want_tablet && kind="tablet"
  local matches=()
  local serial characteristics is_tablet
  for serial in $(adb devices | tail -n +2 | awk '$2=="device"{print $1}'); do
    characteristics=$(adb -s "$serial" shell getprop ro.build.characteristics | tr -d '\r')
    is_tablet=false
    [[ "$characteristics" == *tablet* ]] && is_tablet=true
    [[ "$is_tablet" == "$want_tablet" ]] && matches+=("$serial")
  done
  if [[ ${#matches[@]} -eq 0 ]]; then
    echo "  ✗ No Android $kind emulator/device connected." >&2
    return 1
  fi
  if [[ ${#matches[@]} -gt 1 ]]; then
    echo "  ✗ Multiple Android ${kind}s connected; only run one." >&2
    return 1
  fi
  adb -s "${matches[0]}" exec-out screencap -p > "$out"
}

# ─── devices ─────────────────────────────────────────────────────────────
EMULATOR="${ANDROID_HOME:-$HOME/Library/Android/sdk}/emulator/emulator"
running_ios_udid=""
running_android_serial=""

device_target() {
  case "$1" in
    iphone)       echo "iPhone 15 Pro" ;;
    ipad)         echo "iPad Pro 13-inch (M5)" ;;
    pixel-phone)  echo "Pixel_5" ;;
    pixel-tablet) echo "Pixel_Tablet" ;;
  esac
}

simulator_udid() {
  xcrun simctl list devices available | awk -v name="$1" '
    { line = $0; sub(/^[ \t]+/, "", line) }
    index(line, name " (") == 1 && match(line, /\([0-9A-F-]{36}\)/) {
      print substr(line, RSTART + 1, RLENGTH - 2); exit
    }'
}

# Builds incrementally for the device, installs, launches and returns.
run_helium_on() {
  echo "  Building and launching Helium ..."
  (cd "$REPO" && flutter run -d "$1" --no-resident) >"$WORKDIR/flutter-run.log" 2>&1 || {
    echo "  ✗ flutter run failed; see the log below." >&2
    tail -20 "$WORKDIR/flutter-run.log" >&2
    return 1
  }
}

start_ios() {
  local name="$1"
  local udid
  udid=$(simulator_udid "$name")
  if [[ -z "$udid" ]]; then
    echo "  ✗ No '$name' simulator; create it in Xcode." >&2
    return 1
  fi
  xcrun simctl boot "$udid" 2>/dev/null || true
  running_ios_udid="$udid"
  open -a "Device Hub" 2>/dev/null || true
  run_helium_on "$udid"
}

start_android() {
  local avd="$1"
  "$EMULATOR" -avd "$avd" -no-snapshot-save >/dev/null 2>&1 &
  local serial="" attempt
  for attempt in $(seq 1 100); do
    for serial in $(adb devices | awk 'NR > 1 && $2 == "device" { print $1 }'); do
      [[ "$(adb -s "$serial" emu avd name 2>/dev/null | head -1 | tr -d '\r')" == "$avd" ]] &&
        [[ "$(adb -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == 1 ]] &&
        break 2
    done
    serial=""
    sleep 3
  done
  if [[ -z "$serial" ]]; then
    echo "  ✗ The $avd emulator did not boot." >&2
    return 1
  fi
  running_android_serial="$serial"
  run_helium_on "$serial"
}

start_device() {
  local target
  target=$(device_target "$1")
  echo "  Starting $target ..."
  case "$1" in
    iphone|ipad) start_ios "$target" ;;
    *)           start_android "$target" ;;
  esac
}

stop_device() {
  if [[ -n "$running_ios_udid" ]]; then
    xcrun simctl shutdown "$running_ios_udid" 2>/dev/null || true
    running_ios_udid=""
  fi
  if [[ -n "$running_android_serial" ]]; then
    adb -s "$running_android_serial" emu kill >/dev/null 2>&1 || true
    running_android_serial=""
  fi
}

# ─── framing ─────────────────────────────────────────────────────────────
# frameit operates on every .png in cwd, producing <name>_framed.png.
# Framefile.json forces specific device types so framing works regardless of
# which fastlane version maps the resolution to which device name.
write_framefile() {
  # force_device_type pins to the newest frame available in frameit's catalog
  # (14 Pro is the latest; 15 Pro frames have not been released upstream).
  cat > "$WORKDIR/Framefile.json" <<'FRAMEFILE'
{
  "default": {
    "frame": "BLACK"
  },
  "data": [
    { "filter": "_iphone", "force_device_type": "iPhone 14 Pro" },
    { "filter": "_ipad",   "force_device_type": "iPad Pro (12.9-inch) (4th generation)" }
  ]
}
FRAMEFILE
}

framed_dir_for() {
  case "$1" in
    "$IOS_DEST")            echo "$FRAMED_ROOT/ios" ;;
    "$ANDROID_PHONE_DEST")  echo "$FRAMED_ROOT/android-phone" ;;
    "$ANDROID_TABLET_DEST") echo "$FRAMED_ROOT/android-tablet" ;;
  esac
}

# Keeps the plain framed shot and writes its captioned store copy to dest.
finish_framed() {
  local framed="$1"  # framed png in $WORKDIR
  local slug="$2"
  local dest="$3"
  local name
  name="$(basename "$framed")"
  local framed_dir
  framed_dir="$(framed_dir_for "$dest")"

  if copy_if_changed "$framed" "$framed_dir/$name"; then
    echo "  ✓ $framed_dir/$name"
  else
    echo "  ⊜ $framed_dir/$name unchanged"
  fi
  if ! "$REPO/bin/caption-screenshot.sh" "$framed" "$dest/$name" "$slug"; then
    echo "  ✗ Captioning failed for $name" >&2
    rm -f "$framed"
    exit 1
  fi
  rm -f "$framed"
}

frame_and_move() {
  local raw="$1"     # raw png in $WORKDIR
  local slug="$2"    # e.g. 01-month-view_iphone
  local dest="$3"    # destination dir
  local framed="${slug}_framed.png"

  write_framefile
  (
    cd "$WORKDIR"
    fastlane frameit >/tmp/frameit.log 2>&1
  ) || true

  if [[ -f "$WORKDIR/$framed" ]]; then
    rm -f "$raw"
    finish_framed "$WORKDIR/$framed" "$slug" "$dest"
  else
    echo "  ✗ frameit failed to produce $framed" >&2
    echo "    Check /tmp/frameit.log for details." >&2
    echo "    Run: make screenshots" >&2
    rm -f "$raw"
    exit 1
  fi
}

# Pixel Tablet — frameit's catalog has no modern Android tablet frame.
# Source frame: jamesjingyi/mockup-device-frames (Porcelain colorway),
# rotated to portrait and tinted dark to match the Pixel 5 phone frame.
# Frame's screen area: 1731×2747 at offset +200+200 (portrait).
PIXEL_TABLET_FRAME="$REPO/bin/frame-pixel-tablet.png"

composite_pixel_tablet() {
  local raw="$1"
  local slug="$2"
  local dest="$3"
  local framed="$WORKDIR/${slug}_framed.png"

  if [[ ! -f "$PIXEL_TABLET_FRAME" ]]; then
    echo "  ✗ Pixel Tablet frame missing at $PIXEL_TABLET_FRAME"
    mv "$raw" "$dest/${slug}.png"
    return 1
  fi

  if command -v magick >/dev/null; then
    magick "$PIXEL_TABLET_FRAME" \
      \( "$raw" -resize 1731x2747! \) \
      -gravity northwest -geometry +200+200 -composite \
      "$framed"
  else
    convert "$PIXEL_TABLET_FRAME" \
      \( "$raw" -resize 1731x2747! \) \
      -gravity northwest -geometry +200+200 -composite \
      "$framed"
  fi
  rm -f "$raw"
  finish_framed "$framed" "$slug" "$dest"
}

# ─── per-screenshot loop ─────────────────────────────────────────────────
prompt_and_capture() {
  local capture_fn="$1"
  local device_slug="$2"
  local frame_mode="$3"   # "frameit" | "pixel-tablet" | "none"
  local dest="$4"
  local index="$5"
  local shot="$6"

  local prefix
  prefix=$(printf "%02d" "$index")
  local slug="${prefix}-${shot}_${device_slug}"
  local raw="$WORKDIR/${slug}.png"

  local is_dark=false
  [[ " ${DARK_SHOTS[*]} " == *" $shot "* ]] && is_dark=true

  echo ""
  if $is_dark; then
    echo "  🌙 Switch Helium to dark mode for this shot (Settings, moon icon)."
  fi
  read -r -p "  → Navigate to '${shot}'. Press Enter to capture, 's' to skip, 'q' to quit: " reply
  case "$reply" in
    q|Q) echo "Quitting."; exit 0 ;;
    s|S) echo "  ↷ skipped"; return 0 ;;
  esac

  if ! $capture_fn "$raw" "$device_slug"; then
    echo "  Capture failed; skipping $slug"
    return 0
  fi
  echo "  📸 captured $(basename "$raw")"
  if $is_dark; then
    echo "  ☀️  Switch Helium back to light mode before the next shot."
  fi

  case "$frame_mode" in
    frameit)      frame_and_move "$raw" "$slug" "$dest" || true ;;
    pixel-tablet) composite_pixel_tablet "$raw" "$slug" "$dest" || true ;;
    none|*)
      mv "$raw" "$dest/${slug}.png"
      echo "  ✓ $dest/${slug}.png (no frame)"
      ;;
  esac
}

run_device() {
  local label="$1"
  local slug="$2"
  local capture_fn="$3"
  local frame_mode="$4"
  local dest="$5"
  shift 5
  local shots=("$@")

  echo ""
  echo "════════════════════════════════════════════════════════════"
  echo "  $label  (${#shots[@]} screenshots → $dest)"
  echo "════════════════════════════════════════════════════════════"
  echo "The example schedule's reminders are shared by every device, so restore them if a previous device"
  echo "cleared them: the bell should show its count for '$BELL_SHOT'."
  read -r -p "Press Enter to start the $label with the latest Helium build ('s' to skip this device): " reply
  if [[ "$reply" == "s" || "$reply" == "S" ]]; then
    echo "Skipping $label."
    return 0
  fi
  if ! start_device "$slug"; then
    echo "  ✗ Couldn't start the $label; skipping it." >&2
    stop_device
    return 0
  fi
  read -r -p "  Helium is open on the $label. Sign in if it asks, then press Enter: " _

  local i=1
  for shot in "${shots[@]}"; do
    prompt_and_capture "$capture_fn" "$slug" "$frame_mode" "$dest" "$i" "$shot"
    if [[ "$shot" == "$BELL_SHOT" ]]; then
      echo "  🔔 Open the notification bell and clear the reminders, so the count is gone for the remaining shots."
    fi
    ((i++))
  done
  stop_device
}

# ─── go ──────────────────────────────────────────────────────────────────
echo "iOS shots    → $IOS_DEST"
echo "Pixel phone  → $ANDROID_PHONE_DEST"
echo "Pixel tablet → $ANDROID_TABLET_DEST"
echo "Workdir      → $WORKDIR (cleaned on exit)"

run_device "iPhone 15 Pro"    "iphone"       capture_ios     "frameit"      "$IOS_DEST"            "${PHONE_SHOTS[@]}"
run_device "iPad Pro 13\" M5" "ipad"         capture_ios     "frameit"      "$IOS_DEST"            "${TABLET_SHOTS[@]}"
run_device "Pixel 5"          "pixel-phone"  capture_android "frameit"      "$ANDROID_PHONE_DEST"  "${PHONE_SHOTS[@]}"
run_device "Pixel Tablet"     "pixel-tablet" capture_android "pixel-tablet" "$ANDROID_TABLET_DEST" "${TABLET_SHOTS[@]}"

# ─── frame any remaining raw screenshots in dest ────────────────────────
# Catches files from a prior run where framing failed (e.g. frameit wasn't
# initialized). Looks for NN-*_iphone.png / NN-*_ipad.png without _framed.
echo ""
echo "════════════════════════════════════════════════════════════"
echo "Checking for un-framed raw screenshots in $IOS_DEST ..."
echo "════════════════════════════════════════════════════════════"
FRAMED_COUNT=0
for raw in "$IOS_DEST"/*.png; do
  [[ -f "$raw" ]] || continue
  basename="$(basename "$raw" .png)"
  # Skip framed files
  [[ "$basename" == *_framed ]] && continue
  echo "  Framing $basename ..."
  mv "$raw" "$WORKDIR/${basename}.png"
  frame_and_move "$WORKDIR/${basename}.png" "$basename" "$IOS_DEST"
  ((FRAMED_COUNT++))
done
if [[ "$FRAMED_COUNT" -eq 0 ]]; then
  echo "  (none found)"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "Capture done. Scaling iPhone and iPad shots to App Store dimensions ..."
echo "════════════════════════════════════════════════════════════"
"$(dirname "${BASH_SOURCE[0]}")/scale-for-appstore.sh"
