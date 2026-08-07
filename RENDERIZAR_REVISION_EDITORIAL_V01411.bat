@echo off
cd /d "C:\libro-machine-learning-r-covid-dev"

echo.
echo RENDER COMPLETO - REVISION EDITORIAL v0.14.1.1
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
pause
