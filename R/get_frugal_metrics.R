#' Compute frugal risk metrics for an R package
#'
#' @description
#' A lightweight ("frugal") variant of [risk_assess_pkg()] that skips the most
#' expensive parts of a full assessment:
#'
#'   * the test suite is **not** executed (R CMD check is run with
#'     `--no-tests`, sourced from [setup_rcmdcheck_args()] with
#'     `check_type = "2"`),
#'   * unit-test coverage is **not** computed (no call to
#'     `test.assessr::get_package_coverage()`), and
#'   * remote metadata (CRAN/Bioconductor versions, GitHub stats, downloads,
#'     reverse dependencies) is **not** fetched.
#'
#' What is still produced:
#'
#'   * documentation risk metrics ([doc_riskmetric()]),
#'   * R CMD check score (with the frugal flag set described above),
#'   * direct & session dependencies, exports, author and license metadata,
#'   * a traceability matrix without coverage
#'     ([create_traceability_matrix()] with `execute_coverage = FALSE`),
#'   * a `risk_analysis` block ([get_risk_analysis()]).
#'
#' @param package_name Character. Name of the package to assess.
#' @param version Character or `NA`. Specific version to fetch. Default `NA`
#'   uses the latest available.
#' @param repos Character. Repository URLs to use when fetching the tarball.
#'   Defaults to `getOption("repos")`.
#'
#' @return A named list with the same top-level shape as [risk_assess_pkg()]:
#'   \describe{
#'     \item{`results`}{Risk-metric results list (with frugal placeholders).}
#'     \item{`covr_list`}{Coverage placeholder produced by
#'           [init_frugal_covr_list()].}
#'     \item{`tm_list`}{Traceability matrix (no coverage).}
#'     \item{`check_list`}{R CMD check output from [run_rcmdcheck()].}
#'     \item{`risk_analysis`}{Risk levels from [get_risk_analysis()].}
#'   }
#'   Returns `NULL` if the tarball cannot be fetched or the package cannot
#'   be unpacked.
#'
#' @seealso [risk_assess_pkg()], [setup_rcmdcheck_args()], [set_up_pkg()],
#'   [init_frugal_results()], [init_frugal_covr_list()].
#'
#' @examples
#' \dontrun{
#' frugal <- get_frugal_metrics("here", version = "1.0.1")
#' }
#'
#' @export
get_frugal_metrics <- function(package_name,
                               version = NA,
                               repos   = getOption("repos")) {
  
  checkmate::assert_string(package_name, min.chars = 1L)
  
  # 1. Fetch the tarball -----------------------------------------------------
  v <- if (is.null(version) || (length(version) == 1L && is.na(version))) NULL else version
  temp_file <- tryCatch(
    get_package_tarfile(package_name = package_name, version = v, repos = repos),
    error = function(e) {
      warning("Failed to download package '", package_name, "': ",
              conditionMessage(e), ". Returning NULL.")
      NULL
    }
  )
  if (is.null(temp_file)) return(NULL)
  
  # Make sure all temporary artefacts are cleaned up no matter how we exit.
  modified_tar_file <- NULL
  on.exit({
    for (f in c(temp_file, modified_tar_file)) {
      if (!is.null(f) && file.exists(f)) unlink(f)
    }
  }, add = TRUE)
  
  # 2. Modify DESCRIPTION ----------------------------------------------------
  modified_tar_file <- modify_description_file(temp_file)
  
  # 3. Unpack via set_up_pkg() in *frugal* mode (check_type = "2") ----------
  # This is the only behavioural difference vs. the full pipeline: the
  # rcmdcheck_args list returned here carries --no-tests in addition to the
  # basic-check flags; see setup_rcmdcheck_args() for the exact contents.
  install_list    <- set_up_pkg(modified_tar_file, check_type = "2")
  pkg_source_path <- install_list$pkg_source_path
  
  if (!isTRUE(install_list$package_installed) ||
      is.null(pkg_source_path) || !nzchar(pkg_source_path)) {
    message("Failed to unpack package.")
    return(NULL)
  }
  
  # 4. Local install ---------------------------------------------------------
  package_installed <- install_package_local(pkg_source_path)
  
  results    <- NULL
  tm_list    <- NULL
  check_list <- NULL
  
  if (isTRUE(package_installed)) {
    
    # 5. Identity + empty results -------------------------------------------
    pkg_desc <- get_pkg_desc(pkg_source_path,
                             fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver  <- pkg_desc$Version
    
    metadata <- get_risk_metadata()
    results  <- create_empty_results(pkg_name, pkg_ver, pkg_source_path, metadata)
    
    # 6. Documentation risk metrics -----------------------------------------
    doc_scores <- doc_riskmetric(pkg_name, pkg_ver, pkg_source_path)
    results$has_bug_reports_url <- doc_scores$has_bug_reports_url
    results$license             <- doc_scores$license
    results$has_examples        <- doc_scores$has_examples
    results$has_docs            <- doc_scores$has_docs
    results$has_ex_docs_score   <- doc_scores$has_ex_docs_score
    results$has_maintainer      <- doc_scores$has_maintainer
    results$size_codebase       <- doc_scores$size_codebase
    results$has_news            <- doc_scores$has_news
    results$has_source_control  <- doc_scores$has_source_control
    results$has_vignettes       <- doc_scores$has_vignettes
    results$has_website         <- doc_scores$has_website
    results$news_current        <- doc_scores$news_current
    results$export_help         <- doc_scores$export_help
    
    # 7. R CMD check (frugal flags from set_up_pkg) -------------------------
    rcmdcheck_args      <- install_list$rcmdcheck_args
    rcmdcheck_args$path <- pkg_source_path
    check_list          <- run_rcmdcheck(pkg_source_path, rcmdcheck_args)
    results$check       <- check_list$check_score
    
    # 8. Exports + dependencies + author + license --------------------------
    results$export_calc  <- assess_exports(pkg_source_path)
    
    deps                 <- get_dependencies(pkg_source_path)
    results$dependencies <- risk.assessr::get_session_dependencies(deps)
    
    results$author       <- get_pkg_author(pkg_name, pkg_source_path)
    results$license_name <- extract_license_from_description(pkg_source_path)
    
    # 9. Traceability matrix without coverage -------------------------------
    tm_list <- create_traceability_matrix(
      pkg_name         = pkg_name,
      pkg_source_path  = pkg_source_path,
      func_covr        = NULL,
      execute_coverage = FALSE
    )
    
    # 10. Pad uncomputed slots so downstream reports render cleanly ---------
    results <- init_frugal_results(results)
    
  } else {
    message("Package installation failed.")
  }
  
  covr_list <- init_frugal_covr_list()
  
  list(
    results       = results,
    covr_list     = covr_list,
    tm_list       = tm_list,
    check_list    = check_list,
    risk_analysis = if (is.null(results)) NULL else get_risk_analysis(results)
  )
}


#' Initialise frugal-mode result placeholders
#'
#' @description
#' Internal helper used by [get_frugal_metrics()] to fill the slots of a
#' `results` list that the frugal pipeline does **not** compute (test
#' coverage, remote metadata) with safe placeholders. The shape mirrors what
#' [assess_pkg()] produces so [generate_html_report()] and
#' [write_summary_report()] keep working without special-casing frugal output.
#'
#'
#' Existing values are preserved — a slot is only overwritten when it is
#' missing or empty.
#'
#' @param results A `results` list (typically produced by
#'   [create_empty_results()] and partially populated by the frugal pipeline).
#'
#' @return The `results` list with the placeholders described above.
#' @keywords internal
init_frugal_results <- function(results) {
  
  if (is.null(results)) return(results)
  
  is_blank <- function(x) {
    is.null(x) ||
      (length(x) == 1L && is.character(x) && (is.na(x) || !nzchar(trimws(x)))) ||
      (length(x) == 1L && is.logical(x) && is.na(x))
  }
  
  if (is_blank(results$tests)) {
    results$tests <- list()
  }
  
  # `covr` must be numeric 0, NOT NA — convert_number_to_percent() compares
  # the value with `>= 0 && <= 1`, which raises "missing value where TRUE/FALSE
  # needed" if the value is NA.
  if (is_blank(results$covr) || is.na(suppressWarnings(as.numeric(results$covr)))) {
    results$covr <- 0
  }
  
  if (is_blank(results$suggested_deps) || !is.data.frame(results$suggested_deps)) {
    results$suggested_deps <- data.frame(
      source             = if (!is.null(results$pkg_name)) results$pkg_name else NA_character_,
      suggested_function = NA_character_,
      message            = "Not computed in frugal mode",
      where              = NA_character_,
      stringsAsFactors   = FALSE
    )
  }
  
  if (is_blank(results$rev_deps)) {
    results$rev_deps <- 0
  }
  
  if (is_blank(results$host) || !is.list(results$host)) {
    results$host <- list(
      cran_links         = NULL,
      bioconductor_links = NULL,
      github_links       = NULL,
      internal_links     = NULL
    )
  }
  
  if (is_blank(results$github_data) || !is.list(results$github_data)) {
    results$github_data <- list(
      created_at           = NULL,
      stars                = NULL,
      forks                = NULL,
      date                 = NULL,
      recent_commits_count = NULL,
      open_issues          = NULL
    )
  }
  
  if (is_blank(results$download) || !is.list(results$download)) {
    results$download <- list(
      total_download      = 0,
      last_month_download = 0
    )
  }
  
  # version_info is consumed by normalize_data() / extract_risk_inputs() in
  # get_risk_analysis(); a list shape with explicit NULL/NA fields keeps
  # those helpers on their happy path.
  if (is_blank(results$version_info) || !is.list(results$version_info)) {
    results$version_info <- list(
      all_versions              = NULL,
      last_version              = NULL,
      difference_version_months = NA_real_
    )
  }
  
  results
}


#' Initialise frugal-mode coverage list
#'
#' @description
#' Internal helper that returns a `covr_list` placeholder with the exact
#' nested keys [generate_html_report()] reads from `covr_list`:
#'
#' All numeric values are `0` so [generate_trace_matrix_section()] short-
#' circuits its `total_coverage == 0` branch and renders a "Traceability
#' matrix unsuccessful" placeholder rather than dereferencing missing
#' coverage columns.
#'
#' @return A list shaped like the output of
#'   `test.assessr::get_package_coverage()` but populated with frugal
#'   placeholders that flow safely through every accessor in
#'   [generate_html_report()] and [write_summary_report()].
#' @keywords internal
init_frugal_covr_list <- function() {
  list(
    multi_framework = FALSE,
    frameworks      = list(),
    total_cov       = 0,
    test_pkg_data   = list(),
    res_cov         = list(
      coverage = list(
        totalcoverage = 0,
        filecoverage  = NULL
      ),
      errors = NA_character_,
      notes  = NA_character_
    )
  )
}
