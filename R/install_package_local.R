#' Install package locally
#'
#' @param pkg_source_path - source path for install local
#' @param force_install logical. If TRUE, forces installation even if package is already installed.
#'
#' @return logical - package_installed 
#' @examples
#' \dontrun{
#' results <- install_package_local("pkg_source_path")
#' print(results)
#' }
#' @export
install_package_local <- function(pkg_source_path, force_install = FALSE) {
  
  pkg_disp <- basename(pkg_source_path)
  message(glue::glue("installing {pkg_disp} locally"))
  
  # Check if the package source path exists
  if (!dir.exists(pkg_source_path)) {
    message(glue::glue("No such file or directory: {pkg_source_path}"))
    package_installed <- FALSE
  } else if (!force_install && requireNamespace(pkg_disp, quietly = TRUE)) {
    message(glue::glue("{pkg_disp} is already installed"))
    package_installed <- TRUE
  } else {
    tryCatch(
      {
        remotes::install_local(
          pkg_source_path,
          dependencies = TRUE,
          upgrade = "never",
          force = TRUE,
          quiet = TRUE,
          INSTALL_opts = "--with-keep.source"
        )
        message(glue::glue("{pkg_disp} installed locally"))
        package_installed <- TRUE
      },  
      error = function(cond) {
        message(glue::glue("Local installation issue is: {cond}"))
        message(glue::glue("{pkg_disp} not installed locally"))
        package_installed <- FALSE
      }
    )
  }
  
  return(package_installed)
}
