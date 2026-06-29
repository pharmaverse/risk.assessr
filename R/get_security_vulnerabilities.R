#' Retrieve raw vulnerability data from the OSV API
#'
#' Sub-function that queries the Open Source Vulnerabilities (OSV) database
#' (\url{https://osv.dev/#use-the-api}) for a single package using `curl`.
#' The query is sent as a POST request to the OSV `query` endpoint. All network
#' and parsing steps are wrapped in `tryCatch` so that an unavailable API or a
#' request time-out reports a message and returns `NULL` rather than stopping
#' the calling function.
#'
#' @param pkg_name Character. Name of the package to query.
#' @param pkg_ver Character. Optional package version. When supplied, OSV only
#'   returns vulnerabilities affecting that version.
#' @param ecosystem Character. OSV ecosystem the package belongs to. Defaults to
#'   `"CRAN"`.
#' @param timeout Numeric. Maximum number of seconds to wait for the request.
#'   Defaults to 30.
#'
#' @return A list parsed from the OSV JSON response (with a `vulns` element when
#'   vulnerabilities are found), or `NULL` if the API is unavailable, times out,
#'   or returns an error status.
#'
#' @examples
#' \dontrun{
#' fetch_osv_data("commonmark", ecosystem = "CRAN")
#' }
#'
#' @importFrom curl curl_fetch_memory new_handle handle_setheaders handle_setopt
#' @importFrom jsonlite toJSON fromJSON
#' @keywords internal
fetch_osv_data <- function(pkg_name, pkg_ver = NULL, ecosystem = "CRAN",
                           timeout = 30) {
  url <- "https://api.osv.dev/v1/query"
  
  # build the OSV query body; include the version only when it is available
  pkg <- list(name = pkg_name, ecosystem = ecosystem)
  if (!is.null(pkg_ver) && !is.na(pkg_ver) && nzchar(pkg_ver)) {
    body <- list(version = pkg_ver, package = pkg)
  } else {
    body <- list(package = pkg)
  }
  body_json <- jsonlite::toJSON(body, auto_unbox = TRUE)
  
  handle <- curl::new_handle(connecttimeout = 10, timeout = timeout)
  curl::handle_setheaders(handle, "Content-Type" = "application/json")
  curl::handle_setopt(handle, post = TRUE, postfields = body_json)
  
  resp <- tryCatch(
    curl::curl_fetch_memory(url, handle = handle),
    error = function(e) {
      message("Failed to reach OSV API: ", conditionMessage(e))
      NULL
    }
  )
  
  if (is.null(resp)) return(NULL)
  
  if (resp$status_code != 200) {
    message("OSV API returned status ", resp$status_code, ".")
    return(NULL)
  }
  
  parsed <- tryCatch(
    jsonlite::fromJSON(rawToChar(resp$content), simplifyVector = FALSE),
    error = function(e) {
      message("Failed to parse OSV response: ", conditionMessage(e))
      NULL
    }
  )
  
  return(parsed)
}

#' Get security vulnerabilities for a package
#'
#' Retrieves known security vulnerabilities for a package from the Open Source
#' Vulnerabilities (OSV) database (\url{https://osv.dev/#use-the-api}) and
#' returns them as a data frame. Data retrieval is delegated to
#' [fetch_osv_data()], which handles an unavailable API or request time-out
#' gracefully (reporting a message and returning no data instead of stopping).
#'
#' Each vulnerability is reported with its type via the `summary` field (for
#' example `"Denial of Service (DoS) vulnerability"`,
#' `"Arbitrary Code Execution (ACE) Vulnerability"`,
#' `"NULL pointer dereference vulnerability"`, or
#' `"Cross-site Request Forgery (CSRF) vulnerability"`) and a fuller description
#' in `details`.
#'
#' @param pkg_name Character. Name of the package to query.
#' @param pkg_ver Character. Optional package version. When supplied, only
#'   vulnerabilities affecting that version are returned.
#' @param ecosystem Character. OSV ecosystem the package belongs to. Defaults to
#'   `"CRAN"`.
#'
#' @return A data frame with one row per vulnerability and the columns:
#' \describe{
#'   \item{id}{OSV / advisory identifier (e.g. `"RSEC-2023-6"`).}
#'   \item{summary}{Short description of the vulnerability type.}
#'   \item{details}{Detailed description of the vulnerability.}
#'   \item{introduced}{Version in which the vulnerability was introduced.}
#'   \item{fixed}{Version in which the vulnerability was fixed.}
#'   \item{modified}{Timestamp the advisory was last modified.}
#'   \item{published}{Timestamp the advisory was published.}
#' }
#' An empty data frame (zero rows, same columns) is returned when there are no
#' known vulnerabilities or when the API could not be reached.
#'
#' @examples
#' \dontrun{
#' get_security_vulnerabilities("commonmark", "1.7", ecosystem = "CRAN")
#' }
#'
#' @export
get_security_vulnerabilities <- function(pkg_name, pkg_ver = NULL,
                                         ecosystem = "CRAN") {
  message(paste0("Checking security vulnerabilities for ", pkg_name, "..."))
  
  empty_vulns <- data.frame(
    id         = character(0),
    summary    = character(0),
    details    = character(0),
    introduced = character(0),
    fixed      = character(0),
    modified   = character(0),
    published  = character(0),
    stringsAsFactors = FALSE
  )
  
  if (is.null(pkg_name) || is.na(pkg_name) || !nzchar(pkg_name)) {
    message("Package name is NA or empty. Returning no vulnerabilities.")
    return(empty_vulns)
  }
  
  parsed <- fetch_osv_data(pkg_name, pkg_ver, ecosystem)
  
  if (is.null(parsed) || is.null(parsed$vulns) || length(parsed$vulns) == 0) {
    message("No known security vulnerabilities found for ", pkg_name, ".")
    return(empty_vulns)
  }
  
  # pull the first non-NULL "introduced"/"fixed" value out of the nested
  # affected -> ranges -> events structure of an OSV record
  get_event_version <- function(vuln, field) {
    affected <- vuln$affected
    if (is.null(affected)) return(NA_character_)
    for (a in affected) {
      for (r in a$ranges) {
        for (e in r$events) {
          if (!is.null(e[[field]])) return(as.character(e[[field]]))
        }
      }
    }
    NA_character_
  }
  
  pick <- function(x) if (is.null(x)) NA_character_ else as.character(x)
  
  rows <- lapply(parsed$vulns, function(vuln) {
    data.frame(
      id         = pick(vuln$id),
      summary    = pick(vuln$summary),
      details    = pick(vuln$details),
      introduced = get_event_version(vuln, "introduced"),
      fixed      = get_event_version(vuln, "fixed"),
      modified   = pick(vuln$modified),
      published  = pick(vuln$published),
      stringsAsFactors = FALSE
    )
  })
  
  vulnerabilities <- do.call(rbind, rows)
  
  return(vulnerabilities)
}
