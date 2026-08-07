$ErrorActionPreference = "Stop"

$ProjectDir = "C:\libro-machine-learning-r-dev"
$BookPdfGenerated = "Aprendizaje-y-Clasificación-Automática-con-R.pdf"
$BookPdfAscii = "Aprendizaje-y-Clasificacion-Automatica-con-R.pdf"
$PublicPdfName = "libro-machine-learning-r.pdf"

$DocsDir = Join-Path $ProjectDir "docs"
$TempDir = Join-Path $ProjectDir "_publicacion_temp"
$TempPdf = Join-Path $TempDir $PublicPdfName

function Fail([string]$Message) {
    Write-Host ""
    Write-Host "ERROR: $Message" -ForegroundColor Red
    Read-Host "Presione Enter para cerrar"
    exit 1
}

try {
    Set-Location $ProjectDir

    Write-Host "Repositorio remoto:" -ForegroundColor Cyan
    git remote -v
    Write-Host ""
    Write-Host "Debe aparecer gilbertorodriguez59/libro-machine-learning-r-dev.git"
    Read-Host "Presione Enter para continuar"

    if (Test-Path $TempDir) {
        Remove-Item $TempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

    Write-Host ""
    Write-Host "1. Generando PDF del libro..." -ForegroundColor Cyan
    & quarto render --profile pdf --to pdf
    if ($LASTEXITCODE -ne 0) {
        Fail "Falló la generación del PDF."
    }

    # Buscar exclusivamente los nombres del PDF del libro.
    $Candidates = @(
        (Join-Path $DocsDir $BookPdfGenerated),
        (Join-Path $DocsDir $BookPdfAscii),
        (Join-Path $ProjectDir $BookPdfGenerated),
        (Join-Path $ProjectDir $BookPdfAscii),
        (Join-Path (Join-Path $ProjectDir "_book") $BookPdfGenerated),
        (Join-Path (Join-Path $ProjectDir "_book") $BookPdfAscii)
    )

    $BookPdf = $null
    foreach ($Candidate in $Candidates) {
        if (Test-Path -LiteralPath $Candidate) {
            $BookPdf = $Candidate
            break
        }
    }

    if (-not $BookPdf) {
        # Último recurso: buscar un PDF cuyo nombre comience con
        # Aprendizaje-y-Clasific..., excluyendo la carpeta recursos.
        $BookPdf = Get-ChildItem -Path $ProjectDir -Recurse -Filter "*.pdf" -File |
            Where-Object {
                $_.Name -like "Aprendizaje-y-Clasific*Automatica-con-R.pdf" -and
                $_.FullName -notmatch "\\recursos\\"
            } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1 -ExpandProperty FullName
    }

    if (-not $BookPdf) {
        Fail "No se encontró el PDF del libro. No se usará ningún PDF de recursos."
    }

    Write-Host "PDF correcto del libro:"
    Write-Host $BookPdf

    Copy-Item -LiteralPath $BookPdf -Destination $TempPdf -Force

    if (-not (Test-Path -LiteralPath $TempPdf)) {
        Fail "No se pudo guardar temporalmente el PDF del libro."
    }

    Write-Host ""
    Write-Host "2. Generando sitio HTML..." -ForegroundColor Cyan
    & quarto render --to html
    if ($LASTEXITCODE -ne 0) {
        Fail "Falló la generación del HTML."
    }

    if (-not (Test-Path $DocsDir)) {
        New-Item -ItemType Directory -Path $DocsDir -Force | Out-Null
    }

    Write-Host ""
    Write-Host "3. Restaurando PDF del libro..." -ForegroundColor Cyan

    # Nombre corto para enlace directo.
    Copy-Item -LiteralPath $TempPdf `
        -Destination (Join-Path $DocsDir $PublicPdfName) -Force

    # Nombre automático utilizado por el icono de Quarto.
    Copy-Item -LiteralPath $TempPdf `
        -Destination (Join-Path $DocsDir $BookPdfGenerated) -Force

    $IndexHtml = Join-Path $DocsDir "index.html"
    $FinalShort = Join-Path $DocsDir $PublicPdfName
    $FinalQuarto = Join-Path $DocsDir $BookPdfGenerated

    if (-not (Test-Path -LiteralPath $IndexHtml)) {
        Fail "No existe docs\index.html."
    }
    if (-not (Test-Path -LiteralPath $FinalShort)) {
        Fail "No existe docs\$PublicPdfName."
    }
    if (-not (Test-Path -LiteralPath $FinalQuarto)) {
        Fail "No existe el PDF usado por el icono de Quarto."
    }

    Write-Host ""
    Write-Host "Archivos verificados:" -ForegroundColor Green
    Get-Item -LiteralPath $IndexHtml, $FinalShort, $FinalQuarto |
        Select-Object Name, Length, LastWriteTime |
        Format-Table -AutoSize

    Remove-Item $TempDir -Recurse -Force

    Write-Host ""
    Write-Host "4. Guardando y subiendo cambios..." -ForegroundColor Cyan

    git add -A
    if ($LASTEXITCODE -ne 0) {
        Fail "Falló git add."
    }

    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        git commit -m "Corregir PDF del libro y eliminar información duplicada"
        if ($LASTEXITCODE -ne 0) {
            Fail "No se pudo crear el commit."
        }
    }
    else {
        Write-Host "No hay cambios nuevos para registrar."
    }

    git push
    if ($LASTEXITCODE -ne 0) {
        Fail "No se pudieron subir los cambios."
    }

    Write-Host ""
    Write-Host "PUBLICACIÓN TERMINADA CORRECTAMENTE" -ForegroundColor Green
    Write-Host ""
    Write-Host "Web:"
    Write-Host "https://gilbertorodriguez59.github.io/libro-machine-learning-r-dev/"
    Write-Host ""
    Write-Host "PDF:"
    Write-Host "https://gilbertorodriguez59.github.io/libro-machine-learning-r-dev/$PublicPdfName"
    Write-Host ""
    Read-Host "Presione Enter para cerrar"
}
catch {
    Fail $_.Exception.Message
}
