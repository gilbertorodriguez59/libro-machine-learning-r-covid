options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!requireNamespace("shinylive", quietly = TRUE)) {
  install.packages("shinylive", dependencies = TRUE)
}

if (!requireNamespace("shinylive", quietly = TRUE)) {
  stop("No fue posible instalar el paquete shinylive.")
}

cat("Paquete shinylive disponible. Version: ",
    as.character(utils::packageVersion("shinylive")), "\n", sep = "")

tryCatch(
  shinylive::assets_download(),
  error = function(e) {
    message(
      "Aviso al descargar recursos; se intentará durante el renderizado: ",
      conditionMessage(e)
    )
  }
)
