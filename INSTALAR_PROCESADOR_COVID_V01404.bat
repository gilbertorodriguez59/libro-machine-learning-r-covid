@echo off
title Instalar procesador COVID v0.14.0.4
setlocal
set "ORIGEN=%~dp0"
set "DESTINO=C:\libro-machine-learning-r-covid-dev"

if not exist "%DESTINO%\scripts\covid19" (
  echo ERROR: No existe la estructura COVID DEV.
  pause
  exit /b 1
)

if exist "%DESTINO%\scripts\covid19\procesar_cierres_covid19.R" (
  copy /Y "%DESTINO%\scripts\covid19\procesar_cierres_covid19.R" "%DESTINO%\scripts\covid19\procesar_cierres_covid19-respaldo-v01403.R" >nul
)

copy /Y "%ORIGEN%scripts\covid19\procesar_cierres_covid19.R" "%DESTINO%\scripts\covid19\procesar_cierres_covid19.R" >nul

echo.
echo PROCESADOR v0.14.0.4 INSTALADO CORRECTAMENTE.
echo.
echo Ahora ejecute:
echo C:\libro-machine-learning-r-covid-dev\PROCESAR_CIERRES_COVID19.bat
echo.
pause
