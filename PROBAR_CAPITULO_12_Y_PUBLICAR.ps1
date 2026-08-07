$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host ""
Write-Host "Probando primero el capítulo 12 en PDF..." -ForegroundColor Cyan

quarto render 11-redes-neuronales.qmd --to pdf

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: El capítulo 12 todavía presenta un problema." -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "El capítulo 12 se generó correctamente." -ForegroundColor Green
Write-Host "Ahora se publicará el libro completo."
Write-Host ""

call PREPARAR_SHINYLIVE_Y_PUBLICAR_V0121.bat
