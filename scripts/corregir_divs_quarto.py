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
    min_balance = 0
    for line in lines:
        if fence_pat.match(line):
            in_code = not in_code
            continue
        if in_code:
            continue
        if open_pat.match(line):
            balance += 1
        elif close_pat.match(line):
            balance -= 1
            min_balance = min(min_balance, balance)

    if min_balance < 0:
        raise SystemExit(f'{p}: hay cierres ::: sin apertura correspondiente')

    if balance > 0:
        with p.open('a', encoding='utf-8', newline='\n') as f:
            f.write('\n')
            for _ in range(balance):
                f.write(':::\n')
        print(f'{p}: agregados {balance} cierres ::: al final del archivo')
    else:
        print(f'{p}: Divs balanceados')
