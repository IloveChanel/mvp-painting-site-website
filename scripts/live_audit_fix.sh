#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

PAGES=(index about services gallery blog contact)
HERO_PAGES=(index about services gallery blog)
ROOT="public"
IMGROOT="public/assets/images"
LOGO_SRC="assets/images/logos/logo-black.png"

echo "== 1) HTML patch across pages =="

fix_file () {
  local f="$1"; [ -f "$f" ] || return 0

  # Fix any stray comment tokens
  sed -i 's/<<!--/<!--/g' "$f"

  # Keep only one include of style.css, custom.css, hero-rotator.js
  for pat in 'assets/css/style\.css' 'assets/css/custom\.css' 'assets/js/hero-rotator\.js'; do
    awk -v P="$pat" 'BEGIN{c=0} { if ($0 ~ P) { c++; if (c>1) next } print }' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  done

  # Keep only the first fixed logo image (class="logo-fixed")
  awk 'BEGIN{c=0} { if ($0 ~ /class="[^"]*logo-fixed[^"]*"/) { c++; if (c>1) next } print }' "$f" > "$f.tmp" && mv "$f.tmp" "$f"

  # Correct any header brand logo path missing /logos/
  sed -i 's#assets/images/logo-black.png#assets/images/logos/logo-black.png#g' "$f"

  # Remove inline HERO <img> tags (we inject a background rotator)
  sed -i '/assets\/images\/hero-[a-z-]*\/hero-[a-z-]*-[0-9]\+\.\(jpeg\|jpg\|png\|webp\)/d' "$f"

  # Lazy-load gallery images and footer logo
  sed -i 's#<img src="assets/images/gallery/#<img loading="lazy" decoding="async" src="assets/images/gallery/#g' "$f"
  sed -i 's#<img src="assets/images/logos/logo-white.png#<img loading="lazy" decoding="async" src="assets/images/logos/logo-white.png#g' "$f"

  # Replace any empty base64 logos with file path
  sed -i 's#src="data:image/png;base64,[^"]*"#src="assets/images/logos/logo-white.png"#g' "$f"
}

for p in "${PAGES[@]}"; do fix_file "$ROOT/$p.html" || true; done  # .html files
# also handle /contact or /services without .html (Netlify clean URLs)
for p in contact services; do [ -f "$ROOT/$p" ] && fix_file "$ROOT/$p"; done

echo "== 2) Ensure CSS/JS assets and head links =="

mkdir -p "$ROOT/assets/css" "$ROOT/assets/js"

# Build Tailwind if you have src/input.css
if [ -f ./src/input.css ]; then
  npx tailwindcss -i ./src/input.css -o "$ROOT/assets/css/style.css" --minify
fi

# Ensure custom.css (logo + parallax styles)
touch "$ROOT/assets/css/custom.css"
grep -q '\.logo-fixed' "$ROOT/assets/css/custom.css" || cat >> "$ROOT/assets/css/custom.css" <<'CSS'
/* Fixed top-right logo */
.logo-fixed{position:fixed;top:20px;right:20px;height:60px;z-index:1000}
@media (max-width:640px){.logo-fixed{height:48px;top:12px;right:12px}}
CSS

grep -q '/* === PARALLAX HERO ROTATOR === */' "$ROOT/assets/css/custom.css" || cat >> "$ROOT/assets/css/custom.css" <<'CSS'
/* === PARALLAX HERO ROTATOR === */
.parallax-hero{position:relative;min-height:440px;overflow:hidden}
@media (max-width:640px){.parallax-hero{min-height:320px}}
.parallax-hero .slides{position:absolute;inset:0;will-change:transform}
.parallax-hero .slide{position:absolute;inset:0;background-size:cover;background-position:center;opacity:0;transition:opacity .8s ease}
.parallax-hero .slide.is-active{opacity:1}
.parallax-hero .overlay{position:absolute;inset:0;pointer-events:none;background:linear-gradient(180deg,rgba(0,0,0,.12),rgba(0,0,0,.10))}
CSS

# Rotator JS
cat > "$ROOT/assets/js/hero-rotator.js" <<'JS'
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

# Ensure head links + single fixed-logo per page
ensure_head_logo () {
  local file="$1"; [ -f "$file" ] || return 0
  # Remove Tailwind CDN if present
  sed -i '/cdn\.tailwindcss\.com/d' "$file"
  # Ensure links
  grep -q 'assets/css/style.css' "$file" || sed -i 's#</head>#  <link rel="stylesheet" href="assets/css/style.css">\n</head>#' "$file"
  grep -q 'assets/css/custom.css' "$file" || sed -i 's#</head>#  <link rel="stylesheet" href="assets/css/custom.css">\n</head>#' "$file"
  grep -q 'assets/js/hero-rotator.js' "$file" || sed -i 's#</head>#  <script src="assets/js/hero-rotator.js" defer></script>\n</head>#' "$file"
  # Ensure exactly one fixed overlay logo
  grep -q 'class="logo-fixed"' "$file" || sed -i "s#<body[^>]*>#&\n  <img src=\"$LOGO_SRC\" alt=\"MVP Painting Logo\" class=\"logo-fixed\">#" "$file"
}
for p in "${PAGES[@]}"; do
  for cand in "$ROOT/$p.html" "$ROOT/$p"; do
    [ -f "$cand" ] && ensure_head_logo "$cand"
  done
done

echo "== 3) Inject parallax heroes from hero-* folders =="

inject_hero () {
  local page="$1"
  # support both clean (/contact) and .html; we inject only into real files that exist
  local html="$ROOT/${page}.html"
  [ -f "$html" ] || return 0
  local dir="$IMGROOT/hero-$page"
  [ -d "$dir" ] || { echo "  (skip $page: $dir not found)"; return 0; }
  imgs=( "$dir"/*.jpeg "$dir"/*.jpg "$dir"/*.png "$dir"/*.webp )
  [ ${#imgs[@]} -gt 0 ] || { echo "  (skip $page: no images)"; return 0; }

  mkdir -p scripts
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
  } > "scripts/hero_${page}.html"

  begin="<!-- BEGIN HERO (${page^^}) -->"; end="<!-- END HERO (${page^^}) -->"
  sed -i "/${begin//\//\\/}/,/${end//\//\\/}/d" "$html"
  awk -v r="$(cat "scripts/hero_${page}.html")" '
    BEGIN{ins=0}
    /<body[^>]*>/ && ins==0 { print; print r; ins=1; next }
    { print }
    END{ if(ins==0) print r }
  ' "$html" > "$html.tmp" && mv "$html.tmp" "$html"
}
for p in "${HERO_PAGES[@]}"; do inject_hero "$p"; done

echo "== 4) Cache-bust asset links =="
STAMP=$(date +%s)
for f in "$ROOT"/*.html "$ROOT"/contact "$ROOT"/services; do
  [ -f "$f" ] || continue
  sed -i "s#assets/css/style.css[^\"']*#assets/css/style.css?v=$STAMP#g" "$f"
  sed -i "s#assets/css/custom.css[^\"']*#assets/css/custom.css?v=$STAMP#g" "$f"
  sed -i "s#assets/js/hero-rotator.js[^\"']*#assets/js/hero-rotator.js?v=$STAMP#g" "$f"
done

echo "== 5) Commit & push =="
git add -A
git commit -m "Live audit: dedupe includes, fix logo paths, rebuild heroes, cache-bust ($STAMP)" || echo "Nothing to commit."
git push || true

echo "All done."
