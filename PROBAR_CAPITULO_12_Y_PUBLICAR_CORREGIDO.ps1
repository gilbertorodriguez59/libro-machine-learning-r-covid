$ErrorActionPreference = "Stop"

$ProjectDir = "C:\libro-machine-learning-r-dev"
$Chapter = Join-Path $ProjectDir "11-redes-neuronales.qmd"
$Publisher = Join-Path $ProjectDir "PREPARAR_SHINYLIVE_Y_PUBLICAR_V0121.bat"

function Fail([string]$Message) {
    Write-Host ""
    Write-Host "ERROR: $Message" -ForegroundColor Red
    Read-Host "Presione Enter para cerrar"
    exit 1
}

if (-not (Test-Path -LiteralPath $Chapter)) {
    Fail "No se encontró el capítulo: $Chapter"
}

if (-not (Test-Path -LiteralPath $Publisher)) {
    Fail "No se encontró el publicador: $Publisher"
}

Set-Location $ProjectDir

Write-Host ""
Write-Host "1. Generando solamente el capítulo 12..." -ForegroundColor Cyan

& quarto render "11-redes-neuronales.qmd" --to pdf

if ($LASTEXITCODE -ne 0) {
    Fail "El capítulo 12 todavía presenta un problema."
}

Write-Host ""
Write-Host "El capítulo 12 se generó correctamente." -ForegroundColor Green
Write-Host ""
Write-Host "2. Publicando el libro completo..." -ForegroundColor Cyan
Write-Host ""

# En PowerShell no se usa CALL. Se ejecuta el archivo BAT con el operador &.
& $Publisher

if ($LASTEXITCODE -ne 0) {
    Fail "La publicación completa terminó con un error."
}

Write-Host ""
Write-Host "PUBLICACIÓN COMPLETA TERMINADA CORRECTAMENTE" -ForegroundColor Green
Write-Host ""

Read-Host "Presione Enter para cerrar"
