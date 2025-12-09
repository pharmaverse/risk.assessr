#' Modify the DESCRIPTION File in a R Package Tarball
#'
#' This function recreate a `.tar.gz` R package file after modifying its `DESCRIPTION` file
#' by appending Config/build/clean-inst-doc: false parameter.
#'
#' @param tar_file A string representing the path to the `.tar.gz` file that contains the R package.
#'
#' @return A string containing the path to the newly created modified `.tar.gz` file.
#'
#' @examples
#' \dontrun{
#'   modified_tar <- modify_description_file("path/to/mypackage.tar.gz")
#' }
#'
#' @importFrom utils untar tar
#' @export
modify_description_file <- function(tar_file) {
  
  # Create a temporary directory
  temp_dir <- tempdir()

  # save and set user's current working directory
  oldwd <- getwd()  
  on.exit(setwd(oldwd))
  
  # Extract the tar file into the temporary directory
  tryCatch({
    suppressWarnings({
      untar(tar_file, exdir = temp_dir)
    })
  }, error = function(e) {
    stop("Error in untarring the file: ", e$message)
  })
  
  # Automatically find the package directory by looking for the DESCRIPTION file
  subdirs <- list.dirs(temp_dir, full.names = TRUE, recursive = FALSE)
  
  package_dir <- NULL
  package_name <- NULL
  
  for (dir in subdirs) {
    
    potential_description_file <- file.path(dir, "DESCRIPTION")
    if (file.exists(potential_description_file)) {
      package_dir <- dir
      package_name <- basename(dir)
      break
    }
  }
  
  if (is.null(package_dir)) {
    stop("Package directory not found (no DESCRIPTION file found).")
  }
  
  description_file <- file.path(package_dir, "DESCRIPTION")
  if (!file.exists(description_file)) {
    stop("DESCRIPTION file not found in the extracted package directory.")
  }
  
  # Modify the DESCRIPTION file
  description_content <- readLines(description_file)
  
  if ("Config/build/clean-inst-doc: false" %in% description_content) {
    return(tar_file)
  }
  
  description_content <- c(description_content, "Config/build/clean-inst-doc: false")
  writeLines(description_content, description_file)
  
  # Recreate a new tar.gz file
  modified_tar_file <- tempfile(fileext = ".tar.gz")
  
  # set working directory to temp_dir
  setwd(temp_dir)
  
  tryCatch({
    suppressWarnings({
      tar(modified_tar_file, files = package_name, compression = "gzip", tar = "internal")
    })
  }, error = function(e) {
    setwd(oldwd) 
    stop("Error in creating the tar.gz file: ", e$message)
  })
  
  # # Clean up extracted files in temp_dir
  unlink(package_dir, recursive = TRUE)
  
  return(modified_tar_file)
}
