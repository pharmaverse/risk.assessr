#' Generate HTML Report for Package Assessment
#'
#' @description Generates an HTML report for the package assessment results using rmarkdown.
#'
#' @param assessment_results List containing the results from risk_assess_pkg function.
#' @param output_dir Character string indicating the directory where the report will be saved. 
#'
#' @return Path to the generated HTML report.
#'
#' @examples
#' \dontrun{
#' assessment_results <- risk_assess_pkg()
#' generate_html_report(assessment_results, output_dir = "path/to/save/report")
#' }
#' @importFrom rmarkdown render
#' @importFrom fs dir_exists
#' @importFrom fs path_abs
#' @export
generate_html_report <- function(assessment_results, output_dir = NULL) {
  
  # Check if rmarkdown is available
  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    message("Package 'rmarkdown' is required but not installed.")
    return(NULL)
  }
  
  # check input
  checkmate::assert_list(assessment_results, names = "named", any.missing = TRUE)
  checkmate::assert_list(assessment_results$results, names = "named", any.missing = TRUE)
  
  # If output_dir is not set, use the current working directory
  if (is.null(output_dir)) {
    output_dir <- getwd()
    message(glue::glue("No output directory specified. Setting output to {output_dir}"))
  }
  
  # Create the risk summary data
  risk_summary_output <- generate_risk_summary(assessment_results)
  
  # Create the risk summary data
  risk_details_output <- generate_risk_details(assessment_results)
  
  # Capture the output of generate_rcmd_check_section
  rcmd_check_output <- generate_rcmd_check_section(assessment_results)
  
  # Capture the output of generate_coverage_section
  coverage_output <- generate_coverage_section(assessment_results)
  
  # Capture the output of generate_doc_metrics_section
  doc_metrics_output <- generate_doc_metrics_section(assessment_results)
  
  # Capture the output of generate_pop_metrics_section
  pop_metrics_output <- generate_pop_metrics_section(assessment_results) 
  
  # Capture the output of generate_deps_section
  deps_output <- generate_deps_section(assessment_results)
  
  # Capture the output of generate_rev_deps_section
  rev_deps_output <- generate_rev_deps_section(assessment_results)
  
  # set up data for checking if trace_matrix is empty
  total_coverage <- assessment_results$covr_list$res_cov$coverage$totalcoverage
  file_coverage <- assessment_results$covr_list$res_cov$coverage$filecoverage
  
  # create general traceability matrix
  general_tm <- assessment_results$tm_list$tm
  
  # Capture the output of generate_trace_matrix_section
  trace_matrix_output <- 
    generate_trace_matrix_section(total_coverage, file_coverage, general_tm)
  
  # create high risk traceability matrix
  high_risk_tm <- assessment_results$tm_list$coverage$high_risk
  if (!is.data.frame(high_risk_tm)) {
    high_risk_tm <- dplyr::tibble(high_risk_tm)
  }
  
  high_risk_matrix_output <- 
    generate_fg_trace_matrix_section(tm_type = "High Risk", high_risk_tm)
  
  
  # create medium risk traceability matrix
  medium_risk_tm <- assessment_results$tm_list$coverage$medium_risk
  if (!is.data.frame(medium_risk_tm)) {
    medium_risk_tm <- dplyr::tibble(medium_risk_tm)
  }
  
  medium_risk_matrix_output <- 
    generate_fg_trace_matrix_section(tm_type = "Medium Risk", medium_risk_tm)
  
  # create low risk traceability matrix
  low_risk_tm <- assessment_results$tm_list$coverage$low_risk
  if (!is.data.frame(low_risk_tm)) {
    low_risk_tm <- dplyr::tibble(low_risk_tm)
  }
  
  low_risk_matrix_output <- 
    generate_fg_trace_matrix_section(tm_type = "Low Risk", low_risk_tm)
  
  # create defunct function traceability matrix
  defunct_func_tm <- assessment_results$tm_list$function_type$defunct
  if (!is.data.frame(defunct_func_tm)) {
    defunct_func_tm <- dplyr::tibble(defunct_func_tm)
  }
  
  defunct_func_matrix_output <- 
    generate_fg_trace_matrix_section(tm_type = "Defunct Functions", defunct_func_tm)
  
  # create imported function traceability matrix
  imported_func_tm <- assessment_results$tm_list$function_type$imported
  if (!is.data.frame(imported_func_tm)) {
    imported_func_tm <- dplyr::tibble(imported_func_tm)
  }
  
  imported_func_matrix_output <- 
    generate_fg_trace_matrix_section(tm_type = "Imported Functions", imported_func_tm)
  
  # create re-exported function traceability matrix
  reexported_func_tm <- assessment_results$tm_list$function_type$rexported
  if (!is.data.frame(reexported_func_tm)) {
    reexported_func_tm <- dplyr::tibble(reexported_func_tm)
  }
  
  reexported_func_matrix_output <- 
    generate_fg_trace_matrix_section(tm_type = "Re-exported Functions", reexported_func_tm)
  
  # create experimental function traceability matrix
  experimental_func_tm <- assessment_results$tm_list$function_type$experimental
  if (!is.data.frame(experimental_func_tm)) {
    experimental_func_tm <- dplyr::tibble(experimental_func_tm)
  }
  
  experimental_func_matrix_output <- 
    generate_fg_trace_matrix_section(tm_type = "Experimental Functions", experimental_func_tm)
  
  # get risk rules and create thresholds for sections 
  risk_rules <- get_risk_definition()
  code_covr_thresholds <- extract_thresholds_by_id(risk_rules, "code_coverage")
  code_covr_maxes <- get_max_thresholds(code_covr_thresholds)
  
  cmd_check_thresholds <- extract_thresholds_by_id(risk_rules, "cmd-check")
  cmd_check_maxes <- get_max_thresholds(cmd_check_thresholds)
  
  dep_thresholds <- extract_thresholds_by_id(risk_rules, "dependencies_count")
  dep_maxes <- get_max_thresholds(dep_thresholds)
  
  revdep_thresholds <- extract_thresholds_by_id(risk_rules, "reverse_dependencies")
  revdep_maxes <- get_max_thresholds(revdep_thresholds)
  
  pop_thresholds <- extract_thresholds_by_key(risk_rules, "total_download")
  pop_maxes <- get_max_thresholds(pop_thresholds)
  
  license_thresholds <- extract_thresholds_by_id(risk_rules, "license")
  license_maxes <- get_license_thresholds(license_thresholds)
  
  # Create a file name with pkg_name,version, and "risk_assessment.html"
  pkg_name <- assessment_results$results$pkg_name
  pkg_version <- assessment_results$results$pkg_version
  date_time <- assessment_results$results$date_time
  
  # set up report environment
  report_env <- new.env()
  report_env$pkg_name <- pkg_name
  report_env$pkg_version <- pkg_version
  report_env$risk_summary_output <- risk_summary_output
  report_env$risk_details_output <- risk_details_output
  report_env$rcmd_check_output  <- rcmd_check_output
  report_env$coverage_output  <- coverage_output
  report_env$doc_metrics_output  <- doc_metrics_output
  report_env$pop_metrics_output  <- pop_metrics_output
  report_env$deps_df  <- deps_output$deps_df
  report_env$dep_score <- deps_output$dep_score
  report_env$import_count  <- deps_output$import_count
  report_env$suggest_count <- deps_output$suggest_count
  report_env$rev_deps_df  <- rev_deps_output$rev_deps_df
  report_env$rev_deps_summary$rev_deps_no <- rev_deps_output$rev_deps_summary$rev_deps_no
  report_env$rev_deps_summary$rev_deps_score <- rev_deps_output$rev_deps_summary$rev_deps_score
  report_env$trace_matrix_output  <- trace_matrix_output
  report_env$high_risk_matrix_output  <- high_risk_matrix_output
  report_env$medium_risk_matrix_output  <- medium_risk_matrix_output
  report_env$low_risk_matrix_output  <- low_risk_matrix_output
  report_env$defunct_func_matrix_output  <- defunct_func_matrix_output
  report_env$imported_func_matrix_output  <- imported_func_matrix_output
  report_env$reexported_func_matrix_output <- reexported_func_matrix_output
  report_env$experimental_func_matrix_output <- experimental_func_matrix_output
  report_env$code_covr_maxes <- code_covr_maxes
  report_env$cmd_check_maxes <- cmd_check_maxes
  report_env$dep_maxes <- dep_maxes
  report_env$revdep_maxes <- revdep_maxes
  report_env$pop_maxes <- pop_maxes
  report_env$license_maxes <- license_maxes
  
  
  if (dir_exists(output_dir)) {
    
    output_file <- path_abs(
      glue::glue("risk_report_{pkg_name}_{pkg_version}.html"),
      start = output_dir
    )
    
    template_path <- system.file(
      "report_templates",
      "risk_report_template.Rmd",
      package = "risk.assessr"
    )
    
    # Render the R Markdown file to the output directory
    # CRAN-safe: skip rendering on CRAN, avoid viewer launch
    if (identical(Sys.getenv("NOT_CRAN"), "true") || interactive()) {
      if (requireNamespace("rmarkdown", quietly = TRUE)) {
        message(paste0("Rendering report for ", pkg_name))
        render(
          input = template_path,
          output_file = output_file,
          envir = report_env,
          quiet = TRUE
        )
      } else {
        message("Package 'rmarkdown' is required but not installed.")
        return(NULL)
      }
    } else {
      message("Rendering skipped on CRAN or non-interactive environment.")
      return(NULL)
    }
    
  } else {
    message("The output directory does not exist.")
    return(NULL)
  }
  
  return(output_file)
}

