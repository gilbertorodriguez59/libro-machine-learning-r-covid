$ErrorActionPreference = "Stop"

$Proyecto = "C:\libro-machine-learning-r-covid-dev"
$Origen = $PSScriptRoot
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Respaldo = Join-Path $Proyecto ("respaldo-editorial-v01411-" + (Get-Date -Format "yyyyMMdd-HHmmss"))

function Fallar([string]$Mensaje) {
    Write-Host ""
    Write-Host ("ERROR: " + $Mensaje) -ForegroundColor Red
    Read-Host "Presione Enter para cerrar"
    exit 1
}

if (-not (Test-Path -LiteralPath (Join-Path $Proyecto "_quarto.yml"))) {
    Fallar "No se encontro el proyecto COVID DEV."
}

New-Item -ItemType Directory -Path $Respaldo -Force | Out-Null

Write-Host ""
Write-Host "Creando respaldo..." -ForegroundColor Cyan

Get-ChildItem -LiteralPath $Proyecto -File |
    Where-Object { $_.Extension -in @(".qmd", ".yml", ".yaml", ".bib", ".tex", ".ipynb") } |
    Copy-Item -Destination $Respaldo -Force

Write-Host ("Respaldo: " + $Respaldo) -ForegroundColor Green

$Nuevos = @(
    "00-bienvenida.qmd",
    "00-creditos-editoriales.qmd",
    "00-licencia-y-uso-academico.qmd",
    "00-prefacio.qmd",
    "00-agradecimientos.qmd",
    "glosario.qmd",
    "indice-figuras.qmd",
    "indice-tematico.qmd",
    "acerca-del-autor.qmd"
)

