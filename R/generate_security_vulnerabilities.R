#' Assess an R package's security vulnerabilities from package name and version
#'
#' This function retrieves known security vulnerabilities for `pkg_name` and
#' `pkg_ver` from the Open Source Vulnerabilities database.
#'
#' @param pkg_name A character string specifying the name of the package to assess.
#' @param pkg_ver A character string specifying the version of the package to assess. Default is `NULL`, which assesses every known version.
#' @param ecosystem A character string specifying the OSV ecosystem the package belongs to. Default is `"CRAN"`.
#'
#' @return A data frame of known security vulnerabilities for the package, with columns
#' `id`, `summary`, `details`, `introduced`, `fixed`, `modified`, and `published`. An
#' empty data frame with the same columns is returned when there are no known
#' vulnerabilities.
#'
#' @examples
#' \dontrun{
#'
#' results <- generate_security_vulnerabilities(
#'   "commonmark",
#'   pkg_ver = "1.7"
#' )
#'
#' print(results)
#' 
#' results_multi <- c("haven", "commonmark") |>
#'   rlang::set_names() |>
#'   purrr::map(generate_security_vulnerabilities) |>
#'   purrr::list_rbind(names_to = "pkg")
#' 
#'   print(results_multi)
#' }
#'
#' @export
generate_security_vulnerabilities <- function(pkg_name, pkg_ver = NULL, ecosystem = "CRAN") {
  
  checkmate::assert_string(pkg_name, min.chars = 1L)
  checkmate::assert_string(pkg_ver, null.ok = TRUE)
  checkmate::assert_string(ecosystem, min.chars = 1L)
  
  vulnerabilities <- get_security_vulnerabilities(
    pkg_name = pkg_name,
    pkg_ver = pkg_ver,
    ecosystem = ecosystem
  )
  
  return(vulnerabilities)
}
