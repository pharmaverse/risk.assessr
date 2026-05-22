#' Extract risk thresholds by id
#'
#' @param risk_rule - list containing all risk rules
#' @param id_value - character vector containing risk rule choice
#'
#' @return list containing specific risk rules
#' @export
extract_thresholds_by_id <- function(risk_rule, id_value) {
  idx <- which(vapply(risk_rule, function(x) x$id == id_value, logical(1)))
  if (length(idx) == 1) {
    return(risk_rule[[idx]]$thresholds)
  }
  return(NULL)
}

#' Extract risk thresholds by key
#'
#' @param risk_rule - list containing all risk rules
#' @param key_value - character vector containing risk rule choice
#'
#' @return list containing specific risk rules
#' @export
extract_thresholds_by_key <- function(risk_rule, key_value) {
  idx <- which(vapply(risk_rule, function(x) x$key == key_value, logical(1)))
  if (length(idx) == 1) {
    return(risk_rule[[idx]]$thresholds)
  }
  return(NULL)
}
