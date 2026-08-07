@echo off
set "PROY=C:\libro-machine-learning-r-dev"
set "BACK=C:\respaldo-capitulo-12-corregido"
if not exist "%PROY%\11-redes-neuronales.qmd" (
  echo ERROR: No se encontro 11-redes-neuronales.qmd
  pause
  exit /b 1
)
if not exist "%BACK%" mkdir "%BACK%"
copy /Y "%PROY%\11-redes-neuronales.qmd" "%BACK%\11-redes-neuronales.qmd" >nul
if errorlevel 1 (
  echo ERROR: No se pudo crear el respaldo.
  pause
  exit /b 1
)
echo Capitulo 12 respaldado correctamente en:
echo %BACK%
pause
