#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

: "${DRY_RUN:=1}"   # DRY_RUN=1 (preview), set DRY_RUN=0 to apply

ROOT="public"
LOGODIR="$ROOT/assets/images/logos"
PAGES=(index about services gallery blog contact)
HERO_DIR="$ROOT/assets/images"
KEEP_EXT=(jpeg png webp jpg)   # preference order for hero dupes; .jpeg first

say() { printf '%s\n' "$*"; }
do_mv() { if [ "$DRY_RUN" = "0" ]; then git mv -f "$1" "$2" 2>/dev/null || mv -f "$1" "$2"; fi; say "move: $1 -> $2"; }
do_rm() { if [ "$DRY_RUN" = "0" ]; then rm -f -- "$@"; fi; printf 'delete: %s\n' "$@"; }

ensure_dir() { mkdir -p "$1"; }

# ---------- 0) Make sure folders exist ----------
ensure_dir "$LOGODIR"
ensure_dir design/brand

# ---------- 1) Standardize LOGOS ----------
say "== logos =="
# Normalize/keep only logo-black.png & logo-white.png under LOGODIR
for color in black white; do
  want="$LOGODIR/logo-$color.png"
  # Find a candidate if canonical missing
  if [ ! -f "$want" ]; then
    cand="$(find "$ROOT/assets/images" -maxdepth 2 -type f -iregex ".*logo-$color\.(png|jpg|jpeg|webp)" | head -n1 || true)"
    [ -n "${cand:-}" ] && do_mv "$cand" "$want"
  fi
  # Remove other variants of same color
  for f in "$LOGODIR"/logo-"$color".{jpg,jpeg,webp,png}; do
    [ -e "$f" ] || continue
    [ "$f" = "$want" ] || do_rm "$f"
  done
done
# Drop generic logo.png anywhere under /logos
for f in "$LOGODIR"/logo.png "$ROOT/assets/images/logo.png"; do
  [ -e "$f" ] && do_rm "$f"
done

# Move design/source logo files out of public (won’t be deployed)
for f in "$LOGODIR"/*.{ai,svg,eps,pdf,psd,ai?,SVG,EPS,PDF,PSD} 2>/dev/null; do
  [ -e "$f" ] || continue
  do_mv "$f" "design/brand/$(basename "$f")"
done
# Move any extra “MVP-PAINTING-LOGO*” files out of public (keep the 2 canonical PNGs only)
for f in "$LOGODIR"/MVP-* "$LOGODIR"/*MVP* 2>/dev/null; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  case "$base" in
    logo-black.png|logo-white.png) : ;;
    *) do_mv "$f" "design/brand/$base" ;;
  esac
done

# ---------- 2) Dedupe HERO images ----------
say "== hero images dedupe (keep ${KEEP_EXT[*]} by preference) =="
for dir in "$HERO_DIR"/hero-*; do
  [ -d "$dir" ] || continue
  # collect basenames
  declare -A seen=()
  for f in "$dir"/*.*; do bn="${f%.*}"; seen["$bn"]=1; done
  for bn in "${!seen[@]}"; do
    files=()
    for e in jpeg jpg png webp; do [ -f "$bn.$e" ] && files+=("$bn.$e"); done
    [ ${#files[@]} -le 1 ] && continue
    # choose keeper by preference
    keep=""
    for e in "${KEEP_EXT[@]}"; do [ -f "$bn.$e" ] && { keep="$bn.$e"; break; }; done
    say "[hero] keep $(basename "$keep")"
    for f in "${files[@]}"; do
      [ "$f" = "$keep" ] && continue
      do_rm "$f"
    done
  done
  unset seen
done

# ---------- 3) Clean HTML duplicates & paths ----------
say "== html cleanup =="
fix_html () {
  local f="$1"; [ -f "$f" ] || return 0

  # a) keep single includes for style.css, custom.css, hero-rotator.js
  for pat in 'assets/css/style\.css' 'assets/css/custom\.css' 'assets/js/hero-rotator\.js'; do
    awk -v P="$pat" 'BEGIN{c=0} { if ($0 ~ P) { c++; if (c>1) next } print }' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  done

  # b) remove inline hero <img> tags (we use background slides)
  sed -i '/assets\/images\/hero-[a-z-]*\/hero-[a-z-]*-[0-9]\+\.\(jpeg\|jpg\|png\|webp\)/d' "$f"

  # c) keep only one floating fixed logo image
  awk 'BEGIN{c=0} { if ($0 ~ /class="[^"]*logo-fixed[^"]*"/) { c++; if (c>1) next } print }' "$f" > "$f.tmp" && mv "$f.tmp" "$f"

  # d) fix header brand logo path (ensure /logos/)
  sed -i 's#assets/images/logo-black.png#assets/images/logos/logo-black.png#g' "$f"
  sed -i 's#assets/images/logos/logo\.png#assets/images/logos/logo-black.png#g' "$f"
}
for p in "${PAGES[@]}"; do
  for file in "$ROOT/$p.html" "$ROOT/$p"; do
    [ -f "$file" ] && fix_html "$file"
  done
done

# ---------- 4) Report remaining potential duplicates ----------
say "== report =="
say "-- hero duplicate basenames (should be empty) --"
for d in "$HERO_DIR"/hero-*; do
  [ -d "$d" ] || continue
  ls "$d"/*.* 2>/dev/null | sed -E 's/\.(jpeg|jpg|png|webp)$//' | sort | uniq -d || true
done

say "-- multiple includes check (per page) --"
for p in "${PAGES[@]}"; do
  f="$ROOT/$p.html"; [ -f "$f" ] || f="$ROOT/$p"
  [ -f "$f" ] || continue
  printf "%s\n" "## $f"
  awk ' /assets\/css\/style\.css/ {s++} /assets\/css\/custom\.css/ {c++} /assets\/js\/hero-rotator\.js/ {h++}
        END {printf("style.css=%d custom.css=%d hero-rotator.js=%d\n", s, c, h)}' "$f"
done

say "DONE (DRY_RUN=$DRY_RUN). If the plan looks correct, run again with DRY_RUN=0 to apply."
