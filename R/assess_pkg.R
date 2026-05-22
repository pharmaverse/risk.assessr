#' Assess package
#'  
#' @description assess package for risk metrics
#' 
#' @param pkg_source_path - source path for install local
#' @param rcmdcheck_args - arguments for R Cmd check - these come from setup_rcmdcheck_args
#' @param covr_timeout - setting for covr time out
#'
#' @return list containing results - list containing metrics, covr, tm - trace matrix, and R CMD check
#' @keywords internal
assess_pkg <- function(
    pkg_source_path,
    rcmdcheck_args,
    covr_timeout = Inf
) {
  # record covr tests
  options(covr.record_tests = TRUE)
  
  # Input checking
  checkmate::assert_string(pkg_source_path)
  checkmate::assert_directory_exists(pkg_source_path)
  checkmate::assert_list(rcmdcheck_args)
  checkmate::assert_numeric(rcmdcheck_args$timeout)
  checkmate::anyInfinite(rcmdcheck_args$timeout)
  checkmate::check_character(rcmdcheck_args$args, pattern = "--no-manual")
  checkmate::check_character(rcmdcheck_args$args, pattern = "--ignore-vignettes")
  checkmate::check_character(rcmdcheck_args$args, pattern = "--no-vignettes")
  checkmate::check_character(rcmdcheck_args$args, pattern = "--as-cran")
  checkmate::check_character(rcmdcheck_args$build_args, pattern = "--no-build-vignettes|NULL")
  checkmate::assert_string(rcmdcheck_args$env)
  checkmate::check_logical(rcmdcheck_args$quiet)
  
  # Get package name and version
  pkg_desc <- get_pkg_desc(pkg_source_path, 
                                               fields = c("Package", 
                                                          "Version"))
  pkg_name <- pkg_desc$Package
  pkg_ver <- pkg_desc$Version
  pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)

  metadata <- get_risk_metadata()
  results <- create_empty_results(pkg_name, pkg_ver, pkg_source_path, metadata)
  doc_scores <- doc_riskmetric(pkg_name, pkg_ver, pkg_source_path)
  
  # doc data
  results$has_bug_reports_url <- doc_scores$has_bug_reports_url
  results$license <- doc_scores$license
  results$has_examples <- doc_scores$has_examples
  results$has_docs <- doc_scores$has_docs
  results$has_ex_docs_score <- doc_scores$has_ex_docs_score
  results$has_maintainer <- doc_scores$has_maintainer
  results$size_codebase <- doc_scores$size_codebase 
  results$has_news <- doc_scores$has_news
  results$has_source_control <- doc_scores$has_source_control
  results$has_vignettes <- doc_scores$has_vignettes
  results$has_website <- doc_scores$has_website
  results$news_current <- doc_scores$news_current
  results$export_help <- doc_scores$export_help 
  
  message(paste0("Getting unit test coverage for ", pkg_name))
  
  if (is.null(pkg_source_path) || !nzchar(pkg_source_path)) {
    warning(paste("`pkg_source_path` is missing. Returning NULL."))
    return(NULL)
  } else {
    package_installed <- TRUE
  }
    
  covr_list <- test.assessr::get_package_coverage(pkg_source_path, 
                                                  package_installed)
  
  message(paste0("Unit test coverage for ", pkg_name, "  finished"))
  
  # add test types to results
  results$tests <- covr_list$test_pkg_data
  
  # add total coverage to results
  results$covr <- covr_list$total_cov
  
  if (is.na(results$covr) | results$covr == 0L) {
    #  create empty traceability matrix
    tm_list <- create_empty_tm(pkg_name)
  } else {
    #  create traceability matrix
    tm_list <- create_traceability_matrix(pkg_name, 
                                     pkg_source_path,
                                     covr_list$res_cov) 
  }
  # run R Cmd check
  rcmdcheck_args$path <- pkg_source_path
  check_list <- run_rcmdcheck(pkg_source_path, rcmdcheck_args) # use tarball
  
  # add rcmd check score to results
  results$check <- check_list$check_score
  
  deps <- get_dependencies(pkg_source_path)
  
  # add suggested dependencies to results
  fallback_suggested_deps <- data.frame(
    source             = pkg_name,
    suggested_function = NA_character_,
    message            = "Error in checking suggested functions",
    where              = NA_character_,
    stringsAsFactors   = FALSE
  )
  
  results$suggested_deps <- tryCatch(
    {
      out <- check_suggested_exp_funcs(pkg_name, pkg_source_path, deps)
      # Normalize to a data.frame
      if (is.null(out)) {
        fallback_suggested_deps
      } else if (is.data.frame(out)) {
        out
      } else {
        # Coerce or fallback if the helper returns another type
        fallback_suggested_deps
      }
    },
    error = function(e) {
      message("An error occurred in checking suggested functions: ", conditionMessage(e))
      fallback_suggested_deps
    }
  )
  
  
  results$export_calc <- assess_exports(pkg_source_path)

  # dependencies
  results$dependencies <- risk.assessr::get_session_dependencies(deps)
  
  # author
  pkg_author <- get_pkg_author(pkg_name, pkg_source_path)
  results$author <- pkg_author
  
  # license
  pkg_license <- extract_license_from_description(pkg_source_path)
  results$license_name <- pkg_license
  
  # get host repo
  pkg_host <- get_host_package(pkg_name, pkg_ver, pkg_source_path)
  results$host <- pkg_host
  
  owner <- get_repo_owner(pkg_host$github_links, pkg_name)
  
  # get github Data
  github_data <- get_github_data(owner, pkg_name)
  results$github_data <- github_data

  download_list <- list("total_download" = get_cran_total_downloads(pkg_name),
                        "last_month_download" = get_cran_total_downloads(pkg_name, months=1)
  )
  
  results$download <- download_list
  
  # Get versions
  version_info <- list("all_versions" = NULL,
                       "last_version" =  NULL)  
  
  if (!is.null(pkg_host$cran_links)) {
    
    result_cran <- check_and_fetch_cran_package(pkg_name, pkg_ver)

    version_info <- list("all_versions" = result_cran$all_versions,
                          "last_version" =  result_cran$last_version)
    

    results$rev_deps <-  cran_revdep(pkg_name) 
        
  } else if (!is.null(pkg_host$bioconductor_links)) {
    
    html_content <- fetch_bioconductor_releases()
    release_data <- parse_bioconductor_releases(html_content)
    result_bio <- get_bioconductor_package_url(pkg_name, pkg_ver, release_data)
    
    all_versions <- result_bio$all_versions
    last_version <- result_bio$last_version
    bioconductor_version_package <- result_bio$bioconductor_version_package
    
    version_info <- list("all_versions" = all_versions,
                         "last_version" =  last_version,
                         "bioconductor_version_package" = bioconductor_version_package)
    
    
    results$rev_deps <- bioconductor_reverse_deps(pkg_name, version = bioconductor_version_package)
    
  }
  
  all_versions <- version_info$all_versions
  last_version <- version_info$last_version

  if (!is.null(all_versions)) {

    index <- which(sapply(all_versions, function(x) x$version == pkg_ver))
    
    if (length(index) == 0) {
      index <- length(all_versions)
    }
    
    current_date <- as.Date(all_versions[[index]]$date)
    last_date <- as.Date(last_version$date)
    
    difference_months <- length(seq(current_date, last_date, by = "month")) - 1
    version_info$difference_version_months <- difference_months
    
  } else {
    version_info$difference_version_months <- NA
  }
  
  results$version_info <- version_info
  
  # this allows for packages not on CRAN or bioconductor to be processed
  # Check if rev_deps is NULL or contains only empty strings
  if (is.null(results$rev_deps) || all(results$rev_deps == "")) {
    results$rev_deps <- 0
  }
  
  
  # # Replace empty string revdep_score with 0
  # if (results$revdep_score == "") {
  #   results$revdep_score <- 0
  # }
  
  results <- rapply( results, f=function(x) ifelse(is.nan(x),0,x), how="replace" )	  
  results <- rapply( results, f=function(x) ifelse(is.na(x),0,x), how="replace" )
  
  return(list(
              results = results,
              covr_list = covr_list,
              tm_list = tm_list,
              check_list = check_list,
              risk_analysis = get_risk_analysis(results)
              ))
}