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
    """Normaliza cualquier iframe YouTube al mismo contenedor responsive."""
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
    """Orden uniforme: enlaces/tabla -> bloque HTML (video/vista previa) -> Colab -> notas finales."""
    # Inserta después del primer bloque content-visible HTML completo que incluya YouTube.
    blocks = list(re.finditer(
        r'::: \{\.content-visible when-format="html"\}.*?\n:::',
        section,
        re.S,
    ))
    for b in blocks:
        if 'youtube.com/embed/' in b.group(0):
            pos = b.end()
            return section[:pos] + "\n\n" + colab.strip() + "\n" + section[pos:]

    # Respaldo: después de la tabla de recursos, si existe.
    table = re.search(r'\n\| Recurso \|.*?(?=\n\n)', section, re.S)
    if table:
        pos = table.end()
        return section[:pos] + "\n\n" + colab.strip() + "\n" + section[pos:]

    # Último respaldo: inmediatamente después del encabezado.
    pos = section.find('\n', len(ENCABEZADO))
    if pos == -1:
        pos = len(ENCABEZADO)
    return section[:pos] + "\n\n" + colab.strip() + "\n" + section[pos:]


for nombre in CAPITULOS:
    p = Path(nombre)
    text = p.read_text(encoding="utf-8")

    inicio = text.find(ENCABEZADO)
    if inicio < 0:
        raise SystemExit(f"Falta la sección de materiales en {nombre}")

    siguiente = re.search(r'^##\s+', text[inicio + len(ENCABEZADO):], re.M)
    if siguiente:
        fin = inicio + len(ENCABEZADO) + siguiente.start()
    else:
        fin = len(text)

    section = text[inicio:fin]

    # Extraer el bloque Colab existente para recolocarlo siempre en el mismo sitio.
    m_colab = COLAB_RE.search(section)
    if not m_colab:
        raise SystemExit(f"Falta bloque Colab en {nombre}")
    colab = m_colab.group(0).strip()
    section = COLAB_RE.sub("\n", section, count=1)

    # Unificar el ID del video tomando como referencia el iframe incrustado.
    video_id = youtube_id_from_section(section)
    if video_id:
        # Cualquier enlace individual de YouTube dentro de materiales apuntará al mismo video.
        section = re.sub(
            r'https://www\.youtube\.com/watch\?v=[A-Za-z0-9_-]+',
            f'https://www.youtube.com/watch?v={video_id}',
            section,
        )
        section = normalize_iframe(section)

    # Recolocar Colab después del bloque visual del video, de manera uniforme.
    section = insert_colab_after_html(section, colab)

    # Limpieza de espacios excesivos.
    section = re.sub(r'\n{4,}', '\n\n\n', section)
    text = text[:inicio] + section + text[fin:]
    p.write_text(text, encoding="utf-8")
    print(f"Normalizado: {nombre} | video={video_id or 'sin video'}")

print("Materiales complementarios normalizados en los 13 capítulos.")
