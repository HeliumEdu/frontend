#!/usr/bin/env bash
# Syncs onboarding screenshots, the device frames and the logo from the www project into this repo. www is the source of truth for
# these images; frontend carries renamed copies consumed by the onboarding flow.
#
# Files are only written when source and destination differ (byte-for-byte).
# Requires no external tools beyond standard coreutils.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WWW="$REPO/../www"

if [[ ! -d "$WWW" ]]; then
  echo "✗ www not found at $WWW" >&2
  exit 1
fi

# ─── mapping: www path → path in this repo ───────────────────────────────────
SYNC_MAP=(
  "src/assets/img/screenshots/class-manager.png:assets/img/onboarding_class_manager.png"
  "src/assets/img/screenshots/external-calendars.png:assets/img/onboarding_external_calendars.png"
  "src/assets/img/screenshots/grade-calculator-square.png:assets/img/onboarding_grade_calculator_square.png"
  "src/assets/img/screenshots/grades-breakdown.png:assets/img/onboarding_grades_breakdown.png"
  "src/assets/img/screenshots/grades-dashboard.png:assets/img/onboarding_grades_dashboard.png"
  "src/assets/img/screenshots/month-view.png:assets/img/onboarding_month_view.png"
  "src/assets/img/screenshots/edit-note.png:assets/img/onboarding_notebook.png"
  "src/assets/img/screenshots/reminders.png:assets/img/onboarding_reminders.png"
  "src/assets/img/screenshots/todos.png:assets/img/onboarding_todos.png"
  "src/assets/img/screenshots/week-view.png:assets/img/onboarding_week_view.png"
  "src/assets/img/screenshots/frames/frame-laptop.png:assets/img/frame_laptop.png"
  "src/assets/img/screenshots/frames/frame-phone.png:assets/img/frame_phone.png"
  "src/assets/img/screenshots/frames/frame-tablet.png:assets/img/frame_tablet.png"
  "src/assets/img/helium-logo.png:assets/img/logo.png"
)

echo "Syncing assets (www → $(basename "$REPO")) ..."
copied=0
for entry in "${SYNC_MAP[@]}"; do
  src="$WWW/${entry%%:*}"
  dst="$REPO/${entry##*:}"
  if [[ ! -f "$src" ]]; then
    echo "  ⚠ missing in www: ${entry%%:*}" >&2
    continue
  fi
  if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
    echo "  ⊜ ${entry##*:} unchanged"
  else
    cp "$src" "$dst"
    echo "  ✓ ${entry##*:}"
    ((copied++))
  fi
done
echo "  ($copied files updated)"
