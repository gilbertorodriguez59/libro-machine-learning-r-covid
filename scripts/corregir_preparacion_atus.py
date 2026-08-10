from pathlib import Path

# -----------------------------------------------------------------------------
# 1. Preparación robusta de ATUS
# -----------------------------------------------------------------------------
p = Path('02-preparacion-datos.qmd')
text = p.read_text(encoding='utf-8')

old_localizar = r'''archivos_atus <- list.files(
  path = "datos",
  pattern = "^atus.*\\.csv$",
  full.names = TRUE,
  ignore.case = TRUE
)

archivos_atus'''

new_localizar = r'''archivos_atus <- list.files(
  path = "datos",
  pattern = "^atus.*\\.csv$",
  full.names = TRUE,
  ignore.case = TRUE
)

# Preferir una base ATUS cruda cuando esté disponible.
# La base *_ml_preparado.csv es una salida de este mismo capítulo y
# no contiene necesariamente CLASACC.
archivos_crudos <- archivos_atus[
  !grepl("ml_preparado", basename(archivos_atus), ignore.case = TRUE)
]

archivos_atus'''

old_ruta = r'''ruta_atus <- archivos_atus[1]

atus <- read_csv('''
new_ruta = r'''ruta_atus <- if (length(archivos_crudos) > 0) {
  archivos_crudos[1]
} else {
  archivos_atus[1]
}

atus <- read_csv('''

old_respuesta = r'''atus_modelo <- atus_base |>
  mutate(
    CLASACC_TXT = str_to_lower(as.character(CLASACC)),
    accidente_con_victimas = case_when(
      str_detect(CLASACC_TXT, "sólo daños") ~ "Solo daños",
      str_detect(CLASACC_TXT, "solo daños") ~ "Solo daños",
      str_detect(CLASACC_TXT, "daños") ~ "Solo daños",
      str_detect(CLASACC_TXT, "no fatal") ~ "Con víctimas",
      str_detect(CLASACC_TXT, "fatal") ~ "Con víctimas",
      TRUE ~ NA_character_
    )
  ) |>
  filter(!is.na(accidente_con_victimas))

table(atus_modelo$accidente_con_victimas)'''

new_respuesta = r'''if ("CLASACC" %in% names(atus_base)) {

  # Ruta A: base ATUS cruda del INEGI.
  atus_modelo <- atus_base |>
    mutate(
      CLASACC_TXT = str_to_lower(as.character(CLASACC)),
      accidente_con_victimas = case_when(
        str_detect(CLASACC_TXT, "sólo daños") ~ "Solo daños",
        str_detect(CLASACC_TXT, "solo daños") ~ "Solo daños",
        str_detect(CLASACC_TXT, "daños") ~ "Solo daños",
        str_detect(CLASACC_TXT, "no fatal") ~ "Con víctimas",
        str_detect(CLASACC_TXT, "fatal") ~ "Con víctimas",
        TRUE ~ NA_character_
      )
    ) |>
    filter(!is.na(accidente_con_victimas))

} else if ("ACCIDENTE_CON_VICTIMAS" %in% names(atus)) {

  # Ruta B: base ya preparada incluida con el libro.
  # Después de normalizar nombres, accidente_con_victimas aparece en mayúsculas.
  atus_modelo <- atus |>
    transmute(
      MES,
      ID_HORA,
      DIASEMANA,
      TIPACCID,
      CAUSAACCI,
      accidente_con_victimas = as.character(ACCIDENTE_CON_VICTIMAS)
    ) |>
    mutate(
      accidente_con_victimas = case_when(
        str_to_lower(accidente_con_victimas) %in% c(
          "con víctimas", "con victimas"
        ) ~ "Con víctimas",
        str_to_lower(accidente_con_victimas) %in% c(
          "solo daños", "sólo daños"
        ) ~ "Solo daños",
        TRUE ~ NA_character_
      )
    ) |>
    filter(!is.na(accidente_con_victimas))

  message(
    "Se utilizó datos/atus_ml_preparado.csv como respaldo para el render. ",
    "Para reproducir desde cero la preparación, use la base ATUS cruda del INEGI."
  )

} else {
  stop(
    paste(
      "No se encontró CLASACC ni ACCIDENTE_CON_VICTIMAS.",
      "Revise el diccionario y la versión de la base ATUS."
    )
  )
}

table(atus_modelo$accidente_con_victimas)'''

for old, new, label in [
    (old_localizar, new_localizar, 'localización'),
    (old_ruta, new_ruta, 'selección de archivo'),
    (old_respuesta, new_respuesta, 'variable respuesta'),
]:
    if old in text:
        text = text.replace(old, new, 1)
        print('Corregido:', label)
    elif new in text:
        print('Ya corregido:', label)
    else:
        raise SystemExit(f'No se encontró bloque esperado: {label}')

p.write_text(text, encoding='utf-8')
print('02-preparacion-datos.qmd actualizado')

# -----------------------------------------------------------------------------
# 2. Sintaxis moderna de dplyr::across() detectada durante la prueba de Colab
# -----------------------------------------------------------------------------
p_eval = Path('08-evaluacion-modelos.qmd')
text_eval = p_eval.read_text(encoding='utf-8')

old_across = '''resumen_cv <- resultados_cv |>
  summarise(
    across(
      where(is.numeric) & !matches("pliegue"),
      list(media = mean, desviacion = sd),
      na.rm = TRUE
    )
  )
'''

new_across = '''resumen_cv <- resultados_cv |>
  summarise(
    across(
      where(is.numeric) & !matches("pliegue"),
      list(
        media = ~ mean(.x, na.rm = TRUE),
        desviacion = ~ sd(.x, na.rm = TRUE)
      )
    )
  )
'''

if old_across in text_eval:
    text_eval = text_eval.replace(old_across, new_across, 1)
    print('Corregido: sintaxis across() para dplyr >= 1.1.0')
elif new_across in text_eval:
    print('Ya corregido: sintaxis across()')
else:
    raise SystemExit('No se encontró el bloque esperado de resumen_cv en 08-evaluacion-modelos.qmd')

p_eval.write_text(text_eval, encoding='utf-8')
print('08-evaluacion-modelos.qmd actualizado')
