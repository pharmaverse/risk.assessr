#' @title Normalize Nested Package Data
#' @description Flattens nested package metadata into a flat list for further processing.
#' @param results The nested package metadata (list structure as produced by your package).
#' @return A list with flattened package information.
#' @importFrom purrr pluck
#' @keywords internal
normalize_data <- function(results) {
  list(
    name = pluck(results, "pkg_name", .default = NA_character_),
    version = pluck(results, "pkg_version", .default = NA_character_),
    dependencies_import = names(pluck(results, "dependencies", "imports", .default = list())),
    dependencies_count = length(pluck(results, "dependencies", "imports", .default = list())),
    
    all_versions = pluck(results, "version_info", "all_versions", .default = NULL),
    last_version = pluck(results, "version_info", "last_version", .default = NULL),
    
    maintainer = pluck(results, "author", "maintainer", .default = NA_character_),
    license = clean_license((pluck(results, "license_name", .default = "NOT AVAILABLE"))),
    reverse_dependencies_count = length(pluck(results, "rev_deps", .default = list())),
    funder = pluck(results, "author", "funder", .default = NA_character_),
    authors = pluck(results, "author", "authors", .default = NULL),
    
    has_bug_reports_url = pluck(results, "has_bug_reports_url", .default = NULL),
    has_maintainer      = pluck(results, "has_maintainer",      .default = NULL),
    has_source_control  = pluck(results, "has_source_control",  .default = NULL),
    has_website         = pluck(results, "has_website",         .default = NULL),
    has_vignettes       = pluck(results, "has_vignettes",       .default = NULL),
    has_examples        = pluck(results, "has_examples",        .default = NULL),
    has_news            = pluck(results, "has_news",            .default = NULL),

    code_coverage = pluck(results, "covr", .default = 0),
    cmd_check = pluck(results, "check", .default = 0),
    
    total_download = pluck(results, "download", "total_download", .default = 0),
    last_month_download = pluck(results, "download", "last_month_download", .default = 0),
    
    github_links = pluck(results, "host", "github_links", .default = NULL),
    cran_links = pluck(results, "host", "cran_links", .default = NULL),
    bioconductor_links = pluck(results, "host", "bioconductor_links", .default = NULL),
    internal_links = pluck(results, "host", "internal_links", .default = NULL),
    github_stars = pluck(results, "github_data", "stars", .default = NULL),
    github_forks = pluck(results, "github_data", "forks", .default = NULL),
    github_created_at = pluck(results, "github_data", "created_at", .default = NULL),
    recent_commits_count = pluck(results, "github_data", "recent_commits_count", .default = NULL)
  )
}


#' @title Extract Risk Inputs
#' @description Compute intermediate risk input values from flattened package data.
#' @param flat_data Flat package data as returned by \code{normalize_data()}.
#' @return A list of computed values required for risk scoring.
#' @keywords internal
extract_risk_inputs <- function(flat_data) {
  
  fields <- c("has_bug_reports_url","has_maintainer","has_source_control",
              "has_website","has_vignettes","has_examples","has_news")
  
  documentation_score <- sum(vapply(flat_data[fields], function(x) {
    if (is.null(x)) return(0L)

    if (is.numeric(x) || is.logical(x)) {
      return(as.integer(isTRUE(as.logical(x)))) 
    }
    1L                                         
  }, integer(1L)))
  
  
  all_versions <- flat_data$all_versions
  current_version <- flat_data$version
  last_version <- flat_data$last_version
  
  if (!is.null(all_versions)) {
    
    index <- which(sapply(all_versions, function(x) x$version == current_version))
    
    if (length(index) == 0) {
      index <- length(all_versions)
    }
    later_version <- length(all_versions) - index
    
  } else {
    later_version <- NA
  }
  
  return(c(
    flat_data,
    list(
      documentation_score = documentation_score,
      later_version = later_version
    )
  ))
}


#' @title Get Risk Definition
#' @description Load risk definition config from options, JSON file, or fallback to bundled file.
#' @return A list of risk configuration items.
#' @examples
#' risk_rule <- get_risk_definition()
#' print(risk_rule)
#' @export
#' @export
get_risk_definition <- function() {
  opt <- getOption("risk.assessr.risk_definition")
  
  # If option is a file path
  if (is.character(opt) && file.exists(opt)) {
    def <- tryCatch(
      jsonlite::fromJSON(opt, simplifyVector = FALSE),
      error = function(e) NULL
    )
    if (is.list(def)) return(def)
  }
  
  # If option is already a valid R list
  if (is.list(opt)) {
    message("Using custom risk definition.")
    return(opt)
  }
  
  # fallback
  fallback_path <- system.file("config", "risk-definition.json", package = "risk.assessr")
  
  if (file.exists(fallback_path)) {
    def <- tryCatch(
      jsonlite::fromJSON(fallback_path, simplifyVector = FALSE),
      error = function(e) NULL
    )
    if (is.list(def)) {
      message("Using package's default risk definition.")
      return(def)
    }
  }
  
  stop("No valid risk definition found in options or package fallback.")
}


#' @title Compute Risk Level
#' @description Apply risk thresholds to compute risk level for a single metric.
#' @param value The numeric or categorical value to evaluate.
#' @param risk A list describing the thresholds for the metric.
#' @return The computed risk level (e.g. "low", "medium", "high").
#' @keywords internal
compute_risk <- function(value, risk) {
  
  level <- if (!is.null(risk$default)) { 
    risk$default 
  } else { 
    "unknown" 
  }
  
  if (is.null(value) || all(is.na(value))) {
    return("unknown")
  }
  
  for (threshold in risk$thresholds) {
    if (!is.null(threshold$values)) {
      if (is.list(value) || is.vector(value)) {
        if (any(toupper(value) %in% toupper(threshold$values))) {
          return(threshold$level)
        }
      } else {
        if (toupper(value) %in% toupper(threshold$values)) {
          return(threshold$level)
        }
      }
    } else {
      if (is.null(threshold$max) || value <= threshold$max) {
        return(threshold$level)
      }
    }
  }
  return(level)
}




#' @title Get Risk Analysis
#' @description Compute risk levels for the package metadata.
#' @param data The nested package metadata.
#' @return A named list of computed risk levels.
#'
#' @examples
#' # Minimal mock input for demonstration
#' mock_data <- list(
#'   dependencies_count = 5,
#'   later_version = 2,
#'   code_coverage = 0.75,
#'   last_month_download = 150000,
#'   license = "MIT",
#'   reverse_dependencies_count = 10,
#'   documentation_score = 2,
#'   cmd_check = 0
#' )
#'
#' get_risk_analysis(mock_data)
#' @export
get_risk_analysis <- function(data) {
  
  risk_config <- get_risk_definition()
  flat_data <- normalize_data(data)
  extracted <- extract_risk_inputs(flat_data)
    
  risks <- list()
  for (risk_item in risk_config) {
    
    key <- risk_item$key
    value <- extracted[[key]]
    risks[[key]] <- compute_risk(value, risk_item)
  }
  
  return(risks)
}