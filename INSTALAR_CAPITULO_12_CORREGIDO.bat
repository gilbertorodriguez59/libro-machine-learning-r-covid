@echo off
title Instalar capítulo 12 corregido
cd /d "%~dp0"

set "DEST=C:\libro-machine-learning-r-dev"
set "SRC=%~dp011-redes-neuronales-corregido.qmd"

if not exist "%SRC%" (
  echo ERROR: No se encontro 11-redes-neuronales-corregido.qmd
  pause
  exit /b 1
)

if not exist "%DEST%\11-redes-neuronales.qmd" (
  echo ERROR: No se encontro el capitulo original en %DEST%
  pause
  exit /b 1
)

copy /Y "%DEST%\11-redes-neuronales.qmd" "%DEST%\11-redes-neuronales-respaldo-antes-correccion.qmd" >nul
copy /Y "%SRC%" "%DEST%\11-redes-neuronales.qmd" >nul

echo.
echo Capitulo 12 corregido e instalado.
echo Respaldo:
echo %DEST%\11-redes-neuronales-respaldo-antes-correccion.qmd
echo.
echo Ahora ejecute:
echo PUBLICAR_DIRECTAMENTE_V0131.bat
echo.
pause
