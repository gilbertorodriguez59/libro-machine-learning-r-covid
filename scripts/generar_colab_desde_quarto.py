from pathlib import Path
import json, re, datetime

CHAPTERS = [
    (1, "01-introduccion.qmd", "Introducción al aprendizaje automático", "01-introduccion.ipynb"),
    (2, "02-preparacion-datos.qmd", "Preparación de datos reales", "02-preparacion-datos.ipynb"),
    (3, "03-analisis-exploratorio.qmd", "Análisis exploratorio de datos", "03-analisis-exploratorio.ipynb"),
    (4, "04-regresion-lineal-multiple.qmd", "Regresión lineal simple y múltiple", "04-regresion-lineal.ipynb"),
    (5, "04-regresion-logistica.qmd", "Regresión logística", "05-regresion-logistica.ipynb"),
    (6, "05-knn.qmd", "k vecinos más cercanos (k-NN)", "06-knn.ipynb"),
    (7, "06-arboles-decision.qmd", "Árboles de decisión", "07-arboles-decision.ipynb"),
    (8, "07-random-forest.qmd", "Random Forest", "08-random-forest.ipynb"),
    (9, "08-evaluacion-modelos.qmd", "Evaluación y comparación de modelos", "09-evaluacion-modelos.ipynb"),
    (10, "09-svm.qmd", "Máquinas de vectores de soporte (SVM)", "10-svm.ipynb"),
    (11, "10-naive-bayes.qmd", "Naive Bayes", "11-naive-bayes.ipynb"),
    (12, "11-redes-neuronales.qmd", "Redes neuronales", "12-redes-neuronales.ipynb"),
    (13, "12-kmeans.qmd", "Agrupamiento k-means", "13-kmeans.ipynb"),
]

OUT_MASTER = Path("Aprendizaje_y_Clasificacion_Automatica_con_R_Colab.ipynb")
OUT_DIR = Path("colab")
OUT_INDEX = OUT_DIR / "00-indice-colabs.ipynb"
REPO = "https://github.com/gilbertorodriguez59/libro-machine-learning-r-covid"
RAW = "https://raw.githubusercontent.com/gilbertorodriguez59/libro-machine-learning-r-covid/main"
COLAB_BASE = "https://colab.research.google.com/github/gilbertorodriguez59/libro-machine-learning-r-covid/blob/main"


def md_cell(text):
    text = text.strip("\n")
    return {"cell_type": "markdown", "metadata": {}, "source": [x + "\n" for x in text.splitlines()]}


def code_cell(code):
    code = code.strip("\n")
    return {"cell_type": "code", "execution_count": None, "metadata": {}, "outputs": [],
            "source": [x + "\n" for x in code.splitlines()]}


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
            text = text[end + 5:]
    cells, pos = [], 0
    fence = re.compile(r'```\{([^}]+)\}\n(.*?)\n```', re.S)
    for m in fence.finditer(text):
        before = clean_markdown(text[pos:m.start()])
        if before:
            cells.append(md_cell(before))
        engine, body = m.group(1).strip(), m.group(2)
        if engine.startswith("shinylive-r"):
            cells.append(md_cell("**Laboratorio interactivo:** este bloque se ejecuta en la versión web mediante Shinylive; aquí se conserva el desarrollo reproducible del capítulo."))
        elif engine.startswith("r"):
            body = "\n".join(line for line in body.splitlines() if not line.lstrip().startswith("#|"))
            if "eval: false" not in m.group(2):
                cells.append(code_cell(body))
        else:
            cells.append(md_cell("```" + engine + "\n" + body + "\n```"))
        pos = m.end()
    tail = clean_markdown(text[pos:])
    if tail:
        cells.append(md_cell(tail))
    return cells


def setup_cell():
    return code_cell(f'''# Preparación automática y autónoma del capítulo
options(repos = c(CRAN = "https://cloud.r-project.org"))

paquetes_libro <- c(
  "ggplot2", "readr", "dplyr", "tidyr", "stringr", "data.table",
  "class", "rpart", "randomForest", "ranger", "e1071", "naivebayes",
  "neuralnet", "cluster", "caret", "factoextra", "scales", "plotly", "DT"
)
faltantes <- paquetes_libro[!vapply(paquetes_libro, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltantes)) install.packages(faltantes)

dir.create("datos/covid19/procesados", showWarnings = FALSE, recursive = TRUE)
dir.create("datos/covid19/muestras", showWarnings = FALSE, recursive = TRUE)
dir.create("datos/covid19/diccionarios", showWarnings = FALSE, recursive = TRUE)

archivos_colab <- c(
  "util_graficas.R" = "{RAW}/util_graficas.R",
  "datos/atus_ml_preparado.csv" = "{RAW}/datos/atus_ml_preparado.csv",
  "datos/covid19/procesados/covid19_mexico_2022_ml_preparado.csv.gz" = "{RAW}/datos/covid19/procesados/covid19_mexico_2022_ml_preparado.csv.gz",
  "datos/covid19/muestras/covid19_mexico_2022_muestra.csv.gz" = "{RAW}/datos/covid19/muestras/covid19_mexico_2022_muestra.csv.gz",
  "datos/covid19/diccionarios/diccionario_covid19_ml.csv" = "{RAW}/datos/covid19/diccionarios/diccionario_covid19_ml.csv"
)
for (destino in names(archivos_colab)) {{
  if (!file.exists(destino)) download.file(archivos_colab[[destino]], destino, mode = "wb", quiet = TRUE)
}}
stopifnot(all(file.exists(names(archivos_colab))))
source("util_graficas.R")
cat("Entorno autónomo listo. R:", R.version.string, "\\n")
''')


