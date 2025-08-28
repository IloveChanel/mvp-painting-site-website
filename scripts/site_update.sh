#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

PAGES=(index about gallery blog services)
LOGO_SRC="assets/images/logos/logo-black.png"

mkdir -p public/assets/css public/assets/js scripts

# Build Tailwind if input exists
if [ -f ./src/input.css ]; then
  npx tailwindcss -i ./src/input.css -o ./public/assets/css/style.css --minify
fi

# Ensure CSS/JS
touch public/assets/css/custom.css
grep -q '\.logo-fixed' public/assets/css/custom.css || cat >> public/assets/css/custom.css <<'CSS'
/* Fixed top-right logo */
.logo-fixed{position:fixed;top:20px;right:20px;height:60px;z-index:1000}
@media (max-width:640px){.logo-fixed{height:48px;top:12px;right:12px}}
CSS

grep -q '/* === PARALLAX HERO ROTATOR === */' public/assets/css/custom.css || cat >> public/assets/css/custom.css <<'CSS'
/* === PARALLAX HERO ROTATOR === */
.parallax-hero{position:relative;min-height:440px;overflow:hidden}
@media (max-width:640px){.parallax-hero{min-height:320px}}
.parallax-hero .slides{position:absolute;inset:0;will-change:transform}
.parallax-hero .slide{position:absolute;inset:0;background-size:cover;background-position:center;opacity:0;transition:opacity .8s ease}
.parallax-hero .slide.is-active{opacity:1}
.parallax-hero .overlay{position:absolute;inset:0;pointer-events:none;background:linear-gradient(180deg,rgba(0,0,0,.12),rgba(0,0,0,.10))}
CSS

cat > public/assets/js/hero-rotator.js <<'JS'
document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.parallax-hero .slides').forEach(slides => {
    const items = Array.from(slides.querySelectorAll('.slide'));
    if (!items.length) return;
    let i = 0; items[0].classList.add('is-active');
    setInterval(() => { items[i].classList.remove('is-active'); i=(i+1)%items.length; items[i].classList.add('is-active'); }, 5000);
  });
  const onScroll = () => {
    document.querySelectorAll('.parallax-hero .slides').forEach(slides => {
      const rect = slides.parentElement.getBoundingClientRect();
      slides.style.transform = `translateY(${rect.top * -0.15}px)`;
    });
  };
  onScroll(); document.addEventListener('scroll', onScroll, { passive: true });
});
JS

# Ensure head links and fixed logo
fix_head () {
  local f="public/$1.html"; [ -f "$f" ] || return 0
  sed -i '/cdn\.tailwindcss\.com/d' "$f"
  grep -q 'assets/css/style.css' "$f" || sed -i 's#</head>#  <link rel="stylesheet" href="assets/css/style.css">\n</head>#' "$f"
  grep -q 'assets/css/custom.css' "$f" || sed -i 's#</head>#  <link rel="stylesheet" href="assets/css/custom.css">\n</head>#' "$f"
  grep -q 'assets/js/hero-rotator.js' "$f" || sed -i 's#</head>#  <script src="assets/js/hero-rotator.js" defer></script>\n</head>#' "$f"
  grep -q 'class="logo-fixed"' "$f" || sed -i "s#<body[^>]*>#&\n  <img src=\"$LOGO_SRC\" alt=\"MVP Painting Logo\" class=\"logo-fixed\">#" "$f"
}
for p in "${PAGES[@]}"; do fix_head "$p"; done

# Helper: inject hero from assets/images/hero-<page>/*
inject_hero () {
  local page="$1"; local html="public/${page}.html"; [ -f "$html" ] || return 0
  local dir="public/assets/images/hero-$page"
  [ -d "$dir" ] || { echo "skip hero ($page): $dir not found"; return 0; }
  imgs=( "$dir"/*.jpeg "$dir"/*.jpg "$dir"/*.png "$dir"/*.webp )
  [ ${#imgs[@]} -gt 0 ] || { echo "skip hero ($page): no images in $dir"; return 0; }

  local block="scripts/hero_${page}.html"
  {
    echo "<!-- BEGIN HERO (${page^^}) -->"
    echo "<section class=\"parallax-hero\" id=\"hero-${page}\" aria-label=\"${page^} hero\">"
    echo "  <div class=\"slides\">"
    for f in "${imgs[@]}"; do
      rel="${f#public/}"
      printf "    <div class=\"slide\" style=\"background-image:url('%s')\"></div>\n" "$rel"
    done
    echo "  </div>"
    echo "  <div class=\"overlay\"></div>"
    echo "</section>"
    echo "<!-- END HERO (${page^^}) -->"
  } > "$block"

  local begin="<!-- BEGIN HERO (${page^^}) -->" end="<!-- END HERO (${page^^}) -->"
  sed -i "/${begin//\//\\/}/,/${end//\//\\/}/d" "$html"
  awk -v r="$(cat "$block")" '
    BEGIN{ins=0}
    /<body[^>]*>/ && ins==0 { print; print r; ins=1; next }
    { print }
    END{ if(ins==0) print r }
  ' "$html" > "$html.tmp" && mv "$html.tmp" "$html"
}
for p in "${PAGES[@]}"; do inject_hero "$p"; done

# Stage changes
git add public/assets/css/style.css public/assets/css/custom.css public/assets/js/hero-rotator.js public/*.html scripts/*.html 2>/dev/null || true
