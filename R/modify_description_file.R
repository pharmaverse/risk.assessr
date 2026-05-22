#' Modify the DESCRIPTION File in a R Package Tarball
#'
#' This function recreate a `.tar.gz` R package file after modifying its `DESCRIPTION` file
#' by appending Config/build/clean-inst-doc: false parameter.
#'
#' @param tar_file A string representing the path to the `.tar.gz` file that contains the R package.
#'
#' @return A string containing the path to the newly created modified `.tar.gz` file,
#'   or the original `tar_file` path unchanged if modification was unnecessary or failed.
#'
#' @examples
#' \dontrun{
#'   modified_tar <- modify_description_file("path/to/mypackage.tar.gz")
#' }
#'
#' @importFrom utils untar tar
#' @export
modify_description_file <- function(tar_file) {
  
  # Default: return the original tarball unchanged.
  # Every failure path leaves `result` as `tar_file`.
  result  <- tar_file
  proceed <- TRUE
  
  # Per-call isolated extraction directory.
  # Critical fix: tempdir() is shared across calls, so any prior run that
  # extracted `pkgname/` into it would cause list.dirs() to pick up the stale
  # directory, writing DESCRIPTION changes to the wrong path.
  # tempfile() guarantees a fresh, empty directory for every call.
  temp_dir <- tempfile("modify_desc_")
  if (!dir.create(temp_dir, recursive = TRUE)) {
    message("Unable to create temp dir; returning original tarball.")
    proceed <- FALSE
  } else {
    on.exit(unlink(temp_dir, recursive = TRUE, force = TRUE), add = TRUE)
    oldwd <- getwd()
    on.exit(setwd(oldwd), add = TRUE)
  }
  
  # --- Extract ---------------------------------------------------------------
  if (proceed) {
    proceed <- tryCatch(
      withCallingHandlers(
        { utils::untar(tar_file, exdir = temp_dir); TRUE },
        warning = function(w) {
          message("untar note: ", conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) {
        message("Error in untarring the file: ", conditionMessage(e))
        FALSE
      }
    )
  }
  
  # --- Discover package directory --------------------------------------------
  package_dir <- NULL
  if (proceed) {
    for (d in list.dirs(temp_dir, full.names = TRUE, recursive = FALSE)) {
      if (file.exists(file.path(d, "DESCRIPTION"))) {
        package_dir <- d
        break
      }
    }
    if (is.null(package_dir)) {
      message("Package directory not found (no DESCRIPTION file found); ",
              "returning original tarball.")
      proceed <- FALSE
    }
  }
  
  # --- Read / modify DESCRIPTION ---------------------------------------------
  if (proceed) {
    desc_path  <- file.path(package_dir, "DESCRIPTION")
    desc_lines <- readLines(desc_path)
    
    if ("Config/build/clean-inst-doc: false" %in% desc_lines) {
      proceed <- FALSE   # already present — no modification needed
    }
  }
  
  if (proceed) {
    # Strip trailing blank lines so the new field is not placed after an empty
    # line, which would create a second DCF record and cause read.dcf() to error.
    while (length(desc_lines) > 0L && !nzchar(trimws(desc_lines[length(desc_lines)]))) {
      desc_lines <- desc_lines[-length(desc_lines)]
    }
    desc_lines <- c(desc_lines, "Config/build/clean-inst-doc: false")
    
    proceed <- tryCatch(
      { writeLines(desc_lines, desc_path); TRUE },
      error = function(e) {
        message("Error writing modified DESCRIPTION: ", conditionMessage(e))
        FALSE
      }
    )
  }
  
  # --- Re-pack ---------------------------------------------------------------
  if (proceed) {
    modified_tar_file <- tempfile(fileext = ".tar.gz")
    setwd(temp_dir)
    tar_ok <- tryCatch(
      withCallingHandlers(
        {
          utils::tar(modified_tar_file, files = basename(package_dir),
                     compression = "gzip", tar = "internal")
          TRUE
        },
        warning = function(w) {
          message("tar note: ", conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) {
        message("Error in creating the tar.gz file: ", conditionMessage(e))
        FALSE
      }
    )
    if (isTRUE(tar_ok)) {
      result <- modified_tar_file
    } else if (file.exists(modified_tar_file)) {
      # tar() may have created a partial file before erroring; modified_tar_file
      # lives in tempdir(), not temp_dir, so the on.exit() above does not catch it.
      unlink(modified_tar_file, force = TRUE)
    }
  }
  
  return(result)
}