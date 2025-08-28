#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

PUB="public"
CSS="$PUB/assets/css/custom.css"
JSDIR="$PUB/assets/js"
STAMP=$(date +%s)

# 0) Make sure CSS/JS exist
mkdir -p "$(dirname "$CSS")" "$JSDIR"
touch "$CSS"

# 1) Strong visual styles (nav bold, hero darker text, soft overlay, better cards)
#    These are appended once.
grep -q '/* === NAV + HERO TIGHTEN === */' "$CSS" || cat >> "$CSS" <<'CSS'
/* === NAV + HERO TIGHTEN === */
.site-nav a{font-weight:700} /* bolder nav */
.site-nav a:hover{opacity:.85}

/* Keep hero 2:1 and show first slide */
.parallax-hero{position:relative;width:100%;aspect-ratio:1980/1000;height:auto;max-height:85vh;overflow:hidden}
@media (max-width:640px){.parallax-hero{aspect-ratio:16/10;max-height:70vh}}
.parallax-hero .slides{position:absolute;inset:0;will-change:transform}
.parallax-hero .slide{position:absolute;inset:0;background-size:cover;background-position:center;opacity:0;transition:opacity .8s ease}
.parallax-hero .slide.is-active,.parallax-hero .slide:first-child{opacity:1}

/* Soft gradient overlay for readability (not a box) */
.parallax-hero .overlay{
  position:absolute;inset:0;
  background: linear-gradient(to bottom, rgba(0,0,0,.35) 0%, rgba(0,0,0,.15) 45%, rgba(0,0,0,0) 75%);
  pointer-events:none;
}

/* If you ever want zero overlay again, add class "no-overlay" on the section */
.parallax-hero.no-overlay .overlay{background:none !important}

/* Caption text: darker & heavier without blur */
.parallax-hero .caption h1{color:#0f172a;font-weight:900;letter-spacing:-.01em}
.parallax-hero .caption p{color:#111827;font-weight:600}

/* Card images: use ratio so they aren’t short/cropped */
.img-card{display:block;width:100%;aspect-ratio:1980/1000;min-height:220px;object-fit:cover}
@media (max-width:640px){.img-card{aspect-ratio:16/10}}
CSS

# 2) Standard header with logo + CTA (applied to every page)
HEADER_BLOCK='
<header class="bg-white/95 backdrop-blur shadow-sm sticky top-0 z-50">
  <div class="max-w-7xl mx-auto flex items-center justify-between py-4 px-6">
    <a href="index.html" class="flex items-center gap-3">
      <img src="assets/images/logos/logo-black.png" alt="MVP Painting Logo" class="h-12 w-auto" style="display:block">
      <span class="sr-only">MVP Painting</span>
    </a>
    <nav class="site-nav hidden md:flex items-center gap-6">
      <a href="index.html">Home</a>
      <a href="services.html">Services</a>
      <a href="gallery.html">Gallery</a>
      <a href="about.html">About</a>
      <a href="blog.html">Blog</a>
      <a href="contact.html">Contact</a>
      <a href="tel:17343662493" class="inline-block px-3 py-1 rounded bg-[#0f172a] text-white font-semibold">Call Now</a>
    </nav>
  </div>
</header>'

for f in "$PUB"/*.html; do
  [ -f "$f" ] || continue

  # ensure CSS/JS links
  grep -q 'assets/js/hero-rotator.js' "$f" || sed -i 's#</head>#  <script src="assets/js/hero-rotator.js" defer></script>\n</head>#' "$f"
  grep -q 'assets/css/custom.css' "$f" || sed -i 's#</head>#  <link rel="stylesheet" href="assets/css/custom.css">\n</head>#' "$f"

  # normalize any old logo path
  sed -i 's#assets/images/logo-black.png#assets/images/logos/logo-black.png#g' "$f"

  # drop any stray top-of-body floating logos
  sed -i '/class="[^"]*logo-fixed[^"]*"/d' "$f"

  # replace the first <header>…</header> with standard header
  awk -v h="$HEADER_BLOCK" '
    BEGIN{inH=0; printed=0}
    /<header[[:space:]>]/ && !printed {print h; inH=1; printed=1; next}
    inH && /<\/header>/ {inH=0; next}
    inH {next}
    {print}
  ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"

  # cache-bust
  sed -i "s#assets/css/custom.css[^\"']*#assets/css/custom.css?v=$STAMP#g" "$f"
  sed -i "s#assets/js/hero-rotator.js[^\"']*#assets/js/hero-rotator.js?v=$STAMP#g" "$f"

  # make sure card images use the ratio class on Home
  case "$f" in
    *index.html) sed -i 's/class="w-full h-56 object-cover"/class="img-card"/g' "$f" ;;
  esac
done

echo "Done: nav bold + CTA, darker hero text, soft overlay, card ratio, logo enforced."
