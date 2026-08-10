from pathlib import Path

p = Path("08-evaluacion-modelos.qmd")
text = p.read_text(encoding="utf-8")
title = "## Comparación integrada de modelos con COVID-19"

section = r'''

## Comparación integrada de modelos con COVID-19

Los capítulos anteriores aplicaron distintos algoritmos a COVID-19. Para compararlos de manera más coherente construiremos ahora un **benchmark didáctico común**: todos los modelos usarán las mismas variables, la misma muestra, la misma partición de entrenamiento/prueba y las mismas métricas.

> **Uso académico:** esta comparación sirve para estudiar diferencias entre algoritmos. No es una evaluación clínica ni debe utilizarse para pronóstico individual.

### Una muestra balanceada para comparar algoritmos

La variable `MURIO` está muy desbalanceada en la base original. Si evaluáramos únicamente exactitud sobre una muestra aleatoria, un modelo podría obtener un valor alto simplemente prediciendo casi siempre la clase mayoritaria.

Para este ejercicio tomamos, de forma reproducible, hasta 2 500 observaciones de cada clase. Esto produce un banco de pruebas balanceado. **Las métricas obtenidas describen este benchmark educativo y no la prevalencia de defunción en la población.**

```{r covid-comparacion-preparar}
ruta_covid <- "datos/covid19/procesados/covid19_mexico_2022_ml_preparado.csv.gz"

if (file.exists(ruta_covid)) {
  covid_comp_base <- readr::read_csv(ruta_covid, show_col_types = FALSE) |>
    dplyr::select(
      MURIO, EDAD, NEUMONIA, DIABETES, HIPERTENSION,
      OBESIDAD, RENAL_CRONICA, NUM_COMORBILIDADES
    ) |>
    tidyr::drop_na() |>
    dplyr::mutate(
      MURIO = factor(
        MURIO,
        levels = c(0, 1),
        labels = c("Sin defunción", "Defunción")
      )
    )

  set.seed(2026)
  n_por_clase <- min(
    2500,
    min(table(covid_comp_base$MURIO))
  )

  covid_comp <- covid_comp_base |>
    dplyr::group_by(MURIO) |>
    dplyr::slice_sample(n = n_por_clase) |>
    dplyr::ungroup()

  set.seed(2026)
  idx_train <- unlist(lapply(
    split(seq_len(nrow(covid_comp)), covid_comp$MURIO),
    function(i) sample(i, floor(0.80 * length(i)))
  ))

  train_comp <- covid_comp[idx_train, ]
  test_comp <- covid_comp[-idx_train, ]

  prop.table(table(train_comp$MURIO))
  prop.table(table(test_comp$MURIO))
}
```

### Función común de métricas

```{r covid-comparacion-funcion-metricas}
metricas_covid_comunes <- function(real, predicho) {
  niveles <- c("Sin defunción", "Defunción")
  real <- factor(real, levels = niveles)
  predicho <- factor(predicho, levels = niveles)
  m <- table(Real = real, Predicho = predicho)

  VP <- m["Defunción", "Defunción"]
  FN <- m["Defunción", "Sin defunción"]
  FP <- m["Sin defunción", "Defunción"]
  VN <- m["Sin defunción", "Sin defunción"]

  div <- function(a, b) {
    if (is.na(b) || b == 0) return(NA_real_)
    as.numeric(a / b)
  }

  exactitud <- div(VP + VN, sum(m))
  sensibilidad <- div(VP, VP + FN)
  especificidad <- div(VN, VN + FP)
  precision <- div(VP, VP + FP)
  f1 <- if (is.na(precision) || is.na(sensibilidad) ||
            precision + sensibilidad == 0) {
    NA_real_
  } else {
    2 * precision * sensibilidad / (precision + sensibilidad)
  }

  data.frame(
    exactitud = exactitud,
    sensibilidad = sensibilidad,
    especificidad = especificidad,
    precision = precision,
    f1 = f1
  )
}
```

### 1. Regresión logística

```{r covid-comparacion-logistica}
if (exists("train_comp")) {
  modelo_log_comp <- glm(
    MURIO ~ EDAD + NEUMONIA + DIABETES + HIPERTENSION +
      OBESIDAD + RENAL_CRONICA + NUM_COMORBILIDADES,
    data = train_comp,
    family = binomial
  )

  prob_log_comp <- predict(modelo_log_comp, test_comp, type = "response")
  pred_log_comp <- factor(
    ifelse(prob_log_comp >= 0.50, "Defunción", "Sin defunción"),
    levels = levels(train_comp$MURIO)
  )
}
```

### 2. k-NN

```{r covid-comparacion-knn}
if (exists("train_comp")) {
  vars_comp <- c(
    "EDAD", "NEUMONIA", "DIABETES", "HIPERTENSION",
    "OBESIDAD", "RENAL_CRONICA", "NUM_COMORBILIDADES"
  )

  X_train <- as.matrix(train_comp[vars_comp])
  X_test <- as.matrix(test_comp[vars_comp])

  medias <- apply(X_train, 2, mean)
  desv <- apply(X_train, 2, sd)
  desv[desv == 0] <- 1

  X_train_z <- scale(X_train, center = medias, scale = desv)
  X_test_z <- scale(X_test, center = medias, scale = desv)

  pred_knn_comp <- class::knn(
    train = X_train_z,
    test = X_test_z,
    cl = train_comp$MURIO,
    k = 11
  )
}
```

### 3. Árbol de decisión

```{r covid-comparacion-arbol}
if (exists("train_comp")) {
  modelo_arbol_comp <- rpart::rpart(
    MURIO ~ EDAD + NEUMONIA + DIABETES + HIPERTENSION +
      OBESIDAD + RENAL_CRONICA + NUM_COMORBILIDADES,
    data = train_comp,
    method = "class",
    control = rpart::rpart.control(
      cp = 0.002,
      minsplit = 60,
      minbucket = 20,
      maxdepth = 5
    )
  )

  pred_arbol_comp <- predict(
    modelo_arbol_comp,
    test_comp,
    type = "class"
  )
}
```

### 4. Random Forest

```{r covid-comparacion-rf}
if (exists("train_comp")) {
  set.seed(2026)
  modelo_rf_comp <- ranger::ranger(
    MURIO ~ EDAD + NEUMONIA + DIABETES + HIPERTENSION +
      OBESIDAD + RENAL_CRONICA + NUM_COMORBILIDADES,
    data = train_comp,
    num.trees = 300,
    mtry = 3,
    min.node.size = 20,
    classification = TRUE,
    probability = FALSE,
    seed = 2026
  )

  pred_rf_comp <- predict(modelo_rf_comp, test_comp)$predictions
}
```

### 5. SVM radial

```{r covid-comparacion-svm}
if (exists("train_comp")) {
  set.seed(2026)
  modelo_svm_comp <- e1071::svm(
    MURIO ~ EDAD + NEUMONIA + DIABETES + HIPERTENSION +
      OBESIDAD + RENAL_CRONICA + NUM_COMORBILIDADES,
    data = train_comp,
    kernel = "radial",
    cost = 1,
    gamma = 1 / 7,
    scale = TRUE
  )

  pred_svm_comp <- predict(modelo_svm_comp, test_comp)
}
```

### 6. Naive Bayes

```{r covid-comparacion-nb}
if (exists("train_comp")) {
  train_nb_comp <- train_comp |>
    dplyr::mutate(
      NEUMONIA = factor(NEUMONIA),
      DIABETES = factor(DIABETES),
      HIPERTENSION = factor(HIPERTENSION),
      OBESIDAD = factor(OBESIDAD),
      RENAL_CRONICA = factor(RENAL_CRONICA)
    )

  test_nb_comp <- test_comp |>
    dplyr::mutate(
      NEUMONIA = factor(NEUMONIA, levels = levels(train_nb_comp$NEUMONIA)),
      DIABETES = factor(DIABETES, levels = levels(train_nb_comp$DIABETES)),
      HIPERTENSION = factor(HIPERTENSION, levels = levels(train_nb_comp$HIPERTENSION)),
      OBESIDAD = factor(OBESIDAD, levels = levels(train_nb_comp$OBESIDAD)),
      RENAL_CRONICA = factor(RENAL_CRONICA, levels = levels(train_nb_comp$RENAL_CRONICA))
    )

  modelo_nb_comp <- e1071::naiveBayes(
    MURIO ~ EDAD + NEUMONIA + DIABETES + HIPERTENSION +
      OBESIDAD + RENAL_CRONICA + NUM_COMORBILIDADES,
    data = train_nb_comp,
    laplace = 1
  )

  pred_nb_comp <- predict(modelo_nb_comp, test_nb_comp, type = "class")
}
```

### 7. Red neuronal

```{r covid-comparacion-nn}
if (exists("train_comp")) {
  train_nn_comp <- as.data.frame(X_train_z)
  test_nn_comp <- as.data.frame(X_test_z)
  train_nn_comp$MURIO_NUM <- ifelse(train_comp$MURIO == "Defunción", 1, 0)

  set.seed(2026)
  modelo_nn_comp <- neuralnet::neuralnet(
    MURIO_NUM ~ EDAD + NEUMONIA + DIABETES + HIPERTENSION +
      OBESIDAD + RENAL_CRONICA + NUM_COMORBILIDADES,
    data = train_nn_comp,
    hidden = 5,
    linear.output = FALSE,
    lifesign = "none",
    stepmax = 1e6
  )

  prob_nn_comp <- as.numeric(
    neuralnet::compute(
      modelo_nn_comp,
      test_nn_comp[vars_comp]
    )$net.result[, 1]
  )

  pred_nn_comp <- factor(
    ifelse(prob_nn_comp >= 0.50, "Defunción", "Sin defunción"),
    levels = levels(train_comp$MURIO)
  )
}
```

### Tabla comparativa final

```{r covid-comparacion-tabla}
if (exists("pred_nn_comp")) {
  comparacion_covid_modelos <- dplyr::bind_rows(
    cbind(modelo = "Regresión logística", metricas_covid_comunes(test_comp$MURIO, pred_log_comp)),
    cbind(modelo = "k-NN (k=11)", metricas_covid_comunes(test_comp$MURIO, pred_knn_comp)),
    cbind(modelo = "Árbol de decisión", metricas_covid_comunes(test_comp$MURIO, pred_arbol_comp)),
    cbind(modelo = "Random Forest", metricas_covid_comunes(test_comp$MURIO, pred_rf_comp)),
    cbind(modelo = "SVM radial", metricas_covid_comunes(test_comp$MURIO, pred_svm_comp)),
    cbind(modelo = "Naive Bayes", metricas_covid_comunes(test_comp$MURIO, pred_nb_comp)),
    cbind(modelo = "Red neuronal", metricas_covid_comunes(test_comp$MURIO, pred_nn_comp))
  )

  comparacion_covid_modelos |>
    dplyr::mutate(
      dplyr::across(
        c(exactitud, sensibilidad, especificidad, precision, f1),
        ~ round(.x, 3)
      )
    )
}
```

```{r covid-comparacion-grafica, fig.width=8, fig.height=5}
if (exists("comparacion_covid_modelos")) {
  comp_larga <- comparacion_covid_modelos |>
    tidyr::pivot_longer(
      cols = c(exactitud, sensibilidad, especificidad, precision, f1),
      names_to = "metrica",
      values_to = "valor"
    )

  ggplot2::ggplot(
    comp_larga,
    ggplot2::aes(x = modelo, y = valor, fill = metrica)
  ) +
    ggplot2::geom_col(position = "dodge") +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(limits = c(0, 1)) +
    ggplot2::labs(
      title = "Comparación común de modelos con COVID-19",
      subtitle = "Misma muestra balanceada, mismas variables y misma partición 80/20",
      x = NULL,
      y = "Valor de la métrica",
      fill = "Métrica"
    ) +
    tema_libro()
}
```

::: {.callout-important title="No existe un ganador universal"}
El modelo con mayor exactitud no necesariamente es el mejor para todos los objetivos. La sensibilidad prioriza detectar defunciones; la especificidad prioriza reconocer correctamente los casos sin defunción; precisión y F1 ofrecen otras perspectivas. Además, aquí se usaron hiperparámetros didácticos fijos, no una búsqueda exhaustiva de optimización.
:::

### Lectura recomendada de la tabla

Al comparar los modelos conviene preguntar:

1. ¿Cuál ofrece el mejor equilibrio entre sensibilidad y especificidad?
2. ¿Algún modelo gana en exactitud pero pierde mucha sensibilidad?
3. ¿La mayor complejidad de Random Forest, SVM o la red neuronal produce una mejora suficiente frente a la regresión logística?
4. ¿Un modelo sencillo sería preferible si ofrece resultados parecidos y mayor interpretabilidad?
5. ¿Cambiaría la conclusión si la muestra conservara la fuerte desproporción original entre clases?

Esta comparación cierra la ruta supervisada del caso COVID-19 y conecta los capítulos de algoritmos con una evaluación común y reproducible.
'''

if title not in text:
    text = text.rstrip() + section + "\n"
    p.write_text(text, encoding="utf-8")
    print("Comparación integrada COVID agregada al capítulo 9")
else:
    print("El capítulo 9 ya contiene la comparación integrada COVID")
