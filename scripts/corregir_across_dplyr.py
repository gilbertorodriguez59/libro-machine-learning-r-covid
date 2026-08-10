from pathlib import Path

p = Path('08-evaluacion-modelos.qmd')
text = p.read_text(encoding='utf-8')

old = '''resumen_cv <- resultados_cv |>
  summarise(
    across(
      where(is.numeric) & !matches("pliegue"),
      list(media = mean, desviacion = sd),
      na.rm = TRUE
    )
  )
'''

new = '''resumen_cv <- resultados_cv |>
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

if old in text:
    text = text.replace(old, new, 1)
    p.write_text(text, encoding='utf-8')
    print('Sintaxis across() actualizada para dplyr >= 1.1.0')
elif new in text:
    print('La sintaxis across() ya está actualizada')
else:
    raise SystemExit('No se encontró el bloque esperado de resumen_cv')
