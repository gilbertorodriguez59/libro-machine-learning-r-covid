options(stringsAsFactors = FALSE)

raiz <- "C:/libro-machine-learning-r-covid-dev"
originales <- file.path(raiz, "datos", "covid19", "originales")
procesados <- file.path(raiz, "datos", "covid19", "procesados")
muestras <- file.path(raiz, "datos", "covid19", "muestras")
diccionarios <- file.path(raiz, "datos", "covid19", "diccionarios")
diagnosticos <- file.path(raiz, "datos", "covid19", "diagnosticos")

invisible(lapply(c(originales, procesados, muestras, diccionarios, diagnosticos), dir.create, recursive = TRUE, showWarnings = FALSE))

for (p in c("data.table", "readr")) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
}

library(data.table)
library(readr)

anios <- 2020:2025

normalizar <- function(x) {
  x <- toupper(x)
  x <- iconv(x, from = "", to = "ASCII//TRANSLIT")
  gsub("[^A-Z0-9_]", "_", x)
}

buscar_archivo <- function(anio) {
  x <- list.files(originales, full.names = TRUE, recursive = FALSE)
  x <- x[grepl(as.character(anio), basename(x), fixed = TRUE) & grepl("\\.(zip|csv)$", x, ignore.case = TRUE)]
  if (length(x) == 0) return(NA_character_)
  x[which.max(file.info(x)$size)]
}

