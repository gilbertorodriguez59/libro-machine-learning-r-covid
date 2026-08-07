VERSIÓN 0.12.3 — CORRECCIÓN LATEX

Problema corregido:
- La fórmula z=w_1x_1+w_2x_2+...+w_px_p+b apareció como texto normal.
- LaTeX interpreta los guiones bajos únicamente dentro del modo matemático.
- Esto produjo el error "Missing $ inserted".

Solución:
- La fórmula quedó encerrada correctamente en modo matemático.
- Se revisaron las fórmulas simples del capítulo 12.
- Se conserva la corrección anterior de neuralnet.
- Se conserva el laboratorio interactivo Shinylive.

Pasos:
1. Copie esta versión sobre C:\libro-machine-learning-r-dev sin borrar .git.
2. No es necesario volver a instalar neuralnet si ya lo hizo.
3. Ejecute PREPARAR_SHINYLIVE_Y_PUBLICAR_V0121.bat.
