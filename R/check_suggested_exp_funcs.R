#' Create items matched
#' 
#' @description create a df with functions that match exported functions from
#' a suggested package
#'  
#' @param extracted_functions - exported functions from the target package
#' @param suggested_exp_func - exported functions from a suggested package
#'
#' @keywords internal
create_items_matched <- function(extracted_functions, suggested_exp_func) {
  
  items_matched <- extracted_functions %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      matched = any(stringr::str_detect(suggested_function, 
                                        paste0("(", suggested_exp_func$package, 
                                               "::)?", 
                                               suggested_exp_func$exported_functions)))
    ) %>%
    dplyr::filter(matched) %>%
    dplyr::select(-matched)
  
  return(items_matched)
}

#' process items matched
#' 
#' @description create a df with functions that match exported functions from
#' a suggested package
#' 
#' @details This function extracts all the functions from the function body 
#' and filters them to keep only function calls
#' It also extracts all the valid function names, matches with the source package
#' and writes a message
#'  
#' @param items_matched - exported functions match the suggested package function
#' @param suggested_exp_func - exported functions from a suggested package
#'
#' @keywords internal
process_items_matched <- function(items_matched, suggested_exp_func) {
  
  # get all unique function names
  all_functions <- unique(suggested_exp_func$functions)
  
  # step 1 - extract function calls
  processed_items_int <- items_matched %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      function_calls = list(unique(unlist(
        stringr::str_extract_all(
          suggested_function,
          paste0("\\b(", paste(all_functions, collapse = "|"), ")\\b")
        )
      )))
    ) %>%
    tidyr::unnest(function_calls) %>%
    dplyr::filter(function_calls != "") %>% # Filter to keep non-empty function calls
    dplyr::filter(!grepl("\\(", function_calls)) %>% # Filter to exclude calls with parentheses
    dplyr::mutate(
      function_calls = gsub("[^a-zA-Z0-9_]", "", function_calls), # Remove non-alphanumeric characters
      is_assignment = sapply(function_calls, function(call) {
        # Caused by error in `grepl()`:
        # ! invalid regular expression '\b[data\b\s*(<-|=)', reason 'Missing ']''
        any(grepl(paste0("\\b", call, "\\b\\s*(<-|=)"), suggested_function, perl = TRUE))
      }),
      is_parameter = sapply(function_calls, function(call) {
        any(grepl(paste0("\\(", ".*\\b", call, "\\b", ".*\\)"), suggested_function, perl = TRUE)) &
          !any(grepl(paste0("\\b", call, "\\b\\s*(<-|=)"), suggested_function, perl = TRUE)) &
          !any(grepl(paste0("\\b", call, "\\b\\s*\\("), suggested_function, perl = TRUE))
      })
    ) %>%
    dplyr::ungroup()
  
  # Ensure is_assignment and is_parameter are logical vectors
  processed_items_int <- processed_items_int %>%
    dplyr::mutate(
      is_assignment = as.logical(is_assignment),
      is_parameter = as.logical(is_parameter)
    )
  
  # Filter out assignments
  processed_items_no_assignments <- processed_items_int %>%
    dplyr::filter(!is_assignment)
  
  # Filter out parameters
  processed_items_no_parameters <- processed_items_no_assignments %>%
    dplyr::filter(!is_parameter)
  
  # Remove the temporary columns
  processed_items_final <- processed_items_no_parameters %>%
    dplyr::select(-is_assignment, -is_parameter)
  
  # extract function names and set up targeted package and message
  processed_items <- processed_items_final %>%
    dplyr::mutate(
      suggested_function = stringr::str_extract(function_calls, "\\w+$"),  # Changed: Extract only the function names
      targeted_package = suggested_exp_func$package[match(function_calls, suggested_exp_func$functions)], 
      message = "Please check if the targeted package should be in Imports"
    ) %>%
    # filter(!is.na(source_package)) %>%
    dplyr::distinct(source, suggested_function, targeted_package, message) %>%
    dplyr::select(source, suggested_function, targeted_package, message)
  
  return(processed_items)
}





