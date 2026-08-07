@echo off
chcp 65001 >nul
title Render revisión editorial v0.14.1
cd /d "C:\libro-machine-learning-r-covid-dev"

echo.
echo ============================================================
echo RENDER COMPLETO - REVISION EDITORIAL v0.14.1
echo ============================================================
echo.

if exist ".quarto" rmdir /s /q ".quarto"
if exist "_freeze" rmdir /s /q "_freeze"
if exist "docs" rmdir /s /q "docs"

quarto render --no-cache

if errorlevel 1 (
  echo.
  echo ERROR DURANTE EL RENDER.
  pause
  exit /b 1
)

echo.
echo RENDER TERMINADO CORRECTAMENTE.
echo.
if exist "docs\index.html" start "" "docs\index.html"
start "" "docs"
echo.
echo Revise:
echo - nombre del autor sin MI
echo - páginas iniciales
echo - conexiones con el volumen teórico
echo - glosario y referencias
echo - índice de figuras
echo - índice temático
echo - acerca del autor
echo.
pause
