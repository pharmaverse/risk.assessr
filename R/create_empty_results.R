#' Create empty results
#' 
#' @description This creates an empty results list
#' for all risk metrics
#'
#' @param pkg_name package name
#' @param pkg_ver package version
#' @param pkg_source_path package source path
#' @param metadata list with metadata
#' 
#' @return - list with empty risk profile values
#' 
#' @keywords internal
create_empty_results <- function(pkg_name,
                                 pkg_ver,
                                 pkg_source_path,
                                 metadata) {

results <- list(
  pkg_name = pkg_name,
  pkg_version = pkg_ver,
  pkg_source_path = pkg_source_path,
  date_time = metadata$datetime,
  executor = metadata$executor,
  sysname = metadata$info$sys$sysname,
  version = metadata$info$sys$version,
  release = metadata$info$sys$release,
  machine = metadata$info$sys$machine,
  comments = " ",
  has_bug_reports_url = "",
  license = "",
  license_name = "",
  has_examples = "",
  has_maintainer = "",
  size_codebase = "",
  has_news = "",
  has_source_control= "",
  has_vignettes = "",
  has_website = "",
  news_current = "",
  export_help = "",
  export_calc = "",
  check = "",
  covr = "",
  dependencies = "",
  suggested_deps = "",
  rev_deps = "",
  author = "",
  host = "",
  github_data = "",
  version_info = "",
  download = ""
)
return(results)
}