#' Helper function to replace NULL with "N/A"
#'
#' @param x - input value
#'
#' @keywords internal
handle_null <- function(x) {
  if (is.null(x)) {
    return("N/A")
  } else {
    return(x)
  }
}

#' Convert number to abbreviation
#'
#' @param value 
#'
#' @keywords internal
convert_number_to_abbreviation <- function(value) {
  result <- NA
  
  if (!is.na(value) && is.numeric(value)) {
    abs_value <- abs(value)
    
    if (abs_value >= 1e6) {
      result <- paste0(round(value / 1e6, 1), "M")
    } else if (abs_value >= 1e3) {
      result <- paste0(round(value / 1e3, 1), "K")
    } else {
      result <- as.character(value)
    }
  }
  
  return(result)
}

#' Convert number to percent
#'
#' @param value 
#'
#' @keywords internal
convert_number_to_percent <- function(value) {
  result <- NA
  
  if (!is.na(value) && is.numeric(value)) {
    percent_value <- round(value * 100, 1)
    result <- paste0(percent_value, "%")
  }
  
  return(result)
}

#' Helper to conditionally apply handle_null or abbreviation
#'
#' @param x - value
#'
#' @keywords internal
safe_value <- function(x) {
  if (is.null(x)) {
    return(handle_null(x))
  } else {
    return(convert_number_to_abbreviation(x))
  }
}

