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
#' @export
#'
#' @examples
#' \donttest{
#' pkg_name <- "foo"
#' res_check <- list(
#'   notes = c("'foo' import not declared from: 'bar'",
#'             "Namespace in Imports field not imported from: 'baz'",
#'             "no visible global function definition for 'qux'",
#'             "some harmless note"),
#'   warnings = character(0),
#'   errors = character(0)
#' )
#' updated <- check_forbidden_notes(res_check, pkg_name)
#' print(updated$errors)  # Should include the first three notes
#' print(updated$notes)   # Should include only the harmless note
#' }
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


#' Run covr and potentially save results to disk
#'
#' @param pkg_source_path package installation directory
#' @param timeout Timeout to pass to [callr::r_safe()] when running covr.
#'
#'
#' @return list with total coverage and function coverage
#' @keywords internal
run_coverage <- function(pkg_source_path, timeout = Inf) {
  
  pkg_name <- basename(pkg_source_path)
  
  message(glue::glue("running code coverage for {pkg_name}"))
  
  # run covr
  res_cov <- tryCatch({
    coverage_list <- run_covr(pkg_source_path, timeout)
    
    # If no testable functions are found in the package, `filecoverage` and `totalcoverage`
    # will yield logical(0) and NaN respectively. Coerce to usable format
    if(is.na(coverage_list$totalcoverage)){
      if(rlang::is_empty(coverage_list$filecoverage) && is.logical(coverage_list$filecoverage)){
        coverage_list$totalcoverage <- 0
        notes <- "no testable functions found"
      }else{
        message(glue::glue("Total coverage returned NaN. This likely means the package had non-standard characteristics."))
        notes <- NA
      }
    }else{
      notes <- NA
    }
    
    list(name = pkg_name, coverage = coverage_list, errors = NA, notes = notes)
  },
  error = function(cond){
    coverage_list <- list(filecoverage = NA, totalcoverage = NA_integer_)
    list(
      name = pkg_name, coverage = coverage_list,
      errors = cond,
      notes = NA
    )
  })
  
  if(is.na(res_cov$coverage$totalcoverage)) {
    message(glue::glue("code coverage for {pkg_name} unsuccessful"))
  } else {
    message(glue::glue("code coverage for {pkg_name} successful"))
  }  
  
  # return total coverage as fraction
  total_cov <- as.numeric(res_cov$coverage$totalcoverage/100)
  
  if(is.na(total_cov)){
    message(glue::glue("R coverage for {pkg_name} failed. Read in the covr output to see what went wrong: "))
  }
  
  if(!is.na(res_cov$notes)){
    message(glue::glue("R coverage for {pkg_name} had notes: {res_cov$notes}"))
  }
  
  covr_list <- list(
    total_cov = total_cov,
    res_cov = res_cov
  )
  return(covr_list)
}

#' Run covr in subprocess with timeout
#'
#' @param path - path to source file
#' @param timeout - length of timeout - set to Inf
#' @keywords internal
run_covr <- function(path, timeout) {
  callr::r_safe(
    function(p) {
      covr::coverage_to_list(covr::package_coverage(p, type = "tests"))
    },
    args = list(path),
    libpath = .libPaths(),
    repos = NULL,
    package = FALSE,
    user_profile = FALSE,
    error = "error",
    timeout = timeout
  )
}


