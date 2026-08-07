$ErrorActionPreference = "Stop"

$File = Join-Path $PSScriptRoot "11-redes-neuronales.qmd"

if (-not (Test-Path -LiteralPath $File)) {
    Write-Host "No se encontró 11-redes-neuronales.qmd" -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "Revisando el capítulo de redes neuronales..." -ForegroundColor Cyan

$Content = Get-Content -LiteralPath $File -Raw -Encoding UTF8

$Problem = [regex]::Matches(
    $Content,
    '(?m)^[^`$\\\[]*\b(?:w|x|y|z|p)_[0-9A-Za-z]+[^`$\\\]]*$'
)

if ($Problem.Count -gt 0) {
    Write-Host ""
    Write-Host "Se encontraron líneas que conviene revisar:" -ForegroundColor Yellow
    foreach ($Match in $Problem) {
        Write-Host $Match.Value
    }
}
else {
    Write-Host "No se detectaron fórmulas simples con guiones bajos fuera de modo matemático." -ForegroundColor Green
}

Write-Host ""
Write-Host "Ahora puede ejecutar el publicador de Shinylive."
pause
