from pathlib import Path

p = Path("12-kmeans.qmd")
text = p.read_text(encoding="utf-8")
marker = "\n## Materiales complementarios del capítulo\n"
title = "Caso aplicado B: k-means con COVID-19"

section = r'''

## Caso aplicado B: k-means con COVID-19

En esta segunda ruta aplicada usamos datos abiertos de COVID-19 México 2022 para descubrir **perfiles de observaciones semejantes**. A diferencia de los capítulos de clasificación, k-means es un método no supervisado: por ello la variable `MURIO` **no participa en la formación de los grupos**.

> **Uso académico:** los clusters representan patrones estadísticos dentro de esta muestra. No son categorías clínicas, diagnósticos ni niveles de riesgo médico.

### Preparar las variables para agrupamiento

Usamos variables numéricas relacionadas con edad y comorbilidades. Las variables binarias se mantienen como 0/1 y todas se estandarizan para evitar que una escala domine las distancias.

```{r covid-kmeans-preparar}
ruta_covid <- "datos/covid19/procesados/covid19_mexico_2022_ml_preparado.csv.gz"

if (file.exists(ruta_covid)) {
  covid_km <- readr::read_csv(ruta_covid, show_col_types = FALSE) |>
    dplyr::select(
      MURIO, EDAD, NEUMONIA, DIABETES, HIPERTENSION,
      OBESIDAD, RENAL_CRONICA, NUM_COMORBILIDADES
    ) |>
    tidyr::drop_na()

  set.seed(2026)
  covid_km <- covid_km |>
    dplyr::sample_n(min(12000, nrow(covid_km)))

  variables_km <- c(
    "EDAD", "NEUMONIA", "DIABETES", "HIPERTENSION",
    "OBESIDAD", "RENAL_CRONICA", "NUM_COMORBILIDADES"
  )

  X_covid_km <- scale(covid_km[variables_km])
}
```

::: {.callout-important title="MURIO queda fuera del agrupamiento"}
`MURIO` se conserva únicamente para una interpretación posterior. No se incluye en `X_covid_km`, de modo que los clusters se forman sin conocer la variable de defunción.
:::

### Explorar el número de grupos con el método del codo

```{r covid-kmeans-codo, fig.width=7, fig.height=4.5}
if (exists("X_covid_km")) {
  valores_k_covid <- 1:8
  wss_covid <- numeric(length(valores_k_covid))

  for (i in seq_along(valores_k_covid)) {
    set.seed(2026)
    ajuste <- kmeans(
      X_covid_km,
      centers = valores_k_covid[i],
      nstart = 30,
      iter.max = 100
    )
    wss_covid[i] <- ajuste$tot.withinss
  }

  plot(
    valores_k_covid, wss_covid,
    type = "b", pch = 19,
    xlab = "Número de clusters k",
    ylab = "Suma de cuadrados interna",
    main = "COVID-19: método del codo"
  )
}
```

El método del codo no elige automáticamente un valor perfecto de \(k\); ayuda a identificar cuándo agregar más clusters produce mejoras cada vez menores.

### Comparar silhouette

Para que el cálculo de distancias sea ligero, se evalúa silhouette sobre una submuestra reproducible.

```{r covid-kmeans-silhouette}
if (exists("X_covid_km")) {
  set.seed(2026)
  n_sil <- min(2500, nrow(X_covid_km))
  idx_sil <- sample(seq_len(nrow(X_covid_km)), n_sil)
  X_sil <- X_covid_km[idx_sil, , drop = FALSE]
  dist_sil <- dist(X_sil)

  sil_promedio <- sapply(2:6, function(k_actual) {
    set.seed(2026)
    km_tmp <- kmeans(X_sil, centers = k_actual, nstart = 30)
    sil_tmp <- cluster::silhouette(km_tmp$cluster, dist_sil)
    mean(sil_tmp[, "sil_width"])
  })

  data.frame(
    k = 2:6,
    silhouette_promedio = sil_promedio
  )
}
```

### Ajustar una solución didáctica con tres clusters

Para mantener la interpretación sencilla usamos \(k=3\). En un análisis formal, este valor debería justificarse conjuntamente con el codo, silhouette, estabilidad e interpretabilidad.

```{r covid-kmeans-modelo}
if (exists("X_covid_km")) {
  set.seed(2026)
  modelo_covid_km <- kmeans(
    X_covid_km,
    centers = 3,
    nstart = 50,
    iter.max = 100
  )

  covid_km$cluster <- factor(modelo_covid_km$cluster)
  table(covid_km$cluster)
}
```

### Interpretar los centroides

```{r covid-kmeans-centroides}
if (exists("modelo_covid_km")) {
  centroides_covid <- as.data.frame(modelo_covid_km$centers)
  centroides_covid$cluster <- factor(seq_len(nrow(centroides_covid)))
  centroides_covid
}
```

Como los datos están estandarizados, un centroide positivo indica que el cluster presenta, en promedio, valores superiores a la media de la muestra para esa variable; un valor negativo indica valores inferiores.

### Perfil descriptivo en unidades originales

```{r covid-kmeans-perfiles}
if (exists("modelo_covid_km")) {
  perfiles_covid <- covid_km |>
    dplyr::group_by(cluster) |>
    dplyr::summarise(
      n = dplyr::n(),
      edad_media = mean(EDAD),
      neumonia_pct = mean(NEUMONIA) * 100,
      diabetes_pct = mean(DIABETES) * 100,
      hipertension_pct = mean(HIPERTENSION) * 100,
      obesidad_pct = mean(OBESIDAD) * 100,
      renal_cronica_pct = mean(RENAL_CRONICA) * 100,
      comorbilidades_media = mean(NUM_COMORBILIDADES),
      .groups = "drop"
    )

  perfiles_covid
}
```

### Observar `MURIO` después de formar los grupos

Ahora sí usamos la variable `MURIO`, pero únicamente como una **descripción externa** de los clusters ya construidos.

```{r covid-kmeans-murio}
if (exists("modelo_covid_km")) {
  mortalidad_por_cluster <- covid_km |>
    dplyr::group_by(cluster) |>
    dplyr::summarise(
      casos = dplyr::n(),
      defunciones_registradas = sum(MURIO == 1),
      porcentaje_defuncion = mean(MURIO == 1) * 100,
      .groups = "drop"
    )

  mortalidad_por_cluster
}
```

::: {.callout-warning title="Interpretación correcta"}
Una diferencia en el porcentaje de defunción entre clusters **no demuestra causalidad** y tampoco convierte k-means en un modelo predictivo. Los grupos fueron definidos únicamente por semejanza en las variables de entrada.
:::

### Visualización bidimensional mediante PCA

La siguiente gráfica usa PCA solo para proyectar los clusters en dos dimensiones y facilitar su visualización; el agrupamiento continúa siendo el realizado en el espacio estandarizado original.

```{r covid-kmeans-pca, fig.width=7, fig.height=5}
if (exists("modelo_covid_km")) {
  pca_covid_km <- prcomp(X_covid_km, center = FALSE, scale. = FALSE)

  grafica_covid_km <- data.frame(
    PC1 = pca_covid_km$x[, 1],
    PC2 = pca_covid_km$x[, 2],
    cluster = covid_km$cluster
  )

  ggplot2::ggplot(
    grafica_covid_km,
    ggplot2::aes(x = PC1, y = PC2, color = cluster)
  ) +
    ggplot2::geom_point(alpha = 0.35, size = 1.2) +
    ggplot2::labs(
      title = "Perfiles COVID-19 obtenidos con k-means",
      subtitle = "Proyección PCA para visualizar los clusters",
      x = "Componente principal 1",
      y = "Componente principal 2",
      color = "Cluster"
    ) +
    ggplot2::theme_minimal()
}
```

::: {.callout-tip title="Qué aprendemos con este caso"}
Este ejercicio muestra una diferencia fundamental: en clasificación usamos una etiqueta para aprender a predecirla; en clustering buscamos estructura sin etiqueta. Después podemos relacionar los grupos con variables externas para describirlos, pero no para afirmar que esas variables causaron los clusters.
:::
'''

if title not in text:
    if marker not in text:
        raise SystemExit("No se encontró el marcador de materiales complementarios")
    text = text.replace(marker, section + marker, 1)

old = "\nEn el siguiente capítulo estudiaremos el **Análisis de Componentes Principales (PCA)** como técnica de reducción de dimensión.\n"
new = "\nCon este capítulo cerramos la ruta principal de algoritmos del libro. Los apéndices reúnen el glosario, las referencias y los índices para consulta.\n"
text = text.replace(old, new)

p.write_text(text, encoding="utf-8")
print("12-kmeans.qmd actualizado con caso COVID-19 y cierre editorial corregido")
