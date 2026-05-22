#' Write the risk assessment summary report
#'
#' Renders the package risk assessment report (`summary.Rmd`) to a chosen format
#' and writes it to disk. The output file path can be inferred or explicitly set.
#' You can specify the output format directly via `output_format` or let it be
#' inferred from the extension of `output_file`. If `output_dir` is not provided,
#' the current working directory is used.
#'
#' @section Behavior:
#' - If `output_dir` is `NULL`, it defaults to `getwd()` and a message is printed.
#' - If `output_file` is `NULL`, a file name is auto-generated as
#'   `"summary_report_<pkg>_<version>.html"` inside `output_dir`.
#' - If `output_file` points to an existing directory (or ends with a path separator),
#'   a file name is composed inside that directory as
#'   `"summary_report_<pkg>_<version>.html"`.
#' - If `output_file` is a relative path, it is resolved against `output_dir`.
#' - If `output_format` is provided, it determines the render format
#'   (and the `output_file` name is adjusted to match the format).
#' - If `output_format` is not provided, the render format is inferred from the
#'   extension of `output_file`. Unknown extensions trigger a warning and the
#'   extension is changed to `.html`.
#'
#' @param results A results object containing the risk assessment results. It is
#'   expected to include `results$results$pkg_name` and `results$results$pkg_version`,
#'   which are used to construct default file names and report parameters.
#' @param output_file `character(1)` or `NULL`. The output file path **or** a directory.
#'   - If `NULL`, a default name is generated:
#'     `"summary_report_<pkg_name>_<pkg_version>.html"` in `output_dir`.
#'   - If it is a directory, the default name is composed inside it.
#'   - If it is a relative path, it is resolved against `output_dir`.
#' @param output_format `character(1)` or `NULL`. Explicit output format to render:
#'   one of `"html"` or `"md"` (case-insensitive; do **not** include a leading dot).
#'   If `NULL`, the format is inferred from the extension of `output_file`.
#'   Unknown values trigger a warning and default to HTML.
#' @param output_dir `character(1)` or `NULL`. Base directory used when
#'   `output_file` is `NULL` or a relative path. If `NULL`, defaults to the
#'   current working directory (`getwd()`), with an informational message.
#'
#' @return (Invisibly) the absolute path to the written report file.
#'
#' @details
#' The function calls [rmarkdown::render()] on an internal template:
#' `system.file("report_templates", "summary.Rmd", package = "risk.assessr")`.
#'
#' The format mapping is:
#' - `"html"` -> [rmarkdown::html_document()]
#' - `"md"`   -> [rmarkdown::md_document()]
#'
#' If `output_format` is provided, it takes precedence for rendering even if
#' `output_file` has a different extension; in that case the filename is adjusted
#' to match the format. If `output_format` is not provided, the function infers the
#' format from `output_file`'s extension. For unknown extensions, it warns and
#' rewrites the extension to `.html`.
#'
#' @examples
#' \dontrun{
#' # generate assessment_results
#' results <- risk_assess_pkg()
#' 
#' # Basic usage: auto-name in the working directory (HTML)
#' write_summary_report(results)
#'
#' # Specify output directory (auto-name inside that directory)
#' write_summary_report(results, output_dir = "artifacts")
#'
#' # Provide an explicit filename (relative to output_dir)
#' write_summary_report(results, output_file = "reports/summary.html")
#'
#' # Provide a directory as output_file: auto-name inside that directory
#' write_summary_report(results, output_file = "reports/")
#'
#' # Render to Markdown explicitly
#' write_summary_report(results, output_format = "md")
#'
#' # Let the extension drive the format (md)
#' write_summary_report(results, output_file = "reports/summary.md")
#'
#' # Case-insensitive formats work; avoid leading dots (".md" is not valid)
#' write_summary_report(results, output_format = "MD")
#' }
#'
#' @importFrom rmarkdown render html_document md_document
#' @importFrom tools file_ext
#' @export
write_summary_report <- function(results, output_file = NULL, output_format = NULL, output_dir = NULL) {
  
  # set up tool version
  
  # Get the installed package path
  pkg_path <- find.package("risk.assessr")
  
  # extract the Version field
  tool_version <- tryCatch(
    get_pkg_desc(pkg_path, fields = "Version"),
    error = function(e) {
      stop(
        "Failed to retrieve package description for 'risk.assessr': ",
        conditionMessage(e),
        call. = FALSE
      )
    }
  )
  
  if (is.null(tool_version) || is.null(tool_version$Version)) {
    stop(
      "Package description for 'risk.assessr' does not contain a valid 'Version' field.",
      call. = FALSE
    )
  }
  
  
  
  params <- list(
    analysis = generate_risk_analysis(results),
    name = results$results$pkg_name,
    version = results$results$pkg_version,
    tool_version = tool_version$Version,
    data = results
  )
  
  # If output_dir is not set, use the current working directory
  if (is.null(output_dir)) {
    output_dir <- getwd()
    message(glue::glue("No output directory specified. Setting output to {output_dir}"))
  }
  
  # Decide target path
  if (is.null(output_file)) {
    # Choose default extension based on explicit output_format (html|md), else html
    default_ext <- {
      if (!is.null(output_format)) {
        fmt <- tolower(output_format)
        if (fmt %in% c("html", "md")) fmt else "html"
      } else {
        "html"
      }
    }
    
    # Default: write to output_dir, auto-named (CRAN-friendly)
    output_file <- fs::path_abs(
      glue::glue("summary_report_{params$name}_{params$version}.{default_ext}"),
      start = output_dir
    )
    message("Report will be written to: ", output_file)
  } else {
    # Caller supplied a filename or directory; we respect it
    if (dir.exists(output_file) || grepl("/$|\\\\$", output_file)) {
      # Treat as directory: compose filename inside it (default ext is html here; corrected later)
      output_file <- fs::path_abs(
        glue::glue("summary_report_{params$name}_{params$version}.html"),
        start = output_file
      )
    } else if (!fs::is_absolute_path(output_file)) {
      # Resolve relative paths against output_dir
      output_file <- fs::path_abs(output_file, start = output_dir)
    }
  }
  
  # Infer output format from either explicit parameter or extension
  final_ext <- tolower(tools::file_ext(output_file))
  output_format_obj <- if (!is.null(output_format)) {
    fmt <- tolower(output_format)
    
    fmt_obj <- switch(
      fmt,
      html = rmarkdown::html_document(),
      md   = rmarkdown::md_document(),
      {
        warning("Unknown 'output_format'; defaulting to HTML (only 'html' and 'md' are supported).")
        fmt <- "html"
        rmarkdown::html_document()
      }
    )
    
    # Ensure filename extension matches explicit output_format
    if (!identical(final_ext, fmt)) {
      output_file <- fs::path_ext_set(output_file, fmt)
      final_ext <- fmt
    }
    
    # For MD: strictly disallow HTML to avoid extra html artifacts
    if (identical(fmt, "md")) {
      knitr::opts_knit$set(always_allow_html = FALSE)
      knitr::opts_chunk$set(dev = "png", fig.ext = "png")
    }
    
    fmt_obj
  } else {
    # Original behavior: infer from the file extension (and fix unknowns to .html)
    fmt_obj <- switch(
      final_ext,
      html = rmarkdown::html_document(),
      md   = rmarkdown::md_document(),
      {
        warning("Unknown extension; defaulting to HTML (only '.html' and '.md' are supported).")
        output_file <- fs::path_ext_set(output_file, "html")
        final_ext <- "html"
        rmarkdown::html_document()
      }
    )
    
    # For MD: strictly disallow HTML
    if (identical(final_ext, "md")) {
      knitr::opts_knit$set(always_allow_html = FALSE)
      knitr::opts_chunk$set(dev = "png", fig.ext = "png")
    }
    
    fmt_obj
  }
  
  # Render in a single target directory to avoid extra artifacts near template
  render_dir  <- dirname(output_file)
  render_name <- basename(output_file)
  template_path <- system.file("report_templates", 
                               "summary.Rmd", 
                               package = "risk.assessr")
  
  do.call(rmarkdown::render, list(
    input              = template_path,
    output_format      = output_format_obj,
    output_file        = render_name,        # basename only
    output_dir         = render_dir,         # final output placed here
    envir              = new.env(),
    params             = params,
    intermediates_dir  = render_dir,         # intermediates here, not in template dir
    knit_root_dir      = render_dir,         # force chunk outputs under render_dir
    clean              = TRUE,               # remove intermediates after successful render
    quiet              = TRUE                # suppress knit/pandoc progress lines
  ))
  
  # Final, single message confirming the actual output file
  message("Output created: ", file.path(render_dir, render_name))
  
}

