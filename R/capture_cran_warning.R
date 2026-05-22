#' Capture CRAN URL warnings and errors
#'
#' This internal function attempts to open a CRAN URL and read its contents.
#' It captures and classifies warnings and errors related to network issues,
#' such as timeouts or inaccessible URLs.
#'
#' @param cran_url Character. Base URL of the CRAN mirror.
#' @param path Character. Path to the resource on the CRAN server.
#'
#' @return A list with two elements:
#' \describe{
#'   \item{status}{Character string indicating the result type: "success", "url_error", "timeout", "error", "url_warning", "timeout_warning", or "warning".}
#'   \item{message}{Character string with the captured warning or error message, or NULL if successful.}
#' }
#'
#' @keywords internal
#' @examples
#' \dontrun{
#'   capture_cran_warning("http://cran.us.r-project.org", "src/contrib/Meta/archive.rds")
#' }
capture_cran_warning <- function(cran_url, path) {
  full_url <- sprintf("%s/%s", cran_url, path)
  result <- tryCatch({
    con <- url(full_url, open = "rb")
    on.exit(close(con), add = TRUE)
    readBin(con, "raw", n = 1e6)
    list(status = "success", message = NULL)
  }, error = function(e) {
    msg <- conditionMessage(e)
    if (grepl("cannot open URL", msg)) {
      return(list(status = "url_error", message = msg))
    } else if (grepl("504 Gateway Timeout", msg)) {
      return(list(status = "timeout", message = msg))
    } else {
      return(list(status = "error", message = msg))
    }
  }, warning = function(w) {
    msg <- conditionMessage(w)
    if (grepl("cannot open URL", msg)) {
      return(list(status = "url_warning", message = msg))
    } else if (grepl("504 Gateway Timeout", msg)) {
      return(list(status = "timeout_warning", message = msg))
    } else {
      return(list(status = "warning", message = msg))
    }
  })
  return(result)
}