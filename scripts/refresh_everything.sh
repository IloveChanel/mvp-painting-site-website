#!/usr/bin/env bash
set -euo pipefail

# 1) Install packages (only if needed)
if [ -f package-lock.json ]; then
  npm ci
else
  npm install
fi

# 2) Rebuild Tailwind if your input exists
if [ -f ./src/input.css ]; then
  npx tailwindcss -i ./src/input.css -o ./public/assets/css/style.css --minify
fi

# 3) Re-run the site update (hero/logo/head links) if present
[ -f scripts/site_update.sh ] && bash scripts/site_update.sh || true

# 4) Cache-bust CSS/JS links so browsers load the new files
STAMP=$(date +%s)
for f in public/*.html; do
  [ -f "$f" ] || continue
  sed -i "s#assets/css/style.css[^\"']*#assets/css/style.css?v=$STAMP#g" "$f"
  sed -i "s#assets/css/custom.css[^\"']*#assets/css/custom.css?v=$STAMP#g" "$f"
  sed -i "s#assets/js/hero-rotator.js[^\"']*#assets/js/hero-rotator.js?v=$STAMP#g" "$f"
done

# 5) Commit & push (triggers Netlify deploy)
git add public/*.html public/assets/css/style.css public/assets/css/custom.css public/assets/js/hero-rotator.js 2>/dev/null || true
git commit -m "Refresh: install, rebuild, cache-bust ($STAMP)" || echo "Nothing to commit."
git push || true

echo "Done. If you still don't see changes, hard refresh the browser (Ctrl+F5)."
