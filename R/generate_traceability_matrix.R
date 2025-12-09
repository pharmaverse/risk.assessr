#' Assess an R Package traceability matrix from package name and version
#'
#' This function use `risk.assessr::create_traceability_matrix` function with only the package name and version
#'
#' @param package_name A character string specifying the name of the package to assess.
#' @param version A character string specifying the version of the package to assess. Default is `NA`, which assesses the latest version.
#' @param repos A character string specifying the repo directly. Default is NULL, which uses the mirrors
#' @param execute_coverage Logical (`TRUE`/`FALSE`). If `TRUE`, execute test coverage.
#' 
#'
#' @return The function returns package traceability_matrix
#' If the package cannot be downloaded or installed, an error message is returned.
#'
#'
#' @examples
#' \dontrun{
#' r <- getOption("repos")
#' # save current repo options  
#' old <- options(repos = r)
#' r["CRAN"] = "http://cran.us.r-project.org"
#' options(repos = r)#' 
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
#' # restore user's repo options
#' options(old)
#' 
#' print(results_no_test_covr)
#' 
#' print(results_test_covr)
#' }
#' 
#' @importFrom remotes download_version
#' @export
generate_traceability_matrix <- function(package_name, version=NA, repos = NULL, execute_coverage = FALSE) {
  
  # Save current repo options
  old_repos <- getOption("repos")
  
  if (!is.null(repos)) {
    repo_to_use <- repos
  } else {
    repo_to_use <- getOption("repos")
  }
  
  options(repos = repo_to_use)
  
  download_successful <- FALSE
  message(paste("Checking", package_name, "on CRAN..."))
  
  temp_file <- NULL
  
  # Try CRAN first
  if (check_cran_package(package_name)) {
    tryCatch({
      temp_file <- remotes::download_version(package = package_name, version = version)
      download_successful <- TRUE
    }, error = function(e) {
      message(paste("CRAN download failed:", e$message))
    })
  }
  
  # If not successful on CRAN, try Bioconductor
  if (!download_successful) {
    message(paste("Checking", package_name, "on Bioconductor..."))
    
    html_content <- fetch_bioconductor_releases()
    release_data <- parse_bioconductor_releases(html_content)
    result_bio <- get_bioconductor_package_url(package_name, version, release_data)
    
    if (!is.null(result_bio$url)) {
      temp_file <- tempfile()
      tryCatch({
        download.file(url = result_bio$url, destfile = temp_file, mode = "wb")
        download_successful <- TRUE
      }, error = function(e) {
        message(paste("Bioconductor download failed:", e$message))
      })
    } else {
      message(paste("No", package_name, "package found on Bioconductor"))
    }
  }
  
  # Final fallback: attempt internal mirror
  if (!download_successful) {
    message(paste("Attempting internal fallback download for", package_name))
    tryCatch({
      temp_file <- remotes::download_version(package = package_name, version = version)
    }, error = function(e) {
      message(paste("Failed to download the package from any source. Error:", e$message), call. = FALSE)
    })
  }
  
  if (is.null(temp_file)) {
    return(NULL)
  }
  
  # If no error, proceed with the package tarball
  modified_tar_file <- modify_description_file(temp_file)
  
  # Set up the package using the temporary file
  install_list <- set_up_pkg(modified_tar_file)
  
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  
  # Check if the package needs to be installed locally
  package_installed <- install_package_local(pkg_source_path)
  
  
  if (execute_coverage) {
    test_pkg_data <- check_pkg_tests_and_snaps(pkg_source_path)
    covr_timeout <- Inf
    
    if (test_pkg_data$has_testthat || test_pkg_data$has_testit) {
      covr_list <- run_coverage(
        pkg_source_path,
        covr_timeout
      )
    } else {
      message("No testthat or testit configuration")
      covr_list <- NULL
    }  
  } else {
    covr_list <- NULL
  }
  
  # Check if the package was installed successfully
  if (package_installed == TRUE) {
    
    traceability_matrix <- create_traceability_matrix(
      pkg_name = package_name,
      pkg_source_path = pkg_source_path,
      func_covr = covr_list$res_cov,
      execute_coverage = execute_coverage
    )
    
  } else {
    message("Package installation failed.")
    traceability_matrix <- NULL
  }
  
  unlink(temp_file)
  
  if (!identical(getOption("repos"), old_repos)) {
    options(repos = old_repos)
  }
  
  return(traceability_matrix)
}