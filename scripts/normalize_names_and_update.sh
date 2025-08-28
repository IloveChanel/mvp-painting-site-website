#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

ROOT="public/assets/images"
PAGES=(index about gallery blog)   # add 'services' later when you have that folder

# --- A) Rename hero folders to the final names ---
rename_folder () {
  local old="$1" new="$2"
  if [ -d "$old" ] && [ ! -d "$new" ]; then
    mv "$old" "$new"
  elif [ -d "$old" ] && [ -d "$new" ]; then
    # move contents if both exist
    mv "$old"/* "$new"/ 2>/dev/null || true
    rmdir "$old" 2>/dev/null || true
  fi
}
rename_folder "$ROOT/hero-about-photos"   "$ROOT/hero-about"
rename_folder "$ROOT/hero-blog-photos"    "$ROOT/hero-blog"
rename_folder "$ROOT/hero-gallery-photos" "$ROOT/hero-gallery"
rename_folder "$ROOT/hero-index-photo"    "$ROOT/hero-index"

# Ensure targets exist
for p in "${PAGES[@]}"; do mkdir -p "$ROOT/hero-$p"; done

# --- B) Normalize hero filenames (lowercase, hyphens, preserve number if present) ---
normalize_dir () {
  local page="$1" dir="$ROOT/hero-$page"
  [ -d "$dir" ] || return 0
  declare -A used=()
  # Collect all candidate files
  files=( "$dir"/*.[Jj][Pp][Gg] "$dir"/*.[Jj][Pp][Ee][Gg] "$dir"/*.[Pp][Nn][Gg] "$dir"/*.[Ww][Ee][Bb][Pp] )
  for f in "${files[@]}"; do
    [ -e "$f" ] || continue
    base="$(basename "$f")"
    # lowercase + spaces/underscores -> hyphens
    low="$(echo "$base" | tr '[:upper:]' '[:lower:]')"
    low="${low// /-}"; low="${low//_/-}"
    ext="${low##*.}"
    name="${low%.*}"
    # normalize ext: jpg -> jpeg; keep png/webp as-is
    case "$ext" in
      jpg) ext="jpeg" ;;
      jpeg|png|webp) : ;;
      *) : ;;
    esac
    # grab first number if present
    num="$(echo "$name" | grep -oE '[0-9]+' | head -n1 || true)"
    # if no number, pick next free
    if [[ -z "$num" ]]; then
      i=1
      while [[ -n "${used[$i]-}" || -e "$dir/hero-$page-$i.$ext" ]]; do i=$((i+1)); done
      num="$i"
    fi
    used[$num]=1
    # stage path adjustments
    src="$dir/$base"
    mid="$dir/$low"
    [ "$src" != "$mid" ] && mv -f "$src" "$mid" || true
    dst="$dir/hero-$page-$num.$ext"
    [ "$mid" != "$dst" ] && mv -f "$mid" "$dst" || true
  done
}
for p in "${PAGES[@]}"; do normalize_dir "$p"; done

# --- C) Update HTML references to new folders and names ---
for html in public/*.html; do
  [ -f "$html" ] || continue
  # folders
  sed -i 's#assets/images/hero-about-photos#assets/images/hero-about#g' "$html"
  sed -i 's#assets/images/hero-blog-photos#assets/images/hero-blog#g' "$html"
  sed -i 's#assets/images/hero-gallery-photos#assets/images/hero-gallery#g' "$html"
  sed -i 's#assets/images/hero-index-photo#assets/images/hero-index#g' "$html"
  # old file prefixes -> new hero-* prefixes
  sed -i 's#index-photo-#hero-index-#g' "$html"
  sed -i 's#about-photo-#hero-about-#g' "$html"
  sed -i 's#gallery-photo-#hero-gallery-#g' "$html"
  sed -i 's#blog-photo-#hero-blog-#g' "$html"
  # ensure .jpg -> .jpeg for hero refs
  sed -E -i 's#(assets/images/hero-[^" ]+-[0-9]+)\.jpg#\1.jpeg#g' "$html"
done

# --- D) Re-inject parallax heroes + ensure head/logo (idempotent) ---
# (Creates the helpers if they don't exist, then runs them)
mkdir -p public/assets/css public/assets/js

# CSS: fixed logo + hero styles
touch public/assets/css/custom.css
grep -q '\.logo-fixed' public/assets/css/custom.css || cat >> public/assets/css/custom.css <<'CSS'
/* Fixed top-right logo */
.logo-fixed{position:fixed;top:20px;right:20px;height:60px;z-index:1000}
@media (max-width:640px){.logo-fixed{height:48px;top:12px;right:12px}}
CSS
grep -q '/* === PARALLAX HERO ROTATOR === */' public/assets/css/custom.css || cat >> public/assets/css/custom.css <<'CSS'
/* === PARALLAX HERO ROTATOR === */
.parallax-hero{position:relative;min-height:440px;overflow:hidden}
@media (max-width:640px){.parallax-hero{min-height:320px}}
.parallax-hero .slides{position:absolute;inset:0;will-change:transform}
.parallax-hero .slide{position:absolute;inset:0;background-size:cover;background-position:center;opacity:0;transition:opacity .8s ease}
.parallax-hero .slide.is-active{opacity:1}
.parallax-hero .overlay{position:absolute;inset:0;pointer-events:none;background:linear-gradient(180deg,rgba(0,0,0,.12),rgba(0,0,0,.10))}
CSS

# JS: rotator
cat > public/assets/js/hero-rotator.js <<'JS'
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

# Head/Logo per page
ensure_head_and_logo () {
  local f="public/$1.html"; [ -f "$f" ] || return 0
  sed -i '/cdn\.tailwindcss\.com/d' "$f"
  grep -q 'assets/css/style.css' "$f" || sed -i 's#</head>#  <link rel="stylesheet" href="assets/css/style.css">\n</head>#' "$f"
  grep -q 'assets/css/custom.css' "$f" || sed -i 's#</head>#  <link rel="stylesheet" href="assets/css/custom.css">\n</head>#' "$f"
  grep -q 'assets/js/hero-rotator.js' "$f" || sed -i 's#</head>#  <script src="assets/js/hero-rotator.js" defer></script>\n</head>#' "$f"
  grep -q 'class="logo-fixed"' "$f" || sed -i 's#<body[^>]*>#&\
  <img src="assets/images/logos/logo-black.png" alt="MVP Painting Logo" class="logo-fixed">#' "$f"
}
for p in "${PAGES[@]}"; do ensure_head_and_logo "$p"; done

# Inject hero blocks from new hero folders
inject_hero () {
  local page="$1" html="public/${page}.html" dir="$ROOT/hero-$page"
  [ -f "$html" ] || return 0
  [ -d "$dir" ] || { echo "skip hero ($page): $dir missing"; return 0; }
  imgs=( "$dir"/*.jpeg "$dir"/*.jpg "$dir"/*.png "$dir"/*.webp )
  [ ${#imgs[@]} -gt 0 ] || { echo "skip hero ($page): no images in $dir"; return 0; }
  mkdir -p scripts
  {
    echo "<!-- BEGIN HERO (${page^^}) -->"
    echo "<section class=\"parallax-hero\" id=\"hero-${page}\" aria-label=\"${page^} hero\">"
    echo "  <div class=\"slides\">"
    for f in "${imgs[@]}"; do
      rel="${f#public/}"
      printf "    <div class=\"slide\" style=\"background-image:url('%s')\"></div>\n" "$rel"
    done
    echo "  </div>"
    echo "  <div class=\"overlay\"></div>"
    echo "</section>"
    echo "<!-- END HERO (${page^^}) -->"
  } > "scripts/hero_${page}.html"
  begin="<!-- BEGIN HERO (${page^^}) -->"; end="<!-- END HERO (${page^^}) -->"
  sed -i "/${begin//\//\\/}/,/${end//\//\\/}/d" "$html"
  awk -v r="$(cat "scripts/hero_${page}.html")" '
    BEGIN{ins=0}
    /<body[^>]*>/ && ins==0 { print; print r; ins=1; next }
    { print }
    END{ if(ins==0) print r }
  ' "$html" > "$html.tmp" && mv "$html.tmp" "$html"
}
for p in "${PAGES[@]}"; do inject_hero "$p"; done

# Stage changes
git add public/assets/css/custom.css public/assets/js/hero-rotator.js public/*.html "$ROOT"/hero-*/* 2>/dev/null || true
