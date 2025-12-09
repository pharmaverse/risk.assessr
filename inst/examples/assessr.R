# set up
repos <- "http://cran.us.r-project.org"
install.packages('remotes', repos = repos)
remotes::install_local(repos = repos)
library(risk.assessr)

pkg <- commandArgs(trailingOnly = TRUE) |>
  jsonlite::fromJSON()

output_path <- Sys.getenv("OUTPUT_PATH", "output")

# create results dir
target_dir <- file.path(output_path, pkg$name, pkg$version)
dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)

# assess
options(repos='http://cran.us.r-project.org')
risk.assessr::assess_pkg_r_package(pkg$name, pkg$version) |>
  jsonlite::write_json(file.path(target_dir, "assessr.json"), force=TRUE, auto_unbox=TRUE)
