from pathlib import Path
import json, re, datetime

CHAPTERS = [
    "01-introduccion.qmd",
    "02-preparacion-datos.qmd",
    "03-analisis-exploratorio.qmd",
    "04-regresion-lineal-multiple.qmd",
    "04-regresion-logistica.qmd",
    "05-knn.qmd",
    "06-arboles-decision.qmd",
    "07-random-forest.qmd",
    "08-evaluacion-modelos.qmd",
    "09-svm.qmd",
    "10-naive-bayes.qmd",
    "11-redes-neuronales.qmd",
    "12-kmeans.qmd",
]

OUT = Path("Aprendizaje_y_Clasificacion_Automatica_con_R_Colab.ipynb")
REPO = "https://github.com/gilbertorodriguez59/libro-machine-learning-r-covid"
RAW = "https://raw.githubusercontent.com/gilbertorodriguez59/libro-machine-learning-r-covid/main"


def md_cell(text):
    text = text.strip("\n")
    return {"cell_type": "markdown", "metadata": {}, "source": [x + "\n" for x in text.splitlines()]}


def code_cell(code):
    code = code.strip("\n")
    return {
        "cell_type": "code",
        "execution_count": None,
        "metadata": {},
        "outputs": [],
        "source": [x + "\n" for x in code.splitlines()],
    }


def clean_markdown(text):
    text = re.sub(r'^:::\s*\{[^\n]*\}\s*$', '', text, flags=re.M)
    text = re.sub(r'^:::\s*$', '', text, flags=re.M)
    text = re.sub(r'\{target="_blank"\}', '', text)
    text = re.sub(r'\{fig-alt="[^"]*"[^}]*\}', '', text)
    text = re.sub(r'\{width="?[0-9.%]+"?\}', '', text)
    text = re.sub(r'<div[^>]*>.*?</div>', '', text, flags=re.S|re.I)
    text = re.sub(r'<iframe.*?</iframe>', '*Video disponible en la versión web del libro.*', text, flags=re.S|re.I)
    text = re.sub(r'\n{3,}', '\n\n', text)
    return text.strip()


def parse_qmd(path):
    text = Path(path).read_text(encoding="utf-8-sig")
    if text.startswith("---\n"):
        end = text.find("\n---\n", 4)
        if end != -1:
            text = text[end+5:]

    cells = []
    pos = 0
    fence = re.compile(r'```\{([^}]+)\}\n(.*?)\n```', re.S)
    for m in fence.finditer(text):
        before = clean_markdown(text[pos:m.start()])
        if before:
            cells.append(md_cell(before))

        engine = m.group(1).strip()
        body = m.group(2)
        if engine.startswith("r"):
            body = "\n".join(line for line in body.splitlines() if not line.lstrip().startswith("#|"))
            if "eval: false" not in m.group(2):
                cells.append(code_cell(body))
        elif engine.startswith("shinylive-r"):
            cells.append(md_cell(
                "**Laboratorio interactivo:** este bloque se ejecuta en la versión web del libro mediante Shinylive. "
                "En Colab se conserva el desarrollo algorítmico del capítulo, pero no la interfaz Shiny del navegador."
            ))
        else:
            cells.append(md_cell("```" + engine + "\n" + body + "\n```"))
        pos = m.end()

    tail = clean_markdown(text[pos:])
    if tail:
        cells.append(md_cell(tail))
    return cells


def extract_toc(cells):
    toc = ["# Índice general", ""]
    for cell in cells:
        if cell["cell_type"] != "markdown":
            continue
        for line in cell["source"]:
            s = line.strip()
            m = re.match(r'^(#{1,2})\s+(.+)$', s)
            if not m:
                continue
            level = len(m.group(1))
            title = re.sub(r'[*`]', '', m.group(2)).strip()
            if title in {"Índice general"}:
                continue
            indent = "  " if level == 2 else ""
            toc.append(f"{indent}- {title}")
    return "\n".join(toc)


