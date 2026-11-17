# Offline doubles for network-bound calls reached by assess_pkg() and risk_assess_pkg().

# Removes R and base packages from a dependency table without CRAN metadata.
mock_remove_base <- function(df) {
  base_rec_pkgs <- c("base", "compiler", "datasets", "graphics", "grDevices",
                     "grid", "methods", "parallel", "splines", "stats",
                     "stats4", "tcltk", "tools", "utils")
  deps <- df[!(df$package == "R" | df$package %in% base_rec_pkgs), ]
  return(deps)
}

# Installs a local source package without resolving dependencies from a repository.
offline_install_local <- function(path = ".", ..., quiet = TRUE, INSTALL_opts = character()) {
  utils::install.packages(
    pkgs = path,
    repos = NULL,
    type = "source",
    quiet = quiet,
    INSTALL_opts = INSTALL_opts
  )
  return(invisible(TRUE))
}

# Builds a mock that records a test failure when a live CRAN lookup is reached.
offline_tripwire <- function(name, value) {
  force(value)
  tripwire <- function(...) {
    testthat::fail(paste0("Live network call reached: ", name))
    return(value)
  }
  return(tripwire)
}

# Mocks every network-bound binding reachable from assess_pkg() and risk_assess_pkg().
local_offline_network <- function(env = parent.frame()) {
  testthat::local_mocked_bindings(
    capture_cran_warning = function(cran_url, path) list(status = "success", message = NULL),
    remove_base_packages = mock_remove_base,
    cran_revdep = function(pkg, ...) character(0),
    get_cran_total_downloads = function(pkg, months = NULL) 0,
    check_cran_package = offline_tripwire("check_cran_package", FALSE),
    parse_package_info = offline_tripwire("parse_package_info", NULL),
    cran_packages = offline_tripwire("cran_packages", NULL),
    .package = "risk.assessr",
    .env = env
  )
  testthat::local_mocked_bindings(
    install_local = offline_install_local,
    .package = "remotes",
    .env = env
  )
  return(invisible(TRUE))
}
