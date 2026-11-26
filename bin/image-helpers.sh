# Sourced by the screenshot scripts. Writes only land when the pixels change, so
# re-running a job on unchanged screens leaves the repos clean.
#
# Requires: ImageMagick 7+ (magick).

# ImageMagick write options that leave out its timestamp chunks, so rendering the
# same pixels twice gives the same bytes.
PNG_STABLE=(-define png:exclude-chunk=date,time)

# With a tolerance, images whose normalized RMSE is under it also count as identical.
images_identical() {
  local a="$1" b="$2" tolerance="${3:-}"
  [[ -f "$a" && -f "$b" ]] || return 1
  cmp -s "$a" "$b" && return 0
  if [[ -n "$tolerance" ]]; then
    local rmse
    rmse=$(magick compare -metric RMSE "${a}[-1]" "${b}[-1]" null: 2>&1) || true
    [[ "$rmse" =~ \(([0-9.e-]+)\) ]] || return 1
    awk -v normalized="${BASH_REMATCH[1]}" -v tolerance="$tolerance" 'BEGIN { exit !(normalized < tolerance) }'
    return
  fi
  local differing_pixels
  differing_pixels=$(magick compare -metric AE "$a" "$b" null: 2>&1) || true
  [[ "${differing_pixels%% *}" == "0" ]]
}

# Moves a freshly rendered file onto dst, or discards it when dst already has the
# same pixels. Returns 1 when dst is left untouched.
replace_if_changed() {
  local rendered="$1" dst="$2" tolerance="${3:-}"
  if images_identical "$rendered" "$dst" "$tolerance"; then
    rm -f "$rendered"
    return 1
  fi
  chmod 644 "$rendered"
  mv -f "$rendered" "$dst"
}

# Returns 1 when dst already has src's pixels and is left untouched.
copy_if_changed() {
  local src="$1" dst="$2" tolerance="${3:-}"
  images_identical "$src" "$dst" "$tolerance" && return 1
  cp -f "$src" "$dst"
}
