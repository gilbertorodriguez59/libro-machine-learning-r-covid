from pathlib import Path
import csv, gzip, random

# ---------- Interactivo ATUS real para capítulo 3 ----------
atus_path = Path("datos/atus_ml_preparado.csv")
cap3 = Path("03-analisis-exploratorio.qmd")
text3 = cap3.read_text(encoding="utf-8")
marker3 = "\n## Conclusión\n"
title3 = "## Laboratorio interactivo ATUS: mes, hora y víctimas"

if title3 not in text3 and atus_path.exists():
    agg = {}
    with atus_path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            mes = row.get("MES", "")
            hora = row.get("ID_HORA", "")
            clase = row.get("accidente_con_victimas", "")
            if not mes or not hora or not clase:
                continue
            try:
                mes_i = int(float(mes)); hora_i = int(float(hora))
            except Exception:
                continue
            key = (mes_i, hora_i)
            total, vict = agg.get(key, (0, 0))
            total += 1
            if clase.strip().lower() == "con víctimas":
                vict += 1
            agg[key] = (total, vict)

    rows = []
    for (mes, hora), (total, vict) in sorted(agg.items()):
        rows.append((mes, hora, total, vict))

    r_mes = ",".join(str(r[0]) for r in rows)
    r_hora = ",".join(str(r[1]) for r in rows)
    r_total = ",".join(str(r[2]) for r in rows)
    r_vict = ",".join(str(r[3]) for r in rows)

    section3 = f'''

{title3}

Este laboratorio utiliza **conteos agregados calculados a partir de la base ATUS preparada del libro**. Permite seleccionar un mes y observar cómo cambia el número de accidentes por hora y la proporción de accidentes con víctimas.

::: {{.content-visible when-format="html"}}

```{{shinylive-r}}
#| standalone: true
#| viewerHeight: 720
#| components: [viewer]

library(shiny)

datos_atus <- data.frame(
  MES = c({r_mes}),
  ID_HORA = c({r_hora}),
  TOTAL = c({r_total}),
  CON_VICTIMAS = c({r_vict})
)
datos_atus$PORC_VICTIMAS <- ifelse(datos_atus$TOTAL > 0,
                                   100 * datos_atus$CON_VICTIMAS / datos_atus$TOTAL,
                                   0)

ui <- fluidPage(
  titlePanel("Explorador ATUS por mes y hora"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("mes", "Mes", min = 1, max = 12, value = 1, step = 1),
      radioButtons("vista", "Mostrar", choices = c(
        "Número de accidentes" = "total",
        "% con víctimas" = "victimas"
      ))
    ),
    mainPanel(
      plotOutput("grafica", height = "430px"),
      tableOutput("resumen"),
      textOutput("interpretacion")
    )
  )
)

server <- function(input, output, session) {{
  datos_mes <- reactive({{
    datos_atus[datos_atus$MES == input$mes, ]
  }})

  output$grafica <- renderPlot({{
    d <- datos_mes()
    if (input$vista == "total") {{
      plot(d$ID_HORA, d$TOTAL, type = "h", lwd = 5,
           xlab = "Hora del día", ylab = "Número de accidentes",
           main = paste("ATUS: accidentes por hora - mes", input$mes))
      points(d$ID_HORA, d$TOTAL, pch = 19)
    }} else {{
      plot(d$ID_HORA, d$PORC_VICTIMAS, type = "b", pch = 19,
           xlab = "Hora del día", ylab = "% con víctimas",
           ylim = c(0, max(5, max(d$PORC_VICTIMAS, na.rm = TRUE) * 1.1)),
           main = paste("ATUS: proporción con víctimas - mes", input$mes))
    }}
    grid()
  }})

  output$resumen <- renderTable({{
    d <- datos_mes()
    data.frame(
      Indicador = c("Accidentes del mes", "Con víctimas", "% con víctimas"),
      Valor = c(sum(d$TOTAL), sum(d$CON_VICTIMAS),
                round(100 * sum(d$CON_VICTIMAS) / sum(d$TOTAL), 2))
    )
  }})

  output$interpretacion <- renderText({{
    d <- datos_mes()
    h <- d$ID_HORA[which.max(d$TOTAL)]
    paste0("En el mes seleccionado, la hora con mayor número de accidentes es ",
           h, ":00. Cambia el mes y compara si el patrón se conserva.")
  }})
}}

shinyApp(ui, server)
```

:::

::: {{.content-visible when-format="pdf"}}

### Laboratorio interactivo ATUS disponible en la versión web

La versión web permite seleccionar el mes, comparar accidentes por hora y observar el porcentaje de accidentes con víctimas usando agregados de la base ATUS preparada.

:::
'''
    if marker3 in text3:
        text3 = text3.replace(marker3, section3 + marker3, 1)
        cap3.write_text(text3, encoding="utf-8")
        print("Interactivo ATUS agregado a capítulo 3")

