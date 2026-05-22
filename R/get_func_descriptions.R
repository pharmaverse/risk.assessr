#' Get function descriptions
#' 
#' @description get descriptions of exported functions 
#' 
#' @param pkg_name - name of the package
#'
#' @keywords internal
get_func_descriptions <- function(pkg_name) {
  
  # Try loading Rd database
  db <- tryCatch(
    tools::Rd_db(pkg_name),
    error = function(e) {
      message(glue::glue("tools::Rd_db() failed for '{pkg_name}': {e$message}"))
      return(NULL)
    }
  )
  
  # If Rd_db failed, try alternative method
  if (is.null(db)) {
    pkg_path <- find.package(pkg_name, quiet = TRUE)
    man_path <- file.path(pkg_path, "man")
    rd_files <- list.files(man_path, pattern = "\\.Rd$", full.names = TRUE)
    
    db <- lapply(rd_files, function(f) {
      tryCatch(
        tools::parse_Rd(f),
        error = function(e) {
          message(glue::glue("Failed to parse {basename(f)}: {e$message}"))
          return(NULL)
        }
      )
    })
    db <- db[!sapply(db, is.null)]
  }
  
  # Extract descriptions
  description <- lapply(db, function(x) {
    tags <- lapply(x, attr, "Rd_tag")
    if ("\\description" %in% tags) {
      out <- paste(unlist(x[which(tags == "\\description")]), collapse = "")
    } else {
      out <- NULL
    }
    invisible(out)
  })
  
  # Extract names
  names(description) <- sapply(db, function(x) {
    tags <- lapply(x, attr, "Rd_tag")
    if ("\\name" %in% tags) {
      name <- unlist(x[which(tags == "\\name")])
      name <- gsub("\n", "", name)
      return(name)
    } else {
      return(NULL)
    }
  })
  
  # Filter out NULLs
  description <- description[!sapply(description, is.null)]
  
  return(description)
}

    
