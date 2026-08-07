@echo off
setlocal
set "ORIGEN=%~dp0"
set "DESTINO=C:\libro-machine-learning-r-covid-dev"

if not exist "%DESTINO%\scripts\covid19" (
  echo ERROR: No existe la carpeta COVID DEV.
  pause
  exit /b 1
)

copy /Y "%ORIGEN%scripts\covid19\procesar_cierres_covid19.R" "%DESTINO%\scripts\covid19\procesar_cierres_covid19.R" >nul

echo.
echo PROCESADOR 2020-2025 INSTALADO CORRECTAMENTE.
echo.
echo Ahora ejecute:
echo C:\libro-machine-learning-r-covid-dev\PROCESAR_CIERRES_COVID19.bat
echo.
pause
