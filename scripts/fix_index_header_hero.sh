#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

INDEX="public/index.html"
IMG_DIR="public/assets/images/hero-index"
CSS="public/assets/css/custom.css"

# Backup
cp -f "$INDEX" "public/index.backup_$(date +%Y%m%d_%H%M%S).html"

# Ensure CSS for hero + caption overlay
mkdir -p "$(dirname "$CSS")"
touch "$CSS"
if ! grep -q '/* === HERO CAPTION === */' "$CSS"; then
  cat >> "$CSS" <<'CSS'
/* === HERO CAPTION === */
.parallax-hero{position:relative;min-height:520px;overflow:hidden}
@media (max-width:640px){.parallax-hero{min-height:360px}}
.parallax-hero .slides{position:absolute;inset:0;will-change:transform}
.parallax-hero .slide{position:absolute;inset:0;background-size:cover;background-position:center;opacity:0;transition:opacity .8s ease}
.parallax-hero .slide.is-active{opacity:1}
.parallax-hero .overlay{position:absolute;inset:0;pointer-events:none;background:linear-gradient(180deg,rgba(0,0,0,.18),rgba(0,0,0,.12))}
.parallax-hero .caption{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;text-align:center;padding:clamp(16px,3vw,48px);z-index:2}
.parallax-hero .caption .card{max-width:960px;background:rgba(0,0,0,.35);color:#fff;border-radius:16px;padding:clamp(18px,2.6vw,30px);backdrop-filter:blur(4px)}
.parallax-hero .caption h1{margin:0 0 .4em;font-size:clamp(28px,4.2vw,48px);line-height:1.1;font-weight:800}
.parallax-hero .caption p{margin:0 0 1em;font-size:clamp(16px,2.1vw,20px)}
.parallax-hero .caption .cta{display:inline-block;padding:12px 22px;font-weight:700;border-radius:12px;background:#f1c232;color:#111;text-decoration:none}
.parallax-hero .caption .cta:hover{opacity:.92}
CSS
fi

# Build the hero rotation block with overlay text
mkdir -p scripts
BLOCK="scripts/hero_index_with_caption.html"
{
  echo "<!-- BEGIN HERO (INDEX) -->"
  echo "<section class=\"parallax-hero\" id=\"hero-index\" data-hero=\"rotation\" aria-label=\"Index hero\">"
  echo "  <div class=\"slides\">"
  for f in "$IMG_DIR"/*.jpeg "$IMG_DIR"/*.jpg "$IMG_DIR"/*.png "$IMG_DIR"/*.webp; do
    [ -e "$f" ] || continue
    rel=\"${f#public/}\"
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

# Clean any previously injected hero block
sed -i '/<!-- BEGIN HERO (INDEX) -->/,/<!-- END HERO (INDEX) -->/d' "$INDEX"

# Remove the old orange gradient band (legacy hero)
sed -i '/<!-- Hero Section -->/,/<\/section>/d' "$INDEX"
awk '
  BEGIN{skip=0}
  /<section[^>]*class=.*bg-gradient-to-br.*from-accent.*to-gold/ {skip=1}
  skip==0 {print}
  skip==1 && /<\/section>/ {skip=0}
' "$INDEX" > "$INDEX.tmp" && mv "$INDEX.tmp" "$INDEX"

# Remove stray demo images near the top (portfolio preview / project gallery / footer logo placeholders)
sed -i '/<!-- Portfolio Preview -->/,+5d' "$INDEX"
sed -i '/<!-- Project Gallery -->/,+5d' "$INDEX"
sed -i '/<!-- Footer Logo -->/,+2d' "$INDEX"

# Remove any inline fixed overlay logos (we'll keep the header brand logo)
sed -i '/class="[^"]*logo-fixed[^"]*"/d' "$INDEX"

# Fix header brand logo path if missing /logos/
sed -i 's#assets/images/logo-black.png#assets/images/logos/logo-black.png#g' "$INDEX"

# Inject the new hero directly AFTER </header> so header is above the rotation
if grep -q '</header>' "$INDEX"; then
  awk -v r="$(cat "$BLOCK")" '
    BEGIN{ins=0}
    { print }
    /<\/header>/ && ins==0 { print r; ins=1 }
  ' "$INDEX" > "$INDEX.tmp" && mv "$INDEX.tmp" "$INDEX"
else
  # Fallback: after <body>
  awk -v r="$(cat "$BLOCK")" '
    BEGIN{ins=0}
    /<body[^>]*>/ && ins==0 { print; print r; ins=1; next }
    { print }
  ' "$INDEX" > "$INDEX.tmp" && mv "$INDEX.tmp" "$INDEX"
fi

echo "index.html updated: header above hero rotation, orange band removed, overlay caption+CTA added."
