#' Read Description file and parse the package name and version
#'
#' @param pkg_source_path path to package source code (untarred)
#' @param fields - select specified elements from description
#'
#' @return list with package description
#' @keywords internal
get_pkg_desc <- function(pkg_source_path, fields = NULL){
  
  pkg_desc_path <- file.path(pkg_source_path, "DESCRIPTION")
  
  desc_file <- read.dcf(pkg_desc_path, fields = fields)[1L,]
  pkg_desc <- as.list(desc_file)
  
  return(pkg_desc)
}

#' Get risk metadata
#'
#' @param executor - user who executes the riskmetrics process 
#' 
#' adapted from mrgvalprep::get_sys_info() and mpn.scorecard
#' @importFrom rlang %||%
#' 
#' @return list with metadata
#' @keywords internal
get_risk_metadata <- function(executor = NULL) {
  checkmate::assert_string(executor, null.ok = TRUE)
  
  metadata <- list(
    datetime = as.character(Sys.time()),
    executor = executor %||% Sys.getenv("USER"),
    info = list()
  )
  
  metadata[["info"]][["sys"]] <- as.list(Sys.info())[c("sysname", "version", "release", "machine")]
  
  return(metadata)
}

#' Assign output file path for various outputs during scorecard rendering
#'
#' @param out_dir output directory for saving results
#' @param ext file name and extension
#'
#' @details
#' The basename of `out_dir` should be the package name and version pasted together
#' @keywords internal
get_result_path <- function(
     out_dir,
     ext = c("check.rds", "covr.rds", "tm_doc.rds", "tm_doc.xlsx")){
   
   ext <- match.arg(ext)
   
   pkg_name <- basename(out_dir)
   
   file.path(out_dir, paste0(pkg_name,".",ext))
 }

#' get package name for display
#'
#' @param input_string - string containing package name
#'
#' @return pkg_disp - package name for display
#'
#' @examples
#' \donttest{
#' pkg_source_path <- "/home/user/R/test.package.0001_0.1.0.tar.gz"
#' pkg_disp_1 <- get_pkg_name(pkg_source_path)
#' print(pkg_disp_1)
#' 
#' pkg <- "TxDb.Dmelanogaster.UCSC.dm3.ensGene_3.2.2.tar.gz"
#' pkg_disp_2 <- get_pkg_name(pkg)
#' print(pkg_disp_2)
#' }
#' 
#' @export
get_pkg_name <- function(input_string) {
  
  # detect path separators: both forward slash (Unix/macOS) and backslash (Windows)
  test_string <- stringr::str_match(input_string, "[/\\\\]")
  
  if (any(is.na(test_string)) == FALSE) {
    # extract package name from the last component of the file path
    input_string <- stringr::str_split_i(input_string, "[/\\\\]", -1)
    
  }
  
  # extract package name
  pkg_disp <- stringr::str_extract(input_string, "[^-|_]+")
  
  return(pkg_disp)
}

#' Helper to extract "R/<file>" from any path by taking the last two components
#'
#' @param long_file_name A string containing the full file path (supports forward 
#'  slash or backslash))
#'
#' @return A character string composed of the last two path components, e.g., "R/add.R"
#'
#' @keywords internal
extract_short_path <- function(long_file_name) {
  if (is.na(long_file_name)) {
    result <- NA_character_
  } else {
    parts <- unlist(strsplit(long_file_name, "[/\\\\]"))
    trailing_sep <- grepl("[/\\\\]$", long_file_name)
    parts <- parts[parts != ""]
    if (length(parts) == 0) {
      result <- ""
    } else if (length(parts) == 1) {
      result <- if (trailing_sep) paste0(parts[1], "/") else parts[1]
    } else {
      if (trailing_sep) {
        result <- paste0(parts[length(parts)], "/")
      } else {
        result <- paste0(parts[length(parts) - 1], "/", parts[length(parts)])
      }
    }
  }
  return(result)
}
