@echo off
set "PROY=C:\libro-machine-learning-r-dev"
set "BACK=C:\respaldo-capitulo-12-corregido\11-redes-neuronales.qmd"
if not exist "%BACK%" (
  echo ERROR: No existe el respaldo del capitulo 12.
  pause
  exit /b 1
)
copy /Y "%BACK%" "%PROY%\11-redes-neuronales.qmd" >nul
if errorlevel 1 (
  echo ERROR: No se pudo restaurar el capitulo 12.
  pause
  exit /b 1
)
echo Capitulo 12 corregido restaurado correctamente.
pause
