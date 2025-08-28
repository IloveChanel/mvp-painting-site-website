#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

INDEX="public/index.html"
CSS="public/assets/css/custom.css"
IMG1="assets/images/gallery/interior/kitchen-after-sterling-heights-macomb-county.jpg"
IMG2="assets/images/gallery/exterior/exterior-brick-after-eastpointe-macomb-county.jpg"
IMG3="assets/images/gallery/commercial/commercial-masonic-temple-after-stclair-shores-macomb-county.jpg"

# 0) backup
cp -f "$INDEX" "public/index.backup_$(date +%Y%m%d_%H%M%S).html"

# 1) CSS: remove any hero caption box/blur/shadow and soften overlay
mkdir -p "$(dirname "$CSS")"; touch "$CSS"

# ensure a first-slide fallback
grep -q '/* === HERO FALLBACK === */' "$CSS" || cat >> "$CSS" <<'CSS'
/* === HERO FALLBACK === */
.parallax-hero .slide:first-child{opacity:1}
CSS

# hard override: no box, no blur, no text-shadow; overlay very light (or none)
cat >> "$CSS" <<'CSS'
/* === HERO CAPTION NO-BOX (force) === */
.parallax-hero .overlay{background: none !important}
.parallax-hero .caption .card{
  background: transparent !important;
  backdrop-filter: none !important;
  box-shadow: none !important;
  border: 0 !important;
  padding: clamp(18px,2.6vw,30px);
}
.parallax-hero .caption h1,
.parallax-hero .caption p{
  text-shadow: none !important;
}
CSS

# 2) Header brand logo: fix path AND ensure it exists inside header brand link
#    Replace the brand link (the one that points to index.html) with a known-good version.
sed -i '0,/<a href="index\.html"[^>]*>.*<\/a>/{s//<a href="index.html" class="flex items-center gap-3"><img src="assets\/images\/logos\/logo-black.png" alt="MVP Painting Logo" class="h-12 w-auto"><span class="sr-only">MVP Painting<\/span><\/a>/}' "$INDEX"

# Also fix any lingering old path without /logos/
sed -i 's#assets/images/logo-black.png#assets/images/logos/logo-black.png#g' "$INDEX"

# 3) Clean up "Our Work" section by replacing it with a tidy, consistent 3-card grid
awk '
  BEGIN{skip=0}
  /<section[^>]*class="[^"]*max-w-7xl[^"]*[^>]*>/ && /Our Work/ {print "<!-- REPLACED Our Work section -->"; print; print "<h2 class=\"text-3xl font-bold text-center mb-10\">Our Work</h2>"; print "    <div class=\"grid md:grid-cols-3 gap-8\">"; 
    print "      <div class=\"bg-white rounded-2xl shadow overflow-hidden border border-slate-200\">";
    print "        <img loading=\"lazy\" decoding=\"async\" src=\"" ENVIRON["IMG1"] "\" alt=\"Residential Interior Painting\" class=\"w-full h-56 object-cover\">";
    print "        <div class=\"p-5\">";
    print "          <h3 class=\"font-semibold text-lg mb-2\">Residential Interior</h3>";
    print "          <p class=\"text-slate-600\">Clean lines, modern colors, flawless finishes.</p>";
    print "        </div>";
    print "      </div>";
    print "      <div class=\"bg-white rounded-2xl shadow overflow-hidden border border-slate-200\">";
    print "        <img loading=\"lazy\" decoding=\"async\" src=\"" ENVIRON["IMG2"] "\" alt=\"Exterior Painting\" class=\"w-full h-56 object-cover\">";
    print "        <div class=\"p-5\">";
    print "          <h3 class=\"font-semibold text-lg mb-2\">Exterior Painting</h3>";
    print "          <p class=\"text-slate-600\">Weather-resistant coatings that boost curb appeal.</p>";
    print "        </div>";
    print "      </div>";
    print "      <div class=\"bg-white rounded-2xl shadow overflow-hidden border border-slate-200\">";
    print "        <img loading=\"lazy\" decoding=\"async\" src=\"" ENVIRON["IMG3"] "\" alt=\"Commercial Painting\" class=\"w-full h-56 object-cover\">";
    print "        <div class=\"p-5\">";
    print "          <h3 class=\"font-semibold text-lg mb-2\">Commercial Projects</h3>";
    print "          <p class=\"text-slate-600\">Professional results for offices, retail, and more.</p>";
    print "        </div>";
    print "      </div>";
    print "    </div>";
    print "    <div class=\"text-center mt-10\">";
    print "      <a href=\"gallery.html\" class=\"inline-block px-8 py-3 rounded-xl bg-primary text-white font-semibold shadow hover:bg-slate-800 transition\">View Full Gallery</a>";
    print "    </div>";
    skip=1; next
  }
  skip==1 && /<\/section>/ {print; skip=0; next}
  skip==1 {next}
  {print}
' "$INDEX" > "$INDEX.tmp" && mv "$INDEX.tmp" "$INDEX"

# 4) Cache-bust custom.css so browser pulls the latest overrides
STAMP=$(date +%s)
sed -i "s#assets/css/custom.css[^\"']*#assets/css/custom.css?v=$STAMP#g" "$INDEX"

echo "Home visuals fixed: logo ensured, hero caption box removed, Our Work cleaned."