#' Function to check suggested exported functions
#'
#' @description This function checks the exported functions of target package
#' against the exported functions of Suggested dependencies to see if any 
#' Suggested packages should be in Imports in the DESCRIPTION file
#'
#' @param pkg_name - name of the target package   
#' @param pkg_source_path - source of the target package 
#' @param suggested_deps - dependencies in Suggests
#'
#' @return - data frame with results of Suggests check
#' @export
check_suggested_exp_funcs <- function(pkg_name, 
                                      pkg_source_path, 
                                      suggested_deps) {
  
  # Input checks
  checkmate::assert_string(pkg_name)
  checkmate::assert_string(pkg_source_path)
  checkmate::assert_class(suggested_deps, "data.frame")
  
  assert_non_empty_string <- function(x, var.name = deparse(substitute(x))) {
    checkmate::assert_string(x, min.chars = 1, .var.name = var.name)
    if (x == "" || x == " ") {
      stop(sprintf("%s cannot be an empty string", var.name))
    }
  }
  
  assert_non_empty_string(pkg_name)
  assert_non_empty_string(pkg_source_path)
  
  # check if there are any dependencies to be checked
  if (nrow(suggested_deps) != 0) {
    # Check if the package source path contains an R folder
    exp_possible <- contains_r_folder(pkg_source_path)
    
    if (exp_possible == TRUE) {
      # Get the exported functions from the package source path
      exp_func <- get_exports(pkg_source_path)
      
      # rename columns in exp_func to match 
      exp_func <- exp_func %>%
         dplyr::rename(
           source = exported_function,
           suggested_function = function_body
           )
      
      #rename df for further processing
      func_df <- exp_func
      
      # Get the suggested exported functions
      suggested_exp_func <- get_suggested_exp_funcs(suggested_deps)
      
      # Function to test if each column has no values
      test_no_values <- function(df) {
        sapply(df, function(column) all(is.na(column)))
      }
      
      # test for no values
      no_values_test <- test_no_values(suggested_exp_func)
      
      if (!all(no_values_test)) {
        
        # check if func_df is empty of values    
        is_empty <- func_df %>% 
          dplyr::summarise_all(~ all(is.na(.) | . == " ")) %>% 
          unlist() %>% all()
        
        if (is_empty) {
          message(glue::glue("No exported functions from source package {pkg_name}"))
          suggested_matched_functions <- data.frame(
            source = pkg_name,
            suggested_function = NA,
            targeted_package = NA,
            message = glue::glue("No exported functions from source package {pkg_name}")
          ) 
        } else {
          
          items_matched <- create_items_matched(func_df, 
                                                suggested_exp_func)
          
          
          suggested_matched_functions <- 
            process_items_matched(items_matched, 
                                  suggested_exp_func)
        }
        
      } else {
        message("No Suggested packages in the DESCRIPTION file")
        suggested_matched_functions <- data.frame(
          source = pkg_name,
          suggested_function = NA,
          targeted_package = NA,
          message = "No Suggested packages in the DESCRIPTION file"
        ) 
      }
    } else {
      message("No R folder found in the package source path")
      suggested_matched_functions <- data.frame(
        source = pkg_name,
        suggested_function = NA,
        targeted_package = NA,
        message = "No R folder found in the package source path"
      )  
      
    }
    
    # check if suggested_matched functions is empty of values    
    is_empty <- suggested_matched_functions %>% 
      dplyr::summarise_all(~ all(is.na(.) | . == " ")) %>% 
      unlist() %>% all()
    
    if (is_empty) {
      message("No exported functions from Suggested packages in the DESCRIPTION file")
      suggested_matched_functions <- data.frame(
        source = pkg_name,
        suggested_function = NA,
        targeted_package = NA,
        message = "No exported functions from Suggested packages in the DESCRIPTION file"
      ) 
    }
  } else {
    message("No Imports or Suggested packages in the DESCRIPTION file")
    suggested_matched_functions <- data.frame(
      source = pkg_name,
      suggested_function = NA,
      targeted_package = NA,
      message = "No Imports or Suggested packages in the DESCRIPTION file"
    ) 
  }
  
  
  return(suggested_matched_functions)
}
