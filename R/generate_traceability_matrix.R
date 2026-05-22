#' Assess an R Package traceability matrix from package name and version
#'
#' This function use `risk.assessr::create_traceability_matrix` function with only the package name and version
#'
#' @param package_name A character string specifying the name of the package to assess.
#' @param version A character string specifying the version of the package to assess. Default is `NA`, which assesses the latest version.
#' @param repos A character string specifying the repo directly. Default is getOption("repos")
#' @param execute_coverage Logical (`TRUE`/`FALSE`). If `TRUE`, execute test coverage.
#' 
#'
#' @return The function returns package traceability_matrix
#' If the package cannot be downloaded or installed, an error message is returned.
#'
#'
#' @examples
#' \dontrun{
#' 
#' results_no_test_covr <- generate_traceability_matrix(
#'  "here", 
#'  version = "1.0.1", 
#'  execute_coverage = FALSE
#' )
#' 
#' results_test_covr <- generate_traceability_matrix(
#'  "here", 
#'  version = "1.0.1", 
#'  execute_coverage = TRUE
#' )
#' 
#' 
#' print(results_no_test_covr)
#' 
#' print(results_test_covr)
#' }
#' 
#' @importFrom remotes download_version
#' @export
generate_traceability_matrix <- function(package_name, version = NA, repos = getOption("repos"), execute_coverage = FALSE) {

  temp_file <- get_package_tarfile(package_name = package_name, version = version, repos = repos)

  if (is.null(temp_file)) {
    return(NULL)
  }
  
  # Prepare source & installation
  modified_tar_file <- modify_description_file(temp_file)
  install_list <- set_up_pkg(modified_tar_file)
  
  pkg_source_path <- install_list$pkg_source_path
  
  # Install locally
  package_installed <- install_package_local(pkg_source_path)
  
  # Optional coverage
  if (execute_coverage) {
    covr_list <- test.assessr::get_package_coverage(pkg_source_path, package_installed)
  } else {
    covr_list <- NULL
  }
  
  # Build traceability matrix or fail
  if (isTRUE(package_installed)) {
    traceability_matrix <- create_traceability_matrix(
      pkg_name = package_name,
      pkg_source_path = pkg_source_path,
      func_covr = if (is.null(covr_list)) NULL else covr_list$res_cov,
      execute_coverage = execute_coverage
    )
  } else {
    message("Package installation failed.")
    traceability_matrix <- NULL
  }
  
  # Clean up temp tarball
  unlink(temp_file)
  
  return(traceability_matrix)
}