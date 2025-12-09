#' Assess package - simplified
#'  
#' @description simplified input to assess package for risk metrics
#' @param path (optional) path of locally stored package source code
#' @return list containing results - list containing metrics, covr, tm - trace matrix, and R CMD check
#' 
#' @examples
#' \dontrun{
#' risk_assess_package <- risk_assess_pkg()
#' 
#' risk_assess_package <- risk_assess_pkg(path/to/package.tar.gz)
#' }
#' @export
risk_assess_pkg <-function(path = NULL) {

  # save and set user's current working directory
  oldwd <- getwd()  
  on.exit(setwd(oldwd))
  
  # get user chosen file
  pkg_source_path <- if (is.null(path)) file.choose() else path
  
  if (!file.exists(pkg_source_path)) {
    warning(paste("The specified path", pkg_source_path, "does not exist. Returning NULL."))
    return(NULL)
  }
  
  # modify DESCRIPTION file
  modified_tar_file <- modify_description_file(pkg_source_path)
  
  # set CRAN repo to enable running of reverse dependencies
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
 
  # Set up the package using the temporary file
  install_list <- set_up_pkg(modified_tar_file)
  
  # Extract information from the installation list
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  # check if the package needs to be installed locally
  package_installed <- install_package_local(pkg_source_path)
  
  # Check if the package was installed successfully
  if (package_installed == TRUE) {
    # Assess the package
    risk_assess_package <- assess_pkg(pkg_source_path, rcmdcheck_args)
    # Output the assessment result
  } else {
    message("Package installation failed.")
  }
  return(risk_assess_package)
} 