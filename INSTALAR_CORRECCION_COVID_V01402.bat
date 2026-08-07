@echo off
title Instalar correccion COVID v0.14.0.2
setlocal

set "ORIGEN=%~dp0"
set "DESTINO=C:\libro-machine-learning-r-covid-dev"

if not exist "%DESTINO%" (
  echo ERROR: No existe %DESTINO%
  pause
  exit /b 1
)

if not exist "%DESTINO%\scripts\covid19" mkdir "%DESTINO%\scripts\covid19"

copy /Y "%ORIGEN%scripts\covid19\procesar_cierres_covid19.R" "%DESTINO%\scripts\covid19\procesar_cierres_covid19.R" >nul
copy /Y "%ORIGEN%ABRIR_DESCARGAS_OFICIALES_COVID19.bat" "%DESTINO%\ABRIR_DESCARGAS_OFICIALES_COVID19.bat" >nul
copy /Y "%ORIGEN%PROCESAR_CIERRES_COVID19.bat" "%DESTINO%\PROCESAR_CIERRES_COVID19.bat" >nul
copy /Y "%ORIGEN%LEEME_CORRECCION_V01402.txt" "%DESTINO%\LEEME_CORRECCION_V01402.txt" >nul

echo.
echo CORRECCION v0.14.0.2 INSTALADA.
echo.
echo Primero ejecute:
echo ABRIR_DESCARGAS_OFICIALES_COVID19.bat
echo.
pause
