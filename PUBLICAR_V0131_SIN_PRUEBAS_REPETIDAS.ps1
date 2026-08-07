$ErrorActionPreference = "Stop"

$ProjectDir = "C:\libro-machine-learning-r-dev"
$Publisher = Join-Path $ProjectDir "PREPARAR_SHINYLIVE_Y_PUBLICAR_V0121.bat"

function Fail([string]$Message) {
    Write-Host ""
    Write-Host "ERROR: $Message" -ForegroundColor Red
    Read-Host "Presione Enter para cerrar"
    exit 1
}

if (-not (Test-Path -LiteralPath $ProjectDir)) {
    Fail "No existe la carpeta: $ProjectDir"
}

if (-not (Test-Path -LiteralPath $Publisher)) {
    Fail "No se encontró: $Publisher"
}

Set-Location $ProjectDir

Write-Host ""
Write-Host "PUBLICACIÓN v0.13.1" -ForegroundColor Cyan
Write-Host ""
Write-Host "Los interactivos no se probarán uno por uno en PDF."
Write-Host "Quarto procesa el libro completo cuando un archivo pertenece a un book."
Write-Host "Se ejecutará directamente el publicador completo una sola vez."
Write-Host ""

# Eliminar posibles procesos/archivos parciales no es necesario; solo limpiamos
# temporales del proyecto que puedan quedar de una interrupción.
Remove-Item (Join-Path $ProjectDir ".quarto\_freeze") -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $ProjectDir "_book") -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Iniciando publicación completa..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Durante la generación del PDF puede permanecer varios minutos en un porcentaje."
Write-Host "Eso es normal mientras R ejecuta gráficas y ejemplos."
Write-Host ""

& $Publisher

if ($LASTEXITCODE -ne 0) {
    Fail "La publicación terminó con un error."
}

Write-Host ""
Write-Host "PUBLICACIÓN TERMINADA CORRECTAMENTE" -ForegroundColor Green
Write-Host ""
Write-Host "Sitio de desarrollo:"
Write-Host "https://gilbertorodriguez59.github.io/libro-machine-learning-r-dev/"
Write-Host ""
Write-Host "GitHub Pages puede tardar entre 1 y 5 minutos en actualizarse."

Read-Host "Presione Enter para cerrar"
