set -euo pipefail

test -f public/index.html || { echo "âŒ Run from the repo root"; exit 1; }
git add -A && git commit -m "WIP: snapshot before rose-gold everywhere" || true

CSS=public/assets/css/custom.css
touch "$CSS"

# 1) Stronger gradient base on the whole page
if ! grep -q 'ROSE-GOLD-EVERYWHERE' "$CSS"; then
  cat >> "$CSS" <<'CSS'
/* === ROSE-GOLD-EVERYWHERE (v2) === */
html,body{min-height:100%}
body{
  background:
    repeating-linear-gradient(100deg, rgba(255,255,255,.06) 0 2px, rgba(0,0,0,.05) 2px 4px),
    linear-gradient(135deg,#caa04a 0%,#e5c77a 40%,#d9a0a5 100%);
  background-attachment: fixed;
}

/* Let the gradient show through big bands */
section.bg-paper,
.section.bg-paper,
section.bg-white{
  background: transparent !important;
}

/* Keep cards/panels readable */
.card,.value-card,.bg-white:not(section){
  background:#fff !important;
}

/* Optional: testimonials body text stays dark */
.parallax-hero .caption h1{color:#111827}
/* === /ROSE-GOLD-EVERYWHERE === */
CSS
  echo "âœ… Added gradient + transparency overrides to $CSS"
else
  echo "â„¹ï¸ Overrides already present in $CSS"
fi

# 2) Home page: remove any 'bg-paper' class so the section wonâ€™t cover the gradient
#    (only on index.html, safe & idempotent)
sed -i.bak -E 's/\bbg-paper\b ?//g' public/index.html
rm -f public/index.html.bak

# 3) Make sure the three home cards point at your home-cards images if present
for pair in "residential-1 Residential Interior Painting" \
            "commercial-1 Commercial Painting" \
            "exterior-1 Exterior Painting"; do
  name="${pair%% *}"; alt="${pair#* }"
  if [ -f "public/assets/images/home-cards/${name}.jpg" ] || [ -f "public/assets/images/home-cards/${name}.webp" ]; then
    sed -i -E "s#(<img[^>]*class=\"card-img\"[^>]*src=\")[^\"]*(\"[^>]*alt=\"${alt}\")#\1/assets/images/home-cards/${name}.jpg\2#" public/index.html || true
    sed -i -E "s#(<img[^>]*class=\"card-img\"[^>]*src=\")[^\"]*(\"[^>]*alt=\"${alt}\")#\1/assets/images/home-cards/${name}.webp\2#" public/index.html || true
  fi
done

git add -A
git commit -m "Show rose-gold behind all sections; keep cards readable; tidy home cards" || true
git push || true

echo "í¾‰ Done. Hard refresh: https://mvppainting.netlify.app/?t=$(date +%s)"
