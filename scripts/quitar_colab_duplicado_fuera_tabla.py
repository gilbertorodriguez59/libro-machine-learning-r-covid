from pathlib import Path
import re

CAPITULOS = [
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

PATRON = re.compile(
    r'\n*<!-- colab-capitulo -->\s*'
    r'::: \{\.callout-tip title="Cuaderno Google Colab del capítulo"\}.*?'
    r'::: <!-- /colab-capitulo -->\s*\n*',
    re.S,
)

for nombre in CAPITULOS:
    p = Path(nombre)
    text = p.read_text(encoding="utf-8")
    nuevo, n = PATRON.subn("\n\n", text)
    nuevo = re.sub(r'\n{4,}', '\n\n\n', nuevo)
    p.write_text(nuevo, encoding="utf-8")
    print(f"{nombre}: bloques Colab duplicados eliminados = {n}")

print("Colab se conserva únicamente dentro de la tabla de materiales complementarios.")