# ---------- Interactivo COVID real para capítulo 13 ----------
covid_path = Path("datos/covid19/muestras/covid19_mexico_2022_muestra.csv.gz")
cap13 = Path("12-kmeans.qmd")
text13 = cap13.read_text(encoding="utf-8")
marker13 = "\n## Materiales complementarios del capítulo\n"
title13 = "## Laboratorio interactivo COVID: agrupamiento k-means"

if title13 not in text13 and covid_path.exists():
    vars_ = ["EDAD", "NEUMONIA", "DIABETES", "HIPERTENSION", "OBESIDAD", "RENAL_CRONICA", "NUM_COMORBILIDADES"]
    pool = []
    random.seed(2026)
    with gzip.open(covid_path, "rt", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                vals = [float(row[v]) for v in vars_]
            except Exception:
                continue
            if any(v != v for v in vals):
                continue
            pool.append(vals)
    if len(pool) > 360:
        pool = random.sample(pool, 360)

    cols = list(zip(*pool)) if pool else [[] for _ in vars_]
    rcols = {v: ",".join((str(int(x)) if float(x).is_integer() else str(round(x, 4))) for x in col)
             for v, col in zip(vars_, cols)}

    section13 = f'''

{title13}

Este laboratorio utiliza una **submuestra reproducible de la muestra COVID-19 México 2022 incluida en el libro**. Puedes modificar el número de clusters y observar cómo cambian los perfiles en una proyección de componentes principales.

::: {{.content-visible when-format="html"}}

```{{shinylive-r}}
#| standalone: true
#| viewerHeight: 780
#| components: [viewer]

library(shiny)

covid_interactivo <- data.frame(
  EDAD = c({rcols['EDAD']}),
  NEUMONIA = c({rcols['NEUMONIA']}),
  DIABETES = c({rcols['DIABETES']}),
  HIPERTENSION = c({rcols['HIPERTENSION']}),
  OBESIDAD = c({rcols['OBESIDAD']}),
  RENAL_CRONICA = c({rcols['RENAL_CRONICA']}),
  NUM_COMORBILIDADES = c({rcols['NUM_COMORBILIDADES']})
)

ui <- fluidPage(
  titlePanel("COVID-19: explorador k-means"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("k", "Número de clusters", min = 2, max = 6, value = 3, step = 1),
      numericInput("semilla", "Semilla", value = 2026, min = 1),
      helpText("MURIO no se utiliza para formar los grupos.")
    ),
    mainPanel(
      plotOutput("grafica", height = "470px"),
      tableOutput("centroides"),
      textOutput("nota")
    )
  )
)

server <- function(input, output, session) {{
  resultado <- reactive({{
    X <- scale(covid_interactivo)
    set.seed(input$semilla)
    km <- kmeans(X, centers = input$k, nstart = 25)
    pca <- prcomp(X, center = FALSE, scale. = FALSE)
    list(X = X, km = km, pca = pca)
  }})

  output$grafica <- renderPlot({{
    r <- resultado()
    plot(r$pca$x[,1], r$pca$x[,2],
         col = r$km$cluster, pch = 19,
         xlab = "Componente principal 1",
         ylab = "Componente principal 2",
         main = paste("COVID-19: k-means con k =", input$k))
    grid()
  }})

  output$centroides <- renderTable({{
    r <- resultado()
    round(r$km$centers, 2)
  }}, rownames = TRUE)

  output$nota <- renderText({{
    paste0("Los números de cluster no tienen orden clínico. La solución actual explica perfiles de similitud para k = ", input$k, ".")
  }})
}}

shinyApp(ui, server)
```

:::

::: {{.content-visible when-format="pdf"}}

### Laboratorio interactivo COVID disponible en la versión web

La versión web permite cambiar el número de clusters y visualizar una submuestra COVID-19 2022 agrupada mediante k-means y proyectada con PCA.

:::
'''
    if marker13 in text13:
        text13 = text13.replace(marker13, section13 + marker13, 1)
        cap13.write_text(text13, encoding="utf-8")
        print("Interactivo COVID agregado a capítulo 13")
