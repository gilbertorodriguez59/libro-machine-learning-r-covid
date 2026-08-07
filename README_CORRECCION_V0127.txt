VERSIÓN 0.12.7 — COMPATIBILIDAD MATEMÁTICA

Problema corregido:
- Las expresiones en línea escritas como \(...\) llegaban a LaTeX como texto ordinario.
- Por ejemplo, \(\widehat{y}\) se convertía en (\widehat{y}) y producía Missing $ inserted.

Solución:
- Todas las expresiones matemáticas en línea del capítulo 12 se convirtieron a $...$.
- Las fórmulas de bloque permanecen en $$...$$.
- Se revisaron los delimitadores fuera de bloques de código.

Pasos:
1. Copiar sobre C:\libro-machine-learning-r-dev sin borrar .git.
2. Ejecutar PROBAR_CAPITULO_12_Y_PUBLICAR.bat.
