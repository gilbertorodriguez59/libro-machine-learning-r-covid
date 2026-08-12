from pathlib import Path
import re

CAPITULOS = [
    (6, "05-knn.qmd", "k vecinos más cercanos, k-NN"),
    (7, "06-arboles-decision.qmd", "Árboles de decisión para clasificación"),
    (8, "07-random-forest.qmd", "Random Forest"),
    (9, "08-evaluacion-modelos.qmd", "Evaluación y comparación de modelos"),
    (10, "09-svm.qmd", "Máquinas de vectores de soporte, SVM"),
    (11, "10-naive-bayes.qmd", "Naive Bayes"),
    (12, "11-redes-neuronales.qmd", "Redes neuronales"),
    (13, "12-kmeans.qmd", "Agrupamiento k-means"),
]

PLAYLIST = "https://www.youtube.com/playlist?list=PLDJYd2v7Kt-Q"
HEADING = "## Materiales complementarios del capítulo"


def first(pattern, text):
    m = re.search(pattern, text, re.I | re.S)
    return m.group(1) if m else None


def youtube_id(section):
    for pat in [
        r'youtube\.com/embed/([A-Za-z0-9_-]+)',
        r'youtu\.be/([A-Za-z0-9_-]+)',
        r'youtube\.com/watch\?v=([A-Za-z0-9_-]+)',
    ]:
        x = first(pat, section)
        if x:
            return x
    return None


def resource(section, ext):
    matches = re.findall(r'\((recursos/[^)]+\.' + re.escape(ext) + r')\)', section, re.I)
    if matches:
        return matches[0]
    matches = re.findall(r'(recursos/[A-Za-z0-9_./-]+\.' + re.escape(ext) + r')', section, re.I)
    return matches[0] if matches else None


def colab_url(section):
    return first(r'(https://colab\.research\.google\.com/github/[^)\s]+\.ipynb)', section)


def make_block(n, title, vid, pdf, pptx, png, colab):
    if not all([vid, pdf, pptx, png, colab]):
        faltan = [k for k, v in {"video": vid, "pdf": pdf, "pptx": pptx, "png": png, "colab": colab}.items() if not v]
        raise SystemExit(f"Capítulo {n}: faltan recursos: {', '.join(faltan)}")

    youtube = f"https://www.youtube.com/watch?v={vid}"
    embed = f"https://www.youtube.com/embed/{vid}"

    return f'''{HEADING}

Estos recursos permiten repasar los conceptos principales del capítulo mediante distintos formatos. La presentación puede consultarse en PDF o modificarse en PowerPoint; la infografía ofrece una síntesis visual, el video explica los contenidos y el cuaderno Colab permite ejecutar los ejemplos de manera autónoma.

| Recurso | Utilidad | Abrir o reproducir | Descargar |
|---|---|---|---|
| Video explicativo | Explicación audiovisual de los contenidos del capítulo. | [Ver en YouTube]({youtube}){{target="_blank"}} | — |
| Presentación en PDF | Diapositivas para lectura, estudio o exposición. | [Ver PDF]({pdf}){{target="_blank"}} | [Descargar PDF]({pdf}){{download="{Path(pdf).name}"}} |
| Presentación editable | Archivo PowerPoint para utilizarlo en clase o adaptarlo. | [Abrir PPTX]({pptx}) | [Descargar PPTX]({pptx}){{download="{Path(pptx).name}"}} |
| Infografía | Resumen visual de las ideas fundamentales. | [Ver infografía]({png}){{target="_blank"}} | [Descargar PNG]({png}){{download="{Path(png).name}"}} |
| Cuaderno Google Colab | Cuaderno autónomo para ejecutar los ejemplos del capítulo sin necesidad de ejecutar los capítulos anteriores. | [Abrir en Google Colab]({colab}){{target="_blank"}} | — |

::: {{.content-visible when-format="html"}}
### Video explicativo

<div class="video-responsive">
  <iframe
    src="{embed}"
    title="Capítulo {n}. {title}"
    frameborder="0"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
    referrerpolicy="strict-origin-when-cross-origin"
    allowfullscreen>
  </iframe>
</div>

### Vista previa de la infografía

[![Infografía del capítulo {n}]({png})]({png})
:::

::: {{.content-visible when-format="pdf"}}
**Video del capítulo:** <{youtube}>

La presentación PDF, el archivo editable, la infografía y el cuaderno Colab pueden consultarse desde la versión web del libro.
:::

::: {{.callout-note title="Elaboración de los materiales"}}
Los materiales complementarios fueron elaborados con apoyo de **NotebookLM de Google**, a partir del contenido del capítulo, y posteriormente revisados y adaptados por el autor. El texto del libro y sus archivos fuente constituyen la referencia principal.
:::

::: {{.callout-tip title="Curso completo en YouTube"}}
Este video forma parte de la lista oficial del curso **Aprendizaje y Clasificación Automática con R**.

[Consultar todos los videos del curso]({PLAYLIST}){{target="_blank"}}
:::
'''


for n, filename, title in CAPITULOS:
    p = Path(filename)
    text = p.read_text(encoding="utf-8")
    start = text.find(HEADING)
    if start < 0:
        raise SystemExit(f"Capítulo {n}: no se encontró materiales complementarios")

    m_next = re.search(r'^##\s+', text[start + len(HEADING):], re.M)
    end = start + len(HEADING) + m_next.start() if m_next else len(text)
    section = text[start:end]

    nuevo = make_block(
        n,
        title,
        youtube_id(section),
        resource(section, "pdf"),
        resource(section, "pptx"),
        resource(section, "png"),
        colab_url(section),
    )
    p.write_text(text[:start] + nuevo + "\n" + text[end:], encoding="utf-8")
    print(f"Capítulo {n} uniformado")

print("Capítulos 6 a 13 uniformados: Colab solo dentro de la tabla.")
