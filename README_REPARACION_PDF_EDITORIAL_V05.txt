REPARACION PDF EDITORIAL V0.5
============================

Este paquete corrige los problemas observados en el PDF:

1. El índice no debe mostrar un capítulo adicional llamado "Aprendizaje y Clasificación Automática con R".
2. Los capítulos deben numerarse correctamente.
3. El PDF debe verse más editorial y menos como una impresión del código.
4. Las gráficas se fuerzan a PNG para mejorar la estabilidad al generar PDF.
5. Se agrega un perfil PDF que oculta código en el PDF, pero mantiene resultados y gráficas.

ARCHIVOS INCLUIDOS
------------------
- _quarto.yml
- _quarto-pdf.yml
- index.qmd
- 00-licencia-y-citacion.qmd
- render_pdf_editorial.bat

INSTALACION
-----------
Copia estos archivos en:
C:\libro-machine-learning-r

Reemplaza los archivos existentes cuando Windows pregunte.

GENERAR HTML
------------
quarto render --to html
type nul > docs\.nojekyll

GENERAR PDF EDITORIAL
---------------------
quarto render --profile pdf --to pdf

FLUJO SEGURO WEB + PDF
----------------------
render_pdf_editorial.bat

SUBIR A GITHUB
--------------
git add .
git commit -m "Corrige PDF editorial e indice"
git push

NOTA
----
Para el PDF profesional se oculta el código con el perfil pdf.
La versión web conserva el código plegable y el estilo visual.
