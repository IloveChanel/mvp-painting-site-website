#!/usr/bin/env bash
set -euo pipefail

# 1) Remove any inline HERO <img> lines (we use injected parallax heroes instead)
#    Matches things like assets/images/hero-*/hero-*-N.(jpeg|jpg|png|webp)
sed -i '/assets\/images\/hero-[a-z-]*\/hero-[a-z-]*-[0-9]\+\.\(jpeg\|jpg\|png\|webp\)/d' public/*.html

# 2) Ensure gallery images are lazy/async
sed -i 's#<img src="assets/images/gallery/#<img loading="lazy" decoding="async" src="assets/images/gallery/#g' public/*.html

# 3) Footer white logo can be lazy
sed -i 's#<img src="assets/images/logos/logo-white.png#<img loading="lazy" decoding="async" src="assets/images/logos/logo-white.png#g' public/*.html

# (Optional) If you see TWO header logos and only want the fixed one,
# uncomment the next line to remove any inline black logo <img> (leave the fixed ".logo-fixed" one).
# sed -i '/assets\/images\/logos\/logo-black\.png/ {/logo-fixed/!d}' public/*.html
