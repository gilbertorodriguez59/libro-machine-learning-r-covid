@echo off
title Corregir evaluacion COVID v0.14.0.1
setlocal
set "ORIGEN=%~dp0"
set "DESTINO=C:\libro-machine-learning-r-covid-dev"
if not exist "%DESTINO%\08-evaluacion-modelos.qmd" (
  echo ERROR: No se encontro el capitulo 9.
  pause
  exit /b 1
)
if not exist "%DESTINO%\respaldo-v01401" mkdir "%DESTINO%\respaldo-v01401"
copy /Y "%DESTINO%\08-evaluacion-modelos.qmd" "%DESTINO%\respaldo-v01401\08-evaluacion-modelos.qmd" >nul
copy /Y "%ORIGEN%08-evaluacion-modelos.qmd" "%DESTINO%\08-evaluacion-modelos.qmd" >nul
echo.
echo CORRECCION INSTALADA CORRECTAMENTE.
echo.
echo Ahora ejecute: quarto render --to html
echo.
pause
