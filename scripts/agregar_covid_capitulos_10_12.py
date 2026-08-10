from pathlib import Path

MARKER = "\n## Materiales complementarios del capítulo\n"

sections = {
"09-svm.qmd": r'''

## Caso aplicado B: SVM con COVID-19

En esta segunda ruta aplicada usamos datos abiertos de COVID-19 México 2022. El objetivo educativo es clasificar la variable `MURIO`, donde **1 representa defunción registrada y 0 ausencia de defunción registrada**, a partir de edad, neumonía, diabetes, hipertensión, obesidad, enfermedad renal crónica y número de comorbilidades.

> **Uso académico:** este ejercicio ilustra el funcionamiento de SVM. No debe interpretarse como herramienta clínica, pronóstico individual ni diagnóstico.

```{r covid-svm-preparar}
ruta_covid <- "datos/covid19/procesados/covid19_mexico_2022_ml_preparado.csv.gz"

if (file.exists(ruta_covid)) {
  covid_svm <- readr::read_csv(ruta_covid, show_col_types = FALSE) |>
    dplyr::select(MURIO, EDAD, NEUMONIA, DIABETES, HIPERTENSION,
                  OBESIDAD, RENAL_CRONICA, NUM_COMORBILIDADES) |>
    tidyr::drop_na() |>
    dplyr::mutate(
      MURIO = factor(MURIO, levels = c(0, 1),
                     labels = c("Sin defunción", "Defunción"))
    )

  set.seed(2026)
  covid_svm <- covid_svm |>
    dplyr::sample_n(min(8000, nrow(covid_svm)))

  set.seed(2026)
  idx_svm_covid <- unlist(lapply(
    split(seq_len(nrow(covid_svm)), covid_svm$MURIO),
    function(i) sample(i, floor(0.80 * length(i)))
  ))

  train_svm_covid <- covid_svm[idx_svm_covid, ]
  test_svm_covid <- covid_svm[-idx_svm_covid, ]
}
```

La división es estratificada para conservar aproximadamente la proporción de ambas clases. Además, `scale = TRUE` estandariza los predictores numéricos dentro de `svm()`.

```{r covid-svm-modelos}
if (exists("train_svm_covid")) {
  frec_covid <- table(train_svm_covid$MURIO)
  pesos_covid <- sum(frec_covid) / (length(frec_covid) * frec_covid)

  modelo_svm_covid_lineal <- e1071::svm(
    MURIO ~ ., data = train_svm_covid,
    kernel = "linear", cost = 1,
    class.weights = pesos_covid,
    scale = TRUE
  )

  modelo_svm_covid_radial <- e1071::svm(
    MURIO ~ ., data = train_svm_covid,
    kernel = "radial", cost = 1,
    gamma = 1 / (ncol(train_svm_covid) - 1),
    class.weights = pesos_covid,
    scale = TRUE
  )

  pred_lin <- predict(modelo_svm_covid_lineal, test_svm_covid)
  pred_rad <- predict(modelo_svm_covid_radial, test_svm_covid)
}
```

```{r covid-svm-metricas}
metricas_covid_binarias <- function(real, predicho, positiva = "Defunción") {
  real <- factor(real, levels = c("Sin defunción", "Defunción"))
  predicho <- factor(predicho, levels = levels(real))
  m <- table(Real = real, Predicho = predicho)
  VP <- m[positiva, positiva]
  FN <- m[positiva, "Sin defunción"]
  FP <- m["Sin defunción", positiva]
  VN <- m["Sin defunción", "Sin defunción"]
  div <- function(a,b) ifelse(b == 0, NA_real_, as.numeric(a/b))
  data.frame(
    exactitud = div(VP+VN, sum(m)),
    sensibilidad = div(VP, VP+FN),
    especificidad = div(VN, VN+FP)
  )
}

if (exists("pred_lin")) {
  comparacion_svm_covid <- dplyr::bind_rows(
    cbind(modelo = "SVM lineal", metricas_covid_binarias(test_svm_covid$MURIO, pred_lin)),
    cbind(modelo = "SVM radial", metricas_covid_binarias(test_svm_covid$MURIO, pred_rad))
  )
  comparacion_svm_covid
}
```

::: {.callout-tip title="Interpretación"}
La comparación permite estudiar si una frontera no lineal aporta una ventaja real sobre la SVM lineal. En una respuesta desbalanceada, sensibilidad y especificidad deben revisarse junto con la exactitud.
:::
''',
"10-naive-bayes.qmd": r'''

## Caso aplicado B: Naive Bayes con COVID-19

Ahora aplicamos Naive Bayes a COVID-19 México 2022. La variable objetivo es `MURIO` y utilizamos la misma familia de predictores empleada en los capítulos anteriores.

> **Uso académico:** las probabilidades estimadas por este modelo no deben interpretarse como riesgo clínico individual.

```{r covid-nb-preparar}
ruta_covid <- "datos/covid19/procesados/covid19_mexico_2022_ml_preparado.csv.gz"

if (file.exists(ruta_covid)) {
  covid_nb <- readr::read_csv(ruta_covid, show_col_types = FALSE) |>
    dplyr::select(MURIO, EDAD, NEUMONIA, DIABETES, HIPERTENSION,
                  OBESIDAD, RENAL_CRONICA, NUM_COMORBILIDADES) |>
    tidyr::drop_na() |>
    dplyr::mutate(
      MURIO = factor(MURIO, levels = c(0, 1),
                     labels = c("Sin defunción", "Defunción")),
      NEUMONIA = factor(NEUMONIA),
      DIABETES = factor(DIABETES),
      HIPERTENSION = factor(HIPERTENSION),
      OBESIDAD = factor(OBESIDAD),
      RENAL_CRONICA = factor(RENAL_CRONICA)
    )

  set.seed(2026)
  covid_nb <- covid_nb |>
    dplyr::sample_n(min(12000, nrow(covid_nb)))

  set.seed(2026)
  idx_nb_covid <- unlist(lapply(
    split(seq_len(nrow(covid_nb)), covid_nb$MURIO),
    function(i) sample(i, floor(0.80 * length(i)))
  ))

  train_nb_covid <- covid_nb[idx_nb_covid, ]
  test_nb_covid <- covid_nb[-idx_nb_covid, ]
}
```

En este ejemplo las comorbilidades binarias se tratan como variables categóricas, mientras que `EDAD` y `NUM_COMORBILIDADES` se modelan como numéricas.

```{r covid-nb-modelo}
if (exists("train_nb_covid")) {
  modelo_nb_covid <- e1071::naiveBayes(
    MURIO ~ ., data = train_nb_covid,
    laplace = 1
  )

  pred_nb_covid <- predict(modelo_nb_covid, test_nb_covid, type = "class")
  prob_nb_covid <- predict(modelo_nb_covid, test_nb_covid, type = "raw")

  matriz_nb_covid <- table(
    Real = test_nb_covid$MURIO,
    Predicho = pred_nb_covid
  )
  matriz_nb_covid
  head(prob_nb_covid)
}
```

```{r covid-nb-metricas}
if (exists("matriz_nb_covid")) {
  VP <- matriz_nb_covid["Defunción", "Defunción"]
  FN <- matriz_nb_covid["Defunción", "Sin defunción"]
  FP <- matriz_nb_covid["Sin defunción", "Defunción"]
  VN <- matriz_nb_covid["Sin defunción", "Sin defunción"]
  div <- function(a,b) ifelse(b == 0, NA_real_, as.numeric(a/b))
  data.frame(
    exactitud = div(VP+VN, sum(matriz_nb_covid)),
    sensibilidad = div(VP, VP+FN),
    especificidad = div(VN, VN+FP),
    precision = div(VP, VP+FP)
  )
}
```

::: {.callout-note title="Qué aporta este ejemplo"}
Naive Bayes permite observar directamente probabilidades previas y condicionales. Eso lo convierte en un excelente modelo didáctico para conectar el teorema de Bayes con un problema real de clasificación.
:::
''',
"11-redes-neuronales.qmd": r'''

## Caso aplicado B: red neuronal con COVID-19

En este ejemplo entrenamos una red neuronal pequeña para clasificar `MURIO` con datos de COVID-19 México 2022. Se utiliza una arquitectura deliberadamente sencilla para que el objetivo sea comprender el procedimiento y no construir un sistema clínico.

> **Uso académico:** la salida de la red es una predicción estadística sobre esta muestra y no un pronóstico médico individual.

```{r covid-nn-preparar}
ruta_covid <- "datos/covid19/procesados/covid19_mexico_2022_ml_preparado.csv.gz"

if (file.exists(ruta_covid)) {
  covid_nn <- readr::read_csv(ruta_covid, show_col_types = FALSE) |>
    dplyr::select(MURIO, EDAD, NEUMONIA, DIABETES, HIPERTENSION,
                  OBESIDAD, RENAL_CRONICA, NUM_COMORBILIDADES) |>
    tidyr::drop_na()

  set.seed(2026)
  covid_nn <- covid_nn |>
    dplyr::sample_n(min(8000, nrow(covid_nn)))

  set.seed(2026)
  idx_nn_covid <- unlist(lapply(
    split(seq_len(nrow(covid_nn)), covid_nn$MURIO),
    function(i) sample(i, floor(0.80 * length(i)))
  ))

  train_nn_covid <- covid_nn[idx_nn_covid, ]
  test_nn_covid <- covid_nn[-idx_nn_covid, ]

  predictores_nn <- c("EDAD", "NEUMONIA", "DIABETES", "HIPERTENSION",
                      "OBESIDAD", "RENAL_CRONICA", "NUM_COMORBILIDADES")

  medias_nn <- sapply(train_nn_covid[predictores_nn], mean)
  desv_nn <- sapply(train_nn_covid[predictores_nn], sd)
  desv_nn[desv_nn == 0] <- 1

  train_nn_covid[predictores_nn] <- scale(
    train_nn_covid[predictores_nn], center = medias_nn, scale = desv_nn
  )
  test_nn_covid[predictores_nn] <- scale(
    test_nn_covid[predictores_nn], center = medias_nn, scale = desv_nn
  )
}
```

La estandarización se calcula exclusivamente con el conjunto de entrenamiento y después se aplica al conjunto de prueba. Esto evita utilizar información de prueba durante el aprendizaje.

```{r covid-nn-modelo}
if (exists("train_nn_covid")) {
  set.seed(2026)
  modelo_nn_covid <- neuralnet::neuralnet(
    MURIO ~ EDAD + NEUMONIA + DIABETES + HIPERTENSION +
      OBESIDAD + RENAL_CRONICA + NUM_COMORBILIDADES,
    data = train_nn_covid,
    hidden = c(5, 3),
    linear.output = FALSE,
    lifesign = "none",
    stepmax = 1e6
  )

  prob_nn_covid <- as.numeric(
    neuralnet::compute(
      modelo_nn_covid,
      test_nn_covid[predictores_nn]
    )$net.result[, 1]
  )

  pred_nn_covid <- ifelse(prob_nn_covid >= 0.50, 1, 0)
  matriz_nn_covid <- table(
    Real = factor(test_nn_covid$MURIO, levels = c(0,1), labels = c("Sin defunción", "Defunción")),
    Predicho = factor(pred_nn_covid, levels = c(0,1), labels = c("Sin defunción", "Defunción"))
  )
  matriz_nn_covid
}
```

```{r covid-nn-metricas}
if (exists("matriz_nn_covid")) {
  VP <- matriz_nn_covid["Defunción", "Defunción"]
  FN <- matriz_nn_covid["Defunción", "Sin defunción"]
  FP <- matriz_nn_covid["Sin defunción", "Defunción"]
  VN <- matriz_nn_covid["Sin defunción", "Sin defunción"]
  div <- function(a,b) ifelse(b == 0, NA_real_, as.numeric(a/b))
  data.frame(
    exactitud = div(VP+VN, sum(matriz_nn_covid)),
    sensibilidad = div(VP, VP+FN),
    especificidad = div(VN, VN+FP)
  )
}
```

::: {.callout-tip title="Interpretación"}
La red puede representar relaciones no lineales entre edad y comorbilidades, pero eso no garantiza que supere a modelos más simples. La comparación con regresión logística, k-NN, árboles, Random Forest, SVM y Naive Bayes será más importante que observar una sola métrica.
:::
'''
}

for filename, section in sections.items():
    p = Path(filename)
    text = p.read_text(encoding="utf-8")
    title = section.split("\n## ", 1)[1].split("\n", 1)[0]
    if title in text:
        print(f"{filename}: ya contiene {title}")
        continue
    if MARKER not in text:
        raise SystemExit(f"No se encontró marcador en {filename}")
    text = text.replace(MARKER, section + MARKER, 1)
    p.write_text(text, encoding="utf-8")
    print(f"{filename}: sección COVID agregada")