#' Helper to create maintainer
#'
#' @param person_obj - value
#'
#' @keywords internal
extract_maintainer_info <- function(person_obj) {
  # Access the first person in the list
  
  p <- person_obj[[1]]
  
  # Extract fields
  given <- p$given
  family <- p$family
  email <- p$email
  
  # Combine into a single string
  pkg_maintainer <- paste(given, family, "<", email, ">", sep = " ")
  return(pkg_maintainer)
}

#' Extract Maximum Thresholds for Code Coverage Levels
#'
#' This internal function retrieves the `max` values for `"high"`,`"medium"`, and `"low"` levels
#' from a list of code coverage thresholds.
#'
#' @param thresholds A list of threshold objects, each containing a `level` and `max` field.
#'
#' @return A list with three elements:
#' \describe{
#'   \item{high_max}{The maximum threshold value for the `"high"` level.}
#'   \item{medium_max}{The maximum threshold value for the `"medium"` level.}
#'   \item{medium_max}{The maximum threshold value for the `"low"` level.}
#' }
#'
#' @keywords internal
get_max_thresholds <- function(thresholds) {
  high_max <- {{thresholds}}[[which(vapply({{thresholds}}, function(x) x$level == "high", logical(1)))]]$max
  medium_max <- {{thresholds}}[[which(vapply({{thresholds}}, function(x) x$level == "medium", logical(1)))]]$max
  low_max <- {{thresholds}}[[which(vapply({{thresholds}}, function(x) x$level == "low", logical(1)))]]$max
  
  list(high_max = high_max, 
       medium_max = medium_max, 
       low_max = low_max)
}

