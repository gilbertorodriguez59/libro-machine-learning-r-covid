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

HEADING = "## Materiales complementarios del capítulo"
ROW_LABEL = "| Cuaderno Google Colab |"

for nombre in CAPITULOS:
    p = Path(nombre)
    text = p.read_text(encoding="utf-8")
    start = text.find(HEADING)
    if start < 0:
        raise SystemExit(f"No se encontró materiales complementarios en {nombre}")

    next_h = re.search(r'^##\s+', text[start + len(HEADING):], re.M)
    end = start + len(HEADING) + next_h.start() if next_h else len(text)
    section = text[start:end]

    if ROW_LABEL in section:
        print(f"Ya tiene Colab en tabla: {nombre}")
        continue

    m_colab = re.search(
        r'https://colab\.research\.google\.com/github/[^)\s]+\.ipynb',
        section,
    )
    if not m_colab:
        raise SystemExit(f"No se encontró URL Colab en {nombre}")
    colab = m_colab.group(0)

    # Solo se acepta la tabla editorial estándar de cuatro columnas.
    table_head = "| Recurso | Utilidad | Abrir o reproducir | Descargar |"
    if table_head not in section:
        raise SystemExit(
            f"La tabla de {nombre} todavía no usa el formato estándar de cuatro columnas"
        )

    # Insertar al final de las filas de recursos, antes del siguiente bloque no-tabla.
    lines = section.splitlines()
    head_idx = next(i for i, line in enumerate(lines) if line.strip() == table_head)
    i = head_idx + 2  # saltar separador
    while i < len(lines) and lines[i].lstrip().startswith("|"):
        i += 1

    row = (
        "| Cuaderno Google Colab | Cuaderno autónomo para ejecutar los ejemplos del capítulo "
        "sin necesidad de ejecutar los capítulos anteriores. | "
        f"[Abrir en Google Colab]({colab}){{target=\"_blank\"}} | — |"
    )
    lines.insert(i, row)
    new_section = "\n".join(lines)
    text = text[:start] + new_section + text[end:]
    p.write_text(text, encoding="utf-8")
    print(f"Colab agregado a tabla: {nombre}")

print("Las 13 tablas de materiales complementarios incluyen ahora su Colab autónomo.")
