#' Create a Traceability Matrix
#'
#' Returns a table that links all exported functions and their aliases to their documentation (`man` files),
#' the R scripts containing them, and the test scripts that reference them.
#' 
#' @param pkg_name name of package
#' @param pkg_source_path path to a source package
#' @param func_covr function coverage
#' @param verbose Logical (`TRUE`/`FALSE`). If `TRUE`, show any warnings/messages per function.
#' @param execute_coverage Logical (`TRUE`/`FALSE`). If `TRUE`, execute test coverage.
#'
#' @returns a nested list with fine grained traceability matrices
#' 
#' @examples
#' \dontrun{
#' # set CRAN repo to enable running of reverse dependencies
#' r = getOption("repos")
#' r["CRAN"] = "http://cran.us.r-project.org"
#' old <- options(repos = r)
#' 
#' dp <- system.file("test-data", "here-1.0.1.tar.gz", 
#'    package = "risk.assessr")
#' 
#' # Set up the package using the temporary file
#' install_list <- set_up_pkg(dp)
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
#' # Get package name and version
#' pkg_desc <- get_pkg_desc(pkg_source_path, 
#'                          fields = c("Package", 
#'                                     "Version"))
#' pkg_name <- pkg_desc$Package
#' test_pkg_data <- check_pkg_tests_and_snaps(pkg_source_path)
#' 
#' covr_timeout <- Inf
#' 
#' if (test_pkg_data$has_testthat || test_pkg_data$has_testit) {
#'   
#'   covr_list <- run_coverage(
#'     pkg_source_path,  
#'     covr_timeout
#'   )    
#' } else {
#'   message("No testthat or testit configuration")
#'   covr_list <- list(
#'     total_cov = 0,
#'     res_cov = list(
#'       name = pkg_name,
#'       coverage = list(
#'         filecoverage = matrix(0, nrow = 1, dimnames = list("No functions tested")),
#'         totalcoverage = 0
#'       ),
#'       errors = "No testthat or testit configuration",
#'       notes = NA
#'     )
#'   )
#' }
#' # run without test coverage   
#' tm_list_no_covr <- create_traceability_matrix(pkg_name, 
#'                                       pkg_source_path,
#'                                       execute_coverage = FALSE)   
#'                                       
#' # run with test coverage                                         
#' tm_list_covr <- create_traceability_matrix(pkg_name, 
#'                                       pkg_source_path,
#'                                       covr_list$res_cov)
#'                                       
#' # run with test coverage parameter but no test coverage list                                        
#' tm_list_no_covr_list <- create_traceability_matrix(pkg_name, 
#'                                       pkg_source_path)   
#'                                          
#' options(old)
#' }
#' 
#' @export
create_traceability_matrix <- function(pkg_name, 
                                       pkg_source_path, 
                                       func_covr = NULL,
                                       verbose = FALSE,
                                       execute_coverage = TRUE){
  
 
  message(glue::glue("creating traceability matrix for {pkg_name}"))
  
  # Check that package has an R folder
  tm_possible <- contains_r_folder(pkg_source_path) 
  # 
  if (tm_possible == FALSE) {
    tm_list <- create_empty_tm(pkg_name)
    message(glue::glue("no R folder to create traceability matrix for {pkg_name}"))
  } else {  
    
    # Get data.frame of exported functions
    exports_df <- get_exports(pkg_source_path)
    
    # Locate script for each exported function
    exports_df <- map_functions_to_scripts(exports_df, pkg_source_path, verbose)
    
    # Remove duplicates from exports for function and class
    exports_df <- exports_df %>%
      dplyr::distinct(exported_function, class, .keep_all = TRUE)
    
    # Map all Rd files to functions, then join back to exports
    exports_df <- map_functions_to_docs(exports_df, pkg_source_path, verbose)
    
    descrip <- get_func_descriptions(pkg_name)
    
    # Check if descrip is an empty named list and create descript_df accordingly
    if (length(descrip) == 0) {
      descript_df <- data.frame(
        exported_function = "No function found",
        description = "No description found"
      )
    } else {
      # Create df
      descript_df <- data.frame(
        exported_function = names(descrip),
        description = unlist(descrip, use.names = FALSE)
      )
    }
    
    exports_df <- dplyr::left_join(exports_df, 
                                   descript_df, 
                                   by = "exported_function")
    
   
    # Filter out rows with specific keywords in descriptions
    exports_df <- exports_df %>%
      dplyr::filter(!grepl("%>%", exported_function, ignore.case = TRUE)) %>%
      # filter out these functions from the methods package 
      # as they have no documentation
      dplyr::filter(!grepl("^\\.__C__|^\\.__T__", exported_function))
    
    if (execute_coverage == TRUE) {
      if (is.null(func_covr) || is.null(func_covr$coverage) || 
          is.null(func_covr$coverage$filecoverage)) {
        message(glue::glue("the execute_coverage parameter = TRUE but the 'function_coverage' object for {pkg_name} is NULL or non compliant"))
        
        # create dummy func_coverage to allow for 
        # tm creation without test coverage
        func_coverage <- data.frame(
          code_script = factor(exports_df$code_script),
          coverage_percent = rep(0, length(exports_df$code_script)),
          stringsAsFactors = FALSE
        )
        
        # create dummy filecoverage matrix
        filecoverage <- array(
          rep(0, length(func_coverage$code_script)),
          dim = length(func_coverage$code_script),
          dimnames = list(as.character(func_coverage$code_script))
        )
        
        # Set total coverage to 0
        totalcoverage <- 0
        
        # create empty function coverage list
        func_covr <- list(
          name = pkg_name,  
          coverage = list(
            filecoverage = filecoverage,
            totalcoverage = totalcoverage
          ),
          errors = "function coverage' is NULL or non compliant",
          notes = NA
        )
      }
      message(glue::glue("creating traceability matrices for {pkg_name} with test coverage"))
      # convert array to df
      func_coverage <- as.data.frame.table(func_covr$coverage$filecoverage)
      
      # check for column existence
      column_exists <- function(df, column_name) {
        return(column_name %in% names(df))
      }
      cl_exists <- column_exists(func_coverage, "Var1")
      
      if (cl_exists == TRUE) {  
        
        func_coverage <- func_coverage |> dplyr::rename(code_script = Var1, 
                                                        coverage_percent = Freq)
        
        # create total traceability matrix
        tm <- dplyr::left_join(exports_df, 
                               func_coverage, 
                               by = "code_script") 
        
        # create fine grained traceability matrices
        tm_list <- fine_grained_tms(tm, pkg_name)
        
        message(glue::glue("traceability matrices for {pkg_name} successful"))
      } else {
        tm_list <- create_empty_tm(pkg_name)
        message(glue::glue("traceability matrix for {pkg_name} unsuccessful"))
      }
    } else {
      message(glue::glue("creating traceability matrices for {pkg_name} without test coverage"))
      # initalise tm 
      tm <- exports_df
      
      # create dummy func_coverage to allow for 
      # tm creation without test coverage
      func_coverage <- data.frame(
        code_script = factor(exports_df$code_script),
        coverage_percent = rep(0, length(exports_df$code_script)),
        stringsAsFactors = FALSE
      )
      
      # create total traceability matrix
      tm <- dplyr::left_join(exports_df, 
                             func_coverage, 
                             by = "code_script") 
      
      # Remove duplicates from tm for function and class
      tm <- tm %>%
        dplyr::distinct(exported_function, class, .keep_all = TRUE)
      
      # create fine grained traceability matrices
      tm_list <- fine_grained_tms(tm, pkg_name)
      
    }
  }
  return(tm_list)
}

