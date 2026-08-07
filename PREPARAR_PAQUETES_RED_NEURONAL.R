options(repos = c(CRAN = "https://cloud.r-project.org"))

paquetes <- c("neuralnet")

faltantes <- paquetes[
  !vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)
]

if (length(faltantes) > 0) {
  install.packages(faltantes, dependencies = TRUE)
}

cat("\nPaquetes preparados correctamente:\n")
for (p in paquetes) {
  cat("-", p, ":", as.character(packageVersion(p)), "\n")
}
