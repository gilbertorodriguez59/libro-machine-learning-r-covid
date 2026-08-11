from pathlib import Path
import re
import subprocess
import sys

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

ENCABEZADO = "## Materiales complementarios del capítulo"
COLAB_RE = re.compile(
    r'\n*<!-- colab-capitulo -->.*?<!-- /colab-capitulo -->\n*',
    re.S,
)


def youtube_id_from_section(section):
    m = re.search(r'youtube\.com/embed/([A-Za-z0-9_-]{6,})', section)
    if m:
        return m.group(1)
    m = re.search(r'youtube\.com/watch\?v=([A-Za-z0-9_-]{6,})', section)
    return m.group(1) if m else None


def normalize_iframe(section):
    pattern = re.compile(
        r'(?:<div\s+class="video-responsive">\s*)?'
        r'<iframe\b([^>]*?youtube\.com/embed/[A-Za-z0-9_-]+[^>]*)>\s*</iframe>'
        r'(?:\s*</div>)?',
        re.S | re.I,
    )

    def repl(m):
        attrs = m.group(1)
        attrs = re.sub(r'\s+(?:width|height)="[^"]*"', '', attrs, flags=re.I)
        attrs = re.sub(r'\s+style="[^"]*"', '', attrs, flags=re.I)
        attrs = re.sub(r'\s+frameborder="[^"]*"', '', attrs, flags=re.I)
        attrs = attrs.strip()
        return (
            '<div class="video-responsive">\n'
            f'  <iframe {attrs}\n'
            '    frameborder="0"\n'
            '    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"\n'
            '    referrerpolicy="strict-origin-when-cross-origin"\n'
            '    allowfullscreen>\n'
            '  </iframe>\n'
            '</div>'
        )

    return pattern.sub(repl, section)


def insert_colab_after_html(section, colab):
    blocks = list(re.finditer(
        r'::: \{\.content-visible when-format="html"\}.*?\n:::',
        section,
        re.S,
    ))
    for b in blocks:
        if 'youtube.com/embed/' in b.group(0):
            pos = b.end()
            return section[:pos] + "\n\n" + colab.strip() + "\n" + section[pos:]

    table = re.search(r'\n\| Recurso \|.*?(?=\n\n)', section, re.S)
    if table:
        pos = table.end()
        return section[:pos] + "\n\n" + colab.strip() + "\n" + section[pos:]

    pos = section.find('\n', len(ENCABEZADO))
    if pos == -1:
        pos = len(ENCABEZADO)
    return section[:pos] + "\n\n" + colab.strip() + "\n" + section[pos:]


# Primera pasada: normalizar videos y coherencia de enlaces.
for nombre in CAPITULOS:
    p = Path(nombre)
    text = p.read_text(encoding="utf-8")

    inicio = text.find(ENCABEZADO)
    if inicio < 0:
        raise SystemExit(f"Falta la sección de materiales en {nombre}")

    siguiente = re.search(r'^##\s+', text[inicio + len(ENCABEZADO):], re.M)
    fin = inicio + len(ENCABEZADO) + siguiente.start() if siguiente else len(text)
    section = text[inicio:fin]

    m_colab = COLAB_RE.search(section)
    if not m_colab:
        raise SystemExit(f"Falta bloque Colab en {nombre}")
    colab = m_colab.group(0).strip()
    section = COLAB_RE.sub("\n", section, count=1)

    video_id = youtube_id_from_section(section)
    if video_id:
        section = re.sub(
            r'https://www\.youtube\.com/watch\?v=[A-Za-z0-9_-]+',
            f'https://www.youtube.com/watch?v={video_id}',
            section,
        )
        section = normalize_iframe(section)

    section = insert_colab_after_html(section, colab)
    section = re.sub(r'\n{4,}', '\n\n\n', section)
    text = text[:inicio] + section + text[fin:]
    p.write_text(text, encoding="utf-8")
    print(f"Normalizado: {nombre} | video={video_id or 'sin video'}")

# Segunda pasada: capítulos 6 a 13 adoptan exactamente la tabla editorial
# de cuatro columnas usada en los capítulos 1 a 5.
subprocess.run(
    [sys.executable, "scripts/uniformar_materiales_capitulos_06_13.py"],
    check=True,
)

# Tercera pasada: agregar Google Colab como recurso dentro de la tabla de
# materiales complementarios de los 13 capítulos.
subprocess.run(
    [sys.executable, "scripts/agregar_colab_a_tablas_materiales.py"],
    check=True,
)

print("Materiales complementarios uniformes en los 13 capítulos, con Colab incluido en cada tabla.")