all_cells = []
intro = f"""# Aprendizaje y Clasificación Automática con R

**Autor:** Jesús Gilberto Rodríguez Escobedo

Cuaderno completo y ejecutable que acompaña la versión web y PDF del libro. Fue generado automáticamente a partir de los archivos Quarto actuales para mantener sincronizados capítulos, ejemplos ATUS y casos COVID-19.

Repositorio del libro: {REPO}

## Cómo ejecutar este cuaderno

1. **Ejecute primero la celda de preparación automática.** Esa celda instala los paquetes faltantes y descarga `util_graficas.R`, la base ATUS preparada y los archivos COVID-19 utilizados por los ejemplos.
2. **Ejecute las celdas en orden, de arriba hacia abajo.** Muchos ejemplos crean objetos que se utilizan en las celdas siguientes.
3. **Si Colab reinicia o desconecta el entorno de ejecución, vuelva a ejecutar desde la primera celda.** Los objetos que estaban en memoria se pierden al reiniciarse la sesión.
4. Los laboratorios Shinylive permanecen en la versión web; en Colab se conserva el código R reproducible asociado a cada capítulo.

> **Comprobación rápida:** cuando la primera celda termine correctamente debe mostrar `Entorno listo` y `Archivos auxiliares y datos preparados disponibles`.
"""
all_cells.append(md_cell(intro))

setup = f'''# Preparación automática para Google Colab con runtime R
options(repos = c(CRAN = "https://cloud.r-project.org"))

paquetes_libro <- c(
  "ggplot2", "readr", "dplyr", "tidyr", "stringr", "data.table",
  "class", "rpart", "randomForest", "ranger", "e1071", "naivebayes",
  "neuralnet", "cluster", "caret", "factoextra", "scales", "plotly", "DT"
)

faltantes <- paquetes_libro[
  !vapply(paquetes_libro, requireNamespace, logical(1), quietly = TRUE)
]
if (length(faltantes)) install.packages(faltantes)

# Crear la misma estructura de carpetas que usa el libro
dir.create("datos", showWarnings = FALSE, recursive = TRUE)
dir.create("datos/covid19/procesados", showWarnings = FALSE, recursive = TRUE)
dir.create("datos/covid19/muestras", showWarnings = FALSE, recursive = TRUE)
dir.create("datos/covid19/diccionarios", showWarnings = FALSE, recursive = TRUE)

# Archivos necesarios para ejecutar los ejemplos sin clonar el repositorio
archivos_colab <- c(
  "util_graficas.R" = "{RAW}/util_graficas.R",
  "datos/atus_ml_preparado.csv" = "{RAW}/datos/atus_ml_preparado.csv",
  "datos/covid19/procesados/covid19_mexico_2022_ml_preparado.csv.gz" = "{RAW}/datos/covid19/procesados/covid19_mexico_2022_ml_preparado.csv.gz",
  "datos/covid19/muestras/covid19_mexico_2022_muestra.csv.gz" = "{RAW}/datos/covid19/muestras/covid19_mexico_2022_muestra.csv.gz",
  "datos/covid19/diccionarios/diccionario_covid19_ml.csv" = "{RAW}/datos/covid19/diccionarios/diccionario_covid19_ml.csv"
)

for (destino in names(archivos_colab)) {{
  if (!file.exists(destino)) {{
    message("Descargando: ", destino)
    download.file(archivos_colab[[destino]], destino, mode = "wb", quiet = TRUE)
  }}
}}

stopifnot(file.exists("util_graficas.R"))
stopifnot(file.exists("datos/atus_ml_preparado.csv"))
stopifnot(file.exists("datos/covid19/procesados/covid19_mexico_2022_ml_preparado.csv.gz"))
source("util_graficas.R")

cat("Entorno listo. R:", R.version.string, "\n")
cat("Archivos auxiliares y datos preparados disponibles.\n")
'''
all_cells.append(code_cell(setup))

chapter_cells = []
for chapter in CHAPTERS:
    if not Path(chapter).exists():
        raise SystemExit(f"Falta el capítulo {chapter}")
    chapter_cells.extend(parse_qmd(chapter))

all_cells.append(md_cell(extract_toc(chapter_cells)))
all_cells.extend(chapter_cells)

notebook = {
    "cells": all_cells,
    "metadata": {
        "kernelspec": {"display_name": "R", "language": "R", "name": "ir"},
        "language_info": {"name": "R"},
        "colab": {"provenance": []},
        "libro_ml": {
            "generated_from_quarto": True,
            "generated_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "chapters": CHAPTERS,
        },
    },
    "nbformat": 4,
    "nbformat_minor": 5,
}
OUT.write_text(json.dumps(notebook, ensure_ascii=False, indent=1), encoding="utf-8")
print(f"Cuaderno generado: {OUT} ({len(all_cells)} celdas)")