#' Get License Levels from Thresholds
#'
#' This internal utility function processes a list of license thresholds and returns
#' a named list of license values grouped by their risk level (e.g., "high", "medium", "low").
#'
#' @param thresholds A list where each element contains a `level` (character) and `values` (list of character vectors).
#'
#' @return A named list with elements `"high"`, `"medium"`, and `"low"`, each containing a character vector of license names.
#'
#' @keywords internal
get_license_thresholds <- function(thresholds) {
  levels_list <- list()
  
  for (entry in thresholds) {
    level_name <- entry$level
    level_values <- unlist(entry$values)
    levels_list[[level_name]] <- level_values
  }
  
  return(levels_list)
}

#' Generate RCMD Check Metrics Section
#'
#' @description Generates the RCMD Check Metrics HTML table for the HTML report.
#'
#' @param assessment_results - input data
#'
#' @keywords internal
generate_rcmd_check_section <- function(assessment_results) {
  
  rcmd_check_message <- "RCMD Check score"
  
  rcmd_check_score <- assessment_results$check_list$check_score
  
  rcmd_check_score <- convert_number_to_percent(rcmd_check_score) 
  
  # Check if errors, warnings, and notes are character(0) and replace with the message
  errors <- assessment_results$check_list$res_check$errors
  if (length(errors) == 0) {
    errors <- "No errors"
  }
  
  warnings <- assessment_results$check_list$res_check$warnings
  if (length(warnings) == 0) {
    warnings <- "No warnings"
  }
  
  notes <- assessment_results$check_list$res_check$notes
  if (length(notes) == 0) {
    notes <- "No notes"
  }
  
  # Create a data frame for R CMD Check results
  rcmd_check_df <- data.frame(
    Message = rcmd_check_message,
    Score = rcmd_check_score,
    Errors = errors,
    Warnings = warnings,
    Notes = notes
  )
  
  return(rcmd_check_df)
}

#' Generate Risk Summary
#'
#' @description Generates the Risk Summary table for the HTML report.
#'
#' @param assessment_results - input data
#'
#' @keywords internal
generate_risk_summary <- function(assessment_results) {
  
  # Handle NULL
  if (is.null(assessment_results$results$host$bioconductor_links)) {
    bioc_link <- "No Bioconductor link found"
  } else {
    bioc_link <- assessment_results$results$host$bioconductor_links
  }
  
  if (is.null(assessment_results$results$host$github_links)) {
    github_link <- "No GitHub link found"
  } else {
    github_link <- assessment_results$results$host$github_links
  }
  
  if (is.null(assessment_results$results$host$cran_links)) {
    cran_link <- "No CRAN link found"
  } else {
    cran_link <- assessment_results$results$host$cran_links
  }
  
  if (is.null(assessment_results$results$host$internal_links) || 
      is.list(assessment_results$results$host$internal_links)) {
    internal_link <- "No Internal link found"
  } else {
    internal_link <- assessment_results$results$host$internal_links
  }
  
  risk_summary_table <- data.frame(
    Metric = c('Package', 'Version', 'License', 
               'CRAN link', 'GitHub repository',
               'Bioconductor Link', 'Internal Repository'), 
    Value = c(
      assessment_results$results$pkg_name,
      assessment_results$results$pkg_version,
      assessment_results$results$license_name,
      cran_link,
      github_link,
      bioc_link,
      internal_link
    )
  )
  
  return(risk_summary_table)
}

