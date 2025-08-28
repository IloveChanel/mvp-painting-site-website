#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

INDEX="public/index.html"
CSS="public/assets/css/custom.css"

# 0) backup
cp -f "$INDEX" "public/index.backup_$(date +%Y%m%d_%H%M%S).html" 2>/dev/null || true

# 1) CSS: hero keeps ~2:1 aspect ratio; remove any caption box/blur; fix card images
mkdir -p "$(dirname "$CSS")"
touch "$CSS"

# HERO: preserve your 1980x1000 (~2:1) ratio and avoid weird cropping by keeping container tall enough.
# Also include an OPTIONAL "no-crop" mode you can toggle by adding class="parallax-hero no-crop" (will letterbox instead of crop).
if ! grep -q '/* === HERO RATIO 2:1 === */' "$CSS"; then
  cat >> "$CSS" <<'CSS'
/* === HERO RATIO 2:1 === */
.parallax-hero{position:relative;width:100%;aspect-ratio:1980/1000;height:auto;max-height:85vh;overflow:hidden}
@media (max-width:640px){.parallax-hero{aspect-ratio:16/10;max-height:70vh}}
.parallax-hero .slides{position:absolute;inset:0;will-change:transform}
.parallax-hero .slide{position:absolute;inset:0;background-size:cover;background-position:center;opacity:0;transition:opacity .8s ease}
.parallax-hero .slide.is-active{opacity:1}
/* first slide visible even before JS */
.parallax-hero .slide:first-child{opacity:1}

/* optional no-crop mode (full image, may show bars/edges) */
.parallax-hero.no-crop .slide{background-size:contain;background-repeat:no-repeat;background-color:#0f172a}

/* remove ANY caption box blur/shadow (you asked for clean text on image) */
.parallax-hero .overlay{background:none !important}
.parallax-hero .caption .card{background:transparent !important;backdrop-filter:none !important;box-shadow:none !important;border:0 !important;padding:clamp(18px,2.6vw,30px)}
.parallax-hero .caption h1,.parallax-hero .caption p{text-shadow:none !important}
CSS
fi

# CARD IMAGES: replace fixed h-56 with ratio-based rule to stop aggressive cropping
if ! grep -q '/* === CARD IMG RATIO === */' "$CSS"; then
  cat >> "$CSS" <<'CSS'
/* === CARD IMG RATIO === */
.img-card{display:block;width:100%;aspect-ratio:1980/1000;object-fit:cover}
@media (max-width:640px){.img-card{aspect-ratio:16/10}}
/* If you want NO crop on a specific card, add class "img-card-contain" instead of img-card */
.img-card-contain{display:block;width:100%;aspect-ratio:1980/1000;object-fit:contain;background:#0f172a}
CSS
fi

# 2) HTML: swap card <img> classes from fixed height to our new class
# These are the three cards in "Our Work" on index.html
sed -i 's/class="w-full h-56 object-cover"/class="img-card"/g' "$INDEX"

# 3) Header logo: ensure correct path + real <img> inside the brand link
# Replace the first brand link that points to index.html with a known-good one (keeps layout classes).
sed -i '0,/<a href="index\.html"[^>]*>.*<\/a>/{s//<a href="index.html" class="flex items-center gap-3"><img src="assets\/images\/logos\/logo-black.png" alt="MVP Painting Logo" class="h-12 w-auto"><span class="sr-only">MVP Painting<\/span><\/a>/}' "$INDEX"
# Also fix any lingering old paths without /logos/
sed -i 's#assets/images/logo-black.png#assets/images/logos/logo-black.png#g' "$INDEX"

# 4) Make sure the rotator JS & custom.css are linked (rotation already works, but be thorough)
grep -q 'assets/js/hero-rotator.js' "$INDEX" || sed -i 's#</head>#  <script src="assets/js/hero-rotator.js" defer></script>\n</head>#' "$INDEX"
grep -q 'assets/css/custom.css' "$INDEX" || sed -i 's#</head>#  <link rel="stylesheet" href="assets/css/custom.css">\n</head>#' "$INDEX"

# 5) Cache-bust CSS so you see the new ratios immediately
STAMP=$(date +%s)
sed -i "s#assets/css/custom.css[^\"']*#assets/css/custom.css?v=$STAMP#g" "$INDEX"

echo "Updated: hero ratio, card image ratios, header logo."
