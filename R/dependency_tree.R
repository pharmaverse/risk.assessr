#' Check if a Package is a Base or Recommended R Package
#' 
#' This function determines whether a given package is a base or recommended package
#' using CRAN metadata.
#'
#' @param pkg A character string representing the name of the package.
#' 
#' @return A logical value: `TRUE` if the package is a base or recommended package, `FALSE` otherwise.
#' 
#' @examples
#' \dontrun{
#' is_base("stats")     # TRUE
#' is_base("ggplot2")   # FALSE
#' }
#' @export
is_base <- function(pkg) {
  base_packages <- rownames(installed.packages(priority = "base"))
  return(pkg %in% base_packages)
}

#' Parse Dependencies from a Package DESCRIPTION File
#' 
#' This function extracts and returns the dependencies from the DESCRIPTION file
#' of an R package, focusing on the `Imports` field.
#'
#' @param path A character string specifying the path to the package directory containing the DESCRIPTION file.
#' 
#' @return A data frame with columns:
#' 	- `package`: The name of the imported package.
#' 	- `type`: The type of dependency (e.g., "Imports").
#' 
#' @examples
#' 
#' \dontrun{
#' parse_dcf_dependencies_version("/path/to/package")
#' }
#' @keywords internal
parse_dcf_dependencies_version <- function(path) {
  dcf <- read.dcf(file.path(path, "DESCRIPTION"))
  
  if (!"Imports" %in% colnames(dcf)) {
    return(data.frame(package = character(), type = character(), stringsAsFactors = FALSE))
  }
  
  imports <- dcf[1, "Imports"]
  split_deps <- unlist(strsplit(imports, ","))
  split_deps <- trimws(split_deps)
  
  deps <- data.frame(
    package = split_deps,
    type = rep("Imports", length(split_deps)),
    stringsAsFactors = FALSE,
    row.names = NULL 
  )
  
  return(deps)
}

#' Extract License from Package DESCRIPTION File
#' 
#' This function extracts the license information from a package's DESCRIPTION file.
#'
#' @param path A character string specifying the path to the package directory containing the DESCRIPTION file.
#' 
#' @return A character string representing the package license, or `NA` if not found.
#' 
#' @importFrom desc description
#' @keywords internal
extract_license_from_description <- function(path) {
  desc_file <- file.path(path, "DESCRIPTION")
  
  License <- NA_character_
  
  if (!file.exists(desc_file)) {
    warning("DESCRIPTION file not found: ", desc_file)
  } else {
    tryCatch({
      d <- description$new(file = desc_file)
      
      if (!d$has_fields("License")) {
        warning("No License field in DESCRIPTION: ", desc_file)
      } else {
        License_list <- d$get_list("License")
        
        if (is.null(License_list) || length(License_list) == 0) {
          warning("License field is empty in DESCRIPTION: ", desc_file)
        } else {
          License <- as.character(License_list)
        }
      }
    }, error = function(e) {
      warning("Failed to extract License from DESCRIPTION: ", conditionMessage(e))
      License <- NA_character_
    })
  }
  
  return(License)
}