def notebook(cells, meta_extra=None):
    meta = {
        "kernelspec": {"display_name": "R", "language": "R", "name": "ir"},
        "language_info": {"name": "R"},
        "colab": {"provenance": []},
        "libro_ml": {"generated_from_quarto": True, "generated_utc": datetime.datetime.now(datetime.timezone.utc).isoformat()},
    }
    if meta_extra:
        meta["libro_ml"].update(meta_extra)
    return {"cells": cells, "metadata": meta, "nbformat": 4, "nbformat_minor": 5}


def write_notebook(path, cells, meta_extra=None):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(notebook(cells, meta_extra), ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"Generado: {path} ({len(cells)} celdas)")


OUT_DIR.mkdir(exist_ok=True)

# 1) Cuadernos autónomos por capítulo
chapter_cells_all = []
for number, qmd, title, filename in CHAPTERS:
    if not Path(qmd).exists():
        raise SystemExit(f"Falta el capítulo {qmd}")
    chapter_cells = parse_qmd(qmd)
    intro = md_cell(f'''# Capítulo {number}. {title}

**Aprendizaje y Clasificación Automática con R**  
**Autor:** Jesús Gilberto Rodríguez Escobedo

Este cuaderno es **independiente y autónomo**: puede abrirse directamente sin ejecutar capítulos anteriores.

1. Ejecute primero la celda **Preparación automática y autónoma del capítulo**.
2. Después ejecute las celdas en orden.
3. Si Colab reinicia la sesión, vuelva a ejecutar desde la primera celda.

[Volver al índice de cuadernos Colab]({COLAB_BASE}/colab/00-indice-colabs.ipynb)
''')
    cells = [intro, setup_cell()] + chapter_cells
    write_notebook(OUT_DIR / filename, cells, {"chapter": number, "source": qmd})
    chapter_cells_all.extend(chapter_cells)

# 2) Cuaderno índice / lanzador
links = [
    "# Cuadernos Google Colab por capítulo",
    "",
    "**Aprendizaje y Clasificación Automática con R**  ",
    "**Autor:** Jesús Gilberto Rodríguez Escobedo",
    "",
    "Cada cuaderno es independiente: abre el capítulo que deseas estudiar y ejecuta su primera celda de preparación.",
    "",
    f"- [Abrir el cuaderno completo del libro]({COLAB_BASE}/Aprendizaje_y_Clasificacion_Automatica_con_R_Colab.ipynb)",
    "",
]
for number, qmd, title, filename in CHAPTERS:
    links.append(f"- [Capítulo {number}. {title}]({COLAB_BASE}/colab/{filename})")
links += ["", f"[Abrir la versión web del libro](https://gilbertorodriguez59.github.io/libro-machine-learning-r-covid/)"]
write_notebook(OUT_INDEX, [md_cell("\n".join(links))], {"type": "index"})

# 3) Cuaderno maestro completo
master_intro = md_cell(f'''# Aprendizaje y Clasificación Automática con R

**Autor:** Jesús Gilberto Rodríguez Escobedo

Este es el **cuaderno maestro completo**. Para trabajar de forma más ligera se recomienda usar los cuadernos autónomos por capítulo:

[Abrir índice de Colabs por capítulo]({COLAB_BASE}/colab/00-indice-colabs.ipynb)

## Cómo ejecutar este cuaderno completo

1. Ejecute primero la celda de preparación automática.
2. Ejecute las celdas en orden, de arriba hacia abajo.
3. Si Colab reinicia o desconecta el entorno, vuelva a ejecutar desde la primera celda.
''')
master_cells = [master_intro, setup_cell()]
master_cells.append(md_cell("# Índice general\n\n" + "\n".join(
    f"- Capítulo {n}. {title}" for n, _, title, _ in CHAPTERS
)))
master_cells.extend(chapter_cells_all)
write_notebook(OUT_MASTER, master_cells, {"type": "master", "chapters": [q for _, q, _, _ in CHAPTERS]})
