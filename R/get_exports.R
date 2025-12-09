#' list all package exports
#'
#'
#' @param pkg_source_path a file path pointing to an unpacked/untarred package directory
#'
#' @return data.frame, with one column `exported_function`, that can be passed
#'   to all downstream map_* helpers
#'
#' @examples
#' \donttest{
#' tmpdir <- tempdir()
#'
#' # Locate the package source tarball bundled with risk.assessr
#' dp <- system.file("test-data", "test.package.0001_0.1.0.tar.gz",
#'                   package = "risk.assessr")
#'
#' # Extract the source package into the temporary directory
#' utils::untar(dp, exdir = tmpdir)
#'
#' # Find the extracted package directory (it should contain DESCRIPTION)
#' pkg_dirs <- list.dirs(tmpdir, full.names = TRUE, recursive = FALSE)
#' desc_dir <- pkg_dirs[file.exists(file.path(pkg_dirs, "DESCRIPTION"))]
#' stopifnot(length(desc_dir) == 1L)
#' pkg_source_path <- desc_dir
#'
#' # Now operate on the *source* (no installation)
#' exports_df <- get_exports(pkg_source_path)
#'
#' # Optional: inspect result (kept simple for examples)
#' head(exports_df)
#'
#' # Clean up the extracted sources
#' unlink(pkg_source_path, recursive = TRUE, force = TRUE)
#' }
#' @export
get_exports <- function(pkg_source_path) {
  
  package_name <- extract_package_name(pkg_source_path)
  # Check if the package source path contains an R folder
  exp_possible <- contains_r_folder(pkg_source_path)
  
  if (exp_possible == TRUE) {
  
    result <- extract_exported_function_info(pkg_source_path, package_name)
    
    
    # check if func_df is empty of values    
    is_empty <- result %>% 
      dplyr::summarise_all(~ all(is.na(.) | . == " ")) %>% 
      unlist() %>% all()
    
    if (is_empty) {
      message(glue::glue("No exported functions from source package {package_name}"))
      result <- dplyr::tibble(
        exported_function = NA,
        class = NA,
        function_type = NA,
        function_body = "No exported functions from source package",
        where = package_name
      )  
    } else {   
    
      message(glue::glue("Extracting exported function bodies for {package_name}"))
      
      # ensure that every function_body is consistently a character vector, 
      # even if it's a serialized version of a list (e.g., for R6 methods).
      normalize_function_body <- function(row, package_name) {
        info <- classify_function_body(row, package_name)
        
        # Ensure function_body is always character
        if (is.list(info$function_body)) {
          info$function_body <- paste(capture.output(str(info$function_body)), collapse = "\n")
        }
        
        return(info)
      }
      
      # This code transforms a matrix or data frame result by using 
      # apply to execute a classification function to each row, 
      # and then converts the output into a transposed data frame.
      #result_df_list <- as.data.frame(t(apply(result, 1, function(row) {
      #  as.list(classify_function_body(as.list(row), package_name))
      #})))
      
      result_df_list <- as.data.frame(t(apply(result, 1, function(row) {
        as.list(normalize_function_body(as.list(row), package_name))
      })))
      
      # Extract all columns (e.g., V1, V2, ...) and flatten their first list element
      result <- map_dfr(result_df_list, function(col) {
        if (is.list(col[[1]])) {
          as_tibble(col[[1]])
        } else {
          tibble()
        }
        
      })
    }  
  } else {
    message(glue::glue("No R folder found in the package source path for {package_name}"))
    result <- dplyr::tibble(
      exported_function = NA,
      class = NA,
      function_type = NA,
      function_body = "No R folder found in the package source path",
      where = package_name
    )  
  }  
  
  return(result)
}


