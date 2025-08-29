#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="public/assets"
OUTDIR="reports/dupes"
mkdir -p "$OUTDIR"

# hash function that works in Git Bash
hash_file() {
  if command -v md5sum >/dev/null 2>&1; then
    md5sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

# 1) Collect candidate files (images + css/js), exclude backups/builds
mapfile -d '' FILES < <(find "$ROOT" -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.svg' -o -iname '*.gif' -o -iname '*.css' -o -iname '*.js' \) \
  ! -path '*/rescue_*/*' ! -path '*/dist/*' ! -path '*/pages/*' -print0)

# 2) Exact duplicate groups (by content hash)
TMP_HASH="$(mktemp)"
for f in "${FILES[@]}"; do
  h="$(hash_file "$f")"
  printf '%s|%s\n' "$h" "$f" >> "$TMP_HASH"
done
sort -o "$TMP_HASH" "$TMP_HASH"

HASH_REPORT="$OUTDIR/hash_duplicates.txt"
: > "$HASH_REPORT"
gcount=0
awk -F'|' '
BEGIN{prev=""; first=1}
{
  if($1!=prev){
    if(!first && n>1){print ""}  # blank line between groups
    if(!first && n>1){print header; for(i=1;i<=n;i++) print files[i]}
    prev=$1; header="HASH: "$1; n=0; delete files
    first=0
  }
  files[++n]=$2
}
END{
  if(n>1){print ""; print header; for(i=1;i<=n;i++) print files[i]}
}
' "$TMP_HASH" | tee "$HASH_REPORT" >/dev/null

# 3) Name-stem duplicates (same folder + same stem, different ext)
STEM_REPORT="$OUTDIR/name_stem_duplicates.txt"
: > "$STEM_REPORT"
declare -A STEMS
for f in "${FILES[@]}"; do
  dir="$(dirname "$f")"
  base="$(basename "$f")"
  stem="${base%.*}"
  key="$dir|$stem"
  STEMS["$key"]+="$f"$'\n'
done
for k in "${!STEMS[@]}"; do
  # count lines
  cnt=$(printf "%s" "${STEMS[$k]}" | sed '/^$/d' | wc -l | tr -d ' ')
  if [ "$cnt" -gt 1 ]; then
    echo "DIR|STEM: $k" >> "$STEM_REPORT"
    printf "%s" "${STEMS[$k]}" | sed '/^$/d' >> "$STEM_REPORT"
    echo "" >> "$STEM_REPORT"
  fi
done

# 4) Unreferenced files (not mentioned in any HTML/CSS/JS under public/)
UNREF_REPORT="$OUTDIR/unreferenced.txt"
: > "$UNREF_REPORT"
mapfile -d '' PAGES < <(find public -maxdepth 1 -type f -name '*.html' -print0)
# also scan CSS/JS that might reference images
mapfile -d '' ASSETS_TXT < <(find public/assets -type f \( -name '*.css' -o -name '*.js' \) -print0)

for f in "${FILES[@]}"; do
  rel="${f#public/}"                # assets/images/...
  rel_slash="/$rel"                 # /assets/images/...
  if grep -Rqs -- "$rel"  "${PAGES[@]}" "${ASSETS_TXT[@]}" 2>/dev/null; then
    continue
  elif grep -Rqs -- "$rel_slash" "${PAGES[@]}" "${ASSETS_TXT[@]}" 2>/dev/null; then
    continue
  else
    echo "$f" >> "$UNREF_REPORT"
  fi
done

# 5) Summary
echo "=== Duplicate Audit Complete ==="
echo "• Exact duplicates report: $HASH_REPORT"
echo "• Name-stem duplicates:   $STEM_REPORT"
echo "• Unreferenced assets:    $UNREF_REPORT"
