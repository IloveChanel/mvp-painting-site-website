#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

INDEX="public/index.html"
CSS="public/assets/css/custom.css"
IMG_DIR="public/assets/images/hero-index"
LOGO="assets/images/logos/logo-black.png"

# 0) backup
cp -f "$INDEX" "public/index.backup_$(date +%Y%m%d_%H%M%S).html"

# 1) ensure CSS exists and remove the dark box around the caption
mkdir -p "$(dirname "$CSS")"; touch "$CSS"

# fallback so first slide is visible even before JS runs
grep -q '/* === HERO FALLBACK === */' "$CSS" || cat >> "$CSS" <<'CSS'
/* === HERO FALLBACK === */
.parallax-hero .slide:first-child{opacity:1}
CSS

# remove box: make caption background transparent and add subtle text shadow for readability
if ! grep -q '/* === HERO CAPTION NObox === */' "$CSS"; then
  cat >> "$CSS" <<'CSS'
/* === HERO CAPTION NObox === */
.parallax-hero{position:relative;min-height:520px;overflow:hidden}
@media (max-width:640px){.parallax-hero{min-height:360px}}
.parallax-hero .slides{position:absolute;inset:0;will-change:transform}
.parallax-hero .slide{position:absolute;inset:0;background-size:cover;background-position:center;opacity:0;transition:opacity .8s ease}
.parallax-hero .slide.is-active{opacity:1}
.parallax-hero .overlay{position:absolute;inset:0;pointer-events:none;background:linear-gradient(180deg,rgba(0,0,0,.18),rgba(0,0,0,.12))}
.parallax-hero .caption{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;text-align:center;padding:clamp(16px,3vw,48px);z-index:2}
.parallax-hero .caption .card{max-width:960px;background:transparent;border:none;box-shadow:none;padding:clamp(18px,2.6vw,30px)}
.parallax-hero .caption h1{margin:0 0 .4em;font-size:clamp(28px,4.2vw,48px);line-height:1.1;font-weight:800;text-shadow:0 2px 8px rgba(0,0,0,.35)}
.parallax-hero .caption p{margin:0 0 1em;font-size:clamp(16px,2.1vw,20px);text-shadow:0 1px 6px rgba(0,0,0,.35)}
.parallax-hero .caption .cta{display:inline-block;padding:12px 22px;font-weight:700;border-radius:12px;background:#f1c232;color:#111;text-decoration:none}
.parallax-hero .caption .cta:hover{opacity:.92}
CSS
fi

# 2) hero rotator JS (create if missing) + link in <head>
JS="public/assets/js/hero-rotator.js"
if [ ! -f "$JS" ]; then
  mkdir -p "$(dirname "$JS")"
  cat > "$JS" <<'JS'
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
fi
grep -q 'assets/js/hero-rotator.js' "$INDEX" || sed -i 's#</head>#  <script src="assets/js/hero-rotator.js" defer></script>\n</head>#' "$INDEX"
grep -q 'assets/css/custom.css' "$INDEX"   || sed -i 's#</head>#  <link rel="stylesheet" href="assets/css/custom.css">\n</head>#' "$INDEX"

# 3) rebuild the hero block (clean any previous one, then inject after </header>)
sed -i '/<!-- BEGIN HERO (INDEX) -->/,/<!-- END HERO (INDEX) -->/d' "$INDEX"

mkdir -p scripts
BLOCK="scripts/hero_index_overlay.html"
{
  echo "<!-- BEGIN HERO (INDEX) -->"
  echo "<section class=\"parallax-hero\" id=\"hero-index\" data-hero=\"rotation\" aria-label=\"Index hero\">"
  echo "  <div class=\"slides\">"
  for f in "$IMG_DIR"/*.jpeg "$IMG_DIR"/*.jpg "$IMG_DIR"/*.png "$IMG_DIR"/*.webp; do
    [ -e "$f" ] || continue
    rel="${f#public/}"
    printf "    <div class=\"slide\" style=\"background-image:url('%s')\"></div>\n" "$rel"
  done
  echo "  </div>"
  echo "  <div class=\"overlay\"></div>"
  echo "  <div class=\"caption\">"
  echo "    <div class=\"card\">"
  echo "      <h1>Premium Painting for Homes &amp; Businesses in Macomb &amp; Oakland County</h1>"
  echo "      <p>Transform your space with Michigan’s most trusted painting team. Clean, professional, and always on time.</p>"
  echo "      <a href=\"contact.html#estimate-form\" class=\"cta\">Request Your Free Quote</a>"
  echo "    </div>"
  echo "  </div>"
  echo "</section>"
  echo "<!-- END HERO (INDEX) -->"
} > "$BLOCK"

if grep -q '</header>' "$INDEX"; then
  awk -v r="$(cat "$BLOCK")" '
    BEGIN{ins=0}
    { print }
    /<\/header>/ && ins==0 { print r; ins=1 }
  ' "$INDEX" > "$INDEX.tmp" && mv "$INDEX.tmp" "$INDEX"
else
  awk -v r="$(cat "$BLOCK")" '
    BEGIN{ins=0}
    /<body[^>]*>/ && ins==0 { print; print r; ins=1; next }
    { print }
  ' "$INDEX" > "$INDEX.tmp" && mv "$INDEX.tmp" "$INDEX"
fi

# 4) header logo: correct path and insert a brand img if there is none in <header>
#    a) fix any old paths missing /logos/
sed -i 's#assets/images/logo-black.png#assets/images/logos/logo-black.png#g' "$INDEX"
#    b) if no <img ...MVP Painting Logo...> inside header, insert one just after <header>
if ! awk '/<header/{inH=1} inH && /<\/header>/{inH=0} inH && /<img[^>]*MVP Painting Logo/{found=1} END{exit(!found)}' "$INDEX"; then
  # insert brand image block after the opening <header ...>
  sed -i '0,/<header[^>]*>/{s//&\
    <div class="brand-insert"><a href="index.html"><img src="assets\/images\/logos\/logo-black.png" alt="MVP Painting Logo" class="h-12 w-auto"></a><\/div>/}' "$INDEX"
fi

# 5) cache-bust CSS/JS so Netlify serves fresh assets
STAMP=$(date +%s)
sed -i "s#assets/css/custom.css[^\"']*#assets/css/custom.css?v=$STAMP#g" "$INDEX"
sed -i "s#assets/js/hero-rotator.js[^\"']*#assets/js/hero-rotator.js?v=$STAMP#g" "$INDEX"

echo "Done: logo ensured, rotation enabled, caption box removed."
