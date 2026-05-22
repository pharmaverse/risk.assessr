#' Assess package for risk metrics
#'
#' Assess an R package for risk metrics. Use exactly one of:
#' * `path` – path to a local .tar.gz archive, or
#' * `package` – package name to fetch (optionally with `version`), or
#' * neither – opens an interactive file chooser.
#'
#' @param path Path to a local .tar.gz package archive. Use only when not
#'   providing `package`.
#' @param package Package name to fetch from CRAN, Bioconductor, or internal
#'   repos. Use only when not providing `path`.
#' @param version (optional) Package version when using `package`. Default `NA`
#'   uses the latest available.
#' @param repos Repository URLs when fetching by `package`. Default is
#'   `getOption("repos")`.
#'
#' @return List containing results (metrics, covr, trace matrix, R CMD check),
#'   or `NULL` if the package cannot be assessed.
#'
#' @examples
#' \dontrun{
#' # Local package (path or file chooser)
#' results <- risk_assess_pkg()
#' results <- risk_assess_pkg(path = "path/to/package.tar.gz")
#'
#' # Package by name from repositories
#' results <- risk_assess_pkg(package = "here")
#' results <- risk_assess_pkg(package = "here", version = "1.0.1")
#' results <- risk_assess_pkg(package = "here", repos = "https://cloud.r-project.org")
#' }
#'
#' @export
risk_assess_pkg <- function(path = NULL, package = NULL, version = NA,
                           repos = getOption("repos")) {
  if (!is.null(path) && !is.null(package) && nzchar(package)) {
    warning("Provide either 'path' or 'package', not both. Returning NULL.")
    return(NULL)
  }

  temp_cleanup <- NULL
  modified_cleanup <- NULL
  old_repos <- NULL

  if (!is.null(path)) {
    if (!file.exists(path)) { warning("Path does not exist: ", path, ". Returning NULL."); return(NULL) }
    old_repos <- getOption("repos")
    r <- old_repos
    r["CRAN"] <- "https://cran.us.r-project.org"
    options(repos = r)
    tar_path <- path
  } else if (!is.null(package) && is.character(package) && nzchar(package)) {
    v <- if (is.null(version) || (length(version) == 1L && is.na(version))) NULL else version
    temp_cleanup <- tryCatch(
      get_package_tarfile(package_name = package, version = v, repos = repos),
      error = function(e) {
        warning("Failed to download package '", package, "': ", conditionMessage(e), ". Returning NULL.")
        NULL
      }
    )
    if (is.null(temp_cleanup)) return(NULL)
    tar_path <- temp_cleanup
  } else {
    chosen <- file.choose()
    if (!file.exists(chosen)) { warning("Chosen file does not exist. Returning NULL."); return(NULL) }
    old_repos <- getOption("repos")
    r <- old_repos
    r["CRAN"] <- "https://cran.us.r-project.org"
    options(repos = r)
    tar_path <- chosen
  }

  oldwd <- getwd()
  on.exit(setwd(oldwd), add = TRUE)
  on.exit({
    for (f in c(temp_cleanup, modified_cleanup)) {
      if (!is.null(f) && file.exists(f)) unlink(f)
    }
    if (!is.null(old_repos)) options(repos = old_repos)
  }, add = TRUE)

  modified_tar <- modify_description_file(tar_path)
  if (!identical(modified_tar, tar_path)) modified_cleanup <- modified_tar

  install_list <- set_up_pkg(modified_tar)
  if (!isTRUE(install_list$package_installed) || !nzchar(install_list$pkg_source_path)) {
    message("Failed to unpack package.")
    return(NULL)
  }

  if (!isTRUE(install_package_local(install_list$pkg_source_path))) {
    message("Package installation failed.")
    return(NULL)
  }

  rcmdcheck_args <- install_list$rcmdcheck_args
  rcmdcheck_args$path <- install_list$pkg_source_path
  assess_pkg(pkg_source_path = install_list$pkg_source_path, rcmdcheck_args = rcmdcheck_args)
}
