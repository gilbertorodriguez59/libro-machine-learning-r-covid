@echo off
title Descargar y preparar COVID-19
cd /d "C:\libro-machine-learning-r-covid-dev"

echo.
echo DESCARGA Y PREPARACION DE DATOS COVID-19
echo.
echo Este proceso puede tardar varios minutos y descargar archivos grandes.
echo No cierre esta ventana.
echo.

where Rscript >nul 2>&1
if errorlevel 1 (
  echo ERROR: No se encontro Rscript en el PATH de Windows.
  echo Abra el archivo desde RStudio:
  echo scripts\covid19\descargar_y_preparar_covid19.R
  pause
  exit /b 1
)

Rscript "scripts\covid19\descargar_y_preparar_covid19.R"

if errorlevel 1 (
  echo.
  echo EL PROCESO TERMINO CON UN ERROR.
  echo Revise el mensaje mostrado arriba.
  pause
  exit /b 1
)

echo.
echo DATOS COVID-19 PREPARADOS CORRECTAMENTE.
echo.
pause
