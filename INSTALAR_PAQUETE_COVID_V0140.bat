@echo off
title Instalar paquete COVID v0.14.0
setlocal

set "ORIGEN=%~dp0"
set "DESTINO=C:\libro-machine-learning-r-covid-dev"

if not exist "%DESTINO%" (
  echo ERROR: No existe la carpeta:
  echo %DESTINO%
  pause
  exit /b 1
)

if not exist "%DESTINO%\scripts\covid19" mkdir "%DESTINO%\scripts\covid19"
if not exist "%DESTINO%\datos\covid19\originales" mkdir "%DESTINO%\datos\covid19\originales"
if not exist "%DESTINO%\datos\covid19\procesados" mkdir "%DESTINO%\datos\covid19\procesados"
if not exist "%DESTINO%\datos\covid19\muestras" mkdir "%DESTINO%\datos\covid19\muestras"
if not exist "%DESTINO%\datos\covid19\diccionarios" mkdir "%DESTINO%\datos\covid19\diccionarios"

copy /Y "%ORIGEN%scripts\covid19\descargar_y_preparar_covid19.R" "%DESTINO%\scripts\covid19\descargar_y_preparar_covid19.R" >nul
copy /Y "%ORIGEN%EJECUTAR_DESCARGA_COVID19.bat" "%DESTINO%\EJECUTAR_DESCARGA_COVID19.bat" >nul
copy /Y "%ORIGEN%LEEME_PAQUETE_COVID_V0140.txt" "%DESTINO%\LEEME_PAQUETE_COVID_V0140.txt" >nul

echo.
echo PAQUETE COVID v0.14.0 INSTALADO.
echo.
echo Ahora ejecute:
echo C:\libro-machine-learning-r-covid-dev\EJECUTAR_DESCARGA_COVID19.bat
echo.
pause
