@echo off
chcp 65001 >nul
title Instalar actualización editorial v0.14.1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALAR_ACTUALIZACION_EDITORIAL_V0141.ps1"
