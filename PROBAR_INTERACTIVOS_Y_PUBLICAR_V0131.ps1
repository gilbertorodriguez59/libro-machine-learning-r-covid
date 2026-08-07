$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Fail([string]$Message) {
    Write-Host ""
    Write-Host "ERROR: $Message" -ForegroundColor Red
    Read-Host "Presione Enter para cerrar"
    exit 1
}

Write-Host ""
Write-Host "1. Probando capítulos en PDF..." -ForegroundColor Cyan

$Chapters = @(
    "04-regresion-lineal-multiple.qmd",
    "04-regresion-logistica.qmd",
    "05-knn.qmd",
    "11-redes-neuronales.qmd",
    "12-kmeans.qmd"
)

foreach ($Chapter in $Chapters) {
    Write-Host ""
    Write-Host "Probando $Chapter"
    & quarto render $Chapter --to pdf

    if ($LASTEXITCODE -ne 0) {
        Fail "Falló la prueba PDF de $Chapter"
    }
}

Write-Host ""
Write-Host "2. Probando el sitio HTML completo con Shinylive..." -ForegroundColor Cyan

& quarto render --to html

if ($LASTEXITCODE -ne 0) {
    Fail "Falló la generación HTML."
}

Write-Host ""
Write-Host "PRUEBAS TERMINADAS CORRECTAMENTE" -ForegroundColor Green
Write-Host ""
Write-Host "3. Ejecutando el publicador completo..." -ForegroundColor Cyan

$Publisher = Join-Path $PSScriptRoot "PREPARAR_SHINYLIVE_Y_PUBLICAR_V0121.bat"

if (-not (Test-Path -LiteralPath $Publisher)) {
    Fail "No se encontró PREPARAR_SHINYLIVE_Y_PUBLICAR_V0121.bat"
}

& $Publisher

if ($LASTEXITCODE -ne 0) {
    Fail "La publicación terminó con error."
}

Write-Host ""
Write-Host "PUBLICACIÓN V0.13.1 TERMINADA" -ForegroundColor Green
Read-Host "Presione Enter para cerrar"
