VERSIÓN 0.9.1 — CORRECCIÓN DEL CAPÍTULO DE REGRESIÓN LINEAL

- Se eliminaron las llamadas a cargar_paquete() del archivo Quarto.
- Se sustituyeron por library(ggplot2), library(readr) y library(dplyr).
- Se agregó source("util_graficas.R") antes de utilizar tema_libro().
- El cuaderno Google Colab conserva cargar_paquete(), porque ahí sí está definida.