#' Extract Exported Function Metadata from an R Package
#'
#' This internal utility function analyzes the namespace of an R package and extracts
#' metadata about its exported functions, including classification into S3, S4, S7, and regular functions.
#'
#' @param .pkg_source_path Character. Path to the source directory of the R package.
#' @param package_name Character. Name of the package (typically the folder name or actual package name).
#'
#' @return A tibble with columns: `exported_function`, `class`, `function_type`, `function_body`, and `where`.
#' @keywords internal
extract_exported_function_info <- function(.pkg_source_path, package_name) {
  nsInfo <- parseNamespaceFile(package_name, dirname(.pkg_source_path), mustExist = FALSE)
  
  message(glue::glue("Extracting exported function names for {package_name}"))
  
  exports <- if (!is.null(nsInfo) && !rlang::is_empty(nsInfo$exports)) {
    unname(unlist(nsInfo[["exports"]]))
  } else {
    getNamespaceExports(package_name)
  }
  
  # Fallback: parse export() entries manually from NAMESPACE file
  namespace_file <- file.path(.pkg_source_path, "NAMESPACE")
  if (file.exists(namespace_file)) {
    ns_lines <- readLines(namespace_file)
    export_lines <- grep("^export\\(", ns_lines, value = TRUE)
    
    manual_exports <- regmatches(export_lines, gregexpr("export\\(([^\\)]+)\\)", export_lines))
    manual_exports <- unlist(lapply(manual_exports, function(x) {
      if (length(x) > 0) {
        sub("export\\(([^\\)]+)\\)", "\\1", x)
      } else {
        NULL
      }
    }))
    
    exports <- unique(c(exports, manual_exports))
  }
  
  
  # Define packages that manually export helpers like .data
  preserve_helpers_pkgs <- c("ggplot2", "rlang", "dplyr", "tidyselect")
  
  export_info <- lapply(exports, function(f) {
    obj <- suppressWarnings(
      tryCatch(getExportedValue(package_name, f), error = function(e) NULL)
    )
    
    if (is.null(obj)) {
      # Preserve unresolved exports for specific packages
      if (package_name %in% preserve_helpers_pkgs) {
        return(list(name = f, class = NA, type = "unresolved or helper"))
      } else {
        return(NULL)
      }
    }
    
    if (inherits(obj, "S7_generic")) {
      return(list(name = f, class = NA, type = "S7 generic"))
    }
    
    if (inherits(obj, "S7_class")) {
      return(list(name = f, class = NA, type = "S7 class"))
    }
    
    if (is.function(obj)) {
      body_text <- paste(deparse(body(obj)), collapse = "\n")
      if (grepl("S7::new\\(|new\\(", body_text) || grepl("S7::new_object\\(", body_text)) {
        return(list(name = f, class = NA, type = "S7 constructor"))
      }
      return(list(name = f, class = NA, type = "regular function"))
    }
    
    return(list(name = f, class = NA, type = "non-function or helper"))
  })
  
  # Apply filtering only if package is not in the preserve list
  if (!(package_name %in% preserve_helpers_pkgs)) {
    export_info <- Filter(Negate(is.null), export_info)
  }
  
  export_info_df <- dplyr::tibble(
    exported_function = vapply(export_info, `[[`, character(1), "name"),
    class = vapply(export_info, function(x) {
      if (is.null(x$class) || is.na(x$class)) NA_character_ else as.character(x$class)
    }, character(1)),
    function_type = vapply(export_info, `[[`, character(1), "type"),
    function_body = rep("", length(export_info)),
    where = rep(package_name, length(export_info))
  )
  
  # --- Add S3 methods from NAMESPACE file manually ---
  s3_generics <- character(0)
  s3_classes <- character(0)
  
  if (file.exists(namespace_file)) {
    ns_lines <- readLines(namespace_file)
    s3_lines <- grep("^S3method\\(", ns_lines, value = TRUE)
    
    for (line in s3_lines) {
      matches <- regmatches(line, regexec("S3method\\(([^,]+),\\s*([^\\)]+)\\)", line))[[1]]
      if (length(matches) == 3) {
        generic_full <- matches[2]
        cls <- matches[3]
        
        generic_name <- sub(".*::", "", generic_full)
        
        s3_generics <- c(s3_generics, generic_name)
        s3_classes <- c(s3_classes, cls)
      }
    }
  }
  
  if (!rlang::is_empty(nsInfo$S3methods)) {
    s3_generics <- c(s3_generics, nsInfo$S3methods[, 1])
    s3_classes <- c(s3_classes, nsInfo$S3methods[, 2])
  }
  
  # set up s3 function_type
  s3_function_type <- character(length(s3_generics))
  if (length(s3_generics) > 0) {
    s3_function_type <- ifelse(s3_generics %in% exports, "S3 generic + method", "S3 method")
  }
  
  # set up s3_df
  s3_df <- dplyr::tibble(
    exported_function = s3_generics,
    class = s3_classes,
    function_type = s3_function_type,
    function_body = rep("", length(s3_generics)),
    where = rep(package_name, length(s3_generics))
  )
  
  
  # --- Add S4 methods and generics ---
  s4_df <- NULL
  if (!rlang::is_empty(nsInfo$exportMethods)) {
    s4_methods_raw <- nsInfo$exportMethods
    
    if (is.character(s4_methods_raw)) {
      s4_df <- dplyr::tibble(
        exported_function = unique(s4_methods_raw),
        class = NA_character_,
        function_type = "S4 generic",
        function_body = "",
        where = package_name
      )
    } else if (is.list(s4_methods_raw)) {
      valid_s4_methods <- Filter(function(x) is.character(x) && length(x) >= 2 && !is.na(x[[2]]), s4_methods_raw)
      
      if (length(valid_s4_methods) > 0) {
        s4_func_names <- sapply(valid_s4_methods, `[[`, 1)
        s4_classes <- sapply(valid_s4_methods, `[[`, 2)
        
        s4_df <- unique(dplyr::tibble(
          exported_function = s4_func_names,
          class = s4_classes,
          function_type = "S4 function",
          function_body = "",
          where = package_name
        ))
      }
    }
  }
  
  # --- Remaining exports not in export_info ---
  remaining_exports <- setdiff(exports, export_info_df$exported_function)
  remaining_df <- dplyr::tibble(
    exported_function = remaining_exports,
    class = NA_character_,
    function_type = "unknown",
    function_body = "",
    where = package_name
  )
  
  # --- Combine all sources ---
  result <- dplyr::bind_rows(
    export_info_df,
    if (exists("s3_df") && !is.null(s3_df)) s3_df else NULL,
    if (exists("s4_df") && !is.null(s4_df)) s4_df else NULL,
    if (exists("remaining_df") && !is.null(remaining_df)) remaining_df else NULL
  ) |>
    dplyr::distinct(exported_function, class, .keep_all = TRUE)
  
  return(result)
}

