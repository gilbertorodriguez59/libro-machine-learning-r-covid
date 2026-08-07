@echo off
title Publicar libro interactivo v0.13.1
cd /d "C:\libro-machine-learning-r-dev"

echo.
echo PUBLICACION COMPLETA DEL LIBRO
echo.
echo Se generara el PDF y despues el sitio HTML con Shinylive.
echo El proceso puede tardar varios minutos.
echo.

call PREPARAR_SHINYLIVE_Y_PUBLICAR_V0121.bat

if errorlevel 1 (
  echo.
  echo ERROR: La publicacion termino con un problema.
  pause
  exit /b 1
)

echo.
echo PUBLICACION TERMINADA CORRECTAMENTE.
pause
