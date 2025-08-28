#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

ROOT="public"
LOGODIR="$ROOT/assets/images/logos"

mkdir -p "$LOGODIR"

echo "== 1) Standardize logos (keep logo-black.png, logo-white.png) =="
# Prefer PNG; normalize names and remove extras (incl. generic logo.png)
for color in black white; do
  # If the canonical file exists, remember it; otherwise pick the first match and rename to canonical
  if [ ! -f "$LOGODIR/logo-$color.png" ]; then
    found="$(find "$LOGODIR" -maxdepth 1 -type f -iregex ".*logo-$color\.(png|jpg|jpeg|webp)" | head -n1 || true)"
    if [ -n "${found:-}" ]; then
      git mv -f "$found" "$LOGODIR/logo-$color.png" 2>/dev/null || mv -f "$found" "$LOGODIR/logo-$color.png"
    fi
  fi
  # Remove any other variants after we have the canonical one
  find "$LOGODIR" -maxdepth 1 -type f -iregex ".*logo-$color\.(png|jpg|jpeg|webp)" ! -path "$LOGODIR/logo-$color.png" -delete
done
# Drop generic logo.png if present (avoids confusion)
rm -f "$LOGODIR/logo.png"

echo "== 2) Move design source files (.ai/.svg) out of public =="
mkdir -p design/brand
for f in "$LOGODIR"/*.ai "$LOGODIR"/*.svg; do
  [ -e "$f" ] || continue
  git mv -f "$f" "design/brand/$(basename "$f")" 2>/dev/null || mv -f "$f" "design/brand/$(basename "$f")"
done

echo "== 3) Ensure hero rotator JS + CSS fallback =="
# First-slide visible even if JS is cached/slow
CSS="$ROOT/assets/css/custom.css"
mkdir -p "$(dirname "$CSS")"; touch "$CSS"
grep -q '/* === HERO FALLBACK === */' "$CSS" || cat >> "$CSS" <<'CSS'
/* === HERO FALLBACK === */
.parallax-hero .slide:first-child{opacity:1}
CSS

# Make sure the rotator file exists (you already have it, but this is safe)
JSFILE="$ROOT/assets/js/hero-rotator.js"
if [ ! -f "$JSFILE" ]; then
  mkdir -p "$(dirname "$JSFILE")"
  cat > "$JSFILE" <<'JS'
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

# Link rotator + custom.css in <head> if missing
ensure_head () {
  local f="$1"; [ -f "$f" ] || return 0
  sed -i '/cdn\.tailwindcss\.com/d' "$f"
  grep -q 'assets/css/custom.css' "$f" || sed -i 's#</head>#  <link rel="stylesheet" href="assets/css/custom.css">\n</head>#' "$f"
  grep -q 'assets/js/hero-rotator.js' "$f" || sed -i 's#</head>#  <script src="assets/js/hero-rotator.js" defer></script>\n</head>#' "$f"
}
for f in "$ROOT"/*.html "$ROOT"/{about,services,gallery,blog,contact}; do
  [ -f "$f" ] && ensure_head "$f"
done

echo "== 4) Fix header brand logo path on all pages =="
# Use the black logo in the header brand (white header background)
for f in "$ROOT"/*.html; do
  [ -f "$f" ] || continue
  sed -i 's#assets/images/logo-black.png#assets/images/logos/logo-black.png#g' "$f"
  sed -i 's#assets/images/logos/logo\.png#assets/images/logos/logo-black.png#g' "$f"
done

echo "== 5) Add \"Call Now\" button next to Contact in nav (once) =="
for f in "$ROOT"/*.html; do
  [ -f "$f" ] || continue
  # Insert the button right before </nav> if it doesn't exist yet
  if ! grep -q 'tel:17343662493' "$f"; then
    sed -i 's#</nav>#  <a href="tel:17343662493" class="ml-4 inline-flex items-center rounded-xl bg-accent text-white font-semibold px-4 py-2 shadow hover:opacity-90">Call&nbsp;Now (734)&nbsp;366-2493</a>\n</nav>#' "$f" || true
  fi
done

echo "== 6) Cache-bust asset links so the browser pulls fresh files =="
STAMP=$(date +%s)
for f in "$ROOT"/*.html; do
  [ -f "$f" ] || continue
  sed -i "s#assets/css/custom.css[^\"']*#assets/css/custom.css?v=$STAMP#g" "$f"
  sed -i "s#assets/js/hero-rotator.js[^\"']*#assets/js/hero-rotator.js?v=$STAMP#g" "$f"
done

echo "All fixes applied."
