#' Check for Vignette Folder and .Rmd Files in a .tar File
#'
#' This function checks if a given .tar file contains a 'vignettes' folder
#' and if there is at least one .Rmd file within that folder. If both 'vignettes'
#' and 'inst/doc' folders exist, the function will return \code{FALSE}.
#'
#' @param package_dir A character string specifying the path to the package to be checked.
#' 
#' @return A logical value: \code{TRUE} if the 'R' folder exists, \code{FALSE} otherwise.
#'
#' @details The function checks if the specified folder exists. If  'R'
#' folder does not exist, the function returns \code{FALSE}. 
#' If the R folder exists, the function returns \code{TRUE}. 
#' @keywords internal
contains_r_folder <- function(package_dir) {
 
  if (fs::dir_exists(fs::path(package_dir, "R"))) {
    r_folder <- TRUE
  } else {
    r_folder <- FALSE
  }
  
  return(r_folder)
}
