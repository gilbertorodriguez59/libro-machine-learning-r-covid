@echo off
setlocal
cd /d "%~dp0"

echo Generando PDF profesional con codigo visible...
quarto render --profile pdf --to pdf
if errorlevel 1 goto :error

if not exist pdf_temp mkdir pdf_temp
copy /Y docs\*.pdf pdf_temp\ >nul

echo Restaurando la version HTML...
quarto render --to html
if errorlevel 1 goto :error

type nul > docs\.nojekyll
copy /Y pdf_temp\*.pdf docs\ >nul

echo.
echo PDF profesional y sitio HTML generados correctamente.
goto :end

:error
echo.
echo Ocurrio un error durante el renderizado. Revise el mensaje anterior.
exit /b 1

:end
endlocal
