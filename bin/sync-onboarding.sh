#!/usr/bin/env bash
# Syncs onboarding screenshots and the laptop frame asset from the www project
# into frontend/assets/img/. www is the source of truth for these images;
# frontend carries renamed copies consumed by the onboarding flow.
#
# Files are only written when source and destination differ (byte-for-byte).
# Requires no external tools beyond standard coreutils.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WWW_SCREENSHOTS="$REPO/../www/src/assets/img/screenshots"
FRONTEND_ASSETS="$REPO/assets/img"

if [[ ! -d "$WWW_SCREENSHOTS" ]]; then
  echo "✗ www screenshots not found at $WWW_SCREENSHOTS" >&2
  exit 1
fi

# ─── mapping: www path (relative to WWW_SCREENSHOTS) → frontend filename ─────
SYNC_MAP=(
  "class-manager.png:onboarding_class_manager.png"
  "external-calendars.png:onboarding_external_calendars.png"
  "grade-calculator-square.png:onboarding_grade_calculator_square.png"
  "grades-breakdown.png:onboarding_grades_breakdown.png"
  "grades-dashboard.png:onboarding_grades_dashboard.png"
  "month-view.png:onboarding_month_view.png"
  "edit-note.png:onboarding_notebook.png"
  "reminders.png:onboarding_reminders.png"
  "todos.png:onboarding_todos.png"
  "week-view.png:onboarding_week_view.png"
  "frames/frame-laptop.png:frame_laptop.png"
)

echo "Syncing onboarding assets (www → frontend) ..."
copied=0
for entry in "${SYNC_MAP[@]}"; do
  src="$WWW_SCREENSHOTS/${entry%%:*}"
  dst="$FRONTEND_ASSETS/${entry##*:}"
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
