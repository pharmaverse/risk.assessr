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
  
  # Unique function names, dropping NA / empty entries. Without this an NA in
  # suggested_exp_func$functions would become a literal "NA" alternative in
  # the regex below.
  all_functions <- unique(suggested_exp_func$functions)
  all_functions <- all_functions[!is.na(all_functions) & nzchar(all_functions)]
  
  # Defensive shortcut: if nothing is left to match against, return an empty
  # result with the expected schema instead of building a degenerate '()' regex.
  if (length(all_functions) == 0L) {
    return(dplyr::tibble(
      source = character(0),
      suggested_function = character(0),
      targeted_package = character(0),
      message = character(0)
    ))
  }
  
  # Sort longest-first so e.g. "mean_se" wins over "mean" at the same starting
  # position in ICU alternation (left-to-right semantics).
  all_functions <- all_functions[order(nchar(all_functions), decreasing = TRUE)]
  
  # Quote every name as ICU literal text (\Q...\E) so regex metacharacters
  # that legitimately appear in R names ('.', '[', '(', '|', '%', '+', '-')
  # cannot break the alternation. Names like '%in%', '[<-.integer64',
  # '+.Date', 'as.data.frame' are handled the same way as plain names.
  #
  # The boundary uses (?<!\w)...(?!\w) instead of \b. For names composed of
  # word characters this is exactly equivalent to \b (it still rejects
  # substring hits like 'mean' inside 'meaningful'). For names whose first or
  # last character is non-word (e.g. '%in%') \b can never anchor, so dropping
  # it and using lookarounds is required.
  escaped <- paste0("\\Q", all_functions, "\\E")
  alt_pattern <- paste0(
    "(?<!\\w)(", paste(escaped, collapse = "|"), ")(?!\\w)"
  )
  
  # Per-name anchored pattern reused by the is_assignment / is_parameter
  # heuristics so they handle special-character names too. The previous
  # construction (`paste0("\\b", call, "\\b...")`) raised
  # "invalid regular expression '\\b[data\\b\\s*(<-|=)'" for names beginning
  # with '[' and similar.
  anchored <- function(call) paste0("(?<!\\w)\\Q", call, "\\E(?!\\w)")
  
  # Cheap word-character test on a single character. Uses base R + a one-char
  # regex (always trivially valid) so the fallback below does NOT share a
  # failure mode with the ICU engine that just errored. `\w` in PCRE is
  # [A-Za-z0-9_]; matching that explicitly avoids any locale surprises.
  is_word_char <- function(ch) {
    nzchar(ch) && grepl("[A-Za-z0-9_]", ch, perl = TRUE)
  }
  
  extract_calls <- function(body) {
    tryCatch(
      unique(unlist(stringr::str_extract_all(body, alt_pattern))),
      error = function(e) {
        warning(
          paste0(
            "process_items_matched: regex extraction failed (",
            conditionMessage(e),
            "); falling back to fixed-string matching."
          ),
          call. = FALSE
        )
        # Boundary-preserving fallback. A naive str_detect(body, fixed(fn))
        # would match `mean` inside `meaningful`, producing false positives
        # that the downstream is_assignment / is_parameter heuristics do NOT
        # catch (those heuristics use the same anchored regex as the happy
        # path and so reject the surrounding context, but the row has
        # already been added to function_calls and survives both filters
        # with is_assignment = is_parameter = FALSE).
        #
        # To stay consistent with the main alt_pattern's (?<!\w)...(?!\w)
        # boundary semantics, we locate every literal occurrence of `fn`
        # and keep the row only if at least one occurrence is flanked by
        # non-word characters (or string boundaries). All operations here
        # use literal matching + single-character base-R checks, so the
        # fallback succeeds even when the main regex engine failed.
        hits <- vapply(
          all_functions,
          function(fn) {
            locs <- stringr::str_locate_all(body, stringr::fixed(fn))[[1]]
            if (nrow(locs) == 0L) return(FALSE)
            any(vapply(seq_len(nrow(locs)), function(i) {
              s <- locs[i, "start"]
              e <- locs[i, "end"]
              before <- if (s == 1L)          "" else substr(body, s - 1L, s - 1L)
              after  <- if (e == nchar(body)) "" else substr(body, e + 1L, e + 1L)
              !is_word_char(before) && !is_word_char(after)
            }, logical(1)))
          },
          logical(1)
        )
        all_functions[hits]
      }
    )
  }
  
  # step 1 - extract function calls
  processed_items_int <- items_matched %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      function_calls = list(extract_calls(suggested_function))
    ) %>%
    tidyr::unnest(function_calls) %>%
    dplyr::filter(nzchar(function_calls)) %>%
    dplyr::mutate(
      is_assignment = vapply(function_calls, function(call) {
        any(grepl(
          paste0(anchored(call), "\\s*(<-|=)"),
          suggested_function, perl = TRUE
        ))
      }, logical(1)),
      is_parameter = vapply(function_calls, function(call) {
        a <- anchored(call)
        in_parens   <- any(grepl(paste0("\\(.*", a, ".*\\)"),
                                 suggested_function, perl = TRUE))
        is_assign   <- any(grepl(paste0(a, "\\s*(<-|=)"),
                                 suggested_function, perl = TRUE))
        is_call_lhs <- any(grepl(paste0(a, "\\s*\\("),
                                 suggested_function, perl = TRUE))
        in_parens & !is_assign & !is_call_lhs
      }, logical(1))
    ) %>%
    dplyr::ungroup()
  
  # Filter out assignments and named parameters, then drop the helper cols.
  processed_items_final <- processed_items_int %>%
    dplyr::filter(!is_assignment, !is_parameter) %>%
    dplyr::select(-is_assignment, -is_parameter)
  
  # function_calls is already the bare function name (one of all_functions),
  # so use it directly. Do NOT run str_extract(..., "\\w+$") here -- it would
  # return NA for '%in%' and truncate '[<-.integer64' to 'integer64', causing
  # the subsequent match() against suggested_exp_func$functions to miss.
  processed_items <- processed_items_final %>%
    dplyr::mutate(
      suggested_function = function_calls,
      targeted_package = suggested_exp_func$package[
        match(function_calls, suggested_exp_func$functions)
      ],
      message = "Please check if the targeted package should be in Imports"
    ) %>%
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
#' @keywords internal
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
          message(paste0("No exported functions from source package ", pkg_name))
          suggested_matched_functions <- data.frame(
            source = pkg_name,
            suggested_function = NA,
            targeted_package = NA,
            message = paste0("No exported functions from source package ", pkg_name)
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
