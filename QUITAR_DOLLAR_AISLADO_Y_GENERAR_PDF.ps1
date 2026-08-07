$ErrorActionPreference = "Stop"

$ProjectDir = "C:\libro-machine-learning-r-dev"
$Chapter = Join-Path $ProjectDir "11-redes-neuronales.qmd"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Fail([string]$Message) {
    Write-Host ""
    Write-Host "ERROR: $Message" -ForegroundColor Red
    Read-Host "Presione Enter para cerrar"
    exit 1
}

if (-not (Test-Path -LiteralPath $Chapter)) {
    Fail "No se encontró: $Chapter"
}

Set-Location $ProjectDir

$Backup = Join-Path $ProjectDir (
    "11-redes-neuronales-antes-quitar-dollar-aislado-" +
    (Get-Date -Format "yyyyMMdd-HHmmss") +
    ".qmd"
)

Copy-Item -LiteralPath $Chapter -Destination $Backup -Force

Write-Host ""
Write-Host "1. Buscando signos dólar aislados..." -ForegroundColor Cyan

$Lines = [System.IO.File]::ReadAllLines(
    $Chapter,
    [System.Text.Encoding]::UTF8
)

$Result = New-Object System.Collections.Generic.List[string]
$InsideCode = $false
$Removed = New-Object System.Collections.Generic.List[string]

for ($i = 0; $i -lt $Lines.Length; $i++) {
    $Line = $Lines[$i]
    $Trim = $Line.Trim()

    if ($Trim.StartsWith('```')) {
        $InsideCode = -not $InsideCode
        $Result.Add($Line)
        continue
    }

    if (
        -not $InsideCode -and
        (
            $Trim -eq '$' -or
            $Trim -eq '\$'
        )
    ) {
        $Removed.Add(
            "Línea " + ($i + 1) + ": " + $Line
        )
        continue
    }

    $Result.Add($Line)
}

if ($Removed.Count -eq 0) {
    Write-Host "No se encontró ningún dólar aislado en el capítulo 12." -ForegroundColor Yellow
}
else {
    Write-Host "Se eliminaron estas líneas:" -ForegroundColor Green
    foreach ($Item in $Removed) {
        Write-Host $Item
    }
}

$Output = ($Result -join "`r`n")
$Output = [regex]::Replace(
    $Output,
    '(\r?\n){4,}',
    "`r`n`r`n`r`n"
)

[System.IO.File]::WriteAllText(
    $Chapter,
    $Output + "`r`n",
    $Utf8NoBom
)

Write-Host ""
Write-Host "2. Verificando delimitadores $$..." -ForegroundColor Cyan

$Check = [System.IO.File]::ReadAllLines(
    $Chapter,
    [System.Text.Encoding]::UTF8
)

$InsideCode = $false
$DisplayCount = 0
$SingleDollarLines = New-Object System.Collections.Generic.List[string]

for ($i = 0; $i -lt $Check.Length; $i++) {
    $Trim = $Check[$i].Trim()

    if ($Trim.StartsWith('```')) {
        $InsideCode = -not $InsideCode
        continue
    }

    if ($InsideCode) {
        continue
    }

    if ($Trim -eq '$$') {
        $DisplayCount++
    }

    if ($Trim -eq '$' -or $Trim -eq '\$') {
        $SingleDollarLines.Add(
            "Línea " + ($i + 1)
        )
    }
}

if ($SingleDollarLines.Count -gt 0) {
    Write-Host "Todavía quedan signos dólar aislados:" -ForegroundColor Red
    foreach ($Item in $SingleDollarLines) {
        Write-Host $Item
    }
    Fail "No se superó la auditoría."
}

if (($DisplayCount % 2) -ne 0) {
    Fail "El número de delimitadores $$ es impar: $DisplayCount"
}

Write-Host "Auditoría superada. Delimitadores $$: $DisplayCount" -ForegroundColor Green

Write-Host ""
Write-Host "3. Eliminando archivos LaTeX temporales..." -ForegroundColor Cyan

Remove-Item (Join-Path $ProjectDir "index.tex") -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $ProjectDir "index.log") -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $ProjectDir "11-redes-neuronales.tex") -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $ProjectDir "11-redes-neuronales.pdf") -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "4. Generando el PDF completo una sola vez..." -ForegroundColor Cyan
Write-Host "Este proceso puede tardar varios minutos."
Write-Host ""

& quarto render --profile pdf --to pdf

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "LaTeX encontró otro error diferente." -ForegroundColor Red
    Write-Host "Respaldo conservado en:"
    Write-Host $Backup
    Read-Host "Presione Enter para cerrar"
    exit 1
}

Write-Host ""
Write-Host "PDF GENERADO CORRECTAMENTE" -ForegroundColor Green
Write-Host ""
Write-Host "Ahora ejecute:"
Write-Host "PREPARAR_SHINYLIVE_Y_PUBLICAR_V0121.bat"
Write-Host ""

Read-Host "Presione Enter para cerrar"
