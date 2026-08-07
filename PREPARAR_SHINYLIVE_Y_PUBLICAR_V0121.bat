@echo off
setlocal
cd /d "%~dp0"

echo ============================================================
echo  PREPARAR SHINYLIVE Y PUBLICAR VERSION DE DESARROLLO 0.12.1
echo ============================================================
echo.

where Rscript >nul 2>nul
if errorlevel 1 (
  echo ERROR: No se encontro Rscript en el PATH.
  echo Abra RStudio y ejecute instalar_shinylive_v0121.R,
  echo o agregue la carpeta bin de R al PATH de Windows.
  pause
  exit /b 1
)

where quarto >nul 2>nul
if errorlevel 1 (
  echo ERROR: No se encontro Quarto en el PATH.
  pause
  exit /b 1
)

echo 1. Instalando o verificando el paquete shinylive...
Rscript instalar_shinylive_v0121.R
if errorlevel 1 (
  echo ERROR: No se pudo instalar o verificar shinylive.
  pause
  exit /b 1
)

echo.
echo 2. Instalando o actualizando la extension Shinylive de Quarto...
quarto add --no-prompt quarto-ext/shinylive
if errorlevel 1 (
  echo ERROR: No se pudo instalar la extension de Quarto.
  pause
  exit /b 1
)

if not exist "_extensions\quarto-ext\shinylive" (
  echo ERROR: La extension no quedo instalada en _extensions.
  pause
  exit /b 1
)

echo.
echo 3. Publicando la version de desarrollo...
call ejecutar_publicacion_desarrollo_v099.bat

endlocal
