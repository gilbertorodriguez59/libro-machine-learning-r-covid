@echo off
title Renderizar libro COVID con Shinylive
cd /d "C:\libro-machine-learning-r-covid-dev"

echo.
echo GENERANDO LIBRO COVID CON SHINYLIVE
echo.

quarto render --to html -M embed-resources:false

if errorlevel 1 (
  echo.
  echo ERROR AL GENERAR EL LIBRO.
  pause
  exit /b 1
)

echo.
echo LIBRO HTML GENERADO CORRECTAMENTE.
echo.
echo Abra:
echo C:\libro-machine-learning-r-covid-dev\docs\index.html
echo.
pause
