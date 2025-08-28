#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

PAGES=(index about gallery blog services)   # services is harmless if missing
ROOT="public/assets/images"
# Preference: keep first one found
PREF=(jpeg png webp jpg)

for p in "${PAGES[@]}"; do
  dir="$ROOT/hero-$p"
  [ -d "$dir" ] || continue

  # collect basenames (without extension)
  declare -A seen=()
  for f in "$dir"/*.*; do
    bn="${f%.*}"
    seen["$bn"]=1
  done

  for bn in "${!seen[@]}"; do
    files=()
    for ext in jpeg jpg png webp; do
      [ -f "$bn.$ext" ] && files+=("$bn.$ext")
    done
    [ ${#files[@]} -le 1 ] && continue

    # choose the one to keep by preference
    keep=""
    for ext in "${PREF[@]}"; do
      if [ -f "$bn.$ext" ]; then keep="$bn.$ext"; break; fi
    done

    echo "[$p] keeping $(basename "$keep"); deleting $(( ${#files[@]} - 1 )) other variant(s) of $(basename "$bn").*"
    for f in "${files[@]}"; do
      [ "$f" = "$keep" ] && continue
      if [ "${DRY_RUN:-1}" = "1" ]; then
        echo "  would delete: $f"
      else
        rm -f "$f"
        echo "  deleted: $f"
      fi
    done
  done
  unset seen
done
