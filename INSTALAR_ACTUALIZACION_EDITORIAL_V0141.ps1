$ErrorActionPreference = "Stop"

$Proyecto = "C:\libro-machine-learning-r-covid-dev"
$Origen = $PSScriptRoot
$Respaldo = Join-Path $Proyecto ("respaldo-editorial-v0141-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
$Utf8 = New-Object System.Text.UTF8Encoding($false)

function Detener([string]$Mensaje) {
    Write-Host ""
    Write-Host "ERROR: $Mensaje" -ForegroundColor Red
    Read-Host "Presione Enter para cerrar"
    exit 1
}

if (-not (Test-Path -LiteralPath (Join-Path $Proyecto "_quarto.yml"))) {
    Detener "No se encontró el proyecto COVID DEV."
}

New-Item -ItemType Directory -Path $Respaldo -Force | Out-Null

Write-Host ""
Write-Host "1. Creando respaldo editorial..." -ForegroundColor Cyan

$Respaldar = @(
    "_quarto.yml", "_quarto-pdf.yml", "index.qmd",
    "referencias.bib", "00-licencia-y-citacion.qmd",
    "Aprendizaje_y_Clasificacion_Automatica_con_R_Colab.ipynb"
)

foreach ($Nombre in $Respaldar) {
    $Ruta = Join-Path $Proyecto $Nombre
    if (Test-Path -LiteralPath $Ruta) {
        Copy-Item -LiteralPath $Ruta -Destination $Respaldo -Force
    }
}

Get-ChildItem -LiteralPath $Proyecto -Filter "*.qmd" -File |
    Copy-Item -Destination $Respaldo -Force

Write-Host "Respaldo: $Respaldo" -ForegroundColor Green

Write-Host ""
Write-Host "2. Instalando páginas editoriales..." -ForegroundColor Cyan

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

Write-Host ""
Write-Host "3. Eliminando el prefijo MI del nombre..." -ForegroundColor Cyan

$Extensiones = @("*.qmd", "*.yml", "*.yaml", "*.tex", "*.md", "*.bib", "*.json", "*.ipynb")

foreach ($Patron in $Extensiones) {
    Get-ChildItem -LiteralPath $Proyecto -Recurse -File -Filter $Patron |
        Where-Object {
            $_.FullName -notmatch '\\docs\\' -and
            $_.FullName -notmatch '\\.git\\' -and
            $_.FullName -notmatch '\\respaldo'
        } |
        ForEach-Object {
            try {
                $Texto = [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8)
                $Nuevo = $Texto.Replace(
                    "MI Jesús Gilberto Rodríguez Escobedo",
                    "Jesús Gilberto Rodríguez Escobedo"
                ).Replace(
                    "MI JesÃºs Gilberto RodrÃ­guez Escobedo",
                    "Jesús Gilberto Rodríguez Escobedo"
                )

                if ($Nuevo -ne $Texto) {
                    [IO.File]::WriteAllText($_.FullName, $Nuevo, $Utf8)
                }
            }
            catch {
                Write-Host "Aviso: no se pudo revisar $($_.FullName)" -ForegroundColor Yellow
            }
        }
}

Write-Host ""
Write-Host "4. Actualizando la estructura del libro..." -ForegroundColor Cyan

$YamlPath = Join-Path $Proyecto "_quarto.yml"
$Yaml = [IO.File]::ReadAllText($YamlPath, [Text.Encoding]::UTF8)

$Yaml = $Yaml.Replace(
    'author: "MI Jesús Gilberto Rodríguez Escobedo"',
    'author: "Jesús Gilberto Rodríguez Escobedo"'
)

$Yaml = $Yaml.Replace(
    'author: "Jesús Gilberto Rodríguez Escobedo"',
    'author: "Jesús Gilberto Rodríguez Escobedo"'
)

$InicioCap = $Yaml.IndexOf("  chapters:")
$InicioApen = $Yaml.IndexOf("  appendices:")

if ($InicioCap -lt 0 -or $InicioApen -lt 0) {
    Detener "No se localizaron chapters y appendices en _quarto.yml."
}

$Antes = $Yaml.Substring(0, $InicioCap)
$DespuesApen = $Yaml.Substring($InicioApen)
$FinApen = $DespuesApen.Length

$NuevaEstructura = @"
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
"@

$Yaml = $Antes + $NuevaEstructura
[IO.File]::WriteAllText($YamlPath, $Yaml, $Utf8)

Write-Host ""
Write-Host "5. Activando índice general y lista de figuras en PDF..." -ForegroundColor Cyan

$PdfPath = Join-Path $Proyecto "_quarto-pdf.yml"
if (Test-Path -LiteralPath $PdfPath) {
    $Pdf = [IO.File]::ReadAllText($PdfPath, [Text.Encoding]::UTF8)

    if ($Pdf -notmatch "(?m)^\s+toc:\s*true") {
        $Pdf = $Pdf -replace "(?m)^  pdf:\s*$", "  pdf:`r`n    toc: true`r`n    lof: true`r`n    number-sections: true"
    }
    elseif ($Pdf -notmatch "(?m)^\s+lof:\s*true") {
        $Pdf = $Pdf -replace "(?m)^(\s+toc:\s*true\s*)$", '$1' + "`r`n    lof: true"
    }

    [IO.File]::WriteAllText($PdfPath, $Pdf, $Utf8)
}

Write-Host ""
Write-Host "6. Agregando la referencia bibliográfica del volumen teórico..." -ForegroundColor Cyan

$BibPath = Join-Path $Proyecto "referencias.bib"
$Bib = [IO.File]::ReadAllText($BibPath, [Text.Encoding]::UTF8)

if ($Bib -notmatch "@book\{rodriguez2026fundamentos") {
    $Entrada = @"

@book{rodriguez2026fundamentos,
  author    = {Rodríguez Escobedo, Jesús Gilberto},
  title     = {Fundamentos Matemáticos del Aprendizaje Automático},
  subtitle  = {Teoría, demostraciones y formulación rigurosa de los métodos de regresión, clasificación y análisis de datos},
  year      = {2026},
  edition   = {Primera edición digital},
  address   = {San Luis Potosí, México}
}
"@
    [IO.File]::AppendAllText($BibPath, $Entrada, $Utf8)
}

Write-Host ""
Write-Host "7. Agregando conexiones con el libro teórico..." -ForegroundColor Cyan

$Conexiones = @{
    "01-introduccion.qmd" = @"
::: {.callout-note title="Conexión con el volumen teórico"}\n\nLa formulación matemática de **Formulación del aprendizaje supervisado y teoría de clasificación** se desarrolla con mayor profundidad en los capítulos 5 y 6 de *Fundamentos Matemáticos del Aprendizaje Automático* [@rodriguez2026fundamentos].\n\n:::\n"@
    "02-preparacion-datos.qmd" = @"
::: {.callout-note title="Conexión con el volumen teórico"}\n\nLa formulación matemática de **representación matemática de datos, probabilidad y estadística** se desarrolla con mayor profundidad en los capítulos 1, 2 y 3 de *Fundamentos Matemáticos del Aprendizaje Automático* [@rodriguez2026fundamentos].\n\n:::\n"@
    "03-analisis-exploratorio.qmd" = @"
::: {.callout-note title="Conexión con el volumen teórico"}\n\nLa formulación matemática de **probabilidad, estadística, covarianza y representación multivariada** se desarrolla con mayor profundidad en los capítulos 2 y 3 de *Fundamentos Matemáticos del Aprendizaje Automático* [@rodriguez2026fundamentos].\n\n:::\n"@
    "04-regresion-lineal-multiple.qmd" = @"
::: {.callout-note title="Conexión con el volumen teórico"}\n\nLa formulación matemática de **regresión lineal simple y múltiple** se desarrolla con mayor profundidad en los capítulos 9 y 10 de *Fundamentos Matemáticos del Aprendizaje Automático* [@rodriguez2026fundamentos].\n\n:::\n"@
    "04-regresion-logistica.qmd" = @"
::: {.callout-note title="Conexión con el volumen teórico"}\n\nLa formulación matemática de **regresión logística, máxima verosimilitud y clasificación probabilística** se desarrolla con mayor profundidad en los capítulos 3, 6 y 11 de *Fundamentos Matemáticos del Aprendizaje Automático* [@rodriguez2026fundamentos].\n\n:::\n"@
    "05-knn.qmd" = @"
::: {.callout-note title="Conexión con el volumen teórico"}\n\nLa formulación matemática de **distancias, escalamiento y vecinos más cercanos** se desarrolla con mayor profundidad en los capítulos 2 y 12 de *Fundamentos Matemáticos del Aprendizaje Automático* [@rodriguez2026fundamentos].\n\n:::\n"@
    "06-arboles-decision.qmd" = @"
::: {.callout-note title="Conexión con el volumen teórico"}\n\nLa formulación matemática de **entropía, impureza, particiones y árboles de decisión** se desarrolla con mayor profundidad en los capítulos 3, 6 y 13 de *Fundamentos Matemáticos del Aprendizaje Automático* [@rodriguez2026fundamentos].\n\n:::\n"@
    "07-random-forest.qmd" = @"
::: {.callout-note title="Conexión con el volumen teórico"}\n\nLa formulación matemática de **bootstrap, ensambles y Random Forest** se desarrolla con mayor profundidad en los capítulos 7 y 14 de *Fundamentos Matemáticos del Aprendizaje Automático* [@rodriguez2026fundamentos].\n\n:::\n"@
    "08-evaluacion-modelos.qmd" = @"
::: {.callout-note title="Conexión con el volumen teórico"}\n\nLa formulación matemática de **matrices de confusión, métricas, validación y selección de modelos** se desarrolla con mayor profundidad en los capítulos 6 y 7 de *Fundamentos Matemáticos del Aprendizaje Automático* [@rodriguez2026fundamentos].\n\n:::\n"@
    "09-svm.qmd" = @"
::: {.callout-note title="Conexión con el volumen teórico"}\n\nLa formulación matemática de **margen, optimización convexa, condiciones KKT y kernels** se desarrolla con mayor profundidad en los capítulos 4 y 15 de *Fundamentos Matemáticos del Aprendizaje Automático* [@rodriguez2026fundamentos].\n\n:::\n"@
    "10-naive-bayes.qmd" = @"
::: {.callout-note title="Conexión con el volumen teórico"}\n\nLa formulación matemática de **probabilidad condicional, teorema de Bayes y clasificación probabilística** se desarrolla con mayor profundidad en los capítulos 3 y 6 de *Fundamentos Matemáticos del Aprendizaje Automático* [@rodriguez2026fundamentos].\n\n:::\n"@
    "11-redes-neuronales.qmd" = @"
::: {.callout-note title="Conexión con el volumen teórico"}\n\nLa formulación matemática de **álgebra lineal, cálculo, descenso por gradiente y redes neuronales** se desarrolla con mayor profundidad en los capítulos 2, 4 y 16 de *Fundamentos Matemáticos del Aprendizaje Automático* [@rodriguez2026fundamentos].\n\n:::\n"@
    "12-kmeans.qmd" = @"
::: {.callout-note title="Conexión con el volumen teórico"}\n\nLa formulación matemática de **distancias, función objetivo, centroides y agrupamiento k-means** se desarrolla con mayor profundidad en los capítulos 2 y 18 de *Fundamentos Matemáticos del Aprendizaje Automático* [@rodriguez2026fundamentos].\n\n:::\n"@
}

foreach ($Archivo in $Conexiones.Keys) {
    $Ruta = Join-Path $Proyecto $Archivo
    if (-not (Test-Path -LiteralPath $Ruta)) {
        Write-Host "Aviso: no existe $Archivo" -ForegroundColor Yellow
        continue
    }

    $Texto = [IO.File]::ReadAllText($Ruta, [Text.Encoding]::UTF8)

    if ($Texto -match "Conexión con el volumen teórico") {
        continue
    }

    $Lineas = $Texto -split "\r?\n"
    $Posicion = -1

    for ($i = 1; $i -lt $Lineas.Count; $i++) {
        if ($Lineas[$i] -match "^##\s+") {
            $Posicion = $i
            break
        }
    }

    if ($Posicion -lt 0) {
        $NuevoTexto = $Texto.TrimEnd() + "`r`n`r`n" + $Conexiones[$Archivo]
    }
    else {
        $Parte1 = ($Lineas[0..($Posicion-1)] -join "`r`n")
        $Parte2 = ($Lineas[$Posicion..($Lineas.Count-1)] -join "`r`n")
        $NuevoTexto = $Parte1 + "`r`n`r`n" + $Conexiones[$Archivo] + "`r`n" + $Parte2
    }

    [IO.File]::WriteAllText($Ruta, $NuevoTexto, $Utf8)
}

Write-Host ""
Write-Host "8. Actualizando presentación y versión..." -ForegroundColor Cyan

$IndexPath = Join-Path $Proyecto "index.qmd"
$Index = [IO.File]::ReadAllText($IndexPath, [Text.Encoding]::UTF8)

$Index = [regex]::Replace(
    $Index,
    "\*\*Versión:\*\*\s*[^\r\n]+",
    "**Versión:** 0.14.1-covid-dev"
)

$Index = $Index.Replace(
    "En esta versión trabajamos con datos de accidentes de tránsito de México y los usamos como hilo conductor",
    "En esta versión trabajamos con datos abiertos de accidentes de tránsito de México y registros de COVID-19 como casos transversales"
)

if ($Index -notmatch "volumen teórico complementario") {
    $Nota = @"

::: {.callout-note title="Volumen teórico complementario"}

Los fundamentos algebraicos, probabilísticos y matemáticos de los algoritmos
se desarrollan en *Fundamentos Matemáticos del Aprendizaje Automático*
[@rodriguez2026fundamentos].

:::
"@
    $Marca = "## Objetivo general"
    $P = $Index.IndexOf($Marca)
    if ($P -ge 0) {
        $Index = $Index.Substring(0, $P) + $Nota + "`r`n" + $Index.Substring($P)
    }
}

[IO.File]::WriteAllText($IndexPath, $Index, $Utf8)

Write-Host ""
Write-Host "9. Verificando archivos esenciales..." -ForegroundColor Cyan

$Requeridos = @(
    "00-bienvenida.qmd",
    "00-creditos-editoriales.qmd",
    "00-licencia-y-uso-academico.qmd",
    "00-prefacio.qmd",
    "00-agradecimientos.qmd",
    "glosario.qmd",
    "referencias.qmd",
    "indice-figuras.qmd",
    "indice-tematico.qmd",
    "acerca-del-autor.qmd"
)

foreach ($Archivo in $Requeridos) {
    if (-not (Test-Path -LiteralPath (Join-Path $Proyecto $Archivo))) {
        Detener "Falta el archivo $Archivo"
    }
}

$Revision = Get-ChildItem -LiteralPath $Proyecto -Recurse -File |
    Where-Object {
        $_.Extension -in @(".qmd", ".yml", ".yaml", ".tex", ".md") -and
        $_.FullName -notmatch '\\docs\\' -and
        $_.FullName -notmatch '\\respaldo'
    } |
    Select-String -SimpleMatch "MI Jesús Gilberto Rodríguez Escobedo"

if ($Revision) {
    Write-Host "Aviso: aún se encontró MI en algún archivo:" -ForegroundColor Yellow
    $Revision | ForEach-Object { Write-Host $_.Path }
}
else {
    Write-Host "Nombre del autor corregido en los archivos revisados." -ForegroundColor Green
}

Write-Host ""
Write-Host "ACTUALIZACIÓN EDITORIAL v0.14.1 INSTALADA" -ForegroundColor Green
Write-Host ""
Write-Host "Proyecto:"
Write-Host $Proyecto
Write-Host ""
Write-Host "Respaldo:"
Write-Host $Respaldo
Write-Host ""
Write-Host "Ahora ejecute:"
Write-Host "RENDERIZAR_REVISION_EDITORIAL_V0141.bat"
Write-Host ""

Read-Host "Presione Enter para cerrar"
