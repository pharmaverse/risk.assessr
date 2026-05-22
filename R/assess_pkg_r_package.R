#' Assess an R package by name (deprecated)
#'
#' Use [risk_assess_pkg()] with `package` instead.
#'
#' @param package_name Package name.
#' @param version Package version. Default `NA` uses latest.
#' @param repos Repository URLs. Default `getOption("repos")`.
#'
#' @return Assessment results or `NULL`.
#'
#' @export
assess_pkg_r_package <- function(package_name, version = NA, repos = getOption("repos")) {
  .Deprecated(
    "risk_assess_pkg",
    msg = "assess_pkg_r_package() is deprecated. Use risk_assess_pkg(package = ..., version = ..., repos = ...) instead."
  )
  risk_assess_pkg(package = package_name, version = version, repos = repos)
}
