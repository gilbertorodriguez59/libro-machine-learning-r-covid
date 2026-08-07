@echo off
title Reparar y renderizar Shinylive COVID
setlocal
cd /d "C:\libro-machine-learning-r-covid-dev"

echo.
echo ============================================================
echo REPARACION INTEGRAL DE SHINYLIVE - LIBRO COVID
echo ============================================================
echo.

if not exist "_quarto.yml" (
  echo ERROR: No se encontro el proyecto COVID DEV.
  pause
  exit /b 1
)

if not exist "respaldo-shinylive-integral" mkdir "respaldo-shinylive-integral"

copy /Y "_quarto.yml" "respaldo-shinylive-integral\_quarto.yml" >nul
if exist "_metadata.yml" copy /Y "_metadata.yml" "respaldo-shinylive-integral\_metadata.yml" >nul

copy /Y "%~dp0_quarto.yml" "_quarto.yml" >nul
copy /Y "%~dp0PREPARAR_SHINYLIVE_COVID.R" "PREPARAR_SHINYLIVE_COVID.R" >nul

if exist "_metadata.yml" del /Q "_metadata.yml"

echo 1. Limpiando resultados y cache anteriores...
if exist ".quarto" rmdir /S /Q ".quarto"
if exist "docs" rmdir /S /Q "docs"

where Rscript >nul 2>&1
if errorlevel 1 (
  echo ERROR: No se encontro Rscript.
  pause
  exit /b 1
)

where quarto >nul 2>&1
if errorlevel 1 (
  echo ERROR: No se encontro Quarto.
  pause
  exit /b 1
)

echo.
echo 2. Verificando el paquete R shinylive...
Rscript "PREPARAR_SHINYLIVE_COVID.R"
if errorlevel 1 (
  echo ERROR: No se pudo preparar el paquete shinylive.
  pause
  exit /b 1
)

echo.
echo 3. Instalando o actualizando la extension Quarto Shinylive...
quarto add --no-prompt quarto-ext/shinylive
if errorlevel 1 (
  echo ERROR: No se pudo instalar la extension Shinylive.
  pause
  exit /b 1
)

if not exist "_extensions\quarto-ext\shinylive" (
  echo ERROR: La extension no quedo instalada en _extensions.
  pause
  exit /b 1
)

echo.
echo 4. Verificando configuracion...
findstr /C:"embed-resources: false" "_quarto.yml" >nul
if errorlevel 1 (
  echo ERROR: La configuracion no contiene embed-resources: false.
  pause
  exit /b 1
)

echo.
echo 5. Renderizando el libro completo...
echo IMPORTANTE: se usa "quarto render" sin "--to html".
quarto render
if errorlevel 1 (
  echo.
  echo ERROR DURANTE EL RENDERIZADO.
  pause
  exit /b 1
)

if not exist "docs\04-regresion-logistica.html" (
  echo ERROR: No se genero el capitulo de regresion logistica.
  pause
  exit /b 1
)

echo.
echo ============================================================
echo LIBRO GENERADO CORRECTAMENTE CON SHINYLIVE
echo ============================================================
echo.
echo Abra:
echo C:\libro-machine-learning-r-covid-dev\docs\04-regresion-logistica.html
echo.
echo Si el navegador conserva la pagina anterior, presione:
echo Ctrl + F5
echo.
pause
