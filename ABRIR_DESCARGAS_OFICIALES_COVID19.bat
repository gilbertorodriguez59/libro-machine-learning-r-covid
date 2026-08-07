@echo off
title Descargar cierres COVID-19 oficiales

set "CARPETA=C:\libro-machine-learning-r-covid-dev\datos\covid19\originales"
if not exist "%CARPETA%" mkdir "%CARPETA%"

start "" "https://www.gob.mx/salud/documentos/datos-abiertos-bases-historicas-direccion-general-de-epidemiologia"
start "" explorer "%CARPETA%"

echo.
echo Se abrieron:
echo 1. La pagina oficial de bases historicas.
echo 2. La carpeta donde debe guardar los archivos.
echo.
echo Descargue:
echo - Cierre Datos Abiertos Historicos 2020
echo - Cierre Datos Abiertos Historicos 2021
echo - Cierre Datos Abiertos Historicos 2022
echo.
echo Guarde o cambie sus nombres para que incluyan el anio:
echo COVID19_2020.zip
echo COVID19_2021.zip
echo COVID19_2022.zip
echo.
pause
