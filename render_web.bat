@echo off
setlocal
cd /d "%~dp0"
quarto render --to html
if errorlevel 1 exit /b 1
type nul > docs\.nojekyll
echo Sitio web generado correctamente.
endlocal
