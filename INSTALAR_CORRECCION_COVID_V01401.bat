@echo off
title Corregir descargador COVID-19 v0.14.0.1
setlocal

set "ORIGEN=%~dp0"
set "DESTINO=C:\libro-machine-learning-r-covid-dev"

if not exist "%DESTINO%\scripts\covid19" (
  echo ERROR: No existe la estructura COVID DEV.
  pause
  exit /b 1
)

if exist "%DESTINO%\scripts\covid19\descargar_y_preparar_covid19.R" (
  copy /Y "%DESTINO%\scripts\covid19\descargar_y_preparar_covid19.R" "%DESTINO%\scripts\covid19\descargar_y_preparar_covid19-respaldo.R" >nul
)

copy /Y "%ORIGEN%scripts\covid19\descargar_y_preparar_covid19.R" "%DESTINO%\scripts\covid19\descargar_y_preparar_covid19.R" >nul

echo.
echo CORRECCION INSTALADA CORRECTAMENTE.
echo.
echo Ahora ejecute nuevamente:
echo C:\libro-machine-learning-r-covid-dev\EJECUTAR_DESCARGA_COVID19.bat
echo.
pause