#' Generate Risk Details
#'
#' @description Generates the Risk Details table for the HTML report.
#'
#' @param assessment_results - input data
#'
#' @keywords internal
generate_risk_details <- function(assessment_results) {
  
  # Ensure covr is numeric before rounding
  assessment_results$results$covr <- 
    as.numeric(assessment_results$results$covr)
  assessment_results$results$covr <- 
    round(assessment_results$results$covr, 2)
  
  check <- handle_null(assessment_results$results$check)
  
  check <- convert_number_to_percent(check)
  
  covr <- handle_null(assessment_results$results$covr)
  
  covr <- convert_number_to_percent(covr)
  
  risk_details_table <- data.frame(
    Metric = c(
      'R CMD Check Score', 'Test Coverage Score', 'Date Time', 'Executor', 
      'OS Name', 'OS Release', 'OS Machine', 'R version'
    ),
    Value = c(
      check,
      covr,
      handle_null(assessment_results$results$date_time),
      handle_null(assessment_results$results$executor),
      handle_null(assessment_results$results$sysname),
      handle_null(assessment_results$results$release),
      handle_null(assessment_results$results$machine),
      handle_null(assessment_results$check_list$res_check$rversion)
    )
  )
  return(risk_details_table)
}

#' Generate file coverage df
#'
#' @description Generates file coverage df when errors list created.
#' 
#' @param file_names - file names
#' @param file_coverage - test coverage for files
#' @param errors - test coverage errors
#' @param notes - test coverage notes
#' 
#' @keywords internal
create_file_coverage_df <- function(file_names, file_coverage, errors, notes) {
  # Convert errors to a character string if it is a complex structure
  if (is.list(errors)) {
    errors <- sapply(errors, function(x) {
      if (is.null(x)) {
        return("N/A")
      } else if (is.data.frame(x)) {
        return(paste(capture.output(print(x)), collapse = "; "))
      } else if (is.list(x)) {
        return(paste(unlist(x), collapse = "; "))
      } else {
        return(as.character(x))
      }
    })
  }
  
  # Ensure the number of rows match
  max_len <- max(length(file_names), length(file_coverage), length(notes))
  
  # Extend lists to match the maximum length
  file_names <- c(file_names, rep("", max_len - length(file_names)))
  file_coverage <- c(file_coverage, rep(NA, max_len - length(file_coverage)))
  notes <- c(notes, rep("", max_len - length(notes)))
  errors <- rep(paste(errors, collapse = "; "), max_len)
  
  # Create the data frame
  file_coverage_df <- data.frame(
    File = file_names,
    Coverage = file_coverage,
    Errors = errors,
    Notes = notes,
    stringsAsFactors = FALSE
  )
  
  return(file_coverage_df)
}

#' Generate Coverage Section
#'
#' @description Generates the Coverage section for the HTML report.
#' 
#' @param assessment_results - input data
#' 
#' @keywords internal
generate_coverage_section <- function(assessment_results) {
  
  total_coverage <- assessment_results$covr_list$res_cov$coverage$totalcoverage
  file_coverage <- assessment_results$covr_list$res_cov$coverage$filecoverage
  
  # Extract file names from the attributes
  file_names <- attr(file_coverage, "dimnames")[[1]]
  
  # Handle errors and notes
  errors <- assessment_results$covr_list$res_cov$errors
  if (all(is.na(errors))) {
    errors <- "No test coverage errors"
  }
  
  notes <- assessment_results$covr_list$res_cov$notes
  if (all(is.na(notes))) {
    notes <- "No test coverage notes"
  }
  
  # Create a data frame for file coverage
  if (is.list(errors) && all(c("message", "srcref", "status", "stdout", "stderr", "parent_trace", "call", "procsrcref", "parent") %in% names(errors))) {
    # Create the file coverage data frame
    file_coverage_df <- create_file_coverage_df(file_names, file_coverage, errors, notes)
  } else {
    # Handle the case where errors does not have the expected structure
    file_coverage_df <- data.frame(
      Function = file_names,
      Coverage = file_coverage,
      Errors = errors,
      Notes = notes,
      stringsAsFactors = FALSE
    )
  }
  
  return(file_coverage_df)
}

