PAQUETE COMPLETO V0.6
Libro: Aprendizaje y Clasificación Automática con R
Autor: MI Jesús Gilberto Rodríguez Escobedo

Cambios principales:
1. Mantiene código visible en PDF.
2. Mejora el estilo del código con letra más pequeña, líneas partidas y marco en PDF.
3. Restaura explicaciones breves del código y de los resultados.
4. Conserva gráficas profesionales con paleta azul, turquesa, coral, morado y ámbar.
5. Mantiene índice correcto: Presentación y Licencia sin numeración; capítulos 1 a 7 numerados.
6. Incluye util_graficas.R, styles.css, _quarto.yml, capítulos 1 a 7 y scripts de render.

Instrucciones:
1. Copiar todos los archivos dentro de C:\libro-machine-learning-r
2. No borrar la carpeta .git si ya existe.
3. Conservar localmente la carpeta datos con atus_2024.csv, pero no subirla a GitHub.
4. Instalar ranger en R si no está instalado:
   install.packages("ranger")

Generar HTML:
   quarto render --to html
   type nul > docs\.nojekyll

Generar PDF con flujo seguro:
   quarto render --to pdf
   mkdir pdf_temp
   copy docs\*.pdf pdf_temp\
   quarto render --to html
   type nul > docs\.nojekyll
   copy pdf_temp\*.pdf docs\

Subir a GitHub:
   git add .
   git commit -m "Actualiza libro version 0.6 con PDF y codigo profesional"
   git push
