#' Get function descriptions
#' 
#' @description get descriptions of exported functions 
#' 
#' @param pkg_name - name of the package
#'
#' @keywords internal
get_func_descriptions <- function(pkg_name){
  db <- tools::Rd_db(pkg_name)
  description <- lapply(db, function(x) {
    tags <- lapply(x, attr, "Rd_tag")
    if ("\\description" %in% tags) {
      out <- paste(unlist(x[which(tags == "\\description")]), collapse = "")
    } else {
      out <- NULL
    }
    invisible(out)
  })
  # Extract function names and use them as names for the descriptions list
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
  description <- description[!sapply(description, is.null)]
  return(description)
}
