param()
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
function Fix-Text([string]$content) {
  $t = $content.Replace([char]0xFEFF,'')
  $t = [regex]::Replace($t, "[\u0000-\u0008\u000B\u000C\u000E-\u001F]", "")
  $t = $t -replace "â€”","—" -replace "â€“","–" -replace "â€¦","…" `
           -replace "â€˜","‘" -replace "â€™","’" -replace "â€œ","“" -replace "â€\u009d?","”" `
           -replace "âœ”","✔" -replace "âœ“","✓" `
           -replace "ðŸ[\u0080-\u00BF]+","" -replace "ðŸ†","🏆" -replace "›¡ï¸",""
  return $t
}
$files = Get-ChildItem -Recurse -Include *.html,*.css,*.js,*.toml
foreach ($f in $files) {
  $raw = [IO.File]::ReadAllText($f.FullName,[Text.Encoding]::UTF8)
  $fixed = Fix-Text $raw
  [IO.File]::WriteAllText($f.FullName,$fixed,$utf8NoBom)
}
Write-Host "Sanitize complete."