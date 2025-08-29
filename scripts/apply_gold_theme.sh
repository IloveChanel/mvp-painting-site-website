set -euo pipefail

# --- sanity checks ---
test -f public/index.html || { echo "❌ Run from your repo root (public/index.html not found)"; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "❌ Not a git repo"; exit 1; }

# --- snapshot current state ---
git add -A && git commit -m "WIP: snapshot before gold theme" || true

# --- ensure folders ---
mkdir -p public/assets/css public/assets/js public/assets/images/home-cards

# --- add/append CSS theme once ---
CSS_FILE="public/assets/css/custom.css"
touch "$CSS_FILE"
if ! grep -q "=== LUXE GOLD THEME START ===" "$CSS_FILE"; then
  cat >> "$CSS_FILE" <<'CSS'

/* === LUXE GOLD THEME START === */
:root{
  --ink:#0f172a;
  --paper:#fbf8f4;
  --gold:#caa04a;
  --gold-2:#e5c77a;
  --rose:#d9a0a5;
  --accent:#6b214e;
  --accent-ink:#ffffff;
}

/* brushed gold -> rose gold */
body{
  color:var(--ink);
  background:
    repeating-linear-gradient(100deg, rgba(255,255,255,.06) 0 2px, rgba(0,0,0,.05) 2px 4px),
    linear-gradient(135deg, var(--gold) 0%, var(--gold-2) 40%, var(--rose) 100%);
  background-attachment: fixed;
}

/* content panels read clearly on the luxe background */
.section, .bg-paper, .bg-white, .card, .value-card{
  background: rgba(255,255,255,.78);
  backdrop-filter: saturate(110%) blur(0px);
}

/* header / nav / CTA */
.header-logo{height:48px;width:auto;display:block}
.site-nav a{font-weight:700}
.site-nav .cta{
  padding:.55rem .95rem;border-radius:.75rem;
  background:var(--accent);color:var(--accent-ink);
  box-shadow:0 6px 18px rgba(107,33,78,.18);
}
.site-nav .cta:hover{filter:brightness(1.05)}

/* hero overlay: crisp text, no blurry box */
.parallax-hero .caption .card{
  background:transparent!important;border:0!important;box-shadow:none!important;
}
.parallax-hero .caption h1{
  color:#111827;
  text-shadow:0 2px 12px rgba(255,255,255,.85), 0 3px 18px rgba(0,0,0,.18);
  font-weight:800;
}
.parallax-hero .caption p{color:#1f2937}

/* home project-gallery cards */
.work-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:24px}
@media (max-width:1024px){ .work-grid{grid-template-columns:repeat(2,1fr)} }
@media (max-width:640px){ .work-grid{grid-template-columns:1fr} }
.card{
  border-radius:18px;overflow:hidden;border:1px solid rgba(17,24,39,.08);
  box-shadow:0 8px 24px rgba(17,24,39,.06);background:#fff;
}
.card-img{width:100%;display:block;object-fit:cover;aspect-ratio:16/9}
.card .body{padding:18px}

/* image safety */
img{max-width:100%;height:auto;display:block}
/* === LUXE GOLD THEME END === */
CSS
  echo "✅ Theme CSS appended to $CSS_FILE"
else
  echo "ℹ️ Theme CSS already present"
fi

# --- ensure header logo uses absolute path on INDEX and add Call Now if missing ---
IDX=public/index.html

# absolute path for header logo (black); if missing fallback to white
if grep -q 'src="assets/images/logos/logo-black.png"' "$IDX"; then
  sed -i.bak 's#src="assets/images/logos/logo-black.png"#src="/assets/images/logos/logo-black.png"#g' "$IDX"
elif grep -q 'src="assets/images/logos/logo-white.png"' "$IDX"; then
  sed -i.bak 's#src="assets/images/logos/logo-white.png"#src="/assets/images/logos/logo-white.png"#g' "$IDX"
fi
rm -f "$IDX.bak"

# add the Call Now CTA inside nav if not present
if ! grep -q 'Call Now' "$IDX"; then
  sed -i.bak '/<\/nav>/{i\
      <a href="tel:17343662493" class="cta">Call Now</a>
  }' "$IDX"
  rm -f "$IDX.bak"
  echo "✅ Inserted Call Now CTA in header nav"
else
  echo "ℹ️ Call Now CTA already present"
fi

# --- footer logo absolute path ---
if grep -q 'src="assets/images/logos/logo-white.png"' "$IDX"; then
  sed -i.bak 's#src="assets/images/logos/logo-white.png"#src="/assets/images/logos/logo-white.png"#g' "$IDX"
  rm -f "$IDX.bak"
fi

# --- prepare home-card images; if not provided, copy sensible defaults ---
RES=public/assets/images/home-cards/residential-1.jpg
COM=public/assets/images/home-cards/commercial-1.jpg
EXT=public/assets/images/home-cards/exterior-1.jpg

test -f "$RES" || cp -f public/assets/images/gallery/interior/kitchen-after-sterling-heights-macomb-county.jpg "$RES" 2>/dev/null || true
test -f "$COM" || cp -f public/assets/images/gallery/commercial/commercial-masonic-temple-after-stclair-shores-macomb-county.jpg "$COM" 2>/dev/null || true
test -f "$EXT" || cp -f public/assets/images/gallery/exterior/exterior-brick-after-eastpointe-macomb-county.jpg "$EXT" 2>/dev/null || true

# --- point the three home cards to the new absolute paths by ALT text ---
# Residential
sed -i.bak -E 's#(<img[^>]*class="card-img"[^>]*src=")[^"]*("[^>]*alt="Residential Interior Painting")#\1\/assets\/images\/home-cards\/residential-1.jpg\2#' "$IDX"
# Commercial
sed -i.bak -E 's#(<img[^>]*class="card-img"[^>]*src=")[^"]*("[^>]*alt="Commercial Painting")#\1\/assets\/images\/home-cards\/commercial-1.jpg\2#' "$IDX"
# Exterior
sed -i.bak -E 's#(<img[^>]*class="card-img"[^>]*src=")[^"]*("[^>]*alt="Exterior Painting")#\1\/assets\/images\/home-cards\/exterior-1.jpg\2#' "$IDX"
rm -f "$IDX.bak"

# --- ensure CSS/JS links exist in <head> (idempotent) ---
# style.css
grep -q 'assets/css/style.css' "$IDX" || sed -i.bak '0,/<\/head>/{s#</head>#  <link rel="stylesheet" href="assets/css/style.css">\n</head>#}' "$IDX"
# custom.css
grep -q 'assets/css/custom.css' "$IDX" || sed -i.bak '0,/<\/head>/{s#</head>#  <link rel="stylesheet" href="assets/css/custom.css">\n</head>#}' "$IDX"
# hero-rotator.js
grep -q 'assets/js/hero-rotator.js' "$IDX" || sed -i.bak '0,/<\/head>/{s#</head>#  <script src="assets/js/hero-rotator.js" defer></script>\n</head>#}' "$IDX"
rm -f "$IDX.bak"

# --- verify logo files exist; warn if missing ---
if [ ! -f public/assets/images/logos/logo-black.png ] && [ ! -f public/assets/images/logos/logo-white.png ]; then
  echo "⚠️  No logo files found in public/assets/images/logos/. Add logo-black.png and/or logo-white.png"
fi

# --- commit & push ---
git add -A
git commit -m "Apply luxe gold theme, fix header logo/CTA, set home-card images, make paths absolute" || true
git push || true

echo "��� Done. Open: https://mvppainting.netlify.app/?t=$(date +%s) and hard-refresh (Ctrl/Cmd+F5)"
