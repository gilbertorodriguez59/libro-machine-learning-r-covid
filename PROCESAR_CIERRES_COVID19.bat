@echo off
title Procesar cierres COVID-19
cd /d "C:\libro-machine-learning-r-covid-dev"

where Rscript >nul 2>&1
if errorlevel 1 (
  echo ERROR: No se encontro Rscript.
  echo Abra en RStudio:
  echo scripts\covid19\procesar_cierres_covid19.R
  pause
  exit /b 1
)

Rscript "scripts\covid19\procesar_cierres_covid19.R"

if errorlevel 1 (
  echo.
  echo EL PROCESO TERMINO CON UN ERROR.
  pause
  exit /b 1
)

echo.
echo DATOS PROCESADOS CORRECTAMENTE.
pause
