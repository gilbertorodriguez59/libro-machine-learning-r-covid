from pathlib import Path
import re

files = [
    Path('index.qmd'),
    Path('00-bienvenida.qmd'),
    Path('00-creditos-editoriales.qmd'),
    Path('00-licencia-y-uso-academico.qmd'),
    Path('00-prefacio.qmd'),
    Path('00-agradecimientos.qmd'),
    Path('00-cuaderno-google-colab.qmd'),
    Path('01-introduccion.qmd'),
    Path('02-preparacion-datos.qmd'),
    Path('03-analisis-exploratorio.qmd'),
    Path('04-regresion-lineal-multiple.qmd'),
    Path('04-regresion-logistica.qmd'),
    Path('05-knn.qmd'),
    Path('06-arboles-decision.qmd'),
    Path('07-random-forest.qmd'),
    Path('08-evaluacion-modelos.qmd'),
    Path('09-svm.qmd'),
    Path('10-naive-bayes.qmd'),
    Path('11-redes-neuronales.qmd'),
    Path('12-kmeans.qmd'),
    Path('glosario.qmd'),
    Path('referencias.qmd'),
    Path('indice-figuras.qmd'),
    Path('indice-tematico.qmd'),
    Path('acerca-del-autor.qmd'),
]

open_pat = re.compile(r'^\s*:::\s*\{.*\}\s*$')
close_pat = re.compile(r'^\s*:::\s*$')
fence_pat = re.compile(r'^\s*```')

for p in files:
    if not p.exists():
        continue

    lines = p.read_text(encoding='utf-8').splitlines()
    in_code = False
    balance = 0
    repaired = []
    removed = 0

    # Primera pasada: eliminar solo cierres ::: que aparecen cuando no existe
    # ningún Div abierto. Los bloques de código se dejan intactos.
    for line in lines:
        if fence_pat.match(line):
            in_code = not in_code
            repaired.append(line)
            continue

        if in_code:
            repaired.append(line)
            continue

        if open_pat.match(line):
            balance += 1
            repaired.append(line)
            continue

        if close_pat.match(line):
            if balance == 0:
                removed += 1
                continue
            balance -= 1
            repaired.append(line)
            continue

        repaired.append(line)

    # Segunda reparación: si quedaron Div abiertos, cerrarlos al final.
    added = balance
    if added > 0:
        if repaired and repaired[-1].strip():
            repaired.append('')
        repaired.extend([':::'] * added)

    # Verificación final estricta.
    check_balance = 0
    in_code = False
    for line in repaired:
        if fence_pat.match(line):
            in_code = not in_code
            continue
        if in_code:
            continue
        if open_pat.match(line):
            check_balance += 1
        elif close_pat.match(line):
            check_balance -= 1
            if check_balance < 0:
                raise SystemExit(f'{p}: persistió un cierre ::: sin apertura')

    if check_balance != 0:
        raise SystemExit(f'{p}: balance final de Divs = {check_balance}')

    p.write_text('\n'.join(repaired).rstrip() + '\n', encoding='utf-8')

    if removed or added:
        print(f'{p}: reparado; cierres sobrantes eliminados={removed}, cierres faltantes agregados={added}')
    else:
        print(f'{p}: Divs balanceados')
