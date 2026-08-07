VERSIÓN 0.12.4 — AUDITORÍA MATEMÁTICA DEL CAPÍTULO 12

Problema corregido:
- La expresión sigmoide quedó fuera del modo matemático durante la conversión
  a LaTeX y produjo "Missing $ inserted".

Cambios:
- Se revisaron todas las expresiones matemáticas del capítulo 12.
- Se normalizaron las fórmulas de bloque a delimitadores $$ ... $$.
- Se repararon expresiones con comandos como \sigma, \frac, \partial,
  \sum, \lambda y \eta.
- Se conserva la corrección de neuralnet.
- Se conserva el laboratorio Shinylive.

Publicación recomendada:
1. Copie esta versión sobre C:\libro-machine-learning-r-dev sin borrar .git.
2. Ejecute PROBAR_CAPITULO_12_Y_PUBLICAR.bat.
3. El archivo probará primero solamente el capítulo 12.
4. Si esa prueba funciona, continuará con la publicación completa.
