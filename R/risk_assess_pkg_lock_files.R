#' Process lock files 
#'
#' @description This function processes `renv.lock` and `pak.lock` files 
#' to produce risk metric data
#' 
#' @param input_data - path to a lock file
#'
#' @return assessment_results - nested list containing risk metric data
#'
#' @importFrom stats setNames
#'
#' @examples
#' \dontrun{
#'   input_data <- ("path/to/mypak.lock")
#'   pak_results <- risk_assess_pkg_lock_files(input_data) 
#'   print(pak_results)
#'  } 
#' @export
risk_assess_pkg_lock_files <- function(input_data) {
  
  message("Starting lock file processing")
  
  # Input checking
  checkmate::assert_string(input_data)
  checkmate::assert_file_exists(input_data,
                                extension = ".lock",
                                access = "r")
  
  # Read the lock file
  lockfile <- fromJSON(input_data)
  
  # Determine the type of lock file and extract package information
  if ("Packages" %in% names(lockfile)) {
    # Process a renv.lock file
    packages <- lockfile$Packages
    is_pak_lock <- FALSE
  } else if ("packages" %in% names(lockfile)) {
    # Process a pak.lock file
    packages <- lockfile$packages
    is_pak_lock <- TRUE
  } else {
    stop("Unsupported lock file format.")
  }
  
  # Function to process each package
  process_package <- function(pkg_info) {
    
    if (is_pak_lock == TRUE) {    
      pkg_name <- pkg_info$package
      pkg_version <- pkg_info$version
    } else {
      pkg_name <- pkg_info$Package
      pkg_version <- pkg_info$Version
    }  
    
    risk_assess_package <- risk.assessr::assess_pkg_r_package(pkg_name, pkg_version)
    return(list(name = pkg_name, version = pkg_version, result = risk_assess_package))
  }
  

  # Apply the process_package function to each package
  if (is.data.frame(packages)) {
    results <- lapply(seq_len(nrow(packages)), function(i) process_package(packages[i, ]))
  } else {
    results <- lapply(packages, process_package)
  }
  
  # Filter out NULL results and create a named list
  assessment_results <- setNames(lapply(results, `[[`, "result"), 
                                 sapply(results, function(x) paste(x$name, x$version, sep = "_")))
  
  message("Finishing lock file processing")
  
  return(assessment_results)
}