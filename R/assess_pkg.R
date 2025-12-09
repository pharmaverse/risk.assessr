#' Assess package
#'  
#' @description assess package for risk metrics
#' 
#' @param pkg_source_path - source path for install local
#' @param rcmdcheck_args - arguments for R Cmd check - these come from setup_rcmdcheck_args
#' @param covr_timeout - setting for covr time out
#'
#' @return list containing results - list containing metrics, covr, tm - trace matrix, and R CMD check
#' 
#' @examples
#' \dontrun{
#' # set CRAN repo to enable running of reverse dependencies
#' r = getOption("repos")
#' r["CRAN"] = "http://cran.us.r-project.org"
#' old <- options(repos = r)
#' 
#' pkg_source_path <- system.file("test-data", "here-1.0.1.tar.gz", 
#'    package = "risk.assessr")
#' pkg_name <- sub("\\.tar\\.gz$", "", basename(pkg_source_path)) 
#' modified_tar_file <- modify_description_file(pkg_source_path)
#' 
#' # Set up the package using the temporary file
#' install_list <- set_up_pkg(modified_tar_file)
#' 
#' # Extract information from the installation list
#' build_vignettes <- install_list$build_vignettes
#' package_installed <- install_list$package_installed
#' pkg_source_path <- install_list$pkg_source_path
#' rcmdcheck_args <- install_list$rcmdcheck_args
#' 
#' # check if the package needs to be installed locally
#' package_installed <- install_package_local(pkg_source_path)
#' 
#' # Check if the package was installed successfully
#' if (package_installed == TRUE) {
#'   # Assess the package
#'   assess_package <- assess_pkg(pkg_source_path, rcmdcheck_args)
#'   # Output the assessment result
#' } else {
#'   message("Package installation failed.")
#' }
#' options(old)
#' }
#' @export
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
  results$has_maintainer <- doc_scores$has_maintainer
  results$size_codebase <- doc_scores$size_codebase 
  results$has_news <- doc_scores$has_news
  results$has_source_control <- doc_scores$has_source_control
  results$has_vignettes <- doc_scores$has_vignettes
  results$has_website <- doc_scores$has_website
  results$news_current <- doc_scores$news_current
  results$export_help <- doc_scores$export_help 
  
  test_pkg_data <- check_pkg_tests_and_snaps(pkg_source_path)
  results$tests <- test_pkg_data
  
  if (test_pkg_data$has_testthat || test_pkg_data$has_testit) {
    
    covr_list <- run_coverage(
      pkg_source_path,  
      covr_timeout
    )    
  } else {
    message("No testthat or testit configuration")
    covr_list <- list(
      total_cov = 0,
      res_cov = list(
        name = pkg_name,
        coverage = list(
          filecoverage = matrix(0, nrow = 1, dimnames = list("No functions tested")),
          totalcoverage = 0
        ),
        errors = "No testthat or testit configuration",
        notes = NA
      )
    )
    
  }
    
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
  
  # tryCatch to allow for continued processing of risk metric data
  results$suggested_deps <- tryCatch(
    withCallingHandlers(
      check_suggested_exp_funcs(pkg_name, pkg_source_path, deps),
      error = function(e) {
        results$suggested_deps <<- rbind(results$suggested_deps, data.frame(
          source = pkg_name,
          function_type = "Unknown",
          suggested_function = "Error in checking suggested functions",
          where = NA,
          stringsAsFactors = FALSE
        ))
        invokeRestart("muffleError")
      }
    ),
    error = function(e) {
      message("An error occurred in checking suggested functions: ", e$message)
      NULL
    }
  )
  
  results$export_calc <- assess_exports(pkg_source_path)

  # dependencies
  results$dependencies <- risk.assessr::get_session_dependencies(deps)
  
  # author
  pkg_author <- get_pkg_author(pkg_name, pkg_source_path)
  results$author <- pkg_author
  
  # license
  pkg_license <- get_pkg_license(pkg_name, pkg_source_path)
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
    
    revdeps_list <- get_reverse_dependencies(pkg_source_path)
    results$rev_deps <- revdeps_list
        
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
