#' Creates information on package installation
#'
#' @param package_path Path to the package tarball (.tar.gz).
#' @param check_type Type of R CMD check: "1" for basic, "2" for CRAN-like.
#'
#' @return list with local package install
#' @examples
#' \dontrun{
#' set_up_pkg("path/to/tarball")
#' }
#' @export
set_up_pkg <- function(package_path, check_type = "1") {
  suppressWarnings(pkg_source_path <- unpack_tarball(package_path))

  #set up build vignettes for R CMD check
  build_vignettes <- !contains_vignette_folder(package_path)

  if (length(pkg_source_path) == 0) {
    package_installed <- FALSE
    pkg_source_path <- ""
    build_vignettes <- FALSE
  } else {
    package_installed <- fs::file_exists(pkg_source_path)
  }

  if (package_installed) {
    rcmdcheck_args <- setup_rcmdcheck_args(check_type, build_vignettes)
  } else {
    rcmdcheck_args <- NULL
  }

  list(
    build_vignettes = build_vignettes,
    package_installed = package_installed,
    pkg_source_path = pkg_source_path,
    rcmdcheck_args = rcmdcheck_args
  )
}
