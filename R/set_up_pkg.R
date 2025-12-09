#' Creates information on package installation
#'
#' @param dp data path and name for the package. 
#' @param check_type basic R CMD check type - "1" CRAN R CMD check_type - "2"
#' 
#' @return list with local package install
#' @examples
#' \dontrun{
#' set_up_pkg(path/to/package, "mypackage")
#' }
#' @export
set_up_pkg <- function(dp, check_type = "1") {
  
  build_vignettes <- TRUE
  
  suppressWarnings(pkg_source_path <- unpack_tarball(dp))
  
  # check for vignettes folder
  bv_result <- contains_vignette_folder(dp)
  
  #set up build vignettes for R CMD check
  if (bv_result == FALSE) {
    build_vignettes <- TRUE
  } else {
    build_vignettes <- FALSE
  }
  
  if (length(pkg_source_path) == 0) {
    package_installed <- FALSE
    results <- ""
    pkg_source_path <- ""
    out_dir <- ""
    build_vignettes <- ""
  } else { 
    if (fs::file_exists(pkg_source_path)) {
      package_installed <- TRUE
    }  
  } 
  
  if (package_installed == TRUE ) {	
    
    rcmdcheck_args <- setup_rcmdcheck_args(check_type, build_vignettes)
  } 
  
  install_list <- list(
    build_vignettes = build_vignettes,
    package_installed = package_installed,
    pkg_source_path = pkg_source_path,
    rcmdcheck_args = rcmdcheck_args
  )
  return(install_list)
}
