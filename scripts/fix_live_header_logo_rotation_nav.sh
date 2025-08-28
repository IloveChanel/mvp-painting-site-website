#!/usr/bin/env bash
set -euo pipefail

ROOT=public
LOGODIR="$ROOT/assets/images/logos"
mkdir -p "$LOGODIR"

# 1) Make sure the logo files are present in the deploy dir
for name in logo-black.png logo-white.png; do
  if [ ! -f "$LOGODIR/$name" ]; then
    found="$(find "$ROOT/assets/images" -maxdepth 2 -type f -iname "$name" | head -n1 || true)"
    if [ -n "${found:-}" ]; then
      cp -f "$found" "$LOGODIR/$name"
      echo "Copied $(basename "$found") into $LOGODIR"
    else
      echo "WARNING: $name missing. Add $LOGODIR/$name (PNG)."
    fi
  fi
done

# 2) Add a CSS safety so first slide is visible even before JS runs
CSS="$ROOT/assets/css/custom.css"
mkdir -p "$(dirname "$CSS")"; touch "$CSS"
grep -q '/* === HERO FALLBACK === */' "$CSS" || cat >> "$CSS" <<'CSS'
/* === HERO FALLBACK === */
.parallax-hero .slide:first-child{opacity:1}
CSS

# 3) Ensure rotator JS + custom.css are linked in <head>
ensure_head () {
  local f="$1"; [ -f "$f" ] || return 0
  grep -q 'assets/js/hero-rotator.js' "$f" || \
    sed -i 's#</head>#  <script src="assets/js/hero-rotator.js" defer></script>\n</head>#' "$f"
  grep -q 'assets/css/custom.css' "$f" || \
    sed -i 's#</head>#  <link rel="stylesheet" href="assets/css/custom.css">\n</head>#' "$f"
}
for f in "$ROOT"/*.html "$ROOT"/{about,services,gallery,blog,contact}; do
  [ -f "$f" ] && ensure_head "$f"
done

# 4) Fix header logo path + add "Call Now" button next to Contact
for f in "$ROOT"/*.html; do
  [ -f "$f" ] || continue
  # correct any old path to the logos folder
  sed -i 's#assets/images/logo-black.png#assets/images/logos/logo-black.png#g' "$f"
  # add a Call Now button once, right before </nav> (if a nav is present)
  if ! grep -q 'tel:17343662493' "$f"; then
    sed -i 's#</nav>#  <a href="tel:17343662493" class="ml-4 inline-flex items-center rounded-xl bg-accent text-white font-semibold px-4 py-2 shadow hover:opacity-90">Call&nbsp;Now (734)&nbsp;366-2493</a>\n</nav>#' "$f" || true
  fi
done