#' Generate Risk Analysis
#'
#' @description Generates the Risk Analysis table for the HTML report.
#'
#' @param assessment_results - input data containing risk analysis metrics
#'
#' @keywords internal
generate_risk_analysis <- function(assessment_results) {
  
  risk <- assessment_results$risk_analysis
  
  # create values for the risk analysis table
  # Ensure covr is numeric before rounding
  assessment_results$results$covr <-
    as.numeric(assessment_results$results$covr)
  assessment_results$results$covr <-
    round(assessment_results$results$covr, 2)
  
  check <- handle_null(assessment_results$results$check)
  
  check <- convert_number_to_percent(check)
  
  covr <- handle_null(assessment_results$results$covr)
  
  covr <- convert_number_to_percent(covr)
  
  license <- assessment_results$results$license_name
  
  example_score <- handle_null(assessment_results$results$has_examples$example_score)
  
  example_score <- convert_number_to_percent(example_score)
  
  has_docs_score <- handle_null(assessment_results$results$has_docs$has_docs_score)
  
  has_docs_score <- convert_number_to_percent(has_docs_score)
  
  has_ex_docs_score <- handle_null(assessment_results$results$has_ex_docs_score)
  
  has_ex_docs_score <- convert_number_to_percent(has_ex_docs_score) 
  
  # get reverse dependencies number
  rev_deps <- assessment_results$results$rev_deps
  
  # Convert the character vector to a data frame with one row per value
  rev_deps_df <- as.data.frame(rev_deps, stringsAsFactors = FALSE)
  
  rev_deps_no = nrow(rev_deps_df)
  
  # get total downloads
  total_download_n <- safe_value(
    assessment_results$results$download$total_download
  )
  
  # Helper to handle NULLs
  get_metric <- function(x, default = "Not assessed") {
    if (is.null(x)) default else x
  }
  
  risk_analysis_table <- data.frame(
    Metric = c(
      "CMD Check",
      "Code Coverage",
      "Dependencies Count",
      "License Risk",
      "URL Documentation Score",
      "Percentage of functions with examples",
      "Percentage of functions with documentation",
      "Combined Examples Documentation Score",
      "Reverse Dependencies Count",
      "Later Version Available",
      "Total Downloads"
    ),
    Risk_Level = c(
      get_metric(risk$cmd_check),
      get_metric(risk$code_coverage),
      get_metric(risk$dependencies_count),
      get_metric(risk$license),
      get_metric(risk$documentation_score),
      get_metric(risk$example_score,  default = " "),
      get_metric(risk$has_docs_score,  default = " "),
      get_metric(risk$has_ex_docs_score),
      get_metric(risk$reverse_dependencies_count),
      get_metric(risk$later_version),
      get_metric(risk$total_download)
    ),
    Risk_Value = c(
      check,
      covr,
      "",
      license,
      "",
      example_score,
      has_docs_score,
      has_ex_docs_score,
      rev_deps_no,
      "",
      total_download_n
    ),
    stringsAsFactors = FALSE
  )
  
  return(risk_analysis_table)
}