#' Extract package name from package source path
#'
#' @param pkg_source_path a file path pointing to an unpacked/untarred package directory
#'
#' @return  package_name
#'
#' @keywords internal
extract_package_name <- function(pkg_source_path) {
  # Split the path by "::"
  parts <- strsplit(pkg_source_path, "::")[[1]]
  
  # Extract the part before "::"
  package_part <- parts[1]
  
  # Remove everything before the package name and the version
  package_name <- sub(".*[/\\\\]", "", package_part)
  package_name <- sub("-[0-9.]+$", "", package_name)
  
  return(package_name)
}

#' Extract all S4 methods 
#'
#' @param generic_name name of function
#'
#' @return  list with method_strings, generic, and methods
#'
#' @keywords internal
get_all_s4_methods <- function(generic_name) {
  is_generic <- methods::isGeneric(generic_name)
  methods_strings <- list()
  has_methods <- FALSE
  
  if (is_generic) {
    methods_list <- methods::findMethods(generic_name)
    
    for (i in seq_along(methods_list@.Data)) {
      method_obj <- methods_list@.Data[[i]]
      if (inherits(method_obj, "MethodDefinition")) {
        method_def <- method_obj@.Data
        method_string <- deparse(method_def)
        methods_strings[[i]] <- paste(method_string, collapse = "\n")
        has_methods <- TRUE
      }
    }
  }
  
  list(
    bodies = methods_strings,
    is_generic = is_generic,
    has_methods = has_methods
  )
}


#' function to preprocess func_full_name 
#' 
#' @description function to extract package, class, and generic
#'  
#' @param func_full_name - full name of the function 
#'
#' @keywords internal
preprocess_func_full_name <- function(func_full_name) {
  
  package <- generic <- class <- NULL
  remaining <- func_full_name
  
  # Handle internal access (:::)
  if (stringr::str_detect(func_full_name, ":::")) {
    package <- stringr::str_extract(func_full_name, "^[^:]+")
    generic <- stringr::str_extract(func_full_name, "(?<=::)[^\\.]+")
    remaining <- stringr::str_match(func_full_name, ":::([^:]+)$")[, 2]
    class <- paste(package, ":::", remaining, sep = "")
    
    # Handle external access (::)
  } else if (grepl("::", func_full_name)) {
    parts <- strsplit(func_full_name, "::")[[1]]
    package <- parts[1]
    remaining <- parts[2]
    remaining_parts <- strsplit(remaining, "\\.")[[1]]
    generic <- remaining_parts[1]
    class <- paste(remaining_parts[-1], collapse = ".")
    
    # No namespace qualifier
  } else {
    parts <- strsplit(func_full_name, "\\.")[[1]]
    remaining <- func_full_name
  }
  
  # Handle infix operators like %/% or %%
  if (grepl("^%.*%$", remaining) || grepl("^`%.*%`$", remaining)) {
    # Normalize to backtick-wrapped form
    if (!grepl("^`.*`$", remaining)) {
      remaining <- paste0("`", remaining, "`")
    }
    generic <- remaining
    class <- "" # Class is not embedded in the name for S4 methods
  }
  
  # Handle special dot-prefixed or double-dot forms
  if (grepl("^\\.\\.|\\.\\.$", remaining)) {
    generic <- remaining
    class <- remaining
  } else if (grepl("^\\.", remaining)) {
    generic <- remaining
    class <- ""
  }
  
  # Clean version of generic for use with isGeneric() and findMethods()
  generic_clean <- if (!is.null(generic)) gsub("^`|`$", "", generic) else ""
  
  return(list(
    package = package,
    generic = generic,
    generic_clean = generic_clean,
    class = class
  ))
}



