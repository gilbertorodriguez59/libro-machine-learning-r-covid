from pathlib import Path

MARCADOR = "\n## Materiales complementarios del capítulo\n"

SECCIONES = {
    "05-knn.qmd": r'''

## Caso aplicado B: k-NN con COVID-19

En esta segunda ruta aplicada usamos la misma muestra educativa de COVID-19 México 2022 empleada en los capítulos anteriores. El objetivo es clasificar `MURIO` a partir de edad, neumonía, diabetes, hipertensión, obesidad, enfermedad renal crónica y número de comorbilidades.

> **Uso académico:** este ejercicio permite estudiar el comportamiento de k-NN. No es una calculadora clínica ni un instrumento de diagnóstico.

```{r covid-knn-preparar}
ruta_covid <- "datos/covid19/procesados/covid19_mexico_2022_ml_preparado.csv.gz"

if (file.exists(ruta_covid)) {
  covid_knn <- read_csv(ruta_covid, show_col_types = FALSE) |>
    select(MURIO, EDAD, NEUMONIA, DIABETES, HIPERTENSION,
           OBESIDAD, RENAL_CRONICA, NUM_COMORBILIDADES) |>
    drop_na()

  set.seed(2026)
  covid_knn <- covid_knn |>
    sample_n(min(12000, nrow(covid_knn))) |>
    mutate(
      MURIO = factor(MURIO, levels = c(1, 0),
                     labels = c("Defunción", "Sin defunción"))
    )

  X_covid <- covid_knn |>
    select(-MURIO) |>
    as.matrix()
  y_covid <- covid_knn$MURIO

  set.seed(2026)
  idx_covid <- sample(seq_len(nrow(X_covid)),
                      size = floor(0.80 * nrow(X_covid)))

  x_train_covid <- X_covid[idx_covid, , drop = FALSE]
  x_test_covid  <- X_covid[-idx_covid, , drop = FALSE]
  y_train_covid <- y_covid[idx_covid]
  y_test_covid  <- y_covid[-idx_covid]

  medias_covid <- apply(x_train_covid, 2, mean)
  desv_covid <- apply(x_train_covid, 2, sd)
  desv_covid[desv_covid == 0] <- 1

  x_train_covid_z <- scale(x_train_covid,
                           center = medias_covid,
                           scale = desv_covid)
  x_test_covid_z <- scale(x_test_covid,
                          center = medias_covid,
                          scale = desv_covid)
}
```

La estandarización es especialmente importante en k-NN porque la distancia euclidiana sería dominada por variables con escalas mayores, como la edad.

```{r covid-knn-modelo}
if (exists("x_train_covid_z")) {
  pred_covid_knn <- knn(
    train = x_train_covid_z,
    test = x_test_covid_z,
    cl = y_train_covid,
    k = 11
  )

  matriz_covid_knn <- table(
    Real = factor(y_test_covid,
                  levels = c("Defunción", "Sin defunción")),
    Predicho = factor(pred_covid_knn,
                      levels = c("Defunción", "Sin defunción"))
  )
  matriz_covid_knn
}
```

```{r covid-knn-comparar-k}
if (exists("x_train_covid_z")) {
  evaluar_knn_covid <- function(k) {
    p <- knn(x_train_covid_z, x_test_covid_z, y_train_covid, k = k)
    m <- table(
      Real = factor(y_test_covid, levels = c("Defunción", "Sin defunción")),
      Predicho = factor(p, levels = c("Defunción", "Sin defunción"))
    )
    VP <- m[1,1]; FN <- m[1,2]; FP <- m[2,1]; VN <- m[2,2]
    data.frame(
      k = k,
      exactitud = (VP + VN) / sum(m),
      sensibilidad = ifelse(VP + FN == 0, NA, VP / (VP + FN)),
      especificidad = ifelse(VN + FP == 0, NA, VN / (VN + FP))
    )
  }

  resultados_k_covid <- do.call(
    rbind,
    lapply(c(3, 5, 11, 21), evaluar_knn_covid)
  )
  resultados_k_covid
}
```

::: {.callout-tip}
## Interpretación
El valor de $k$ controla cuánto se suaviza la decisión. Valores pequeños reaccionan más a observaciones locales; valores mayores producen fronteras más estables. En datos desbalanceados conviene mirar sensibilidad y especificidad, no solo exactitud.
:::
''',

    "06-arboles-decision.qmd": r'''

## Caso aplicado B: árbol de decisión con COVID-19

Usamos la misma muestra común de hasta 12 000 registros de COVID-19 México 2022 y la misma semilla `2026`. El árbol permite observar reglas de decisión fáciles de interpretar.

> **Uso académico:** las reglas encontradas describen el comportamiento de esta muestra y no deben interpretarse como reglas clínicas.

```{r covid-arbol-preparar}
ruta_covid <- "datos/covid19/procesados/covid19_mexico_2022_ml_preparado.csv.gz"

if (file.exists(ruta_covid)) {
  covid_arbol <- read_csv(ruta_covid, show_col_types = FALSE) |>
    select(MURIO, EDAD, NEUMONIA, DIABETES, HIPERTENSION,
           OBESIDAD, RENAL_CRONICA, NUM_COMORBILIDADES) |>
    tidyr::drop_na()

  set.seed(2026)
  covid_arbol <- covid_arbol |>
    sample_n(min(12000, nrow(covid_arbol))) |>
    mutate(
      MURIO = factor(MURIO, levels = c(1, 0),
                     labels = c("Defunción", "Sin defunción"))
    )

  set.seed(2026)
  idx_covid <- sample(seq_len(nrow(covid_arbol)),
                      size = floor(0.80 * nrow(covid_arbol)))
  covid_train <- covid_arbol[idx_covid, ]
  covid_test  <- covid_arbol[-idx_covid, ]
}
```

```{r covid-arbol-modelo}
if (exists("covid_train")) {
  arbol_covid <- rpart(
    MURIO ~ EDAD + NEUMONIA + DIABETES + HIPERTENSION +
      OBESIDAD + RENAL_CRONICA + NUM_COMORBILIDADES,
    data = covid_train,
    method = "class",
    control = rpart.control(
      cp = 0.002,
      minsplit = 80,
      minbucket = 30,
      maxdepth = 5
    )
  )

  printcp(arbol_covid)
}
```

```{r covid-arbol-importancia}
if (exists("arbol_covid")) {
  imp_covid_arbol <- arbol_covid$variable.importance
  if (!is.null(imp_covid_arbol)) {
    data.frame(
      variable = names(imp_covid_arbol),
      importancia = as.numeric(imp_covid_arbol)
    ) |>
      arrange(desc(importancia))
  }
}
```

```{r covid-arbol-metricas}
if (exists("arbol_covid")) {
  pred_covid_arbol <- predict(arbol_covid, covid_test, type = "class")
  matriz_covid_arbol <- table(
    Real = factor(covid_test$MURIO,
                  levels = c("Defunción", "Sin defunción")),
    Predicho = factor(pred_covid_arbol,
                      levels = c("Defunción", "Sin defunción"))
  )
  matriz_covid_arbol

  VP <- matriz_covid_arbol[1,1]
  FN <- matriz_covid_arbol[1,2]
  FP <- matriz_covid_arbol[2,1]
  VN <- matriz_covid_arbol[2,2]

  data.frame(
    exactitud = (VP + VN) / sum(matriz_covid_arbol),
    sensibilidad = ifelse(VP + FN == 0, NA, VP / (VP + FN)),
    especificidad = ifelse(VN + FP == 0, NA, VN / (VN + FP))
  )
}
```

::: {.callout-tip}
## Interpretación
La principal ventaja del árbol es que transforma el modelo en una secuencia visible de decisiones. Su desventaja es que un solo árbol puede cambiar bastante ante pequeñas variaciones de la muestra; esto motiva Random Forest.
:::
''',

    "07-random-forest.qmd": r'''

## Caso aplicado B: Random Forest con COVID-19

Ahora aplicamos un bosque aleatorio a la misma muestra COVID utilizada en k-NN y árboles. Esto permite comparar un árbol individual con un ensamble de muchos árboles.

> **Uso académico:** las importancias y predicciones corresponden a una muestra educativa y no deben usarse para decisiones médicas.

```{r covid-rf-preparar}
ruta_covid <- "datos/covid19/procesados/covid19_mexico_2022_ml_preparado.csv.gz"

if (file.exists(ruta_covid)) {
  covid_rf <- read_csv(ruta_covid, show_col_types = FALSE) |>
    select(MURIO, EDAD, NEUMONIA, DIABETES, HIPERTENSION,
           OBESIDAD, RENAL_CRONICA, NUM_COMORBILIDADES) |>
    tidyr::drop_na()

  set.seed(2026)
  covid_rf <- covid_rf |>
    sample_n(min(12000, nrow(covid_rf))) |>
    mutate(
      MURIO = factor(MURIO, levels = c(1, 0),
                     labels = c("Defunción", "Sin defunción"))
    )

  set.seed(2026)
  idx_covid <- sample(seq_len(nrow(covid_rf)),
                      size = floor(0.80 * nrow(covid_rf)))
  covid_train <- covid_rf[idx_covid, ]
  covid_test  <- covid_rf[-idx_covid, ]
}
```

```{r covid-rf-modelo}
if (exists("covid_train")) {
  rf_covid <- ranger(
    MURIO ~ EDAD + NEUMONIA + DIABETES + HIPERTENSION +
      OBESIDAD + RENAL_CRONICA + NUM_COMORBILIDADES,
    data = covid_train,
    num.trees = 300,
    mtry = 3,
    min.node.size = 20,
    importance = "impurity",
    probability = TRUE,
    seed = 2026
  )
  rf_covid
}
```

```{r covid-rf-importancia, fig.width=7, fig.height=4.5}
if (exists("rf_covid")) {
  imp_covid_rf <- data.frame(
    variable = names(rf_covid$variable.importance),
    importancia = as.numeric(rf_covid$variable.importance)
  ) |>
    arrange(desc(importancia))

  imp_covid_rf

  ggplot(imp_covid_rf,
         aes(x = reorder(variable, importancia), y = importancia)) +
    geom_col(fill = col_azul, width = 0.75) +
    coord_flip() +
    labs(
      title = "Importancia de variables: Random Forest COVID-19",
      x = "Variable",
      y = "Importancia"
    ) +
    tema_libro()
}
```

```{r covid-rf-metricas}
if (exists("rf_covid")) {
  pred_prob_covid_rf <- predict(rf_covid, data = covid_test)$predictions
  pred_clase_covid_rf <- colnames(pred_prob_covid_rf)[
    max.col(pred_prob_covid_rf, ties.method = "first")
  ]

  matriz_covid_rf <- table(
    Real = factor(covid_test$MURIO,
                  levels = c("Defunción", "Sin defunción")),
    Predicho = factor(pred_clase_covid_rf,
                      levels = c("Defunción", "Sin defunción"))
  )
  matriz_covid_rf

  VP <- matriz_covid_rf[1,1]
  FN <- matriz_covid_rf[1,2]
  FP <- matriz_covid_rf[2,1]
  VN <- matriz_covid_rf[2,2]

  data.frame(
    exactitud = (VP + VN) / sum(matriz_covid_rf),
    sensibilidad = ifelse(VP + FN == 0, NA, VP / (VP + FN)),
    especificidad = ifelse(VN + FP == 0, NA, VN / (VN + FP))
  )
}
```

::: {.callout-tip}
## Interpretación
Random Forest suele ser más estable que un árbol individual porque combina muchas decisiones parcialmente distintas. La comparación de métricas con el árbol del capítulo anterior permite observar esa ganancia de estabilidad.
:::
'''
}

for nombre, seccion in SECCIONES.items():
    ruta = Path(nombre)
    texto = ruta.read_text(encoding="utf-8")
    titulo = seccion.strip().splitlines()[0]
    if titulo in texto:
        print(f"{nombre}: sección COVID ya presente")
        continue
    if MARCADOR not in texto:
        raise SystemExit(f"No se encontró marcador en {nombre}")
    texto = texto.replace(MARCADOR, seccion + MARCADOR, 1)
    ruta.write_text(texto, encoding="utf-8")
    print(f"{nombre}: actualizado")
