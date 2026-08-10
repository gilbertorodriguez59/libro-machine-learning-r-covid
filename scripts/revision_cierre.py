from pathlib import Path
import json, re, sys

chapters = [
    "index.qmd", "00-bienvenida.qmd", "00-creditos-editoriales.qmd",
    "00-licencia-y-uso-academico.qmd", "00-prefacio.qmd", "00-agradecimientos.qmd",
    "00-cuaderno-google-colab.qmd", "01-introduccion.qmd", "02-preparacion-datos.qmd",
    "03-analisis-exploratorio.qmd", "04-regresion-lineal-multiple.qmd",
    "04-regresion-logistica.qmd", "05-knn.qmd", "06-arboles-decision.qmd",
    "07-random-forest.qmd", "08-evaluacion-modelos.qmd", "09-svm.qmd",
    "10-naive-bayes.qmd", "11-redes-neuronales.qmd", "12-kmeans.qmd",
    "glosario.qmd", "referencias.qmd", "indice-figuras.qmd", "indice-tematico.qmd",
    "acerca-del-autor.qmd"
]

errors = []
warnings = []
report = ["# Revisión automática de cierre", ""]

for f in chapters:
    p = Path(f)
    if not p.exists():
        errors.append(f"Falta {f}")
        continue
    t = p.read_text(encoding="utf-8-sig")
    if "MI Jesús Gilberto" in t:
        errors.append(f"Autor antiguo encontrado en {f}")
    if "Aprendizaje-y-Clasificación-Automática-con-R.pdf" in t:
        warnings.append(f"Enlace PDF con acentos en fuente: {f}")
    # duplicate named R chunks are a common Quarto failure
    labels = re.findall(r'```\{r\s+([^,}\s]+)', t)
    dup = sorted({x for x in labels if labels.count(x) > 1})
    if dup:
        errors.append(f"Etiquetas R duplicadas en {f}: {', '.join(dup)}")

required_sections = {
    "05-knn.qmd": "Caso aplicado B: k-NN con COVID-19",
    "06-arboles-decision.qmd": "Caso aplicado B: árbol de decisión con COVID-19",
    "07-random-forest.qmd": "Caso aplicado B: Random Forest con COVID-19",
    "08-evaluacion-modelos.qmd": "Comparación integrada de modelos con COVID-19",
    "09-svm.qmd": "Caso aplicado B: SVM con COVID-19",
    "10-naive-bayes.qmd": "Caso aplicado B: Naive Bayes con COVID-19",
    "11-redes-neuronales.qmd": "Caso aplicado B: red neuronal con COVID-19",
    "12-kmeans.qmd": "Caso aplicado B: k-means con COVID-19",
    "03-analisis-exploratorio.qmd": "Laboratorio interactivo ATUS: mes, hora y víctimas",
    "12-kmeans.qmd": "Laboratorio interactivo COVID: agrupamiento k-means",
}
# Python dict cannot hold duplicate keys: check k-means cases independently below.
required_pairs = [
    ("05-knn.qmd", "Caso aplicado B: k-NN con COVID-19"),
    ("06-arboles-decision.qmd", "Caso aplicado B: árbol de decisión con COVID-19"),
    ("07-random-forest.qmd", "Caso aplicado B: Random Forest con COVID-19"),
    ("08-evaluacion-modelos.qmd", "Comparación integrada de modelos con COVID-19"),
    ("09-svm.qmd", "Caso aplicado B: SVM con COVID-19"),
    ("10-naive-bayes.qmd", "Caso aplicado B: Naive Bayes con COVID-19"),
    ("11-redes-neuronales.qmd", "Caso aplicado B: red neuronal con COVID-19"),
    ("12-kmeans.qmd", "Caso aplicado B: k-means con COVID-19"),
    ("03-analisis-exploratorio.qmd", "Laboratorio interactivo ATUS: mes, hora y víctimas"),
    ("12-kmeans.qmd", "Laboratorio interactivo COVID: agrupamiento k-means"),
]
for f, needle in required_pairs:
    if Path(f).exists() and needle not in Path(f).read_text(encoding="utf-8-sig"):
        errors.append(f"Falta sección requerida en {f}: {needle}")

q = Path("_quarto.yml").read_text(encoding="utf-8-sig") if Path("_quarto.yml").exists() else ""
for expected in [
    'author: "Jesús Gilberto Rodríguez Escobedo"',
    'output-file: "Aprendizaje-y-Clasificacion-Automatica-con-R"',
    'downloads: [pdf]'
]:
    if expected not in q:
        errors.append(f"Configuración faltante en _quarto.yml: {expected}")

nb = Path("Aprendizaje_y_Clasificacion_Automatica_con_R_Colab.ipynb")
if not nb.exists():
    errors.append("Falta el cuaderno Colab")
else:
    try:
        obj = json.loads(nb.read_text(encoding="utf-8"))
        if obj.get("nbformat") != 4:
            errors.append("El cuaderno Colab no usa nbformat 4")
        meta = obj.get("metadata", {}).get("libro_ml", {})
        if not meta.get("generated_from_quarto"):
            warnings.append("El Colab no indica haber sido generado desde Quarto")
        report.append(f"- Celdas Colab: {len(obj.get('cells', []))}")
    except Exception as e:
        errors.append(f"Colab inválido: {e}")

report += [
    f"- Capítulos/archivos revisados: {len(chapters)}",
    f"- Errores: {len(errors)}",
    f"- Advertencias: {len(warnings)}",
    "",
    "## Errores",
] + ([f"- {x}" for x in errors] or ["- Ninguno"]) + [
    "", "## Advertencias"
] + ([f"- {x}" for x in warnings] or ["- Ninguna"])

Path("revision-cierre.md").write_text("\n".join(report) + "\n", encoding="utf-8")
print("\n".join(report))

if errors:
    sys.exit(1)
