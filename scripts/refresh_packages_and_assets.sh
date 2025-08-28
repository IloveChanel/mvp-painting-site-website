#!/usr/bin/env bash
set -euo pipefail

echo "Node:"; node -v || true
echo "npm:";  npm -v  || true

# 1) Clean install deps
if [ -f package-lock.json ]; then
  npm ci
else
  npm install
fi

# 2) Ensure Tailwind CLI (dev deps)
if ! npx --yes tailwindcss -v >/dev/null 2>&1; then
  npm i -D tailwindcss postcss autoprefixer
fi

# 3) Ensure Tailwind config exists (DON'T overwrite if present)
if [ ! -f tailwind.config.js ]; then
  npx tailwindcss init -p
  # minimal sensible content globs
  sed -i 's/content: \[\]/content: ["public\\/*.html","public\\/*\\/*.html","src\\/**/*.js"]/g' tailwind.config.js
fi

# 4) Ensure input.css exists (DON'T overwrite if present)
mkdir -p src public/assets/css
if [ ! -f src/input.css ]; then
  cat > src/input.css <<'CSS'
@tailwind base;
@tailwind components;
@tailwind utilities;
/* Your extra CSS can live in public/assets/css/custom.css */
CSS
fi

# 5) Build Tailwind -> public/assets/css/style.css
npx tailwindcss -c tailwind.config.js -i ./src/input.css -o ./public/assets/css/style.css --minify

# 6) Make sure our helper CSS/JS exist (no duplicates)
touch public/assets/css/custom.css
if [ ! -f public/assets/js/hero-rotator.js ]; then
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
fi

echo "✅ Packages refreshed and CSS rebuilt to public/assets/css/style.css"
