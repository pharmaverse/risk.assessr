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
#' @param pkg_ver Character. Optional package version. The OSV database is
#'   queried for every advisory affecting the package, and when a version is
#'   supplied only the advisories affecting that version are kept (filtered
#'   locally against each advisory's affected versions and ranges).
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
  
  # Query OSV by package only (no version). A version-scoped OSV query returns
  # an empty `{}` object whenever the supplied version is not enumerated in an
  # advisory, which parses to a `named list()` with no `vulns` element even
  # though the package has known advisories. Retrieving every advisory for the
  # package and filtering by version below avoids that gap.
  parsed <- fetch_osv_data(pkg_name, ecosystem = ecosystem)
  
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
  
  # decide whether the requested version falls within an advisory's affected
  # set, using the explicit `versions` enumeration first and the
  # introduced/fixed ranges otherwise. Advisories with no affected metadata are
  # kept, as their applicability to the version cannot be ruled out.
  version_is_affected <- function(vuln) {
    if (is.null(pkg_ver) || is.na(pkg_ver) || !nzchar(pkg_ver)) return(TRUE)
    affected <- vuln$affected
    if (is.null(affected) || length(affected) == 0) return(TRUE)
    
    ver <- tryCatch(numeric_version(pkg_ver), error = function(e) NULL)
    
    for (a in affected) {
      # `versions` may arrive either as an array of version strings (live OSV
      # query API) or as an object keyed by version (aggregated advisory feed).
      # The array form supplies the values, the object form the names; combining
      # both handles either source.
      enumerated <- c(unlist(a$versions, use.names = FALSE), names(a$versions))
      if (length(enumerated) && pkg_ver %in% enumerated) return(TRUE)
      
      for (r in a$ranges) {
        introduced <- NA_character_
        fixed      <- NA_character_
        for (e in r$events) {
          if (!is.null(e$introduced)) introduced <- as.character(e$introduced)
          if (!is.null(e$fixed))      fixed      <- as.character(e$fixed)
        }
        if (is.null(ver)) next
        
        intro_ver <- tryCatch(numeric_version(introduced),
                              error = function(e) NULL)
        fixed_ver <- tryCatch(numeric_version(fixed),
                              error = function(e) NULL)
        intro_ok <- is.na(introduced) || is.null(intro_ver) || ver >= intro_ver
        fixed_ok <- is.na(fixed) || is.null(fixed_ver) || ver < fixed_ver
        if (intro_ok && fixed_ok) return(TRUE)
      }
    }
    FALSE
  }
  
  vulns <- Filter(version_is_affected, parsed$vulns)
  
  if (length(vulns) == 0) {
    message("No known security vulnerabilities found for ", pkg_name,
            if (!is.null(pkg_ver) && !is.na(pkg_ver) && nzchar(pkg_ver)) {
              paste0(" ", pkg_ver)
            } else {
              ""
            }, ".")
    return(empty_vulns)
  }
  
  pick <- function(x) if (is.null(x)) NA_character_ else as.character(x)
  
  rows <- lapply(vulns, function(vuln) {
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
