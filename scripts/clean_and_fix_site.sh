#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

: "${DRY_RUN:=1}"   # preview by default. set DRY_RUN=0 to apply.

PUB="public"
LOGOS="$PUB/assets/images/logos"
CSSDIR="$PUB/assets/css"
JSDIR="$PUB/assets/js"
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"

say(){ printf '%s\n' "$*"; }
do_mv(){ if [ "$DRY_RUN" = "0" ]; then mkdir -p "$(dirname "$2")"; git mv -f "$1" "$2" 2>/dev/null || mv -f "$1" "$2"; fi; say "move: $1 -> $2"; }
do_rm(){ if [ "$DRY_RUN" = "0" ]; then rm -f -- "$@"; fi; printf 'delete: %s\n' "$*"; }
do_sed(){ # sed in-place
  if [ "$DRY_RUN" = "0" ]; then sed -i "$1" "$2"; else say "sed: $2 :: $1"; fi
}

# --- 0) Make dirs ---
mkdir -p "$BACKUP_DIR" "$LOGOS" "$CSSDIR" "$JSDIR"

# --- 1) Move HTML backups out of public (don’t deploy backups) ---
for f in "$PUB"/index.backup_*.html; do
  [ -e "$f" ] || continue
  do_mv "$f" "$BACKUP_DIR/$(basename "$f")"
done

# --- 2) Remove old build CSS and stray pages folder assets ---
[ -f "$PUB/assets/index-Cp9mPwme.css" ] && do_rm "$PUB/assets/index-Cp9mPwme.css"
[ -d pages ] && do_mv pages "$BACKUP_DIR/pages_archive"

# --- 3) Logos: keep only logo-black.png + logo-white.png inside /logos ---
for f in "$LOGOS"/*; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  case "$base" in
    logo-black.png|logo-white.png) : ;;
    *) do_mv "$f" "design/brand/$base" ;;
  esac
done

# --- 4) Ensure CSS/JS exist ---
touch "$CSSDIR/custom.css"
[ -f "$JSDIR/hero-rotator.js" ] || cat > "$JSDIR/hero-rotator.js" <<'JS'
document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.parallax-hero .slides').forEach(slides => {
    const items = Array.from(slides.querySelectorAll('.slide'));
    if (!items.length) return;
    let i = 0; items[0].classList.add('is-active');
    setInterval(()=>{ items[i].classList.remove('is-active'); i=(i+1)%items.length; items[i].classList.add('is-active'); }, 5000);
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

# --- 5) Strong CSS overrides: hero text no box + ratios + card image ratio ---
if ! grep -q '/* === SITE FIXES === */' "$CSSDIR/custom.css"; then
cat >> "$CSSDIR/custom.css" <<'CSS'
/* === SITE FIXES === */
.parallax-hero{position:relative;width:100%;aspect-ratio:1980/1000;height:auto;max-height:85vh;overflow:hidden}
@media (max-width:640px){.parallax-hero{aspect-ratio:16/10;max-height:70vh}}
.parallax-hero .slides{position:absolute;inset:0;will-change:transform}
.parallax-hero .slide{position:absolute;inset:0;background-size:cover;background-position:center;opacity:0;transition:opacity .8s ease}
.parallax-hero .slide.is-active,.parallax-hero .slide:first-child{opacity:1}
.parallax-hero .overlay{background:none !important}
.parallax-hero .caption .card{background:transparent !important;backdrop-filter:none !important;box-shadow:none !important;border:0 !important;padding:clamp(18px,2.6vw,30px)}
.parallax-hero .caption h1,.parallax-hero .caption p{ text-shadow:none !important }
.img-card{display:block;width:100%;aspect-ratio:1980/1000;object-fit:cover}
@media (max-width:640px){.img-card{aspect-ratio:16/10}}
CSS
fi

# --- 6) Standard header across ALL public pages (logo + nav + call now) ---
HEADER_BLOCK='
<header class="bg-white/95 backdrop-blur shadow-sm sticky top-0 z-50">
  <div class="max-w-7xl mx-auto flex items-center justify-between py-4 px-6">
    <a href="index.html" class="flex items-center gap-3">
      <img src="assets/images/logos/logo-black.png" alt="MVP Painting Logo" class="h-12 w-auto">
      <span class="sr-only">MVP Painting</span>
    </a>
    <nav class="hidden md:flex items-center gap-6">
      <a href="index.html" class="hover:underline">Home</a>
      <a href="services.html" class="hover:underline">Services</a>
      <a href="gallery.html" class="hover:underline">Gallery</a>
      <a href="about.html" class="hover:underline">About</a>
      <a href="blog.html" class="hover:underline">Blog</a>
      <a href="contact.html" class="hover:underline">Contact</a>
      <a href="tel:17343662493" class="inline-block px-3 py-1 rounded bg-[#0f172a] text-white font-semibold">Call Now</a>
    </nav>
  </div>
</header>'

for f in "$PUB"/*.html; do
  [ -f "$f" ] || continue
  # remove any stray "logo-fixed" images at top
  do_sed '/class="[^"]*logo-fixed[^"]*"/d' "$f"
  # make sure our CSS/JS are linked and custom.css is AFTER style.css
  grep -q 'assets/js/hero-rotator.js' "$f" || do_sed 's#</head>#  <script src="assets/js/hero-rotator.js" defer></script>\n</head>#' "$f"
  grep -q 'assets/css/custom.css' "$f" || do_sed 's#</head>#  <link rel="stylesheet" href="assets/css/custom.css">\n</head>#' "$f"
  # remove legacy Vite css includes
  do_sed '/assets\/index-Cp9mPwme\.css/d' "$f"
  # normalize any old logo path
  do_sed 's#assets/images/logo-black.png#assets/images/logos/logo-black.png#g' "$f"
  # replace existing header block with standard header
  awk -v h="$HEADER_BLOCK" '
    BEGIN{inH=0}
    /<header[[:space:]>]/ {print h; inH=1; next}
    inH && /<\/header>/ {inH=0; next}
    inH {next}
    {print}
  ' "$f" > "$f.tmp" && { [ "$DRY_RUN" = "0" ] && mv "$f.tmp" "$f" || { echo "rewrite header in: $f"; rm -f "$f.tmp"; }; }
done

# --- 7) Fix card images to use .img-card (stops cropping short) on index only ---
IDX="$PUB/index.html"
[ -f "$IDX" ] && do_sed 's/class="w-full h-56 object-cover"/class="img-card"/g' "$IDX"

# --- 8) Cache-bust css/js so Netlify fetches new files ---
STAMP=$(date +%s)
for f in "$PUB"/*.html; do
  [ -f "$f" ] || continue
  do_sed "s#assets/css/custom.css[^\"']*#assets/css/custom.css?v=$STAMP#g" "$f"
  do_sed "s#assets/js/hero-rotator.js[^\"']*#assets/js/hero-rotator.js?v=$STAMP#g" "$f"
done

say "DONE. DRY_RUN=$DRY_RUN"
