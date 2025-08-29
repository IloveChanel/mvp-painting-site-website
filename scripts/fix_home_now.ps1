$ErrorActionPreference = "Stop"

# Paths & backup
$idx   = "public\index.html"
$css   = "public\assets\css\custom.css"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"

if (!(Test-Path $idx)) { Write-Error "public/index.html not found"; exit 1 }
New-Item -ItemType Directory -Force -Path "public\backups" | Out-Null
Copy-Item $idx "public\backups\index.$stamp.html"
if (Test-Path $css) { Copy-Item $css "public\assets\css\custom.backup_$stamp.css" }

# Load HTML
$html = Get-Content $idx -Raw -Encoding UTF8

# 1) Remove any existing header logos (class="header-logo")
$html = [regex]::Replace($html, '<img[^>]*class="[^"]*\bheader-logo\b[^"]*"[^>]*>', '', 'IgnoreCase')

# 2) Ensure a single correct logo inside the first <a href="index.html"...>
$logoFrag = @"
<img src="/assets/images/logos/logo-black.png" alt="MVP Painting Logo" class="header-logo h-12 w-auto" style="height:48px;width:auto;display:block;">
<span class="sr-only">MVP Painting</span>
"@
$html = [regex]::Replace($html, '(<a\s+href="index\.html"[^>]*>)', "`$1`r`n        $logoFrag", 'IgnoreCase')

# 3) Ensure a visible Call Now CTA (idempotent)
if ($html -notmatch 'tel:17343662493') {
  $html = [regex]::Replace(
    $html,
    '(<nav[^>]*class="[^"]*site-nav[^"]*"[^>]*>)([\s\S]*?)(</nav>)',
    '$1$2  <a href="tel:17343662493" class="call-now">Call Now</a> $3',
    'IgnoreCase'
  )
}

# 4) Hero slides -> .jpeg
$html = [regex]::Replace(
  $html,
  "(background-image:url\('?)/?assets/images/hero-index/(hero-index-\d+)\.(?:jpg|jpeg|png)('?\))",
  "background-image:url('/assets/images/hero-index/$2.jpeg')",
  'IgnoreCase'
)

# 5) Home-card images -> .jpeg (residential-1 / commercial-1 / exterior-1)
$html = [regex]::Replace(
  $html,
  '(/assets/images/home-cards/(?:residential-1|commercial-1|exterior-1))\.(?:jpg|jpeg|png)',
  '$1.jpeg',
  'IgnoreCase'
)

# 6) Remove duplicate Our Work block with id="work"
$html = [regex]::Replace($html, '<section[^>]*id="work"[\s\S]*?</section>', '', 'IgnoreCase')

# 7) Remove stray lines like: `cat
$html = [regex]::Replace($html, '^\s*`+.*$', '', 'IgnoreCase, Multiline')

# 8) Ensure custom.css is linked (for the softened background + styles)
if ($html -notmatch 'assets/css/custom\.css') {
  $html = $html -replace '</head>', "  <link rel=""stylesheet"" href=""/assets/css/custom.css?v=$stamp"">`r`n</head>"
}

# Save HTML
Set-Content $idx $html -NoNewline -Encoding UTF8

# 9) Soft gold / rose background + readability + .btn + CTA
New-Item -ItemType Directory -Force -Path (Split-Path $css) | Out-Null
@"
/* === SOFT GOLD / ROSE (v3) === */
:root{ --ink:#0f172a; --gold-1:#f9f6ef; --gold-2:#f5ecd4; --rose-1:#e9c7cb; }
body{
  background:
    radial-gradient(900px 600px at 85% 92%, rgba(233,199,203,.32) 0%, rgba(233,199,203,0) 70%),
    linear-gradient(135deg, #ffffff 0%, #fdfbf7 35%, #faf4e8 62%, #f5eacd 85%, #f1e4bd 100%);
  background-attachment: fixed;
  color: var(--ink);
}
/* Let gradient show through basic sections; keep cards solid white for contrast */
section,.section,.bg-paper,.bg-white{ background: transparent !important; }
.value-card,.card,.cta-band,.bg-white:not(section){ background:#fff !important; }
/* Hero overlay: gentle for legibility without a "box" */
.parallax-hero .overlay{ background: linear-gradient(to bottom, rgba(0,0,0,.12), rgba(0,0,0,.22)); }
/* Nav/CTA */
.site-nav a{ font-weight:700; }
.call-now{
  display:inline-block; padding:.5rem .9rem; border-radius:9999px;
  background:var(--ink); color:#fff; font-weight:700; text-decoration:none;
}
/* Hero CTA button */
.btn{
  display:inline-block; padding:.85rem 1.15rem; border-radius:12px;
  background:#ffffff; color:var(--ink); font-weight:800; text-decoration:none;
  box-shadow:0 10px 24px rgba(0,0,0,.14);
}
.btn:hover{ opacity:.92 }
/* Card images: consistent crop */
.card-img{ width:100%; display:block; object-fit:cover; aspect-ratio:16/9 }
"@ | Set-Content $css -Encoding UTF8

# 10) Commit & push (quiet)
git add -A
git commit -m "Homepage fix: logo, CTA, .jpeg paths, remove duplicates, softer gold/rose bg, btn style" 2>$null
git push 2>$null

Write-Host " Done. Open: https://mvppainting.netlify.app/?v=$stamp"
