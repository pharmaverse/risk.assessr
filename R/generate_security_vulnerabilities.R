#' Assess an R package's security vulnerabilities from package name and version
#'
#' This standalone function retrieves known security vulnerabilities for `pkg_name` and
#' `pkg_ver` from the Open Source Vulnerabilities database.
#'
#' @param pkg_name A character string specifying the name of the package to assess.
#' @param pkg_ver A character string specifying the version of the package to assess. Default is `NULL`, which assesses every known version.
#' @param ecosystem A character string specifying the OSV ecosystem the package belongs to. Default is `"CRAN"`.
#' 
#' @details See the `security vulnerabilities` vignette for more details on the ecosystems
#' 
#' @return A list of known security vulnerabilities for the package, with columns
#' `pkg_name`, `pkg_ver`, `ecosystem`, `id`, `summary`, `details`, `introduced`, 
#' `fixed`, `modified`, and `published`. An
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
#'   purrr::map(\(x) {
#'     res <- generate_security_vulnerabilities(x)
#'     
#'     # 1. Convert NULL to NA so it has a valid size of 1
#'     if (is.null(res$pkg_ver)) res$pkg_ver <- NA_character_
#'     
#'     # 2. Explicitly wrap the vulnerabilities object in a list to form a list-column
#'     res$vulnerabilities <- list(res$vulnerabilities)
#'     
#'     tibble::as_tibble_row(res)
#'   }) |>
#'   purrr::list_rbind(names_to = "pkg")
#' 
#' print(results_multi)
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
  result <- list(
    pkg_name = pkg_name,
    pkg_ver = pkg_ver,
    ecosystem = ecosystem,
    vulnerabilities = vulnerabilities
  )
  
  return(result)
}
