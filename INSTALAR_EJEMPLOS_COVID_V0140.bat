@echo off
title Instalar ejemplos COVID-19 v0.14.0
setlocal

set "ORIGEN=%~dp0"
set "DESTINO=C:\libro-machine-learning-r-covid-dev"

if not exist "%DESTINO%\_quarto.yml" (
  echo ERROR: No existe el proyecto COVID DEV.
  pause
  exit /b 1
)

if not exist "%DESTINO%\respaldo-v0140" mkdir "%DESTINO%\respaldo-v0140"

for %%F in (
  index.qmd
  _quarto.yml
  02-preparacion-datos.qmd
  03-analisis-exploratorio.qmd
  04-regresion-logistica.qmd
  08-evaluacion-modelos.qmd
) do (
  if exist "%DESTINO%\%%F" copy /Y "%DESTINO%\%%F" "%DESTINO%\respaldo-v0140\%%F" >nul
  copy /Y "%ORIGEN%%%F" "%DESTINO%\%%F" >nul
)

if not exist "%DESTINO%\datos\covid19\procesados" mkdir "%DESTINO%\datos\covid19\procesados"
if not exist "%DESTINO%\datos\covid19\diccionarios" mkdir "%DESTINO%\datos\covid19\diccionarios"

xcopy /E /I /Y "%ORIGEN%datos\covid19\*" "%DESTINO%\datos\covid19\" >nul

echo.
echo EJEMPLOS COVID-19 v0.14.0 INSTALADOS CORRECTAMENTE.
echo.
echo Respaldo:
echo %DESTINO%\respaldo-v0140
echo.
echo Ahora genere primero la version web para revisar:
echo quarto render --to html
echo.
pause