#' Download and Parse Dependencies of an R Package
#' 
#' Downloads a package from a repository, extracts it, and parses dependencies from the DESCRIPTION file.
#'
#' @param package_name Name of the package to download.
#' @param version Package version to download (default: `NA` for latest).
#' @param get_license Whether to extract license information (default: `FALSE`).
#' 
#' @return When `get_license = FALSE`, a data frame with columns `package`, `type`, and `parent_package`.
#'   When `get_license = TRUE`, a list with:
#'     - `dependencies`: Data frame of direct dependencies.
#'     - `license`: License of the specified package only (not dependencies). Returns `NA` if not found.
#' 
#' @details The `license` field refers only to the package specified by `package_name`, not its dependencies.
#'   Use `build_dependency_tree()` or `fetch_all_dependencies()` with `get_license = TRUE` for full license information.
#' 
#' @import dplyr
#' @examples
#' \dontrun{
#' download_and_parse_dependencies("dplyr")
#' download_and_parse_dependencies("dplyr", get_license = TRUE)
#' }
#' @export
download_and_parse_dependencies <- function(package_name, version = NA, get_license = FALSE) {
  
  tryCatch({
    temp_file <- remotes::download_version(package = package_name, version = version)
    
    temp_dir <- tempfile()
    dir.create(temp_dir)
    untar(temp_file, exdir = temp_dir)
    
    extracted_dirs <- list.dirs(temp_dir, full.names = TRUE, recursive = FALSE)
    
    package_dir <- if (length(extracted_dirs) == 1) {
      extracted_dirs[1]
    } else {
      file.path(temp_dir, package_name)
    }
    
    desc_path <- file.path(package_dir, "DESCRIPTION")
    
    if (!file.exists(desc_path)) {
      desc_files <- list.files(package_dir, pattern = "DESCRIPTION", recursive = TRUE, full.names = TRUE)
      if (length(desc_files) > 0) desc_path <- desc_files[1]
    }
    
    if (!file.exists(desc_path)) {
      stop(paste("DESCRIPTION file not found for", package_name))
    }
    
    dependencies <- parse_dcf_dependencies_version(package_dir) %>%
      dplyr::mutate(parent_package = package_name)
    
    license <- NA_character_
    if (get_license) {
      license <- extract_license_from_description(package_dir)
    }
    
    unlink(temp_dir, recursive = TRUE)
    
    list(dependencies = dependencies, license = license)
    
  }, error = function(e) {
    message(paste("Failed to download or parse", package_name, "-", e$message))
    list(
      dependencies = data.frame(
        package = character(),
        type = character(),
        parent_package = character(),
        stringsAsFactors = FALSE
      ),
      license = NA_character_
    )
  })
}



#' Extract the Installed Version of a Package
#' 
#' This function retrieves the installed version of a specified R package.
#' If the package is not installed, returns `NA`.
#'
#' @param package_name A character string specifying the name of the package.
#' 
#' @return A character string representing the installed package version, or `NA` if the package is not found.
#' 
#' @examples
#' \dontrun{
#' extract_package_version("dplyr")
#' # 1.1.4
#' }
#' 
#' @export
extract_package_version <- function(package_name) {
  version <- tryCatch(
    packageDescription(package_name, fields = "Version"),
    error = function(e) {
      message("Error: ", e$message)
      return(NA)
    }
  )
  return(version)
}

