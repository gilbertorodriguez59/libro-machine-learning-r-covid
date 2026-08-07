@echo off
cd /d C:\libro-machine-learning-r
if not exist pdf_build mkdir pdf_build
quarto render --to pdf --output-dir pdf_build
echo PDF generado en pdf_build.
