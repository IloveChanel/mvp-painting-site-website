#!/usr/bin/env bash
set -euo pipefail
PUB="public"
STAMP=$(date +%s)

# A) Point all pages to the one true path
for f in "$PUB"/*.html; do
  [ -f "$f" ] || continue
  # fix common wrong paths
  sed -i 's#assets/images/logo-black\.png#assets/images/logos/logo-black.png#g' "$f"
  sed -i 's#assets/images/logo\.png#assets/images/logos/logo-black.png#g' "$f"
  sed -i 's#assets/images/Logos/#assets/images/logos/#g' "$f"   # fix accidental case
done

# B) Ensure the header <img> has a predictable class, then force a visible size
CSS="$PUB/assets/css/custom.css"
mkdir -p "$(dirname "$CSS")"; touch "$CSS"
grep -q '/* === HEADER LOGO SIZE === */' "$CSS" || cat >> "$CSS" <<'CSS'
/* === HEADER LOGO SIZE === */
.header-logo{height:48px;width:auto;display:block}
@media (min-width:768px){.header-logo{height:56px}}
CSS

# add the class on header logos
for f in "$PUB"/*.html; do
  [ -f "$f" ] || continue
  sed -i 's#<img src="assets/images/logos/logo-black.png"#<img src="assets/images/logos/logo-black.png" class="header-logo"#' "$f"
  # cache-bust css so Netlify pulls latest
  sed -i "s#assets/css/custom.css[^\"']*#assets/css/custom.css?v=$STAMP#g" "$f"
done

echo "✅ Logo paths normalized and header logo forced visible."
