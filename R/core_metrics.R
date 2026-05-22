#' Run R CMD CHECK
#'
#' @param pkg_source_path directory path to R project
#' @param rcmdcheck_args list of arguments to pass to `rcmdcheck::rcmdcheck`
#'
#' @details
#' rcmdcheck takes either a tarball or an installation directory.
#'
#' The basename of `pkg_source_path` should be the package name and version pasted together
#'
#' The returned score is calculated via a weighted sum of notes (0.10), warnings (0.25), and errors (1.0). 
#' It has a maximum score of 1 (indicating no errors, notes or warnings)
#' and a minimum score of 0 (equal to 1 error, 4 warnings, or 10 notes). 
#' This scoring methodology is expanded from [riskmetric::metric_score.pkg_metric_r_cmd_check()] by including
#' forbidden notes, 
#' @keywords internal
run_rcmdcheck <- function(pkg_source_path, rcmdcheck_args) {
  
  # We never want the rcmdcheck to fail
  rcmdcheck_args$error_on <- "never"
  
  # run rcmdcheck
  pkg_name <- basename(pkg_source_path)
  
  message(glue::glue("running rcmdcheck for {pkg_name}"))
  
  # Use tryCatch to handle potential errors during rcmdcheck
  res_check <- tryCatch({
    do.call(rcmdcheck::rcmdcheck, rcmdcheck_args)
  }, error = function(e) {
    message(glue::glue("rcmdcheck for {pkg_name} failed to run: {e$message}"))
    return(list(notes = character(0), warnings = character(0), errors = e$message))
  })
  
  
  # Apply forbidden notes check
  res_check <- check_forbidden_notes(res_check, pkg_name)
  
  # Initialize check_score to 0 in case res_check is NULL or calculation fails
  check_score <- 0
  
  # If res_check is not NULL, attempt to calculate the check score
  if (!is.null(res_check)) {
    
    sum_vars <- c(notes = length(res_check$notes), warnings = length(res_check$warnings), errors = length(res_check$errors))
    score_weightings <- c(notes = 0.1, warnings = 0.25, errors = 1)
    check_score <- 1 - min(c(sum(score_weightings * sum_vars), 1))
  }
  
  if(check_score == 1){
    message(glue::glue("rcmdcheck for {pkg_name} passed"))
  }else if(check_score < 1 && check_score > 0){
    message(glue::glue("rcmdcheck for {pkg_name} passed with warnings and/or notes"))
  }else if(check_score == 0){
    message(glue::glue("rcmdcheck for {pkg_name} failed. Read in the rcmdcheck output to see what went wrong: "))
  }
  
  check_list <- list(
    res_check = res_check,
    check_score = check_score
  )
  
  return(check_list)
}

#' Reclassify Forbidden Notes as Errors in rcmdcheck Results
#'
#' This internal helper function scans the `notes` field of an `rcmdcheck` result object
#' for specific patterns that indicate more serious issues. If any of these patterns are found,
#' the corresponding notes are reclassified as errors by moving them from the `notes` field
#' to the `errors` field.
#'
#' @param res_check A list representing the result of an `rcmdcheck` run. It should contain
#'   at least the elements `notes`, `warnings`, and `errors`, each being a character vector.
#' @param pkg_name name of the package   
#'
#' @return A modified version of `res_check` where certain notes matching forbidden patterns
#'   are moved to the `errors` field.
#'
#' @keywords internal
check_forbidden_notes <- function(res_check, pkg_name) {
  if (is.null(res_check$notes) || length(res_check$notes) == 0) {
    message(glue::glue("No forbidden notes for {pkg_name}"))
  } else {
    forbidden_patterns <- c(
      "'.*' import not declared from",
      "Namespace in Imports field not imported from",
      "no visible global .+ definition"
    )
    
    forbidden_matches <- sapply(forbidden_patterns, function(pattern) {
      grepl(pattern, res_check$notes, perl = TRUE)
    })
    
    if (length(res_check$notes) == 1) {
      is_forbidden <- as.logical(forbidden_matches)
    } else {
      is_forbidden <- apply(forbidden_matches, 1, any)
    }
    
    if (any(is_forbidden)) {
      res_check$errors <- c(res_check$errors, res_check$notes[is_forbidden])
      res_check$notes <- res_check$notes[!is_forbidden]
    } else {
      message(glue::glue("No forbidden notes for {pkg_name}"))
    }
  }
  
  return(res_check)
}