#' Generate Doc Metrics Section
#'
#' @description Generates the documentation section for the HTML report.
#' 
#' @param assessment_results - input data
#' 
#' @keywords internal
generate_doc_metrics_section <- function(assessment_results) {
  
  pkg_maintainer <- extract_maintainer_info(assessment_results$results$author$maintainer)
  
  # Extract the relevant elements from assessment_results
  doc_metrics <- data.frame(
    Metric = c(
      'Has Bug Reports URL', 'Has License', 'Has Examples', 'Has Maintainer',
      'Has News', 'Has Source Control', 'Has Vignettes',
      'Has Website', 'News Current', 'Export Help'
    ),
    Value = c(
      handle_null(assessment_results$results$has_bug_reports_url),
      handle_null(assessment_results$results$license),
      handle_null(assessment_results$results$has_examples),
      handle_null(pkg_maintainer),
      handle_null(assessment_results$results$has_news),
      handle_null(assessment_results$results$has_source_control),
      handle_null(assessment_results$results$has_vignettes),
      handle_null(assessment_results$results$has_website),
      handle_null(assessment_results$results$news_current),
      handle_null(assessment_results$results$export_help)
    )
  )  
  
  doc_metrics$Value <- sapply(doc_metrics$Value, function(x) {
    if (x == 0) {
      return('Not Included')
    } else if (x == 1) {
      return('Included')
    } else {
      return(x)
    }
  })
  
  # Extract the relevant elements from assessment_results
  doc_metrics <- data.frame(
    Metric = c(
      'Has Bug Reports URL', 'Has License', 'Has Examples', 'Has Maintainer',
      'Has News', 'Has Source Control', 'Has Vignettes',
      'Has Website', 'Export Help'
    ),
    Value = c(
      handle_null(assessment_results$results$has_bug_reports_url),
      handle_null(assessment_results$results$license),
      handle_null(assessment_results$results$has_examples),
      handle_null(pkg_maintainer),
      handle_null(assessment_results$results$has_news),
      handle_null(assessment_results$results$has_source_control),
      handle_null(assessment_results$results$has_vignettes),
      handle_null(assessment_results$results$has_website),
      handle_null(assessment_results$results$export_help)
    )
  )  
  
  doc_metrics$Value <- sapply(doc_metrics$Value, function(x) {
    if (x == 0) {
      return('Not Included')
    } else if (x == 1) {
      return('Included')
    } else {
      return(x)
    }
  })
  
  return(doc_metrics)
}

#' Generate Popularity Metrics Section
#'
#' @description Generates the popularity section for the HTML report.
#' 
#' @param assessment_results - input data
#' 
#' @keywords internal
generate_pop_metrics_section <- function(assessment_results) {
  
  # Extract the numeric value
  total_download_n <- assessment_results$results$download$total_download
  
  # Extract the relevant elements from assessment_results
  pop_metrics <- data.frame(
    Metric = c(
      'Date created', 'Stars', 'Forks', 'Data Extract Date',
      'Recent Commits', 'Open Issues', 'Downloads Total',
      'Downloads Last Month'
    ),
    Value = c(
      handle_null(assessment_results$results$github_data$created_at),
      handle_null(assessment_results$results$github_data$stars),
      handle_null(assessment_results$results$github_data$forks),
      handle_null(assessment_results$results$github_data$date),
      handle_null(assessment_results$results$github_data$recent_commits_count),
      handle_null(assessment_results$results$github_data$open_issues),
      safe_value(assessment_results$results$download$total_download),
      safe_value(assessment_results$results$download$last_month_download)
    )
  )  
  
  # Add numeric value as a new column 
  # needed for formatting in pop_metrics r chunk in `risk_report_template.Rmd`
  pop_metrics$NumericValue <- NA_real_
  pop_metrics$NumericValue[pop_metrics$Metric == "Downloads Total"] <- total_download_n
  
  return(pop_metrics)
}


#' Generate Trace Matrix Section
#'
#' @description Generates the Trace Matrix section for the HTML report.
#' 
#' @param total_coverage - total coverage for the package
#' @param file_coverage - file coverage for the package
#' @param tm_df - input data
#' 
#' @keywords internal
generate_trace_matrix_section <- function(total_coverage, file_coverage, tm_df) {
  
  if (is.na(total_coverage) || total_coverage == 0 ||
      (is.vector(file_coverage) && any(is.na(file_coverage)))) {
    trace_matrix <- data.frame(
      Exported_function = " ",
      Function_type = " ",
      Code_script = " ",
      Documentation = " ",
      Description = "Traceability matrix unsuccessful",
      Test_Coverage = " ",
      stringsAsFactors = FALSE
    )
  } else {
    trace_matrix <- tm_df %>%
      dplyr::select(
        Exported_function = exported_function,
        Function_type = function_type,
        Code_script = code_script,
        Documentation = documentation,
        Description = description,
        Test_Coverage = coverage_percent
      )
    
    # remove re-exported functions and sort by Test Coverage
    trace_matrix <- trace_matrix |> 
      dplyr::filter(!is.na(`Code_script`) & `Code_script` != "") |> 
      dplyr::arrange(Test_Coverage)
    
  }
  
  return(trace_matrix)  
}

