@echo off
cd /d C:\libro-machine-learning-r
quarto render --to pdf
if not exist pdf_temp mkdir pdf_temp
copy docs\*.pdf pdf_temp\
quarto render --to html
type nul > docs\.nojekyll
copy pdf_temp\*.pdf docs\
echo PDF y web generados con flujo seguro.