#' Get all exported functions and map them to R script where they are defined
#'
#' adapted from mpn.scorecard
#'
#' @param exports_df data.frame with a column, named `exported_function`,
#'   containing the names of all exported functions. Can also have other columns
#'   (which will be returned unmodified).
#' @param pkg_source_path a file path pointing to an unpacked/untarred package directory
#' @param verbose check for extra information
#'
#' @return A data.frame with the columns `exported_function` and `code_script`.
#' @keywords internal
map_functions_to_scripts <- function(exports_df, pkg_source_path, verbose){
 
  # Search for scripts functions are defined in
  funcs_df <- get_toplevel_assignments(pkg_source_path)
  
  if(nrow(funcs_df) == 0){
    # Triggering this means an R/ directory exists, but no assignments were found.
    exports_df <- data.frame()
    message("No top level assignments found in R folder for ", basename(pkg_source_path))
  } else {
  
    #Create join keys 
    exports_df <- exports_df %>% 
      dplyr::mutate(join_key = ifelse(is.na(class), 
                                      exported_function, 
                                      paste0(exported_function, ".", class)))
    # Perform the join
    exports_df <- dplyr::left_join(exports_df, funcs_df, by = c("join_key" = "func"))
    
    if (any(is.na(exports_df$code_script))) {
      if(isTRUE(verbose)) {
        missing_from_files <- exports_df$exported_function[is.na(exports_df$code_script)] %>%
          paste(collapse = "\n")
        message(glue::glue("The following exports were not found in R/ for {basename(pkg_source_path)}:\n{missing_from_files}\n\n"))
      }
    }
  }
  return(exports_df)
}

