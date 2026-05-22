#' Get Dependencies
#'
#' This function extracts the version information of imported and suggested packages for a given package from the current R session. 
#'
#' @param deps_list A data frame containing the dependency information of the package (provided by calc_dependencies function)
#'
#' @return A list with two elements:
#' \item{imports}{A named list of packages in the "Imports" section along with their corresponding versions }
#' \item{suggests}{A named list of packages in the "Suggests" section along with their corresponding versions }
#'
#' @examples
#' \donttest{
#' deps_list <- data.frame(
#'   package = c("dplyr", "ggplot2", "testthat", "knitr"),
#'   type = c("Imports", "Imports", "Suggests", "Suggests")
#' )
#' get_session_dependencies(deps_list)
#' }
#'
#' @importFrom utils sessionInfo
#' @export
get_session_dependencies <- function(deps_list) {
  
  # Get the session info
  info <- sessionInfo()
  
  deps_list$package <- gsub("\\s*\\([^\\)]+\\)", "", deps_list$package)
  
  # Get packages/version from session
  attached_pkgs <- info$otherPkgs
  loaded_pkgs <- info$loadedOnly
  
  if (is.null(attached_pkgs)) {
    attached_pkgs <- list()
  }
  
  if (is.null(loaded_pkgs)) {
    loaded_pkgs <- list()
  }
  
  all_pkgs <- c(attached_pkgs, loaded_pkgs)
  pkg_list <- sapply(all_pkgs, function(pkg) {
    if (is.list(pkg) && !is.null(pkg$Version)) {
      return(pkg$Version)
    } else {
      return("No package version found")  
    }
  })
  
  
  # Function to extract package versions
  create_pkg_version_list <- function(pkg_names, pkg_list) {
    
    pkg_versions <- lapply(pkg_names, function(pkg) {
      if (pkg %in% names(pkg_list)) {
        return(pkg_list[[pkg]])
      } else {
        return("No package version found")
      }
    })
    
    # Return a named list of package versions
    names(pkg_versions) <- pkg_names
    return(pkg_versions)
  }
  
  # Extract imports and suggests from the deps_list
  imports_pkgs <- deps_list$package[deps_list$type == "Imports"]
  suggests_pkgs <- deps_list$package[deps_list$type == "Suggests"]
  
  # Get the imports and suggests packages along with their versions or None
  imports_data <- create_pkg_version_list(imports_pkgs, pkg_list)
  suggests_data <- create_pkg_version_list(suggests_pkgs, pkg_list)
  
  return(list(
    imports = imports_data,
    suggests = suggests_data
  ))
}




