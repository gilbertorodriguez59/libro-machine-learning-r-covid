@echo off
title Instalar correccion Shinylive COVID v0.14.0.2
setlocal

set "ORIGEN=%~dp0"
set "DESTINO=C:\libro-machine-learning-r-covid-dev"

if not exist "%DESTINO%\_quarto.yml" (
  echo ERROR: No se encontro el proyecto COVID DEV.
  pause
  exit /b 1
)

if not exist "%DESTINO%\respaldo-v01402" mkdir "%DESTINO%\respaldo-v01402"

if exist "%DESTINO%\_metadata.yml" (
  copy /Y "%DESTINO%\_metadata.yml" "%DESTINO%\respaldo-v01402\_metadata.yml" >nul
)

copy /Y "%ORIGEN%_metadata.yml" "%DESTINO%\_metadata.yml" >nul
copy /Y "%ORIGEN%RENDERIZAR_COVID_CON_SHINYLIVE.bat" "%DESTINO%\RENDERIZAR_COVID_CON_SHINYLIVE.bat" >nul

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p='%DESTINO%\_quarto.yml';" ^
  "$t=[IO.File]::ReadAllText($p,[Text.Encoding]::UTF8);" ^
  "$t=$t -replace 'embed-resources:\s*true','embed-resources: false';" ^
  "if($t -notmatch 'embed-resources:\s*false'){" ^
  "$t=$t -replace 'html:\s*\r?\n','html:`r`n    embed-resources: false`r`n'};" ^
  "[IO.File]::WriteAllText($p,$t,(New-Object Text.UTF8Encoding($false)))"

echo.
echo CORRECCION SHINYLIVE INSTALADA CORRECTAMENTE.
echo.
echo Ahora ejecute:
echo RENDERIZAR_COVID_CON_SHINYLIVE.bat
echo.
pause