#' Build a Dependency Tree for an R Package
#' 
#' This function constructs a nested list representing the dependency tree of a specified R package.
#' The recursion stops at the specified maximum depth level (default: 3) or until a base package is reached.
#'
#' @param package_name A character string specifying the name of the package.
#' @param level An integer indicating the current recursion depth (default: 1).
#' @param get_license A logical value indicating whether to extract and include license information from DESCRIPTION files (default: `FALSE`).
#' @param max_level An integer specifying the maximum depth level for dependency recursion (default: 3). 
#'                  Set to a higher value to explore deeper dependency layers.
#'
#' @return A nested list representing the dependency tree, where base packages are marked as "base".
#'         If `get_license` is `TRUE`, each package entry in the tree includes a `license` field containing 
#'         that specific package's license (extracted from its DESCRIPTION file). Each package's license is 
#'         independent - the license of a parent package does not imply the licenses of its dependencies.
#'
#' @examples
#' \dontrun{
#' build_dependency_tree("ggplot2")
#' build_dependency_tree("ggplot2", get_license = TRUE)
#' build_dependency_tree("ggplot2", max_level = 5)  # Deeper dependency exploration
#' }
#'
#' @export
build_dependency_tree <- function(package_name, level = 1, get_license = FALSE, max_level = 3) {
  
  message("Dependency tree in progress for " , package_name, " package")

  # Validate max_level (must be non-negative)
  if (!is.numeric(max_level) || length(max_level) != 1 || max_level < 0 || max_level != as.integer(max_level)) {
    warning("max_level must be a non-negative integer")
    return(NULL)  
  }
  
  # Validate package_name
  if (!is.character(package_name) || length(package_name) != 1 || is.na(package_name) || nchar(trimws(package_name)) == 0) {
    warning("package_name must be a non-empty character string")
    return(NULL)  
  }
  
  if (level > max_level) return(NULL)  # Stop at max_level
  
  result <- download_and_parse_dependencies(package_name, get_license = get_license)
  
  # Handle both old format (data.frame) and new format (list with dependencies and license)
  # Note: data.frames are lists in R, so check for list with "dependencies" key first
  if (is.null(result)) {
    deps <- data.frame(package = character(), type = character(), stringsAsFactors = FALSE)
    package_license <- NULL
  } else if (is.list(result) && !is.data.frame(result) && "dependencies" %in% names(result)) {
    # This is the new format: list with dependencies and license
    deps <- result$dependencies
    package_license <- result$license
  } else if (is.data.frame(result)) {
    # This is the old format: just a data.frame
    deps <- result
    package_license <- NULL
  } else {
    deps <- data.frame(package = character(), type = character(), stringsAsFactors = FALSE)
    package_license <- NULL
  }
  
  # Ensure deps has the required structure
  if (!is.data.frame(deps) || !"package" %in% names(deps)) {
    deps <- data.frame(package = character(), type = character(), stringsAsFactors = FALSE)
  }
  
  package_version <- extract_package_version(package_name)
  
  dep_list <- list(version = package_version)
  if (get_license && !is.null(package_license) && !is.na(package_license)) {
    dep_list$license <- package_license
  }
  
  if (nrow(deps) > 0 && "package" %in% names(deps)) {
    for (dep in deps$package) {
      if (!is.na(dep) && !is.null(dep) && nchar(trimws(dep)) > 0) {
        dep_name <- gsub("\\s*\\(.*\\)", "", dep)
        
        if (is_base(dep_name)) {
          dep_list[[dep_name]] <- "base"
        } else {
          dep_list[[dep_name]] <- build_dependency_tree(dep_name, level + 1, get_license = get_license, max_level = max_level)
        }
      }
    }
  }
  
  message("Finished building for ", package_name)
  
  return(dep_list)
}

#' Fetch All Dependencies for a Package
#' 
#' This function builds and retrieves the full dependency tree for a given R package.
#'
#' @param package_name A character string specifying the name of the package.
#' @param get_license A logical value indicating whether to extract and include license information from DESCRIPTION files (default: `FALSE`).
#' @param max_level An integer specifying the maximum depth level for dependency recursion (default: 3).
#'                  Set to a higher value to explore deeper dependency layers.
#' 
#' @return A nested list representing the dependency tree of the package. If `get_license` is `TRUE`, 
#'         each package in the tree (including the root package and all dependencies) will have a 
#'         `license` field containing that package's license extracted from its DESCRIPTION file.
#' 
#' @examples
#' \dontrun{
#' fetch_all_dependencies("ggplot2")
#' fetch_all_dependencies("ggplot2", get_license = TRUE)
#' fetch_all_dependencies("ggplot2", max_level = 5)  # Deeper dependency exploration
#' }
#'
#' @export
fetch_all_dependencies <- function(package_name, get_license = FALSE, max_level = 3) {
  
  # Validate parameters and throw errors (not warnings) for fetch_all_dependencies
  if (!is.numeric(max_level) || length(max_level) != 1 || max_level < 0 || max_level != as.integer(max_level)) {
    stop("max_level must be a non-negative integer")
  }
  
  if (!is.character(package_name) || length(package_name) != 1 || is.na(package_name) || nchar(trimws(package_name)) == 0) {
    stop("package_name must be a non-empty character string")
  }
  
  message("Building dependency tree for: ", package_name, "\n")
  dep_tree <- list()
  tree_result <- build_dependency_tree(package_name, get_license = get_license, max_level = max_level)
  
  # In R, assigning NULL to a list element removes it, so we need to handle this
  # Store the result, which could be NULL
  if (!is.null(tree_result)) {
    dep_tree[[package_name]] <- tree_result
  }
  # If NULL, the list will be empty, which is acceptable behavior
  
  return(dep_tree)
}


