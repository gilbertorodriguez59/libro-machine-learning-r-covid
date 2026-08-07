# ============================================================
# Descargar y preparar datos COVID-19 de México
# Corrección v0.14.0.1
# ============================================================

options(stringsAsFactors = FALSE, timeout = 3600)

raiz <- "C:/libro-machine-learning-r-covid-dev"
dir_originales <- file.path(raiz, "datos", "covid19", "originales")
dir_procesados <- file.path(raiz, "datos", "covid19", "procesados")
dir_muestras <- file.path(raiz, "datos", "covid19", "muestras")
dir_diccionarios <- file.path(raiz, "datos", "covid19", "diccionarios")

dirs <- c(dir_originales, dir_procesados, dir_muestras, dir_diccionarios)
invisible(lapply(dirs, dir.create, recursive = TRUE, showWarnings = FALSE))

paquetes <- c("data.table", "readr")
faltantes <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)]

if (length(faltantes) > 0) {
  install.packages(faltantes, repos = "https://cloud.r-project.org")
}

library(data.table)
library(readr)

url_oficial <- paste0(
  "https://datosabiertos.salud.gob.mx/gobmx/salud/",
  "datos_abiertos/datos_abiertos_covid19.zip"
)

# Respaldo público del mismo formato, solo si el servidor oficial falla.
url_respaldo <- paste0(
  "https://github.com/RodrigoZepeda/covidmx/raw/main/",
  "datos_abiertos_covid19.zip"
)

archivo_zip <- file.path(dir_originales, "datos_abiertos_covid19.zip")
carpeta_extraida <- file.path(dir_originales, "datos_abiertos_covid19")

descargar <- function(url, destino) {
  cat("\nIntentando descargar:\n", url, "\n\n", sep = "")

  resultado <- tryCatch(
    {
      download.file(
        url = url,
        destfile = destino,
        mode = "wb",
        quiet = FALSE,
        method = "libcurl"
      )
      TRUE
    },
    error = function(e) {
      cat("\nNo fue posible descargar desde esta dirección:\n")
      cat(conditionMessage(e), "\n")
      FALSE
    }
  )

  resultado && file.exists(destino) && file.info(destino)$size > 1000000
}

if (!file.exists(archivo_zip) || file.info(archivo_zip)$size < 1000000) {
  correcto <- descargar(url_oficial, archivo_zip)

  if (!correcto) {
    cat("\nEl servidor oficial no respondió. Probando respaldo público...\n")
    correcto <- descargar(url_respaldo, archivo_zip)
  }

  if (!correcto) {
    stop(
      paste0(
        "No fue posible descargar el archivo.\n",
        "Puede descargarlo manualmente desde:\n",
        url_oficial,
        "\ny guardarlo como:\n",
        archivo_zip
      )
    )
  }
} else {
  cat("\nEl ZIP ya existe y será reutilizado:\n", archivo_zip, "\n")
}

cat("\nDescomprimiendo el archivo...\n")
dir.create(carpeta_extraida, recursive = TRUE, showWarnings = FALSE)

unzip(
  zipfile = archivo_zip,
  exdir = carpeta_extraida,
  overwrite = TRUE
)

csvs <- list.files(
  carpeta_extraida,
  pattern = "\\.csv$",
  full.names = TRUE,
  recursive = TRUE
)

if (length(csvs) == 0) {
  stop("El ZIP no contiene ningún archivo CSV.")
}

# Elegir el CSV más grande, que corresponde a la base principal.
archivo_csv <- csvs[which.max(file.info(csvs)$size)]

cat("\nArchivo encontrado:\n", archivo_csv, "\n")
cat("\nLeyendo encabezados...\n")

normalizar_nombres <- function(x) {
  x <- toupper(x)
  x <- iconv(x, from = "", to = "ASCII//TRANSLIT")
  gsub("[^A-Z0-9_]", "_", x)
}

encabezado <- names(
  fread(
    archivo_csv,
    nrows = 0,
    encoding = "Latin-1",
    check.names = FALSE
  )
)

encabezado_norm <- normalizar_nombres(encabezado)

columnas_deseadas <- c(
  "FECHA_ACTUALIZACION", "ID_REGISTRO", "ORIGEN", "SECTOR",
  "ENTIDAD_UM", "SEXO", "ENTIDAD_NAC", "ENTIDAD_RES",
  "MUNICIPIO_RES", "TIPO_PACIENTE", "FECHA_INGRESO",
  "FECHA_SINTOMAS", "FECHA_DEF", "INTUBADO", "NEUMONIA",
  "EDAD", "NACIONALIDAD", "EMBARAZO", "HABLA_LENGUA_INDIG",
  "INDIGENA", "DIABETES", "EPOC", "ASMA", "INMUSUPR",
  "HIPERTENSION", "OTRA_COM", "CARDIOVASCULAR", "OBESIDAD",
  "RENAL_CRONICA", "TABAQUISMO", "OTRO_CASO",
  "TOMA_MUESTRA_LAB", "RESULTADO_LAB",
  "TOMA_MUESTRA_ANTIGENO", "RESULTADO_ANTIGENO",
  "CLASIFICACION_FINAL", "MIGRANTE",
  "PAIS_NACIONALIDAD", "PAIS_ORIGEN", "UCI", "RESULTADO"
)

