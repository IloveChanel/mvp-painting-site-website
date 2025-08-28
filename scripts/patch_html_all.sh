#!/usr/bin/env bash
set -euo pipefail
fix_file () {
  local f="$1"; [ -f "$f" ] || return 0
  sed -i 's/<<!--/<!--/g' "$f"
  # keep single includes
  awk 'BEGIN{c=0} /assets\/css\/custom\.css/{c++; if(c>1) next} {print}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  awk 'BEGIN{c=0} /assets\/js\/hero-rotator\.js/{c++; if(c>1) next} {print}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  awk 'BEGIN{c=0} /assets\/css\/style\.css/{c++; if(c>1) next} {print}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  # single fixed logo
  awk 'BEGIN{c=0} /class="[^"]*logo-fixed[^"]*"/{c++; if(c>1) next} {print}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  # correct header brand path
  sed -i 's#assets/images/logo-black.png#assets/images/logos/logo-black.png#g' "$f"
  # remove inline hero <img> (we inject backgrounds)
  sed -i '/assets\/images\/hero-[a-z-]*\/hero-[a-z-]*-[0-9]\+\.\(jpeg\|jpg\|png\|webp\)/d' "$f"
  # lazy-load gallery & footer white logo
  sed -i 's#<img src="assets/images/gallery/#<img loading="lazy" decoding="async" src="assets/images/gallery/#g' "$f"
  sed -i 's#<img src="assets/images/logos/logo-white.png#<img loading="lazy" decoding="async" src="assets/images/logos/logo-white.png#g' "$f"
  # replace empty base64 logos with file path
  sed -i 's#src="data:image/png;base64,[^"]*"#src="assets/images/logos/logo-white.png"#g' "$f"
}
for f in public/*.html; do fix_file "$f"; done