#' Print a Package Dependency Tree
#' 
#' This function prints a hierarchical representation of a package's dependencies, including version and base status
#'
#' @param tree A nested list representing the package dependency tree, where each package has a `version` field and potentially sub-dependencies.
#' @param prefix A character string used for formatting tree branches (default: "").
#' @param last A logical value indicating if the current package is the last in the tree level (default: `TRUE`).
#' @param show_version A logical value indicating whether to display package versions if available (default: `TRUE`).
#' 
#' @return Prints the dependency tree to the console.
#' 
#' @examples
#' \dontrun{
#' db <- list(
#'   stringr = list(
#'     version = "1.5.1",
#'     cli = list(version = "3.6.2", utils = "base"),
#'     glue = list(version = "1.7.0", methods = "base"),
#'     lifecycle = list(
#'       version = "1.0.4",
#'       cli = list(version = "3.6.2", utils = "base"),
#'       glue = list(version = "1.7.0", methods = "base"),
#'       rlang = list(version = "1.1.3", utils = "base")
#'     ),
#'     magrittr = list(version = "2.0.3"),
#'     rlang = list(version = "1.1.3", utils = "base"),
#'     stringi = list(version = "1.8.3", tools = "base", utils = "base", stats = "base"),
#'     vctrs = list(
#'       version = "0.6.5",
#'       cli = list(version = "3.6.2", utils = "base"),
#'       glue = list(version = "1.7.0", methods = "base"),
#'       lifecycle = list(version = "1.0.4"),
#'       rlang = list(version = "1.1.3", utils = "base")
#'     )
#'   )
#' )
#' print_tree(db)
#' }
#' 
#' @export
print_tree <- function(tree, prefix = "", last = TRUE, show_version = TRUE) {
  
  if (is.list(tree)) {
    # Filter out metadata fields (version, license) - they're not packages
    # These should be displayed as part of package info, not as separate entries
    all_names <- names(tree)
    metadata_fields <- c("version", "license")
    pkg_names <- all_names[!all_names %in% metadata_fields]
    
    # Check if version/license exist at current level (for root package display)
    has_version_here <- "version" %in% all_names && !is.list(tree[["version"]])
    has_license_here <- "license" %in% all_names && !is.list(tree[["license"]])
    
    # Special case: if we're at root level (prefix == "") and there are metadata fields
    # but no package names, this means we're printing a tree that has no root package name
    # (e.g., result of build_dependency_tree directly). In this case, we should skip printing
    # and let the caller handle it, OR we could print a summary. But typically this shouldn't happen.
    
    n <- length(pkg_names)
    
    # If no packages at this level, return early (only metadata)
    if (n == 0) {
      return(invisible(NULL))
    }
    
    i <- 1
    for (pkg in pkg_names) {
      
      # Check if it's a base package
      is_base_pkg <- identical(tree[[pkg]], "base")
      
      # Extract version - use current level metadata if available (for first package at root), otherwise from subtree
      pkg_version <- ""
      if (!is_base_pkg && show_version) {
        # If we're at root level (prefix == "") and version exists here, use it for first package
        if (has_version_here && i == 1 && prefix == "") {
          # This is the first package at root level, use version from current tree metadata
          pkg_version <- paste0(" (v", tree[["version"]], ")")
        } else if (is.list(tree[[pkg]]) && "version" %in% names(tree[[pkg]])) {
          # Check if version is in the package subtree
          pkg_version <- paste0(" (v", tree[[pkg]]$version, ")")
        }
      }
      
      # Extract license - use current level metadata if available (for first package at root), otherwise from subtree
      pkg_license <- ""
      if (!is_base_pkg) {
        # First check if license is in the package subtree (most common case)
        if (is.list(tree[[pkg]]) && "license" %in% names(tree[[pkg]])) {
          license_val <- tree[[pkg]]$license
          if (!is.null(license_val) && !is.na(license_val) && license_val != "") {
            # For root level (prefix == ""), add "license" word, otherwise just the value
            if (prefix == "") {
              pkg_license <- paste0(" ", license_val, " license")
            } else {
              pkg_license <- paste0(" ", license_val)
            }
          }
        } else if (has_license_here && i == 1 && prefix == "") {
          # This is the first package at root level, use license from current tree metadata
          # (for cases where build_dependency_tree result is printed directly)
          license_val <- tree[["license"]]
          if (!is.null(license_val) && !is.na(license_val) && license_val != "") {
            # For root level, add "license" word
            pkg_license <- paste0(" ", license_val, " license")
          }
        }
      } else if (is_base_pkg) {
        # Base packages don't have licenses in the tree structure since they're not downloaded
        pkg_license <- ""
      }
      
      # Append "(base)" for base packages
      base_tag <- if (is_base_pkg) " (base)" else ""
      
      # Formatting for tree structure using Unicode escapes
      connector <- if (i == n) "\u2514\u2500\u2500 " else "\u251c\u2500\u2500 "
      cat(prefix, connector, pkg, pkg_version, base_tag, pkg_license, "\n", sep = "")
      
      # If it's not a base package, recurse into sub-tree
      if (!is_base_pkg) {
        sub_tree <- tree[[pkg]]
        if (is.list(sub_tree)) {
          sub_tree$version <- NULL
          sub_tree$license <- NULL  # Remove license from sub_tree to avoid duplication
        }
        
        new_prefix <- if (i == n) paste0(prefix, "    ") else paste0(prefix, "\u2502   ")
        print_tree(sub_tree, new_prefix, i == n, show_version) 
      }
      
      i <- i + 1
    }
  }
}