#' function to get S3 method 
#' 
#' @description function to get S3 method from generic
#'  
#' @param generic - function generic
#' @param class - function class
#' @param package - package name 
#'
#' @keywords internal
get_s3_method <- function(generic, class, package) {
  func_name <- paste0(generic, ".", class)
  method <- getAnywhere(func_name)
  
  if (length(method$objs) > 0) {
    func <- method$objs[[1]]
    func_env <- environment(func)
    
    # Initialize flags
    has_r6_class <- FALSE
    has_r6_generator <- FALSE
    
    # Try to list objects in the environment
    env_objects <- tryCatch(ls(func_env), error = function(e) character(0))
    
    if (length(env_objects) > 0) {
      # Check for R6 class or generator safely
      has_r6_class <- any(sapply(env_objects, function(obj_name) {
        tryCatch({
          inherits(get(obj_name, envir = func_env), "R6")
        }, error = function(e) FALSE)
      }))
      
      has_r6_generator <- any(sapply(env_objects, function(obj_name) {
        tryCatch({
          inherits(get(obj_name, envir = func_env), "R6ClassGenerator")
        }, error = function(e) FALSE)
      }))
    }
    
    return(list(
      func = func,
      func_env = func_env,
      has_r6_class = has_r6_class,
      has_r6_generator = has_r6_generator
    ))
  } else {
    return(NULL)
  }
}


#' function to get R6 methods 
#' 
#' @description function to get R6 methods from class
#'  
#' @param class_name - function class
#' @keywords internal
get_r6_methods_details <- function(class_name) {
  methods <- class_name$public_methods
  
  # extract method details
  method_details <- lapply(names(methods), function(method_name) {
    method <- methods[[method_name]]
    
    if (!is.function(method)) {
      return(list(name = method_name, body = "<not a function>"))
    }
    
    body_text <- tryCatch(
      deparse(body(method)),
      error = function(e) paste("<error extracting body:", e$message, ">")
    )
    
    list(
      name = method_name,
      body = body_text
    )
  })
  
  return(method_details)
}

#' function to check value of ggproto
#' 
#' @description function to check if first argument inherits from any of the classes specified
#'  
#' @param x - ggproto functions from the target package
#'
#' @keywords internal
function_is_ggproto <- function(x) inherits(x, "ggproto")

#' function to check value of ggproto
#' 
#' @description function to check all classes of a ggproto function
#'  
#' @param value - ggproto functions from the target package
#'
#' @keywords internal
check_ggproto <- function(value) {
  any(class(value) %in% c("ggproto"))
}

#' function to extract ggproto methods
#' 
#' @description function to get all the methods of a ggproto function
#'  
#' @param obj - ggproto env from the target package
#'
#' @keywords internal
extract_ggproto_methods <- function(obj) {
  
  methods <- lapply(names(obj), function(method) {
    if (is.function(obj[[method]])) {
      paste(deparse(body(obj[[method]])), collapse = "\n")
    } else {
      NULL
    }
  })
  methods <- methods[!sapply(methods, is.null)]
  
  return(paste(methods, collapse = "\n\n"))
}

