VERSIÓN 0.12.2 — CORRECCIÓN DE RENDERIZADO

Problema corregido:
- El capítulo intentaba instalar neuralnet durante la generación del PDF.
- R no tenía configurado un espejo de CRAN.

Solución:
- Ya no se instalan paquetes durante el renderizado.
- Los bloques dependientes de neuralnet se muestran, pero no se ejecutan
  automáticamente al generar HTML o PDF.
- Se agregó PREPARAR_PAQUETES_RED_NEURONAL.bat para instalar neuralnet una sola vez.

Pasos:
1. Copie esta versión sobre C:\libro-machine-learning-r-dev sin borrar .git.
2. Ejecute PREPARAR_PAQUETES_RED_NEURONAL.bat una sola vez.
3. Ejecute PREPARAR_SHINYLIVE_Y_PUBLICAR_V0121.bat.
