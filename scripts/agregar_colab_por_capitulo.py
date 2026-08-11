from pathlib import Path

BASE = "https://colab.research.google.com/github/gilbertorodriguez59/libro-machine-learning-r-covid/blob/main/colab"

CAPITULOS = [
    ("01-introduccion.qmd", "01-introduccion.ipynb"),
    ("02-preparacion-datos.qmd", "02-preparacion-datos.ipynb"),
    ("03-analisis-exploratorio.qmd", "03-analisis-exploratorio.ipynb"),
    ("04-regresion-lineal-multiple.qmd", "04-regresion-lineal.ipynb"),
    ("04-regresion-logistica.qmd", "05-regresion-logistica.ipynb"),
    ("05-knn.qmd", "06-knn.ipynb"),
    ("06-arboles-decision.qmd", "07-arboles-decision.ipynb"),
    ("07-random-forest.qmd", "08-random-forest.ipynb"),
    ("08-evaluacion-modelos.qmd", "09-evaluacion-modelos.ipynb"),
    ("09-svm.qmd", "10-svm.ipynb"),
    ("10-naive-bayes.qmd", "11-naive-bayes.ipynb"),
    ("11-redes-neuronales.qmd", "12-redes-neuronales.ipynb"),
    ("12-kmeans.qmd", "13-kmeans.ipynb"),
]

MARCADOR = "<!-- colab-capitulo -->"
ENCABEZADO = "## Materiales complementarios del capítulo"

for qmd, notebook in CAPITULOS:
    p = Path(qmd)
    if not p.exists():
        raise SystemExit(f"No existe {qmd}")

    text = p.read_text(encoding="utf-8")

    if MARCADOR in text:
        print(f"Ya tiene enlace Colab: {qmd}")
        continue

    if ENCABEZADO not in text:
        raise SystemExit(f"No se encontró '{ENCABEZADO}' en {qmd}")

    url = f"{BASE}/{notebook}"
    bloque = f'''\n\n{MARCADOR}\n::: {{.callout-tip title="Cuaderno Google Colab del capítulo"}}\n\nEste capítulo cuenta con un **cuaderno autónomo de Google Colab**. Puede abrirse y ejecutarse de manera independiente, sin necesidad de ejecutar los capítulos anteriores.\n\n[**Abrir este capítulo en Google Colab**]({url}){{target="_blank"}}\n\n::: <!-- /colab-capitulo -->\n'''

    text = text.replace(ENCABEZADO, ENCABEZADO + bloque, 1)
    p.write_text(text, encoding="utf-8")
    print(f"Enlace Colab agregado: {qmd} -> {notebook}")

print("Enlaces Colab por capítulo actualizados.")
