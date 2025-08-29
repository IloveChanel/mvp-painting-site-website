Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$idx = "public/index.html"
$css = "public/assets/css/custom.css"

if (!(Test-Path $idx)) { Write-Error "Missing $idx"; exit 1 }
if (!(Test-Path $css)) {
  New-Item -ItemType Directory -Force -Path (Split-Path $css) | Out-Null
  "" | Set-Content $css
}

# --- Backups ---
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$newDir = "public/backups"
New-Item -ItemType Directory -Force -Path $newDir | Out-Null
Copy-Item $idx "$newDir/index.$stamp.html" -Force
Copy-Item $css "$newDir/custom.$stamp.css" -Force

# --- Load HTML ---
$html = Get-Content $idx -Raw

# 1) Header: ensure ONE logo block (dedupe repeats)
$headerPattern = '<a href="index\.html" class="flex items-center gap-3">.*?</a>'
if ([regex]::IsMatch($html, $headerPattern, 'Singleline')) {
  $cleanHeader = @"
<a href="index.html" class="flex items-center gap-3">
  <img src="/assets/images/logos/logo-black.png" alt="MVP Painting Logo" class="header-logo">
  <span class="sr-only">MVP Painting</span>
</a>
"@
  $html = [regex]::Replace($html, $headerPattern, $cleanHeader, 'Singleline')
}

# 2) Home cards -> PNG (case-insensitive, idempotent)
$targets = @{
  '/assets/images/home-cards/residential-1\.(?:jpe?g|png)' = '/assets/images/home-cards/residential-1.png'
  '/assets/images/home-cards/commercial-1\.(?:jpe?g|png)'  = '/assets/images/home-cards/commercial-1.png'
  '/assets/images/home-cards/exterior-1\.(?:jpe?g|png)'     = '/assets/images/home-cards/exterior-1.png'
}
foreach ($k in $targets.Keys) { $html = [regex]::Replace($html, $k, $targets[$k], 'IgnoreCase') }

# 3) Ensure hero CTA is visible .btn
$html = [regex]::Replace($html,'<a href="contact\.html#estimate-form" class="[^"]*">','<a href="contact.html#estimate-form" class="btn">','IgnoreCase')

# 4) Remove stray `cat` lines or accidental backticks
$html = ($html -split "`r?`n" | Where-Object { ($_ -notmatch '^\s*`cat\s*`$') -and ($_ -notmatch '^\s*`+\s*$') }) -join "`r`n"

# 5) Save HTML
Set-Content $idx $html -NoNewline

# 6) Softer goldwhiterose gradient + visual polish in custom.css (append once)
$softCss = @"
:root{
  --ink:#0f172a;
  --gold-1:#efe6cf; /* very light gold */
  --gold-2:#e9d8b0; /* soft brushed highlight */
  --rose-1:#e3c0c6; /* natural rose */
}
html,body{min-height:100%}
body{
  font-family: Montserrat, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif;
  color: var(--ink);
  background:
    radial-gradient(900px 700px at 100% 100%, rgba(227,192,198,.45), transparent 60%),
    linear-gradient(135deg, #fffef9 0%, var(--gold-1) 35%, var(--gold-2) 66%, var(--rose-1) 100%);
  background-attachment: fixed;
}
section,.section,.bg-paper,.bg-white{ background:transparent !important; }

.header-logo{height:48px;width:auto;display:block}
.site-nav a{font-weight:700}
.call-now{display:inline-block;padding:.5rem .9rem;border-radius:9999px;background:var(--ink);color:#fff;text-decoration:none;font-weight:700}

.parallax-hero .overlay{ background: linear-gradient(to bottom, rgba(0,0,0,.14), rgba(0,0,0,.26)) !important; }
.parallax-hero .caption h1{ color:#fff;font-weight:800;line-height:1.15;text-shadow:0 2px 8px rgba(0,0,0,.30); }

.btn{display:inline-block;padding:.9rem 1.25rem;border-radius:14px;background:#fff;color:var(--ink);font-weight:800;text-decoration:none}
.value-card{background:#fff;border-radius:1rem;box-shadow:0 12px 30px rgba(0,0,0,.10);padding:2rem;text-align:center}
.card{background:#fff;border-radius:1rem;overflow:hidden;box-shadow:0 10px 26px rgba(0,0,0,.10);border:1px solid rgba(15,23,42,.06)}
.card-img{width:100%;display:block;object-fit:cover;aspect-ratio:16/9;object-position:center}

footer .contact, footer .contact a{font-size:1.125rem;font-weight:700}
footer .social a{text-decoration:underline;opacity:.95}
"@

if (-not (Select-String -Path $css -Pattern 'natural rose' -Quiet)) {
  Add-Content $css "`r`n/* === soft-gold-rose (v3) === */`r`n$softCss"
}

# 7) Quick existence check for the assets
$missing = @()
foreach($p in @(
  "public/assets/images/logos/logo-black.png",
  "public/assets/images/home-cards/residential-1.png",
  "public/assets/images/home-cards/commercial-1.png",
  "public/assets/images/home-cards/exterior-1.png"
)) { if(!(Test-Path $p)){ $missing += $p } }
if($missing.Count -gt 0){
  Write-Warning "Missing files:`n - " + ($missing -join "`n - ")
}else{
  Write-Host " All referenced images found."
}

Write-Host " Home page patched. Backup: $newDir/index.$stamp.html"
Write-Host "Next:"
Write-Host "  git add -A"
Write-Host "  git commit -m 'Home quick fix (png cards, softer gold/rose, one logo, CTA, cleanup)'"
Write-Host "  git push"
Write-Host "Then open: https://mvppainting.netlify.app/?v=$stamp"