seleccion_norm <- intersect(columnas_deseadas, encabezado_norm)
seleccion_original <- encabezado[match(seleccion_norm, encabezado_norm)]

cat("\nLeyendo las columnas necesarias de la base nacional...\n")
cat("Este paso puede tardar varios minutos.\n\n")

dt <- fread(
  archivo_csv,
  select = seleccion_original,
  encoding = "Latin-1",
  showProgress = TRUE,
  check.names = FALSE
)

setnames(dt, normalizar_nombres(names(dt)))

cat("\nRegistros leídos: ", format(nrow(dt), big.mark = ","), "\n", sep = "")

# Identificación de casos confirmados.
if ("CLASIFICACION_FINAL" %in% names(dt)) {
  dt[, CONFIRMADO := as.integer(CLASIFICACION_FINAL %in% c(1, 2, 3))]
} else if ("RESULTADO_LAB" %in% names(dt)) {
  dt[, CONFIRMADO := as.integer(RESULTADO_LAB == 1)]
} else if ("RESULTADO" %in% names(dt)) {
  dt[, CONFIRMADO := as.integer(RESULTADO == 1)]
} else {
  stop(
    "No se encontró CLASIFICACION_FINAL, RESULTADO_LAB ni RESULTADO."
  )
}

if (!"FECHA_SINTOMAS" %in% names(dt)) {
  stop("La base no contiene FECHA_SINTOMAS.")
}

dt[, FECHA_SINTOMAS := as.IDate(FECHA_SINTOMAS)]
dt <- dt[CONFIRMADO == 1 & !is.na(FECHA_SINTOMAS)]
dt[, ANIO_SINTOMAS := as.integer(format(FECHA_SINTOMAS, "%Y"))]

# Crear variable de defunción.
if ("FECHA_DEF" %in% names(dt)) {
  fecha_def_texto <- as.character(dt$FECHA_DEF)

  dt[, MURIO := as.integer(
    !is.na(fecha_def_texto) &
      fecha_def_texto != "" &
      fecha_def_texto != "9999-99-99"
  )]
} else {
  dt[, MURIO := NA_integer_]
}

# Comparar únicamente los años centrales de la pandemia.
conteo <- dt[
  ANIO_SINTOMAS %in% 2020:2022,
  .(
    CASOS_CONFIRMADOS = .N,
    DEFUNCIONES_REGISTRADAS = sum(MURIO, na.rm = TRUE)
  ),
  by = ANIO_SINTOMAS
][order(-CASOS_CONFIRMADOS)]

if (nrow(conteo) == 0) {
  stop("No se encontraron casos confirmados de 2020 a 2022.")
}

fwrite(
  conteo,
  file.path(dir_procesados, "conteo_casos_confirmados_por_anio.csv")
)

cat("\nConteo por año de inicio de síntomas:\n")
print(conteo)

anio_max <- conteo$ANIO_SINTOMAS[1]
datos_max <- dt[ANIO_SINTOMAS == anio_max]

cat(
  "\nAño seleccionado: ", anio_max,
  "\nCasos confirmados: ",
  format(nrow(datos_max), big.mark = ","),
  "\n",
  sep = ""
)

# Crear una muestra de hasta 50,000 casos.
set.seed(2026)
n_muestra <- min(50000L, nrow(datos_max))

if (length(unique(na.omit(datos_max$MURIO))) > 1) {
  fallecidos <- datos_max[MURIO == 1]
  sobrevivientes <- datos_max[MURIO == 0]

  n_f <- min(nrow(fallecidos), round(n_muestra * 0.30))
  n_s <- min(nrow(sobrevivientes), n_muestra - n_f)

  muestra <- rbind(
    if (n_f > 0) fallecidos[sample(.N, n_f)] else fallecidos[0],
    if (n_s > 0) sobrevivientes[sample(.N, n_s)] else sobrevivientes[0],
    fill = TRUE
  )

  muestra <- muestra[sample(.N)]
} else {
  muestra <- datos_max[sample(.N, n_muestra)]
}

# Recodificación de variables.
variables_si_no <- intersect(
  c(
    "INTUBADO", "NEUMONIA", "EMBARAZO",
    "HABLA_LENGUA_INDIG", "INDIGENA", "DIABETES", "EPOC",
    "ASMA", "INMUSUPR", "HIPERTENSION", "OTRA_COM",
    "CARDIOVASCULAR", "OBESIDAD", "RENAL_CRONICA",
    "TABAQUISMO", "OTRO_CASO", "UCI"
  ),
  names(muestra)
)

