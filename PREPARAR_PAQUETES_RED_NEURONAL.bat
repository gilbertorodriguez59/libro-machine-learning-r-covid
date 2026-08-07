@echo off
title Preparar paquetes para Redes Neuronales
cd /d "%~dp0"

echo.
echo Instalando o verificando neuralnet...
echo.

Rscript PREPARAR_PAQUETES_RED_NEURONAL.R

if errorlevel 1 (
  echo.
  echo ERROR: No se pudo instalar neuralnet.
  pause
  exit /b 1
)

echo.
echo Preparacion terminada correctamente.
pause
