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
#' package_installed <- TRUE
#' covr_list <- test.assessr::get_package_coverage(
#'   pkg_source_path,
#'   package_installed
#' )
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
  
  if (tm_possible == FALSE) {
    tm_list <- create_empty_tm(pkg_name)
    message(glue::glue("no R folder to create traceability matrix for {pkg_name}"))
  } else {  
    
    # Get data.frame of exported functions
    exports_df <- get_exports(pkg_source_path)
    
    # Remove duplicates from exports for function and class
    exports_df <- exports_df %>%
      dplyr::distinct(exported_function, class, .keep_all = TRUE)
    
    # Resolve each exported function to its Rd page via assess_exported_functions_docs
    docs_result <- assess_exported_functions_docs(pkg_name, pkg_source_path)
    docs_df <- docs_result$data %>%
      dplyr::select(function_name, documentation_location) %>%
      dplyr::rename(documentation = documentation_location)
    
    # assess_exported_functions_docs uses getNamespaceExports(), which returns
    # S3 methods under their full name (e.g. "print.foo").  get_exports() stores
    # the same method as exported_function = "print", class = "foo".
    # Rows with a non-NA class originated from either s3_df (S3 methods) or
    # the list branch of s4_df (S4 methods).  The correct doc key differs:
    #
    #   S3-origin: "generic.class"  — matches getNamespaceExports() output and
    #              the alias entries in the Rd database.
    #   S4-origin: "generic"        — getNamespaceExports() returns only the
    #              generic name for exported S4 methods; all S4 methods for the
    #              same generic legitimately share the same Rd page.
    #
    # S4-origin rows always carry "S4" somewhere in function_type (either the
    # original "S4 function" label or the "S4 generic" / "S4 method, S4 generic"
    # label assigned by classify_function_body).  S3-origin rows may be
    # relabelled to "regular function" when the method body contains no
    # UseMethod() call, so checking for "S3" in function_type is insufficient.
    # Using the inverse — "not S4" — is the correct discriminator.
    exports_df <- exports_df %>%
      dplyr::mutate(
        .doc_key = dplyr::case_when(
          !is.na(class) & !is.na(function_type) &
            !grepl("S4", function_type, ignore.case = TRUE) ~
            paste0(exported_function, ".", class),
          TRUE ~ exported_function
        )
      )
    
    exports_df <- dplyr::left_join(
      exports_df,
      docs_df,
      by = c(".doc_key" = "function_name")
    ) %>%
      dplyr::select(-.doc_key)
    
    # Derive code_script from documentation location (man/foo.Rd -> R/foo.R).
    # This matches the keys used by func_coverage without requiring source-file parsing.
    exports_df <- exports_df %>%
      dplyr::mutate(
        code_script = dplyr::if_else(
          !is.na(documentation),
          sub("^man/", "R/", sub("\\.Rd$", ".R", documentation)),
          NA_character_
        )
      )
    
    # Rd topic names often use underscores while R sources use hyphens
    # (e.g. man/geom_alluvium.Rd vs R/geom-alluvium.r). Resolve against the
    # actual R/ tree so coverage joins succeed even when names differ.
    r_script_lookup <- build_r_script_lookup(pkg_source_path)
    if (length(r_script_lookup)) {
      exports_df <- exports_df %>%
        dplyr::mutate(
          code_script = dplyr::if_else(
            !is.na(code_script),
            dplyr::coalesce(
              unname(r_script_lookup[normalize_code_script_key(code_script)]),
              code_script
            ),
            code_script
          )
        )
      
      # ggproto exports are not functions and have no Rd page; infer from name.
      ggproto_na <- is.na(exports_df$code_script) &
        !is.na(exports_df$function_type) &
        exports_df$function_type == "ggproto"
      if (any(ggproto_na)) {
        inferred <- vapply(
          exports_df$exported_function[ggproto_na],
          function(fn) {
            key <- normalize_code_script_key(
              paste0("R/", camel_to_kebab(fn), ".r")
            )
            val <- unname(r_script_lookup[key])
            if (length(val) == 0L || is.na(val)) NA_character_ else val
          },
          FUN.VALUE = character(1)
        )
        exports_df$code_script[ggproto_na] <- inferred
      }
    }
    
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
          code_script = as.character(exports_df$code_script),
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
      # convert array to df (covr/test.assessr use a 1-D array with dimnames; plain vectors break
      # as.data.frame.table() with 'dimnames applied to non-array')
      
      fc <- func_covr$coverage$filecoverage
      if (!is.null(fc) && (is.numeric(fc) || is.integer(fc)) &&
          !is.array(fc) && !inherits(fc, "table")) {
        dn <- names(fc)
        if (is.null(dn)) dn <- as.character(seq_along(fc))
        fc <- structure(as.numeric(fc), dim = length(fc), dimnames = list(dn))
      }
      # stringsAsFactors = FALSE keeps Var1 as character; the default (TRUE)
      # would produce a factor whose integer codes break the downstream join.
      func_coverage <- as.data.frame.table(fc, stringsAsFactors = FALSE)
      
      # check for column existence
      column_exists <- function(df, column_name) {
        return(column_name %in% names(df))
      }
      cl_exists <- column_exists(func_coverage, "Var1")
      
      if (cl_exists == TRUE) {  
        
        # Step 1: Strip absolute temp-path prefix if Var1 contains full paths.
        # Works on Linux (/tmp/…), macOS (/var/folders/…), and Windows
        # (C:/Users/…/AppData/Local/Temp/…).
        # Step 1: Reduce each Var1 to its last two path components (e.g.
        # "R/foo.R"). extract_short_path is OS-agnostic (handles both "/" and
        # "\\") and does not depend on pkg_name, so it works even when covr
        # unpacks the source into a versioned directory like
        # "data.table-1.17.0/" where matching on "/<pkg_name>/" would fail.
        func_coverage$Var1 <- vapply(
          func_coverage$Var1,
          extract_short_path,
          FUN.VALUE = character(1),
          USE.NAMES = FALSE
        )
        
        # Step 2: Rename columns
        func_coverage <- func_coverage %>%
          rename(code_script = Var1, coverage_percent = Freq)
        
        # Step 3: If code_script values are bare filenames with no directory
        # separator (e.g. "foo.R" instead of "R/foo.R"), prepend "R/" so the
        # join key matches the format produced by fs::path_rel in exports_df.
        # After Step 1 all separators are already forward slashes, so only
        # "/" needs checking here.
        func_coverage$code_script <- ifelse(
          !is.na(func_coverage$code_script) &
            !grepl("/", func_coverage$code_script),
          paste0("R/", func_coverage$code_script),
          func_coverage$code_script
        )
        
        exports_df <- exports_df %>%
          dplyr::mutate(.join_key = normalize_code_script_key(code_script))
        
        func_coverage <- func_coverage %>%
          dplyr::mutate(.join_key = normalize_code_script_key(code_script)) %>%
          dplyr::distinct(.join_key, .keep_all = TRUE)
        
        # create total traceability matrix
        tm <- dplyr::left_join(
          exports_df,
          func_coverage %>% dplyr::select(.join_key, coverage_percent),
          by = ".join_key"
        ) %>%
          dplyr::select(-.join_key) 
        
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
    dplyr::filter(coverage_percent <= 60 | is.na(coverage_percent)) 
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
