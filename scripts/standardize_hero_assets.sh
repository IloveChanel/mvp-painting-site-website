#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

# Pages we maintain hero banners for
PAGES=(index about gallery blog services)

root="public/assets/images"

# 1) Ensure target hero folders exist
for p in "${PAGES[@]}"; do
  mkdir -p "$root/hero-$p"
done

# 2) Move any existing hero images from old locations into new hero-* folders
for p in "${PAGES[@]}"; do
  target="$root/hero-$p"
  candidates=(
    "$root/hero-$p-photos"
    "$root/hero-$p-photo"
    "$root/$p/photo"
    "$root/$p/photos"
    "$root/hero-$p"
  )
  for src in "${candidates[@]}"; do
    [ -d "$src" ] || continue
    # Move common image types (case-insensitive)
    for f in "$src"/*.[Jj][Pp][Gg] "$src"/*.[Jj][Pp][Ee][Gg] "$src"/*.[Pp][Nn][Gg] "$src"/*.[Ww][Ee][Bb][Pp]; do
      [ -e "$f" ] || continue
      mv -f "$f" "$target/"
    done
  done
done

# 3) Normalize filenames: lowercase, hyphens, consistent prefixes, numeric suffixes
for p in "${PAGES[@]}"; do
  dir="$root/hero-$p"
  i=1
  # Build a map of used numbers to avoid collisions
  declare -A used=()
  for f in "$dir"/*; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    # lowercase + replace spaces/underscores with hyphens
    low="$(echo "$base" | tr '[:upper:]' '[:lower:]')"
    low="${low// /-}"; low="${low//_/-}"
    ext="${low##*.}"
    name="${low%.*}"
    # normalize extension (jpg -> jpeg). keep png/webp as-is
    case "$ext" in
      jpg)  ext="jpeg" ;;
      jpeg|png|webp) : ;;
      *)    : ;; # leave uncommon ext alone
    esac
    # try to extract first number in name
    num="$(echo "$name" | grep -oE '[0-9]+' | head -n1 || true)"
    if [[ -z "$num" ]]; then
      # find next free number
      while [[ -n "${used[$i]-}" || -e "$dir/hero-$p-$i.$ext" ]]; do
        i=$((i+1))
      done
      num="$i"
      used[$i]=1
      i=$((i+1))
    else
      # mark this number as used
      used[$num]=1
    fi
    new="$dir/hero-$p-$num.$ext"
    old="$dir/$base"
    # If source path changed due to lowercase/hyphenization, move first
    if [ "$old" != "$dir/$low" ]; then
      mv -f "$old" "$dir/$low"
      old="$dir/$low"
    fi
    # Rename to final canonical
    if [ "$old" != "$new" ]; then
      # If target exists, bump number until free
      while [ -e "$new" ]; do
        num=$((num+1))
        new="$dir/hero-$p-$num.$ext"
      done
      mv -f "$old" "$new"
    fi
  done
done

# 4) Update any old HTML references to new folders/names
for f in public/*.html; do
  [ -f "$f" ] || continue
  # old folder names -> new
  sed -i 's#assets/images/hero-about-photos#assets/images/hero-about#g' "$f"
  sed -i 's#assets/images/hero-blog-photos#assets/images/hero-blog#g' "$f"
  sed -i 's#assets/images/hero-gallery-photos#assets/images/hero-gallery#g' "$f"
  sed -i 's#assets/images/hero-index-photo#assets/images/hero-index#g' "$f"
  # old prefixes -> new (best-effort textual update)
  sed -i 's#index-photo-#hero-index-#g' "$f"
  sed -i 's#about-photo-#hero-about-#g' "$f"
  sed -i 's#gallery-photo-#hero-gallery-#g' "$f"
  sed -i 's#blog-photo-#hero-blog-#g' "$f"
done

echo "Standardization complete. New structure in $root/hero-<page>/hero-<page>-N.jpeg"
