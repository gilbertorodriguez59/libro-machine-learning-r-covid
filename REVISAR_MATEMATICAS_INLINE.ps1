$File = Join-Path $PSScriptRoot "11-redes-neuronales.qmd"
$Text = Get-Content -LiteralPath $File -Raw -Encoding UTF8
if ($Text.Contains('\(') -or $Text.Contains('\)')) {
  Write-Host "ADVERTENCIA: todavía existen delimitadores \( o \)." -ForegroundColor Yellow
} else {
  Write-Host "Correcto: las matemáticas en línea usan delimitadores $...$." -ForegroundColor Green
}
pause
