#' Function to get suggested exported functions
#'
#' @description This function gets exported functions for all packages
#' in the Suggests section of the target package's DESCRIPTION file
#'
#' @param data - all packages listed in the DESCRIPTION file
#'
#' @return - data with package names and exported functions
#' @export
get_suggested_exp_funcs <- function(data) {
  
  # Additional checks for empty dataframe
  assert_non_empty_df <- function(x, var.name = deparse(substitute(x))) {
    checkmate::assert_data_frame(x, min.rows = 1, .var.name = var.name)
  }
  
  assert_non_empty_df(data)
  
  # Filter for Suggested packages
  data <- data |> dplyr::filter(type == "Suggests")
  
  if (nrow(data) != 0) { 
    
  # Use lapply to iterate over each package and get the exported functions
    result <- lapply(data$package, function(pkg) {
      tryCatch({
        exports <- getNamespaceExports(pkg)
        descriptions <- get_func_descriptions(pkg)
        # Highlighted change: Match each export with its corresponding description
        matched_descriptions <- sapply(exports, function(func) {
          if (func %in% names(descriptions)) {
            descriptions[[func]]
          } else {
            NA
          }
        })
        data.frame(package = pkg, functions = exports, descriptions = matched_descriptions, stringsAsFactors = FALSE)
      }, error = function(e) {
        data.frame(package = pkg, functions = e$message, descriptions = NA, stringsAsFactors = FALSE)
      })
    })
    
    # Combine the results into a single data frame
    result_df <- do.call(rbind, result)
    
    # Filter out rows with specific keywords in descriptions
    result_df <- result_df %>%
      dplyr::filter(!grepl("deprecated|superseded|imported|re-exported", descriptions, ignore.case = TRUE)) %>%
      # filter out these functions from the methods package 
      # as they have no documentation
      dplyr::filter(!grepl("^\\.__C__|^\\.__T__", functions))
  } else {
    result_df <- data.frame(
      package = character(),
      functions = character(),
      descriptions = character(),
      stringsAsFactors = FALSE
    )
  }

  return(result_df)
}