extraer_csv <- function(archivo, anio) {
  if (grepl("\\.csv$", archivo, ignore.case = TRUE)) return(archivo)
  destino <- file.path(originales, paste0("extraido_", anio))
  dir.create(destino, recursive = TRUE, showWarnings = FALSE)
  unzip(archivo, exdir = destino, overwrite = TRUE)
  csvs <- list.files(destino, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
  if (length(csvs) == 0) stop("El ZIP de ", anio, " no contiene CSV.")
  csvs[which.max(file.info(csvs)$size)]
}

guardar_diagnostico <- function(csv, anio, encabezado_norm) {
  fwrite(data.table(POSICION = seq_along(encabezado_norm), VARIABLE = encabezado_norm),
         file.path(diagnosticos, paste0("encabezados_", anio, ".csv")))
  candidatas <- encabezado_norm[grepl("COVID|SARS|RESULT|CLASIF|DIAGN|VIRUS|PCR|ANTIG|CONFIRM", encabezado_norm, ignore.case = TRUE)]
  fwrite(data.table(VARIABLE_CANDIDATA = candidatas),
         file.path(diagnosticos, paste0("variables_candidatas_confirmacion_", anio, ".csv")))
}

columnas_interes <- c(
  "ID_REGISTRO", "ENTIDAD_RES", "SEXO", "TIPO_PACIENTE",
  "FECHA_SINTOMAS", "FECHA_DEF", "NEUMONIA", "EDAD",
  "DIABETES", "EPOC", "ASMA", "INMUSUPR", "HIPERTENSION",
  "CARDIOVASCULAR", "OBESIDAD", "RENAL_CRONICA", "TABAQUISMO",
  "UCI", "CLASIFICACION_FINAL", "RESULTADO_LAB", "RESULTADO"
)

leer_anio <- function(archivo, anio) {
  csv <- extraer_csv(archivo, anio)
  encabezado <- names(fread(csv, nrows = 0, encoding = "Latin-1", check.names = FALSE))
  encabezado_norm <- normalizar(encabezado)
  guardar_diagnostico(csv, anio, encabezado_norm)

  variable_confirmacion <- NA_character_
  valores_confirmados <- NULL
  if ("CLASIFICACION_FINAL" %in% encabezado_norm) {
    variable_confirmacion <- "CLASIFICACION_FINAL"; valores_confirmados <- c(1,2,3)
  } else if ("RESULTADO_LAB" %in% encabezado_norm) {
    variable_confirmacion <- "RESULTADO_LAB"; valores_confirmados <- 1
  } else if ("RESULTADO" %in% encabezado_norm) {
    variable_confirmacion <- "RESULTADO"; valores_confirmados <- 1
  }

  if (is.na(variable_confirmacion)) {
    return(list(estado = "ESQUEMA_NO_HOMOLOGADO", anio = anio, datos = NULL,
                mensaje = paste0("El cierre ", anio, " usa un diccionario distinto. Se guardaron diagnósticos.")))
  }

  disponibles <- intersect(columnas_interes, encabezado_norm)
  originales_sel <- encabezado[match(disponibles, encabezado_norm)]
  cat("\nLeyendo ", anio, "...\n", sep = "")
  dt <- fread(csv, select = originales_sel, encoding = "Latin-1", showProgress = TRUE, check.names = FALSE)
  setnames(dt, normalizar(names(dt)))
  dt <- dt[get(variable_confirmacion) %in% valores_confirmados]

  if (!"FECHA_SINTOMAS" %in% names(dt)) {
    return(list(estado = "SIN_FECHA_SINTOMAS", anio = anio, datos = NULL,
                mensaje = paste0("El cierre ", anio, " no contiene FECHA_SINTOMAS.")))
  }

  dt[, FECHA_SINTOMAS := as.IDate(FECHA_SINTOMAS)]
  dt <- dt[!is.na(FECHA_SINTOMAS)]
  dt[, ANIO_SINTOMAS := as.integer(format(FECHA_SINTOMAS, "%Y"))]
  dt <- dt[ANIO_SINTOMAS == anio]

  if ("FECHA_DEF" %in% names(dt)) {
    f <- as.character(dt$FECHA_DEF)
    dt[, MURIO := as.integer(!is.na(f) & f != "" & f != "9999-99-99")]
  } else dt[, MURIO := NA_integer_]

  list(estado = "PROCESADO", anio = anio, datos = dt, mensaje = paste0("Procesado con ", variable_confirmacion))
}

archivos <- vapply(anios, buscar_archivo, character(1))
faltan <- anios[is.na(archivos)]
if (length(faltan) > 0) stop(paste0("Faltan archivos de: ", paste(faltan, collapse = ", "), "\nDeben estar en:\n", originales))

cat("\nArchivos detectados:\n")
print(data.frame(anio = anios, archivo = archivos))

resultados <- Map(leer_anio, archivos, anios)
estado <- rbindlist(lapply(resultados, function(x) data.table(ANIO = x$anio, ESTADO = x$estado, MENSAJE = x$mensaje)), fill = TRUE)
fwrite(estado, file.path(diagnosticos, "estado_procesamiento_2020_2025.csv"))
cat("\nEstado por año:\n"); print(estado)

procesados_ok <- resultados[vapply(resultados, function(x) identical(x$estado, "PROCESADO"), logical(1))]
if (length(procesados_ok) == 0) stop("Ningún año pudo procesarse con esquema reconocido.")

conteo <- rbindlist(lapply(procesados_ok, function(x) data.table(
  ANIO = x$anio,
  CASOS_CONFIRMADOS = nrow(x$datos),
  DEFUNCIONES_REGISTRADAS = sum(x$datos$MURIO, na.rm = TRUE),
  ESTADO = "PROCESADO"
)))[order(-CASOS_CONFIRMADOS)]

no_homologados <- estado[ESTADO != "PROCESADO"]
if (nrow(no_homologados) > 0) {
  conteo_publicado <- rbind(conteo, data.table(
    ANIO = no_homologados$ANIO,
    CASOS_CONFIRMADOS = NA_integer_,
    DEFUNCIONES_REGISTRADAS = NA_integer_,
    ESTADO = no_homologados$ESTADO
  ), fill = TRUE)[order(ANIO)]
} else conteo_publicado <- conteo[order(ANIO)]

fwrite(conteo_publicado, file.path(procesados, "conteo_casos_confirmados_2020_2025.csv"))
cat("\nConteo disponible:\n"); print(conteo_publicado)

anio_max <- conteo$ANIO[1]
resultado_max <- procesados_ok[vapply(procesados_ok, function(x) x$anio == anio_max, logical(1))][[1]]
dt <- resultado_max$datos

set.seed(2026)
n <- min(50000L, nrow(dt))
if ("MURIO" %in% names(dt) && length(unique(na.omit(dt$MURIO))) > 1) {
  pos <- dt[MURIO == 1]; neg <- dt[MURIO == 0]
  np <- min(nrow(pos), round(n * 0.30)); nn <- min(nrow(neg), n - np)
  muestra <- rbind(if (np > 0) pos[sample(.N, np)] else pos[0], if (nn > 0) neg[sample(.N, nn)] else neg[0], fill = TRUE)
  muestra <- muestra[sample(.N)]
} else muestra <- dt[sample(.N, n)]

binarias <- intersect(c("NEUMONIA","DIABETES","EPOC","ASMA","INMUSUPR","HIPERTENSION","CARDIOVASCULAR","OBESIDAD","RENAL_CRONICA","TABAQUISMO","UCI"), names(muestra))
for (v in binarias) {
  x <- suppressWarnings(as.integer(muestra[[v]]))
  muestra[[v]] <- fifelse(x == 1, 1L, fifelse(x == 2, 0L, NA_integer_))
}
if ("TIPO_PACIENTE" %in% names(muestra)) {
  x <- suppressWarnings(as.integer(muestra$TIPO_PACIENTE))
  muestra[, TIPO_PACIENTE := fifelse(x == 2, 1L, fifelse(x == 1, 0L, NA_integer_))]
}

comorb <- intersect(c("DIABETES","EPOC","ASMA","INMUSUPR","HIPERTENSION","CARDIOVASCULAR","OBESIDAD","RENAL_CRONICA","TABAQUISMO"), names(muestra))
if (length(comorb) > 0) muestra[, NUM_COMORBILIDADES := rowSums(.SD, na.rm = TRUE), .SDcols = comorb]

ml_cols <- intersect(c("ID_REGISTRO","FECHA_SINTOMAS","ENTIDAD_RES","SEXO","EDAD","TIPO_PACIENTE","NEUMONIA","DIABETES","EPOC","ASMA","INMUSUPR","HIPERTENSION","CARDIOVASCULAR","OBESIDAD","RENAL_CRONICA","TABAQUISMO","UCI","NUM_COMORBILIDADES","MURIO"), names(muestra))

archivo_muestra <- file.path(muestras, paste0("covid19_mexico_", anio_max, "_muestra.csv.gz"))
archivo_ml <- file.path(procesados, paste0("covid19_mexico_", anio_max, "_ml_preparado.csv.gz"))
fwrite(muestra, archivo_muestra, compress = "gzip")
fwrite(muestra[, ..ml_cols], archivo_ml, compress = "gzip")

cat("\nPROCESO TERMINADO CORRECTAMENTE\n")
cat("\nAño seleccionado: ", anio_max, sep = "")
cat("\nMuestra: ", archivo_muestra, sep = "")
cat("\nBase ML: ", archivo_ml, sep = "")
cat("\nDiagnósticos: ", diagnosticos, "\n", sep = "")
