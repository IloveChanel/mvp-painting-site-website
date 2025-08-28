#!/usr/bin/env bash
set -euo pipefail

DEST=public/assets/images/logos
mkdir -p "$DEST"

# Copy over files if not yet present
for color in black white; do
  SRC=$(find public -maxdepth 3 -iname "logo-$color.png" | head -n1 || true)
  if [ -n "$SRC" ] && [ ! -f "$DEST/logo-$color.png" ]; then
    cp "$SRC" "$DEST/logo-$color.png"
    echo "Copied $SRC to $DEST/logo-$color.png"
  fi
done

# Fix HTML path references
for f in public/*.html public/about public/services public/gallery public/blog public/contact; do
  [ -f "$f" ] || continue
  sed -i 's#assets/images/logo.png#assets/images/logos/logo-black.png#g' "$f"
  sed -i 's#assets/images/logos/logo\.png#assets/images/logos/logo-black.png#g' "$f"
done
