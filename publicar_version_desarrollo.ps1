$ErrorActionPreference = "Stop"

$ProjectDir = "C:\libro-machine-learning-r-dev"
$PublicPdfName = "libro-machine-learning-r.pdf"
$QuartoPdfName = "Aprendizaje-y-Clasificación-Automática-con-R.pdf"

$TempDir = Join-Path $ProjectDir "_publicacion_temp"
$TempPdf = Join-Path $TempDir $PublicPdfName
$DocsDir = Join-Path $ProjectDir "docs"

$FinalPdfShort = Join-Path $DocsDir $PublicPdfName
$FinalPdfQuarto = Join-Path $DocsDir $QuartoPdfName

function Fail([string]$Message) {
    Write-Host ""
    Write-Host "ERROR: $Message" -ForegroundColor Red
    Read-Host "Presione Enter para cerrar"
    exit 1
}

try {
    Set-Location $ProjectDir

    Write-Host "Repositorio remoto configurado:" -ForegroundColor Cyan
    git remote -v
    Write-Host ""
    Write-Host "Debe aparecer: gilbertorodriguez59/libro-machine-learning-r-dev.git"
    Read-Host "Presione Enter para continuar"

    if (Test-Path $TempDir) {
        Remove-Item $TempDir -Recurse -Force
    }

    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

    Write-Host ""
    Write-Host "1. Generando PDF de desarrollo..." -ForegroundColor Cyan
    & quarto render --profile pdf --to pdf

    if ($LASTEXITCODE -ne 0) {
        Fail "Fallo la generacion del PDF."
    }

    Write-Host ""
    Write-Host "2. Localizando el PDF generado..." -ForegroundColor Cyan

    $Pdf = Get-ChildItem -Path $ProjectDir -Recurse -Filter "*.pdf" -File |
        Where-Object { $_.FullName -notlike "$TempDir*" } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $Pdf) {
        Fail "No se encontro ningun PDF generado."
    }

    Write-Host "PDF encontrado:"
    Write-Host $Pdf.FullName

    Copy-Item -LiteralPath $Pdf.FullName -Destination $TempPdf -Force

    if (-not (Test-Path -LiteralPath $TempPdf)) {
        Fail "No se pudo guardar la copia temporal del PDF."
    }

    Write-Host ""
    Write-Host "3. Generando sitio HTML de desarrollo..." -ForegroundColor Cyan
    & quarto render --to html

    if ($LASTEXITCODE -ne 0) {
        Fail "Fallo la generacion del sitio HTML."
    }

    if (-not (Test-Path $DocsDir)) {
        New-Item -ItemType Directory -Path $DocsDir -Force | Out-Null
    }

    Write-Host ""
    Write-Host "4. Restaurando los dos nombres del PDF..." -ForegroundColor Cyan

    Copy-Item -LiteralPath $TempPdf -Destination $FinalPdfShort -Force
    Copy-Item -LiteralPath $TempPdf -Destination $FinalPdfQuarto -Force

    $IndexHtml = Join-Path $DocsDir "index.html"

    if (-not (Test-Path -LiteralPath $IndexHtml)) {
        Fail "No existe docs\index.html."
    }

    if (-not (Test-Path -LiteralPath $FinalPdfShort)) {
        Fail "No existe docs\$PublicPdfName."
    }

    if (-not (Test-Path -LiteralPath $FinalPdfQuarto)) {
        Fail "No existe el PDF requerido por el icono de Quarto."
    }

    Write-Host ""
    Write-Host "Archivos publicos verificados:" -ForegroundColor Green

    Get-Item -LiteralPath $IndexHtml, $FinalPdfShort, $FinalPdfQuarto |
        Select-Object Name, Length, LastWriteTime |
        Format-Table -AutoSize

    Remove-Item $TempDir -Recurse -Force

    Write-Host ""
    Write-Host "5. Guardando cambios en Git..." -ForegroundColor Cyan

    git add -A

    if ($LASTEXITCODE -ne 0) {
        Fail "Fallo git add."
    }

    git diff --cached --quiet

    if ($LASTEXITCODE -ne 0) {
        git commit -m "Actualizar sitio web y PDF de la version de desarrollo"

        if ($LASTEXITCODE -ne 0) {
            Fail "No se pudo crear el commit."
        }
    }
    else {
        Write-Host "No hay cambios nuevos para registrar."
    }

    Write-Host ""
    Write-Host "6. Subiendo a GitHub..." -ForegroundColor Cyan

    git push

    if ($LASTEXITCODE -ne 0) {
        Fail "No se pudieron subir los cambios."
    }

    Write-Host ""
    Write-Host "PUBLICACION DE DESARROLLO TERMINADA CORRECTAMENTE" -ForegroundColor Green
    Write-Host ""
    Write-Host "Libro web:"
    Write-Host "https://gilbertorodriguez59.github.io/libro-machine-learning-r-dev/"
    Write-Host ""
    Write-Host "PDF con nombre corto:"
    Write-Host "https://gilbertorodriguez59.github.io/libro-machine-learning-r-dev/$PublicPdfName"
    Write-Host ""
    Write-Host "PDF usado por el icono de Quarto:"
    Write-Host "https://gilbertorodriguez59.github.io/libro-machine-learning-r-dev/$QuartoPdfName"
    Write-Host ""
    Write-Host "GitHub Pages puede tardar entre 1 y 5 minutos en actualizarse."

    Read-Host "Presione Enter para cerrar"
}
catch {
    Fail $_.Exception.Message
}