for (v in variables_si_no) {
  x <- suppressWarnings(as.integer(muestra[[v]]))
  muestra[[v]] <- fifelse(
    x == 1, 1L,
    fifelse(x == 2, 0L, NA_integer_)
  )
}

if ("TIPO_PACIENTE" %in% names(muestra)) {
  x <- suppressWarnings(as.integer(muestra$TIPO_PACIENTE))
  muestra[, TIPO_PACIENTE := fifelse(
    x == 2, 1L,
    fifelse(x == 1, 0L, NA_integer_)
  )]
}

comorbilidades <- intersect(
  c(
    "DIABETES", "EPOC", "ASMA", "INMUSUPR",
    "HIPERTENSION", "CARDIOVASCULAR", "OBESIDAD",
    "RENAL_CRONICA", "TABAQUISMO"
  ),
  names(muestra)
)

if (length(comorbilidades) > 0) {
  muestra[
    ,
    NUM_COMORBILIDADES := rowSums(.SD, na.rm = TRUE),
    .SDcols = comorbilidades
  ]
}

columnas_ml <- intersect(
  c(
    "ID_REGISTRO", "FECHA_SINTOMAS", "ENTIDAD_RES",
    "SEXO", "EDAD", "TIPO_PACIENTE", "NEUMONIA",
    "DIABETES", "EPOC", "ASMA", "INMUSUPR",
    "HIPERTENSION", "CARDIOVASCULAR", "OBESIDAD",
    "RENAL_CRONICA", "TABAQUISMO", "UCI",
    "NUM_COMORBILIDADES", "MURIO"
  ),
  names(muestra)
)

archivo_muestra <- file.path(
  dir_muestras,
  paste0("covid19_mexico_", anio_max, "_muestra.csv.gz")
)

archivo_ml <- file.path(
  dir_procesados,
  paste0("covid19_mexico_", anio_max, "_ml_preparado.csv.gz")
)

fwrite(muestra, archivo_muestra, compress = "gzip")
fwrite(muestra[, ..columnas_ml], archivo_ml, compress = "gzip")

descripciones <- c(
  ID_REGISTRO = "Identificador anónimo del registro",
  FECHA_SINTOMAS = "Fecha de inicio de síntomas",
  ENTIDAD_RES = "Entidad federativa de residencia",
  SEXO = "1 mujer, 2 hombre",
  EDAD = "Edad en años",
  TIPO_PACIENTE = "0 ambulatorio, 1 hospitalizado",
  NEUMONIA = "0 no, 1 sí",
  DIABETES = "0 no, 1 sí",
  EPOC = "0 no, 1 sí",
  ASMA = "0 no, 1 sí",
  INMUSUPR = "0 no, 1 sí",
  HIPERTENSION = "0 no, 1 sí",
  CARDIOVASCULAR = "0 no, 1 sí",
  OBESIDAD = "0 no, 1 sí",
  RENAL_CRONICA = "0 no, 1 sí",
  TABAQUISMO = "0 no, 1 sí",
  UCI = "0 no, 1 sí",
  NUM_COMORBILIDADES = "Número de comorbilidades registradas",
  MURIO = "0 sin defunción registrada, 1 defunción registrada"
)

diccionario <- data.frame(
  VARIABLE = columnas_ml,
  DESCRIPCION = unname(descripciones[columnas_ml]),
  stringsAsFactors = FALSE
)

write_csv(
  diccionario,
  file.path(dir_diccionarios, "diccionario_covid19_ml.csv")
)

writeLines(
  c(
    "DATOS COVID-19 PARA EL LIBRO",
    "",
    paste("Año seleccionado:", anio_max),
    paste("Casos confirmados:", nrow(datos_max)),
    paste("Registros en la muestra:", nrow(muestra)),
    "",
    "Criterio de caso confirmado:",
    "CLASIFICACION_FINAL igual a 1, 2 o 3.",
    "",
    "La comparación anual se basa en FECHA_SINTOMAS.",
    "",
    "Fuente oficial:",
    url_oficial,
    "",
    "Uso exclusivamente educativo.",
    "No es una herramienta de diagnóstico médico."
  ),
  file.path(dir_muestras, "LEEME_COVID19.txt")
)

cat("\nARCHIVOS GENERADOS CORRECTAMENTE\n")
cat("\n", archivo_muestra, sep = "")
cat("\n", archivo_ml, sep = "")
cat("\n", file.path(dir_procesados, "conteo_casos_confirmados_por_anio.csv"), sep = "")
cat("\n", file.path(dir_diccionarios, "diccionario_covid19_ml.csv"), sep = "")
cat("\n\nProceso terminado.\n")
