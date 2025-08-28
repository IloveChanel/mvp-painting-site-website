#!/usr/bin/env bash
set -euo pipefail
PUB="public"
FILE="$PUB/index.html"
STAMP=$(date +%s)

# 1) Backup
cp "$FILE" "$FILE.bak_$STAMP"

# 2) Strip stray naked images that were sitting under the hero
sed -i '/assets\/images\/gallery\/interior\/kitchen-after-.*\.jpg/d' "$FILE"
sed -i '/assets\/images\/gallery\/exterior\/exterior-brick-after-.*\.jpg/d' "$FILE"
sed -i '/assets\/images\/gallery\/commercial\/commercial-masonic-temple-after-.*\.jpg/d' "$FILE"
sed -i '/assets\/images\/logo-white\.png[^"]*class="h-10 w-auto"/d' "$FILE"

# 3) Remove the old "Our Work" section (if still present)
awk '
  BEGIN{drop=0}
  /<section[^>]*max-w-7xl[^>]*>/ {buf=$0}
  /<h2[^>]*>Our Work<\/h2>/ {drop=1}
  { if(!drop) print }
  /<\/section>/ { if(drop){ drop=0 } }
' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"

# 4) Rebuild the Project Gallery section as a proper 3-card grid
awk '
  BEGIN{inGal=0}
  /<section[^>]*id="gallery"[^>]*>/ {inGal=1; print "<section id=\"gallery\" class=\"section bg-paper\">"; next}
  inGal && /<\/section>/ {
    print "  <div class=\"container\">";
    print "    <h2 class=\"h2 center\">Project Gallery</h2>";
    print "    <div class=\"work-grid\">";
    print "      <a class=\"card\" href=\"gallery.html#interior\">";
    print "        <img class=\"card-img\" src=\"assets/images/gallery/interior/kitchen-after-sterling-heights-macomb-county.jpg\" alt=\"Residential Interior Painting\">";
    print "        <div class=\"body\"><h3>Residential Interior</h3><p>Clean lines, modern colors, flawless finishes.</p></div>";
    print "      </a>";
    print "      <a class=\"card\" href=\"gallery.html#commercial\">";
    print "        <img class=\"card-img\" src=\"assets/images/gallery/commercial/commercial-masonic-temple-after-stclair-shores-macomb-county.jpg\" alt=\"Commercial Painting\">";
    print "        <div class=\"body\"><h3>Commercial Projects</h3><p>Professional results for offices, retail, and more.</p></div>";
    print "      </a>";
    print "      <a class=\"card\" href=\"gallery.html#exterior\">";
    print "        <img class=\"card-img\" src=\"assets/images/gallery/exterior/exterior-brick-after-eastpointe-macomb-county.jpg\" alt=\"Exterior Painting\">";
    print "        <div class=\"body\"><h3>Exterior Painting</h3><p>Weather-resistant coatings that boost curb appeal.</p></div>";
    print "      </a>";
    print "    </div>";
    print "    <p class=\"center mt-10\"><a class=\"btn\" href=\"gallery.html\">View Full Gallery</a></p>";
    print "  </div>";
    print "</section>";
    inGal=0; next
  }
  inGal{next}
  {print}
' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"

# 5) Ensure helper styles exist (no Tailwind required for these)
CSS="$PUB/assets/css/custom.css"
mkdir -p "$(dirname "$CSS")"
touch "$CSS"
if ! grep -q '/* === HOME GRID HELPERS === */' "$CSS"; then
cat >> "$CSS" <<'CSS'
/* === HOME GRID HELPERS === */
.section{padding:4rem 1rem}
.container{max-width:80rem;margin-inline:auto}
.h2{font-size:clamp(1.75rem,2.5vw,2.25rem);font-weight:800;color:#0f172a;margin-bottom:1.25rem}
.center{text-align:center}
.mt-10{margin-top:2.5rem}
.bg-paper{background:#f7f5f2}

.work-grid{display:grid;grid-template-columns:repeat(1,minmax(0,1fr));gap:2rem}
@media (min-width: 768px){.work-grid{grid-template-columns:repeat(3,minmax(0,1fr))}}

.card{display:block;background:#fff;border:1px solid #e5e7eb;border-radius:1rem;overflow:hidden;box-shadow:0 6px 18px rgba(0,0,0,.06)}
.card-img{display:block;width:100%;aspect-ratio:1980/1000;object-fit:cover}
.card .body{padding:1rem}
.card .body h3{font-weight:700;color:#0f172a;margin:0 0 .25rem}
.card .body p{color:#475569;margin:0}

/* hero readability (keeps what we added earlier) */
.parallax-hero .overlay{
  position:absolute;inset:0;
  background: linear-gradient(to bottom, rgba(0,0,0,.35) 0%, rgba(0,0,0,.15) 45%, rgba(0,0,0,0) 75%);
  pointer-events:none;
}
.parallax-hero .caption h1{color:#0f172a;font-weight:900;letter-spacing:-.01em}
.parallax-hero .caption p{color:#111827;font-weight:600}
CSS
fi

# 6) Cache-bust CSS reference so Netlify pulls fresh styles
for f in "$PUB"/*.html; do
  sed -i "s#assets/css/custom.css[^\"']*#assets/css/custom.css?v=$STAMP#g" "$f"
done

echo "✅ Home cleaned and rebuilt. Backup: $FILE.bak_$STAMP"
