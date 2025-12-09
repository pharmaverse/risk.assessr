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
  
  # check if input string is a file path or filename   
  test_string <-  stringr::str_match(input_string, "/")  
  
  if (any(is.na(test_string)) == FALSE) {
    # extract package name from the last part of the file path
    input_string <- stringr::str_split_i(input_string, "/", -1)  
    
  }
  
  # extract package name
  pkg_disp <- stringr::str_extract(input_string, "[^-|_]+")
  
  return(pkg_disp)
}