#' Evaluate Risk Highlighting for Rejection and Mitigation
#'
#' This function analyzes risk levels for key metrics ("CMD Check" and "Code Coverage")
#' and other metrics to determine whether a report should be highlighted for rejection
#' or mitigation based on predefined rules.
#'
#' @param risk_analysis_output A data frame containing at least two columns:
#'   \describe{
#'     \item{Metric}{Character vector of metric names (e.g., "CMD Check", "Code Coverage").}
#'     \item{Risk_Level}{Character vector of risk levels (e.g., "low", "medium", "high").}
#'   }
#'
#' @return status - 3 possible values - "Accepted", "Mitigation Needed", "Rejected"
#'   
#' @details
#' **Rejection Logic:**
#' - Reject if BOTH key metrics ("CMD Check" and "Code Coverage") are medium/high.
#' - OR if there are severe other risks (greater equal to 2 high OR greater equal to 3 medium)
#' - AND at least one key metric is not low.
#'
#' **Mitigation Logic:**
#' - Mitigate if only one key metric is medium/high OR other risks are significant
#'   (greater equal to 1 high OR greater equal to 2 medium), provided the report is not rejected.
#'
#' @keywords internal
evaluate_risk_highlighting <- function(risk_analysis_output) {
  
  # Extract key metrics
  cmd_risk <- tolower(risk_analysis_output$Risk_Level[
    risk_analysis_output$Metric == "CMD Check"
  ])
  coverage_risk <- tolower(risk_analysis_output$Risk_Level[
    risk_analysis_output$Metric == "Code Coverage"
  ])
  
  # Calculate other risks
  other_high_risks <- sum(
    tolower(risk_analysis_output$Risk_Level[
      !(risk_analysis_output$Metric %in% c("CMD Check", "Code Coverage"))
    ]) ==
      "high"
  )
  
  other_medium_risks <- sum(
    tolower(risk_analysis_output$Risk_Level[
      !(risk_analysis_output$Metric %in% c("CMD Check", "Code Coverage"))
    ]) ==
      "medium"
  )
  
  # Rejection logic
  highlight_rejected <- ((cmd_risk %in%
                            c("high", "medium") &&
                            coverage_risk %in% c("high", "medium")) ||
                           ((other_high_risks >= 2 || other_medium_risks >= 3) &&
                              (cmd_risk != "low" || coverage_risk != "low")))
  
  # Mitigation logic
  highlight_mitigation <- (((cmd_risk %in%
                               c("high", "medium") &&
                               coverage_risk == "low") ||
                              (coverage_risk %in% c("high", "medium") && cmd_risk == "low")) ||
                             other_high_risks >= 1 ||
                             other_medium_risks >= 2) &&
    !highlight_rejected
  
  
  # Single return at the end
  status <- if (highlight_rejected) {
    "Rejected"
  } else if (highlight_mitigation) {
    "Mitigation Needed"
  } else {
    "Approved"
  }
  
  return(status)
}