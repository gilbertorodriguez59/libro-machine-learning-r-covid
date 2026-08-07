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
    "11-redes-neuronales-antes-corregir-gradiente-" +
    (Get-Date -Format "yyyyMMdd-HHmmss") +
    ".qmd"
)

Copy-Item -LiteralPath $Chapter -Destination $Backup -Force

Write-Host ""
Write-Host "1. Corrigiendo la fórmula del descenso de gradiente..." -ForegroundColor Cyan

$Text = [System.IO.File]::ReadAllText(
    $Chapter,
    [System.Text.Encoding]::UTF8
)

# Fórmula correcta completa.
$FormulaCorrecta = @'
$$
w^{\mathrm{nuevo}}
=
w^{\mathrm{anterior}}
-
\eta\frac{\partial L}{\partial w}
$$
'@

# Reemplazar el bloque completo, aunque tenga delimitadores mezclados.
$Patterns = @(
    '(?ms)\$\$\s*\$?\s*w\^\{nuevo\}\s*=\s*w\^\{anterior\}\s*-\s*\\eta\\frac\{\\partial L\}\{\\partial w\}\s*\$?\s*\$\$',
    '(?ms)\\\[\s*\$?\s*w\^\{nuevo\}\s*=\s*w\^\{anterior\}\s*-\s*\\eta\\frac\{\\partial L\}\{\\partial w\}\s*\$?\s*\\\]',
    '(?m)^\s*\$?\s*w\^\{nuevo\}\s*=\s*w\^\{anterior\}\s*-\s*\\eta\\frac\{\\partial L\}\{\\partial w\}\s*\$?\s*$',
    '(?m)^\s*-\s*\\eta\\frac\{\\partial L\}\{\\partial w\}\s*$',
    '(?m)^\s*\\eta\\frac\{\\partial L\}\{\\partial w\}\s*$'
)

foreach ($Pattern in $Patterns) {
    $Text = [regex]::Replace(
        $Text,
        $Pattern,
        $FormulaCorrecta
    )
}

# Corregir también la actualización si quedó dividida en varias líneas
# fuera de cualquier bloque matemático.
$Text = [regex]::Replace(
    $Text,
    '(?ms)(?<!\$)\s*w\^\{nuevo\}\s*=\s*w\^\{anterior\}\s*-\s*\\eta\\frac\{\\partial L\}\{\\partial w\}(?!\$)',
    "`r`n$FormulaCorrecta`r`n"
)

# Eliminar delimitadores duplicados inmediatos.
$Text = [regex]::Replace($Text, '\$\$\s*\$\$', '')
$Text = [regex]::Replace($Text, '(\r?\n){4,}', "`r`n`r`n`r`n")

[System.IO.File]::WriteAllText(
    $Chapter,
    $Text,
    $Utf8NoBom
)

Write-Host "Fórmula corregida." -ForegroundColor Green
Write-Host "Respaldo:"
Write-Host $Backup

Write-Host ""
Write-Host "2. Verificando que no quede la derivada fuera del modo matemático..." -ForegroundColor Cyan

$Lines = [System.IO.File]::ReadAllLines(
    $Chapter,
    [System.Text.Encoding]::UTF8
)

$InsideCode = $false
$InsideMath = $false
$Problems = New-Object System.Collections.Generic.List[string]

for ($i = 0; $i -lt $Lines.Length; $i++) {
    $Line = $Lines[$i]
    $Trim = $Line.Trim()

    if ($Trim.StartsWith('```')) {
        $InsideCode = -not $InsideCode
        continue
    }

    if ($InsideCode) {
        continue
    }

    if ($Trim -eq '$$') {
        $InsideMath = -not $InsideMath
        continue
    }

    if (
        $Line.Contains('\eta\frac{\partial L}{\partial w}') -and
        -not $InsideMath
    ) {
        $Problems.Add(
            "Línea " + ($i + 1) + ": " + $Line
        )
    }
}

if ($InsideMath) {
    $Problems.Add("Existe un bloque $$ sin cerrar.")
}

if ($Problems.Count -gt 0) {
    Write-Host ""
    Write-Host "Todavía quedaron expresiones inseguras:" -ForegroundColor Yellow

    foreach ($Problem in $Problems) {
        Write-Host $Problem
    }

    Fail "La auditoría no fue superada."
}

Write-Host "Auditoría superada." -ForegroundColor Green

Write-Host ""
Write-Host "3. Generando solamente el capítulo 12..." -ForegroundColor Cyan

& quarto render "11-redes-neuronales.qmd" --to pdf

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "El capítulo todavía contiene otro error distinto." -ForegroundColor Red
    Write-Host "El respaldo permanece en:"
    Write-Host $Backup
    Read-Host "Presione Enter para cerrar"
    exit 1
}

Write-Host ""
Write-Host "CAPÍTULO 12 GENERADO CORRECTAMENTE" -ForegroundColor Green
Write-Host ""
Write-Host "Ahora ejecute:"
Write-Host "PUBLICAR_V0131_SIN_PRUEBAS_REPETIDAS.bat"
Write-Host ""

Read-Host "Presione Enter para cerrar"
