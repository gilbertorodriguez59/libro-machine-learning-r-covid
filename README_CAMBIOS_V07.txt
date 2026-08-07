APRENDIZAJE Y CLASIFICACION AUTOMATICA CON R
VERSION 0.7 - DESARROLLO

CAMBIOS PRINCIPALES
1. Nuevo capitulo 8: Evaluacion, validacion y comparacion de modelos.
2. Instrucciones paso a paso para descargar ATUS desde el INEGI.
3. Referencia bibliografica y reconocimiento de fuente conforme a los terminos de libre uso del INEGI.
4. Nuevo archivo referencias.bib y apendice de referencias.
5. PDF profesional con codigo visible, fuente monoespaciada, fondo, borde y salto de lineas.
6. Tipografias DejaVu Serif/Sans para texto y DejaVu Sans Mono para codigo.
7. Margenes, encabezados, pies, titulos, tablas y leyendas mejorados.
8. El perfil PDF ya no oculta el codigo.

ARCHIVOS NUEVOS
- 08-evaluacion-modelos.qmd
- referencias.bib
- referencias.qmd
- latex/configuracion-pdf.tex

ARCHIVOS MODIFICADOS
- _quarto.yml
- _quarto-pdf.yml
- index.qmd
- 02-preparacion-datos.qmd
- render_pdf_editorial.bat
- render_web.bat

COMO GENERAR TODO
1. Abra la carpeta del proyecto en RStudio.
2. Ejecute render_pdf_editorial.bat.
3. El proceso genera primero el PDF, despues restaura el HTML y copia el PDF a docs.

COMANDOS EQUIVALENTES
quarto render --profile pdf --to pdf
quarto render --to html

NOTA
Trabaje y pruebe esta version en C:\libro-machine-learning-r-dev.
No copie a la version estable hasta revisar HTML y PDF.
