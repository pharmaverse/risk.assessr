#' Install package locally
#'
#' @param pkg_source_path - source path for install local
#'
#' @return logical - package_installed 
#' @examples
#' \dontrun{
#' results <- install_package_local("pkg_source_path")
#' print(results)
#' }
#' @export
install_package_local <- function(pkg_source_path) {
  
  pkg_disp <- get_pkg_name(pkg_source_path)
  message(paste0("installing ", pkg_disp, " locally"))
  
  # Check if the package source path exists
  if (!dir.exists(pkg_source_path)) {
    message(paste0("No such file or directory: ", pkg_source_path))
    package_installed <- FALSE
  } else if (requireNamespace(pkg_disp, quietly = TRUE)) {
    message(paste0(pkg_disp, " is already installed"))
    package_installed <- TRUE
  } else {
    package_installed <- tryCatch(
      {
        remotes::install_local(
          pkg_source_path,
          dependencies = TRUE,
          upgrade = "never",
          force = TRUE,
          quiet = TRUE,
          INSTALL_opts = "--with-keep.source"
        )
        message(paste0(pkg_disp, " installed locally"))
        TRUE
      },
      error = function(cond) {
        message(paste0("Local installation issue is: ", cond))
        message(paste0(pkg_disp, " not installed locally"))
        FALSE
      }
    )
  }
  
  return(package_installed)
}