#' classify_function_body
#'
#' @description This function gets the function bodies for exported functions
#' 
#' @param row - row with exported functions
#' @param package_name - name of the package
#'
#' @return row - row with the function details plus function body
#' @keywords internal
classify_function_body <- function(row, package_name) {
  
  func_name <- row$exported_function
  func_class <- row$class
  func_type <- row$function_type
  func_full_name <- paste0(package_name, "::", func_name)
  
  generic <- func_name
  class <- func_class
  package <- package_name
  
  # Preprocess if not S3
  if (!(func_type == "S3 function" && !is.na(func_class))) {
    preprocessed <- preprocess_func_full_name(func_full_name)
    package <- preprocessed$package
    generic <- preprocessed$generic
    generic_clean <- preprocessed$generic_clean
    class <- preprocessed$class
  } else {
    generic_clean <- generic
  }
  
  # S4 generic or method
  if (methods::isGeneric(generic_clean)) {
    s4_info <- get_all_s4_methods(generic_clean)
    row$function_body <- paste(s4_info$bodies, collapse = "\n")
    if (s4_info$is_generic && !s4_info$has_methods) {
      row$function_type <- "S4 generic"
    } else if (s4_info$is_generic && s4_info$has_methods) {
      row$function_type <- "S4 method, S4 generic"
    }
    return(row)
  }
  
  # S7 generic
  if (!is.na(func_type) && func_type == "S7 generic") {
    fun_obj <- tryCatch(get(generic, envir = asNamespace(package_name)), error = function(e) NULL)
    if (inherits(fun_obj, "S7_generic")) {
      s7_methods <- get("methods", envir = asNamespace("S7"))(fun_obj)
      if (length(s7_methods) > 0) {
        method_bodies <- sapply(s7_methods, function(m) {
          body <- tryCatch(body(m), error = function(e) NULL)
          if (!is.null(body)) paste(deparse(body), collapse = "\n") else ""
        })
        row$function_body <- paste(method_bodies, collapse = "\n\n")
      } else {
        generic_body <- tryCatch(body(fun_obj), error = function(e) NULL)
        if (!is.null(generic_body)) {
          row$function_body <- paste(deparse(generic_body), collapse = "\n")
        }
      }
    }
    return(row)
  }
  
  # S3 method
  S3_value <- get_s3_method(generic, class, package)
  if (!is.null(S3_value)) {
    row$function_body <- paste(deparse(S3_value$func), collapse = "\n")
    if (inherits(S3_value$func, "function")) {
      row$function_type <- "S3 function"
    }
    if (S3_value$has_r6_class) {
      row$function_type <- paste(row$function_type, "R6 class", sep = ", ")
    }
    if (S3_value$has_r6_generator) {
      row$function_type <- paste(row$function_type, "R6 class generator", sep = ", ")
    }
    return(row)
  }
  
  # Try to get value
  value <- tryCatch(get(generic, envir = asNamespace(package)), error = function(e) NULL)
  
  # S7 class or constructor
  if (inherits(value, "S7_class")) {
    row$function_type <- "S7 class"
    row$function_body <- "<S7 class definition>"
    return(row)
  }
  
  if (is.function(value)) {
    body_text <- paste(deparse(body(value)), collapse = "\n")
    if (grepl("S7::new\\(|new\\(", body_text) || grepl("S7::new_object\\(", body_text)) {
      row$function_type <- "S7 constructor"
      row$function_body <- body_text
      return(row)
    }
  }
  
  # Other types
  if (is.numeric(value)) {
    row$function_type <- "numeric"
    row$function_body <- as.character(value)
    return(row)
  }
  
  if (inherits(value, "rlang_fake_data_pronoun")) {
    row$function_type <- "rlang tidy eval"
    row$function_body <- "<pronoun> - refer to rlang"
    return(row)
  }
  
  if (check_ggproto(value)) {
    if (function_is_ggproto(value)) {
      func_body <- tryCatch(extract_ggproto_methods(value), error = function(e) NULL)
      row$function_body <- if (!is.null(func_body)) paste(deparse(func_body), collapse = "\n") else "Function body not found"
    }
    row$function_type <- "ggproto"
    return(row)
  }
  
  if (inherits(value, "R6ClassGenerator")) {
    row$function_type <- ifelse(is.na(row$function_type), "R6 Class Generator", paste(row$function_type, "R6 class", sep = ", "))
    row$function_body <- get_r6_methods_details(value)
    return(row)
  }
  
  # Regular function fallback
  if (is.function(value)) {
    func_body <- tryCatch(
      withCallingHandlers(
        expr = body(value),
        warning = function(w) {
          if (grepl("argument is not a function", w$message)) {
            row$function_body <- "Function type is unknown"
            invokeRestart("muffleWarning")
          }
        }
      ),
      error = function(e) {
        row$function_body <- "Function body not found"
        NULL
      }
    )
    if (!is.null(func_body)) {
      row$function_body <- paste(deparse(func_body), collapse = "\n")
    }
    if (is.na(row$function_type)) {
      row$function_type <- "regular"
    }
  }
  
  return(row)
}