#' Remove specific symbols from vector of functions
#'
#' adapted from mpn.scorecard
#' 
#' @param funcs vector of functions to filter
#'
#' @keywords internal
filter_symbol_functions <- function(funcs){
  ignore_patterns <- c("\\%>\\%", "\\$", "\\[\\[", "\\[", "\\+", "\\%", "<-")
  pattern <- paste0("(", paste(ignore_patterns, collapse = "|"), ")")
  funcs_return <- grep(pattern, funcs, value = TRUE, invert = TRUE)
  return(funcs_return)
}

#' list all top-level objects defined in the package code
#'
#' adapted from mpn.scorecard
#' 
#' This is primarily for getting all _functions_, but it also returns top-level
#' declarations, regardless of type. This is intentional, because we also want
#' to capture any global variables or anything else that could be potentially
#' exported by the package.
#'
#' @param pkg_source_path a file path pointing to an unpacked/untarred package directory
#'
#' @return A data.frame with the columns `function` and `code_script` with a row for
#'   every top-level object defined in the package.
#'
#' @keywords internal
get_toplevel_assignments <- function(pkg_source_path){
  
  r_files <- tools::list_files_with_type(file.path(pkg_source_path, "R"), "code")
  
  # Triggering this means an R/ directory exists, but no R/Q/S files were found.
  if(rlang::is_empty(r_files)){
    # This shouldn't be triggered, and either indicates a bug in `get_toplevel_assignments`,
    # or an unexpected package setup that we may want to support.
    message(glue::glue("No sourceable R scripts were found in the R/ directory for package {basename(pkg_source_path)}. Make sure this was expected."))
    return(dplyr::tibble(func = character(), code_script = character()))
  }
  
  pkg_functions <- purrr::map_dfr(r_files, function(r_file_i) {
    
    exprs <- tryCatch(parse(r_file_i), error = identity)
    if (inherits(exprs, "error")) {
      warning("Failed to parse ", r_file_i, ": ", conditionMessage(exprs))
      return(dplyr::tibble(func = character(), code_script = character()))
    }
    
    calls <- purrr::keep(as.list(exprs), function(e) {
      if (is.call(e)) {
        op <- as.character(e[[1]])
        return(length(op) == 1 && op %in% c("<-", "=", "setGeneric", "setMethod"))
      }
      return(FALSE)
    })
    lhs <- purrr::map(calls, function(e) {
      name <- as.character(e[[2]])
      if (length(name) == 1) {
        return(name)
      }
    })
    
    function_names <- unlist(lhs) %||% character()
    if (length(function_names) == 0 ) {
      return(dplyr::tibble(func = character(), code_script = character()))
    }
    return(dplyr::tibble(
      func = function_names,
      code_script = rep(fs::path_rel(r_file_i, pkg_source_path), length(function_names))
    ))
  })
  # TODO: do we need to check if there are any funcs defined in multiple files?
  
  return(pkg_functions)
}

#' Map all Rd files to the functions they describe
#'
#' adapted from mpn.scorecard
#'
#' @return Returns the data.frame passed to `exports_df`, with a `documentation`
#'   column appended. This column will contain the path to the `.Rd` files in
#'   `man/` that document the associated exported functions.
#'
#' @keywords internal
map_functions_to_docs <- function(exports_df, pkg_source_path, verbose) {
  
  rd_files <- list.files(file.path(pkg_source_path, "man"), full.names = TRUE)
  rd_files <- rd_files[grep("\\.Rd$", rd_files)]
  if (length(rd_files) == 0) {
    if(isTRUE(verbose)){
      message("No top level assignments found in R folder for ", basename(pkg_source_path))
    }
    return(dplyr::mutate(exports_df, "documentation" = NA))
  }
  
  docs_df <- purrr::map_dfr(rd_files, function(rd_file.i) {
    rd_lines <- readLines(rd_file.i) %>% suppressWarnings()
    
    # Get Rd file and aliases for exported functions
    function_names_lines <- rd_lines[grep("(^\\\\alias)|(^\\\\name)", rd_lines)]
    function_names <- unique(gsub("\\}", "", gsub("((\\\\alias)|(\\\\name))\\{", "", function_names_lines)))
    
    man_name <- paste0(basename(rd_file.i))
    
    data.frame(
      pkg_function = function_names,
      documentation = rep(man_name, length(function_names))
    )
  })
  
  # if any functions are aliased in more than 1 Rd file, collapse those Rd files to a single row
  # TODO: is this necessary? is it even possible to have this scenario without R CMD CHECK failing?
  docs_df <- docs_df %>%
    dplyr::group_by(.data$pkg_function) %>%
    dplyr::summarize(documentation = paste(unique(.data$documentation), collapse = ", ")) %>%
    dplyr::ungroup()
  
  # join back to filter to only exported functions
  exports_df <- dplyr::left_join(exports_df, 
                                 docs_df, 
                                 by = c("join_key" = "pkg_function"))
  
  # Clean up the join_key column 
  exports_df <- exports_df %>% dplyr::select(-join_key)
  
  # message if any exported functions aren't documented
  if (any(is.na(exports_df$documentation)) && isTRUE(verbose)) {
    docs_missing <- exports_df %>% dplyr::filter(is.na(.data$documentation))
    exports_missing <- unique(docs_missing$exported_function) %>% paste(collapse = "\n")
    code_files_missing <- unique(docs_missing$documentation) %>% paste(collapse = ", ")
    message(glue::glue("In package `{basename(pkg_source_path)}`, the R scripts ({code_files_missing}) are missing documentation for the following exports: \n{exports_missing}"))
  }
  
  return(exports_df)
}