foreach ($Nombre in $Nuevos) {
    Copy-Item -LiteralPath (Join-Path $Origen $Nombre) `
              -Destination (Join-Path $Proyecto $Nombre) -Force
}

Write-Host "Corrigiendo nombre del autor..." -ForegroundColor Cyan

$ArchivosTexto = Get-ChildItem -LiteralPath $Proyecto -Recurse -File |
    Where-Object {
        $_.Extension -in @(".qmd", ".yml", ".yaml", ".tex", ".md", ".bib", ".json", ".ipynb") -and
        $_.FullName -notmatch "\\docs\\" -and
        $_.FullName -notmatch "\\.git\\" -and
        $_.FullName -notmatch "\\respaldo"
    }

foreach ($Archivo in $ArchivosTexto) {
    try {
        $Texto = [IO.File]::ReadAllText($Archivo.FullName, [Text.Encoding]::UTF8)
        $Nuevo = $Texto.Replace(
            "MI Jesús Gilberto Rodríguez Escobedo",
            "Jesús Gilberto Rodríguez Escobedo"
        ).Replace(
            "MI JesÃºs Gilberto RodrÃ­guez Escobedo",
            "Jesús Gilberto Rodríguez Escobedo"
        )
        if ($Nuevo -ne $Texto) {
            [IO.File]::WriteAllText($Archivo.FullName, $Nuevo, $Utf8)
        }
    }
    catch {
        Write-Host ("Aviso: no se pudo revisar " + $Archivo.FullName) -ForegroundColor Yellow
    }
}

Write-Host "Actualizando estructura de _quarto.yml..." -ForegroundColor Cyan

$YamlPath = Join-Path $Proyecto "_quarto.yml"
$Yaml = [IO.File]::ReadAllText($YamlPath, [Text.Encoding]::UTF8)

$InicioCap = $Yaml.IndexOf("  chapters:")
$InicioApen = $Yaml.IndexOf("  appendices:")

if ($InicioCap -lt 0) {
    Fallar "No se encontro chapters en _quarto.yml."
}

$Antes = $Yaml.Substring(0, $InicioCap)

$NuevaEstructura = @'
  chapters:
    - index.qmd
    - 00-bienvenida.qmd
    - 00-creditos-editoriales.qmd
    - 00-licencia-y-uso-academico.qmd
    - 00-prefacio.qmd
    - 00-agradecimientos.qmd
    - 00-cuaderno-google-colab.qmd
    - 01-introduccion.qmd
    - 02-preparacion-datos.qmd
    - 03-analisis-exploratorio.qmd
    - 04-regresion-lineal-multiple.qmd
    - 04-regresion-logistica.qmd
    - 05-knn.qmd
    - 06-arboles-decision.qmd
    - 07-random-forest.qmd
    - 08-evaluacion-modelos.qmd
    - 09-svm.qmd
    - 10-naive-bayes.qmd
    - 11-redes-neuronales.qmd
    - 12-kmeans.qmd
  appendices:
    - glosario.qmd
    - referencias.qmd
    - indice-figuras.qmd
    - indice-tematico.qmd
    - acerca-del-autor.qmd
'@

[IO.File]::WriteAllText($YamlPath, ($Antes + $NuevaEstructura), $Utf8)

Write-Host "Agregando referencia del volumen teorico..." -ForegroundColor Cyan

$BibPath = Join-Path $Proyecto "referencias.bib"
if (Test-Path -LiteralPath $BibPath) {
    $Bib = [IO.File]::ReadAllText($BibPath, [Text.Encoding]::UTF8)
    if ($Bib -notmatch "@book\{rodriguez2026fundamentos") {
        $Entrada = @'

@book{rodriguez2026fundamentos,
  author    = {Rodríguez Escobedo, Jesús Gilberto},
  title     = {Fundamentos Matemáticos del Aprendizaje Automático},
  subtitle  = {Teoría, demostraciones y formulación rigurosa de los métodos de regresión, clasificación y análisis de datos},
  year      = {2026},
  edition   = {Primera edición digital},
  address   = {San Luis Potosí, México}
}
'@
        [IO.File]::AppendAllText($BibPath, $Entrada, $Utf8)
    }
}

function AgregarConexion([string]$Nombre, [string]$BloqueBase64) {
    $Ruta = Join-Path $Proyecto $Nombre
    if (-not (Test-Path -LiteralPath $Ruta)) {
        Write-Host ("Aviso: no existe " + $Nombre) -ForegroundColor Yellow
        return
    }

    $Texto = [IO.File]::ReadAllText($Ruta, [Text.Encoding]::UTF8)
    if ($Texto -match "Conexión con el volumen teórico") {
        return
    }

    $Bytes = [Convert]::FromBase64String($BloqueBase64)
    $Bloque = [Text.Encoding]::UTF8.GetString($Bytes)
    $Lineas = $Texto -split "\r?\n"
    $Posicion = -1

    for ($i = 1; $i -lt $Lineas.Count; $i++) {
        if ($Lineas[$i] -match "^##\s+") {
            $Posicion = $i
            break
        }
    }

    if ($Posicion -lt 0) {
        $NuevoTexto = $Texto.TrimEnd() + "`r`n`r`n" + $Bloque
    }
    else {
        $Parte1 = $Lineas[0..($Posicion - 1)] -join "`r`n"
        $Parte2 = $Lineas[$Posicion..($Lineas.Count - 1)] -join "`r`n"
        $NuevoTexto = $Parte1 + "`r`n`r`n" + $Bloque + "`r`n" + $Parte2
    }

    [IO.File]::WriteAllText($Ruta, $NuevoTexto, $Utf8)
}

Write-Host "Agregando conexiones con el volumen teorico..." -ForegroundColor Cyan

AgregarConexion "01-introduccion.qmd" "Ojo6IHsuY2FsbG91dC1ub3RlIHRpdGxlPSJDb25leGnDs24gY29uIGVsIHZvbHVtZW4gdGXDs3JpY28ifQoKTGEgZm9ybXVsYWNpw7NuIG1hdGVtw6F0aWNhIGRlICoqRm9ybXVsYWNpw7NuIGRlbCBhcHJlbmRpemFqZSBzdXBlcnZpc2FkbyB5IHRlb3LDrWEgZGUgY2xhc2lmaWNhY2nDs24qKiBzZSBkZXNhcnJvbGxhIGNvbiBtYXlvciBwcm9mdW5kaWRhZAplbiBsb3MgY2Fww610dWxvcyA1IHkgNiBkZSAqRnVuZGFtZW50b3MgTWF0ZW3DoXRpY29zIGRlbCBBcHJlbmRpemFqZQpBdXRvbcOhdGljbyogW0Byb2RyaWd1ZXoyMDI2ZnVuZGFtZW50b3NdLgoKOjo6Cg=="
AgregarConexion "02-preparacion-datos.qmd" "Ojo6IHsuY2FsbG91dC1ub3RlIHRpdGxlPSJDb25leGnDs24gY29uIGVsIHZvbHVtZW4gdGXDs3JpY28ifQoKTGEgZm9ybXVsYWNpw7NuIG1hdGVtw6F0aWNhIGRlICoqcmVwcmVzZW50YWNpw7NuIG1hdGVtw6F0aWNhIGRlIGRhdG9zLCBwcm9iYWJpbGlkYWQgeSBlc3RhZMOtc3RpY2EqKiBzZSBkZXNhcnJvbGxhIGNvbiBtYXlvciBwcm9mdW5kaWRhZAplbiBsb3MgY2Fww610dWxvcyAxLCAyIHkgMyBkZSAqRnVuZGFtZW50b3MgTWF0ZW3DoXRpY29zIGRlbCBBcHJlbmRpemFqZQpBdXRvbcOhdGljbyogW0Byb2RyaWd1ZXoyMDI2ZnVuZGFtZW50b3NdLgoKOjo6Cg=="
AgregarConexion "03-analisis-exploratorio.qmd" "Ojo6IHsuY2FsbG91dC1ub3RlIHRpdGxlPSJDb25leGnDs24gY29uIGVsIHZvbHVtZW4gdGXDs3JpY28ifQoKTGEgZm9ybXVsYWNpw7NuIG1hdGVtw6F0aWNhIGRlICoqcHJvYmFiaWxpZGFkLCBlc3RhZMOtc3RpY2EsIGNvdmFyaWFuemEgeSByZXByZXNlbnRhY2nDs24gbXVsdGl2YXJpYWRhKiogc2UgZGVzYXJyb2xsYSBjb24gbWF5b3IgcHJvZnVuZGlkYWQKZW4gbG9zIGNhcMOtdHVsb3MgMiB5IDMgZGUgKkZ1bmRhbWVudG9zIE1hdGVtw6F0aWNvcyBkZWwgQXByZW5kaXphamUKQXV0b23DoXRpY28qIFtAcm9kcmlndWV6MjAyNmZ1bmRhbWVudG9zXS4KCjo6Ogo="
AgregarConexion "04-regresion-lineal-multiple.qmd" "Ojo6IHsuY2FsbG91dC1ub3RlIHRpdGxlPSJDb25leGnDs24gY29uIGVsIHZvbHVtZW4gdGXDs3JpY28ifQoKTGEgZm9ybXVsYWNpw7NuIG1hdGVtw6F0aWNhIGRlICoqcmVncmVzacOzbiBsaW5lYWwgc2ltcGxlIHkgbcO6bHRpcGxlKiogc2UgZGVzYXJyb2xsYSBjb24gbWF5b3IgcHJvZnVuZGlkYWQKZW4gbG9zIGNhcMOtdHVsb3MgOSB5IDEwIGRlICpGdW5kYW1lbnRvcyBNYXRlbcOhdGljb3MgZGVsIEFwcmVuZGl6YWplCkF1dG9tw6F0aWNvKiBbQHJvZHJpZ3VlejIwMjZmdW5kYW1lbnRvc10uCgo6OjoK"
AgregarConexion "04-regresion-logistica.qmd" "Ojo6IHsuY2FsbG91dC1ub3RlIHRpdGxlPSJDb25leGnDs24gY29uIGVsIHZvbHVtZW4gdGXDs3JpY28ifQoKTGEgZm9ybXVsYWNpw7NuIG1hdGVtw6F0aWNhIGRlICoqcmVncmVzacOzbiBsb2fDrXN0aWNhLCBtw6F4aW1hIHZlcm9zaW1pbGl0dWQgeSBjbGFzaWZpY2FjacOzbiBwcm9iYWJpbMOtc3RpY2EqKiBzZSBkZXNhcnJvbGxhIGNvbiBtYXlvciBwcm9mdW5kaWRhZAplbiBsb3MgY2Fww610dWxvcyAzLCA2IHkgMTEgZGUgKkZ1bmRhbWVudG9zIE1hdGVtw6F0aWNvcyBkZWwgQXByZW5kaXphamUKQXV0b23DoXRpY28qIFtAcm9kcmlndWV6MjAyNmZ1bmRhbWVudG9zXS4KCjo6Ogo="
AgregarConexion "05-knn.qmd" "Ojo6IHsuY2FsbG91dC1ub3RlIHRpdGxlPSJDb25leGnDs24gY29uIGVsIHZvbHVtZW4gdGXDs3JpY28ifQoKTGEgZm9ybXVsYWNpw7NuIG1hdGVtw6F0aWNhIGRlICoqZGlzdGFuY2lhcywgZXNjYWxhbWllbnRvIHkgdmVjaW5vcyBtw6FzIGNlcmNhbm9zKiogc2UgZGVzYXJyb2xsYSBjb24gbWF5b3IgcHJvZnVuZGlkYWQKZW4gbG9zIGNhcMOtdHVsb3MgMiB5IDEyIGRlICpGdW5kYW1lbnRvcyBNYXRlbcOhdGljb3MgZGVsIEFwcmVuZGl6YWplCkF1dG9tw6F0aWNvKiBbQHJvZHJpZ3VlejIwMjZmdW5kYW1lbnRvc10uCgo6OjoK"
AgregarConexion "06-arboles-decision.qmd" "Ojo6IHsuY2FsbG91dC1ub3RlIHRpdGxlPSJDb25leGnDs24gY29uIGVsIHZvbHVtZW4gdGXDs3JpY28ifQoKTGEgZm9ybXVsYWNpw7NuIG1hdGVtw6F0aWNhIGRlICoqZW50cm9ww61hLCBpbXB1cmV6YSwgcGFydGljaW9uZXMgeSDDoXJib2xlcyBkZSBkZWNpc2nDs24qKiBzZSBkZXNhcnJvbGxhIGNvbiBtYXlvciBwcm9mdW5kaWRhZAplbiBsb3MgY2Fww610dWxvcyAzLCA2IHkgMTMgZGUgKkZ1bmRhbWVudG9zIE1hdGVtw6F0aWNvcyBkZWwgQXByZW5kaXphamUKQXV0b23DoXRpY28qIFtAcm9kcmlndWV6MjAyNmZ1bmRhbWVudG9zXS4KCjo6Ogo="
AgregarConexion "07-random-forest.qmd" "Ojo6IHsuY2FsbG91dC1ub3RlIHRpdGxlPSJDb25leGnDs24gY29uIGVsIHZvbHVtZW4gdGXDs3JpY28ifQoKTGEgZm9ybXVsYWNpw7NuIG1hdGVtw6F0aWNhIGRlICoqYm9vdHN0cmFwLCBlbnNhbWJsZXMgeSBSYW5kb20gRm9yZXN0Kiogc2UgZGVzYXJyb2xsYSBjb24gbWF5b3IgcHJvZnVuZGlkYWQKZW4gbG9zIGNhcMOtdHVsb3MgNyB5IDE0IGRlICpGdW5kYW1lbnRvcyBNYXRlbcOhdGljb3MgZGVsIEFwcmVuZGl6YWplCkF1dG9tw6F0aWNvKiBbQHJvZHJpZ3VlejIwMjZmdW5kYW1lbnRvc10uCgo6OjoK"
AgregarConexion "08-evaluacion-modelos.qmd" "Ojo6IHsuY2FsbG91dC1ub3RlIHRpdGxlPSJDb25leGnDs24gY29uIGVsIHZvbHVtZW4gdGXDs3JpY28ifQoKTGEgZm9ybXVsYWNpw7NuIG1hdGVtw6F0aWNhIGRlICoqbWF0cmljZXMgZGUgY29uZnVzacOzbiwgbcOpdHJpY2FzLCB2YWxpZGFjacOzbiB5IHNlbGVjY2nDs24gZGUgbW9kZWxvcyoqIHNlIGRlc2Fycm9sbGEgY29uIG1heW9yIHByb2Z1bmRpZGFkCmVuIGxvcyBjYXDDrXR1bG9zIDYgeSA3IGRlICpGdW5kYW1lbnRvcyBNYXRlbcOhdGljb3MgZGVsIEFwcmVuZGl6YWplCkF1dG9tw6F0aWNvKiBbQHJvZHJpZ3VlejIwMjZmdW5kYW1lbnRvc10uCgo6OjoK"
AgregarConexion "09-svm.qmd" "Ojo6IHsuY2FsbG91dC1ub3RlIHRpdGxlPSJDb25leGnDs24gY29uIGVsIHZvbHVtZW4gdGXDs3JpY28ifQoKTGEgZm9ybXVsYWNpw7NuIG1hdGVtw6F0aWNhIGRlICoqbWFyZ2VuLCBvcHRpbWl6YWNpw7NuIGNvbnZleGEsIGNvbmRpY2lvbmVzIEtLVCB5IGtlcm5lbHMqKiBzZSBkZXNhcnJvbGxhIGNvbiBtYXlvciBwcm9mdW5kaWRhZAplbiBsb3MgY2Fww610dWxvcyA0IHkgMTUgZGUgKkZ1bmRhbWVudG9zIE1hdGVtw6F0aWNvcyBkZWwgQXByZW5kaXphamUKQXV0b23DoXRpY28qIFtAcm9kcmlndWV6MjAyNmZ1bmRhbWVudG9zXS4KCjo6Ogo="
AgregarConexion "10-naive-bayes.qmd" "Ojo6IHsuY2FsbG91dC1ub3RlIHRpdGxlPSJDb25leGnDs24gY29uIGVsIHZvbHVtZW4gdGXDs3JpY28ifQoKTGEgZm9ybXVsYWNpw7NuIG1hdGVtw6F0aWNhIGRlICoqcHJvYmFiaWxpZGFkIGNvbmRpY2lvbmFsLCB0ZW9yZW1hIGRlIEJheWVzIHkgY2xhc2lmaWNhY2nDs24gcHJvYmFiaWzDrXN0aWNhKiogc2UgZGVzYXJyb2xsYSBjb24gbWF5b3IgcHJvZnVuZGlkYWQKZW4gbG9zIGNhcMOtdHVsb3MgMyB5IDYgZGUgKkZ1bmRhbWVudG9zIE1hdGVtw6F0aWNvcyBkZWwgQXByZW5kaXphamUKQXV0b23DoXRpY28qIFtAcm9kcmlndWV6MjAyNmZ1bmRhbWVudG9zXS4KCjo6Ogo="
AgregarConexion "11-redes-neuronales.qmd" "Ojo6IHsuY2FsbG91dC1ub3RlIHRpdGxlPSJDb25leGnDs24gY29uIGVsIHZvbHVtZW4gdGXDs3JpY28ifQoKTGEgZm9ybXVsYWNpw7NuIG1hdGVtw6F0aWNhIGRlICoqw6FsZ2VicmEgbGluZWFsLCBjw6FsY3VsbywgZGVzY2Vuc28gcG9yIGdyYWRpZW50ZSB5IHJlZGVzIG5ldXJvbmFsZXMqKiBzZSBkZXNhcnJvbGxhIGNvbiBtYXlvciBwcm9mdW5kaWRhZAplbiBsb3MgY2Fww610dWxvcyAyLCA0IHkgMTYgZGUgKkZ1bmRhbWVudG9zIE1hdGVtw6F0aWNvcyBkZWwgQXByZW5kaXphamUKQXV0b23DoXRpY28qIFtAcm9kcmlndWV6MjAyNmZ1bmRhbWVudG9zXS4KCjo6Ogo="
AgregarConexion "12-kmeans.qmd" "Ojo6IHsuY2FsbG91dC1ub3RlIHRpdGxlPSJDb25leGnDs24gY29uIGVsIHZvbHVtZW4gdGXDs3JpY28ifQoKTGEgZm9ybXVsYWNpw7NuIG1hdGVtw6F0aWNhIGRlICoqZGlzdGFuY2lhcywgZnVuY2nDs24gb2JqZXRpdm8sIGNlbnRyb2lkZXMgeSBhZ3J1cGFtaWVudG8gay1tZWFucyoqIHNlIGRlc2Fycm9sbGEgY29uIG1heW9yIHByb2Z1bmRpZGFkCmVuIGxvcyBjYXDDrXR1bG9zIDIgeSAxOCBkZSAqRnVuZGFtZW50b3MgTWF0ZW3DoXRpY29zIGRlbCBBcHJlbmRpemFqZQpBdXRvbcOhdGljbyogW0Byb2RyaWd1ZXoyMDI2ZnVuZGFtZW50b3NdLgoKOjo6Cg=="

$IndexPath = Join-Path $Proyecto "index.qmd"
if (Test-Path -LiteralPath $IndexPath) {
    $Index = [IO.File]::ReadAllText($IndexPath, [Text.Encoding]::UTF8)
    $Index = [regex]::Replace(
        $Index,
        "\*\*Versión:\*\*\s*[^\r\n]+",
        "**Versión:** 0.14.1-covid-dev"
    )
    [IO.File]::WriteAllText($IndexPath, $Index, $Utf8)
}

$PdfPath = Join-Path $Proyecto "_quarto-pdf.yml"
if (Test-Path -LiteralPath $PdfPath) {
    $Pdf = [IO.File]::ReadAllText($PdfPath, [Text.Encoding]::UTF8)
    if ($Pdf -notmatch "(?m)^\s+lof:\s*true") {
        $Pdf = $Pdf -replace "(?m)^  pdf:\s*$", "  pdf:`r`n    toc: true`r`n    lof: true`r`n    number-sections: true"
    }
    [IO.File]::WriteAllText($PdfPath, $Pdf, $Utf8)
}

Write-Host ""
Write-Host "ACTUALIZACION EDITORIAL INSTALADA CORRECTAMENTE." -ForegroundColor Green
Write-Host ("Respaldo: " + $Respaldo)
Write-Host ""
Write-Host "Ejecute ahora:"
Write-Host "RENDERIZAR_REVISION_EDITORIAL_V01411.bat"
Write-Host ""

Read-Host "Presione Enter para cerrar"
