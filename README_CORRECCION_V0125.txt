VERSIÓN 0.12.5 — DELIMITADORES MATEMÁTICOS CORREGIDOS

Causa exacta del error:
- La fórmula de combinación lineal quedó dentro de un bloque $$ ... $$ y,
  además, conservó signos $ internos.
- LaTeX recibió una fórmula anidada y mostró "Display math should end with $$".

Corrección:
- Se eliminó el par de signos $ internos.
- Se auditaron todos los bloques matemáticos del capítulo 12.
- No quedan dólares simples dentro de bloques $$ ... $$.
- Se conservan Shinylive y la corrección de neuralnet.

Pasos:
1. Copie esta versión sobre C:\libro-machine-learning-r-dev sin borrar .git.
2. Ejecute PROBAR_CAPITULO_12_Y_PUBLICAR.bat.