#' Create fine grained traceability matrices
#'
#' @param tm - general traceability matrix with no filtered information
#' @param pkg_name - name of the package
#'
#' @return - nested list with fine grained tms
#' @keywords internal
fine_grained_tms <- function(tm, pkg_name) {
    
    # create high risk coverage tm 
    high_risk_coverage_tm <- tm |> 
      dplyr::filter(coverage_percent <= 60) 
    if (nrow(high_risk_coverage_tm) == 0) {
      high_risk_coverage_tm <- create_empty_tm(pkg_name)
      message(glue::glue("high risk coverage traceability matrix for {pkg_name} not generated"))
    }
    
    # create medium risk coverage tm 
    medium_risk_coverage_tm <- tm |>
      dplyr::filter(coverage_percent > 60, coverage_percent < 80)
    if (nrow(medium_risk_coverage_tm) == 0) {
      medium_risk_coverage_tm <- create_empty_tm(pkg_name)
      message(glue::glue("medium risk coverage traceability matrix for {pkg_name} not generated"))
    }
    
    # create low risk coverage tm 
    low_risk_coverage_tm <- tm |>
      dplyr::filter(coverage_percent >= 80)  
    if (nrow(low_risk_coverage_tm) == 0) {
      low_risk_coverage_tm <- create_empty_tm(pkg_name)
      message(glue::glue("low risk coverage traceability matrix for {pkg_name} not generated"))
    }
   
    # create defunct function tm
    defunct_function_tm <- tm %>% 
      dplyr::filter(
        grepl("defunct|deprecated|deprec|superseded", function_body, ignore.case = TRUE) |
        grepl("defunct|deprecated|deprec|superseded", code_script, ignore.case = TRUE) |
        grepl("defunct|deprecated|deprec|superseded", description, ignore.case = TRUE) |
        grepl("defunct|deprecated|deprec|superseded", documentation, ignore.case = TRUE)
      )
    if (nrow(defunct_function_tm) == 0) {
      defunct_function_tm <- create_empty_tm(pkg_name)
      message(glue::glue("defunct functions traceability matrix for {pkg_name} not generated"))
    }
    
    # create imported function tm
    imported_function_tm <- tm %>% 
      dplyr::filter(
        grepl("imported", code_script, ignore.case = TRUE) | 
        grepl("imported", description, ignore.case = TRUE) |
        grepl("imported", documentation, ignore.case = TRUE)
      )  
    if (nrow(imported_function_tm) == 0) {
      imported_function_tm <- create_empty_tm(pkg_name)
      message(glue::glue("imported functions traceability matrix for {pkg_name} not generated"))
    }
    
    # create reexported function tm
    rexported_function_tm <- tm %>% 
      dplyr::filter(
        grepl("re-exported|reexports", code_script, ignore.case = TRUE) |
        grepl("re-exported|reexports", description, ignore.case = TRUE) |
        grepl("re-exported|reexports", documentation, ignore.case = TRUE)
      )
    
    if (nrow(rexported_function_tm) == 0) {
      rexported_function_tm <- create_empty_tm(pkg_name)
      message(glue::glue("rexported functions traceability matrix for {pkg_name} not generated"))
    }
  
    # create experimental function tm
    experimental_function_tm <- tm %>% 
      dplyr::filter(
        grepl("experimental", code_script, ignore.case = TRUE) |
          grepl("experimental", description, ignore.case = TRUE) |
          grepl("experimental", documentation, ignore.case = TRUE)
      )
    
    if (nrow(experimental_function_tm) == 0) {
      experimental_function_tm <- create_empty_tm(pkg_name)
      message(glue::glue("experimental functions traceability matrix for {pkg_name} not generated"))
    }
    
    # create a nested list
    tm_list <- list(
      tm = tm,
      coverage = list(
        high_risk = high_risk_coverage_tm,
        medium_risk = medium_risk_coverage_tm,
        low_risk = low_risk_coverage_tm
      ),
      function_type = list(
        defunct = defunct_function_tm,
        imported = imported_function_tm,
        rexported = rexported_function_tm,
        experimental = experimental_function_tm
      )
    )
  
  return(tm_list)
}