#' Generate Fine grained Trace Matrices Section
#'
#' @description Generates the Trace Matrices section for the HTML report.
#' 
#' @param tm_type - type of traceability matrix
#' @param tm_df - input data
#' 
#' @keywords internal
generate_fg_trace_matrix_section <- function(tm_type, tm_df) {
  
  # Check if coverage is missing
  if (!"coverage_percent" %in% names(tm_df) || 
      all(is.na(tm_df$coverage_percent))) {
    trace_matrix <- data.frame(
      Exported_function = " ",
      Function_type = " ",
      Code_script = " ",
      Documentation = " ",
      Description = glue::glue("No {tm_type} traceability matrix generated"),
      Test_Coverage = " ",
      stringsAsFactors = FALSE
    )
  } else {
    trace_matrix <- tm_df %>%
      dplyr::select(
        Exported_function = exported_function,
        Function_type = function_type,
        Code_script = code_script,
        Documentation = documentation,
        Description = description,
        Test_Coverage = coverage_percent
      ) %>%
      dplyr::filter(!is.na(Code_script) & Code_script != "") %>%
      dplyr::arrange(Test_Coverage)
  }
  
  return(trace_matrix)  
}


#' Generate Dependencies Section
#'
#' @description Generates the dependencies section for the HTML report.
#' 
#' @param assessment_results - input data
#' 
#' @keywords internal
generate_deps_section <- function(assessment_results) {
  
  # Extract dependencies from assessment_results
  dependencies <- assessment_results$results$dependencies
  
  # Initialize empty lists to store package names, versions, types
  pkg_names <- c()
  pkg_versions <- c()
  pkg_types <- c()
  import_count <- 0
  suggest_count <- 0
  
  # Process Imports
  if (!is.null(dependencies$imports)) {
    for (pkg in names(dependencies$imports)) {
      pkg_names <- c(pkg_names, pkg)
      pkg_versions <- c(pkg_versions, dependencies$imports[[pkg]])
      pkg_types <- c(pkg_types, "Imports")
      import_count <- import_count + 1
    }
  }
  
  # Process Suggests
  if (!is.null(dependencies$suggests)) {
    for (pkg in names(dependencies$suggests)) {
      pkg_names <- c(pkg_names, pkg)
      pkg_versions <- c(pkg_versions, dependencies$suggests[[pkg]])
      pkg_types <- c(pkg_types, "Suggests")
      suggest_count <- suggest_count + 1
    }
  }
  
  # Create a data frame
  deps_df <- data.frame(
    Package = pkg_names,
    Version = pkg_versions,
    Type = pkg_types,
    stringsAsFactors = FALSE
  )
  
  return(list(
    deps_df = deps_df,
    import_count = import_count,
    suggest_count = suggest_count
  ))
}

#' Generate Reverse Dependencies Section
#'
#' @description Generates the reverse dependencies section for the HTML report.
#' 
#' @param assessment_results - input data
#' 
#' @keywords internal
generate_rev_deps_section <- function(assessment_results) {
  
  # Extract dependencies from assessment_results
  
  rev_deps <- assessment_results$results$rev_deps
  
  # Convert the character vector to a data frame with one row per value
  rev_deps_df <- as.data.frame(rev_deps, 
                               stringsAsFactors = FALSE)
  
  # Rename the column 
  colnames(rev_deps_df) <- "Reverse_dependencies"
  
  rev_deps_no = nrow(rev_deps_df)
  
  # Create a summary data frame
  rev_deps_summary <- data.frame(
    rev_deps_no = nrow(rev_deps_df)
  )
  
  return(list(
    rev_deps_df = rev_deps_df,
    rev_deps_summary = rev_deps_summary
  ))
}

