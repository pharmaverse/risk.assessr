#' create empty tm
#' 
#' @param pkg_name - name of package
#' @return empty_tm - list with no tm
#'
#'@keywords internal
create_empty_tm <- function(pkg_name) {
  
  coverage <- list(
    filecoverage = 0,
    totalcoverage = 0
  )
  
  empty_tm <- list(
    pkg_name = pkg_name,
    coverage = coverage,
    errors = NA,
    notes = NA
  )
  
  message(glue::glue("traceability matrix for {pkg_name} unsuccessful"))
  return(empty_tm)
}