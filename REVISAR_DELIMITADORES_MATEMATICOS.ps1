$ErrorActionPreference = "Stop"
$File = Join-Path $PSScriptRoot "11-redes-neuronales.qmd"
$Lines = Get-Content -LiteralPath $File -Encoding UTF8
$InCode = $false
$InMath = $false
$Problems = @()
for ($i = 0; $i -lt $Lines.Count; $i++) {
  $S = $Lines[$i].Trim()
  if ($S.StartsWith("```")) { $InCode = -not $InCode; continue }
  if ($InCode) { continue }
  if ($S -eq '$$') { $InMath = -not $InMath; continue }
  if ($InMath -and $S.Contains('$')) {
    $Problems += "Línea $($i+1): $S"
  }
}
if ($InMath) { $Problems += "Quedó un bloque matemático $$ sin cerrar." }
if ($Problems.Count -gt 0) {
  Write-Host "Se encontraron delimitadores matemáticos incorrectos:" -ForegroundColor Red
  $Problems | ForEach-Object { Write-Host $_ }
  pause
  exit 1
}
Write-Host "Delimitadores matemáticos revisados correctamente." -ForegroundColor Green
pause
