@echo off
cd /d C:\libro-machine-learning-r
if not exist pdf_build mkdir pdf_build
quarto render --to pdf --no-execute --output-dir pdf_build
echo PDF preliminar generado en pdf_build. Copia el PDF a docs si deseas publicarlo.