#' Detect Version Conflicts from dependency tree
#'
#' This function identifies duplicate version packages and reports conflicts.
#'
#' @param pkg_list A nested list structure from fetch_all_dependencies function
#'
#' @return A list of strings describing package version conflicts such as "Conflict in package cli: versions found - 3.6.2, 3.6.1"
#' `NULL` if no conflicts are found.
#'
#' @examples
#' pkg_list <- list(
#'   ggplot2 = list(
#'     version = "3.5.1",
#'     cli = list(version = "3.6.2"),
#'     gtable = list(
#'       version = "0.3.4",
#'       cli = list(version = "3.6.1")
#'     )
#'   )
#' )
#' detect_version_conflicts(pkg_list)
#'
#' @export
detect_version_conflicts <- function(pkg_list) {
  
  check_versions <- function(sublist, version_map = list()) {
    for (key in names(sublist)) {
      if (is.list(sublist[[key]])) {
        if ("version" %in% names(sublist[[key]])) {
          version <- sublist[[key]]$version
          
          # Append version to the existing list
          if (is.null(version_map[[key]])) {
            version_map[[key]] <- c(version)
          } else if (!(version %in% version_map[[key]])) {
            version_map[[key]] <- unique(c(version_map[[key]], version))
          }
        }
        version_map <- check_versions(sublist[[key]], version_map)
      }
    }
    return(version_map)
  }
  
  # Collect all versions encountered
  version_map <- check_versions(pkg_list)
  
  # Identify conflicts 
  conflicts <- list()
  for (pkg in names(version_map)) {
    if (length(version_map[[pkg]]) > 1) {
      conflicts[[pkg]] <- version_map[[pkg]]
    }
  }
  
  # Return conflicts in a readable format
  if (length(conflicts) > 0) {
    return(lapply(names(conflicts), function(pkg) {
      sprintf("Conflict in package %s: versions found - %s", 
              pkg, paste(conflicts[[pkg]], collapse = ", "))
    }))
  } else {
    return(NULL)
  }
}
