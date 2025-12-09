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



#' Download and Parse Dependencies of an R Package
#' 
#' This function downloads a specific version of an R package from a repository,
#' extracts it, and parses its dependencies from the DESCRIPTION file.
#'
#' @param package_name A character string representing the name of the package to download.
#' @param version A character string specifying the version of the package to download. Defaults to `NA`, which fetches the latest version.
#' 
#' @return A data frame containing:
#' 	- `package`: The name of the dependency.
#' 	- `type`: The type of dependency (e.g., "Imports").
#' 	- `parent_package`: The original package for which dependencies were parsed.
#' 
#' @import dplyr
#' @examples
#' \dontrun{
#' download_and_parse_dependencies("dplyr")
#' }
#' @export
download_and_parse_dependencies <- function(package_name, version=NA) {
  
  tryCatch({
    temp_file <- remotes::download_version(package=package_name, version=version)
    
    temp_dir <- tempfile()
    dir.create(temp_dir)
    untar(temp_file, exdir = temp_dir)
    
    extracted_dirs <- list.dirs(temp_dir, full.names = TRUE, recursive = FALSE)
    
    if (length(extracted_dirs) == 1) {
      package_dir <- extracted_dirs[1]
    } else {
      package_dir <- file.path(temp_dir, package_name)
    }
    
    desc_path <- file.path(package_dir, "DESCRIPTION")
    
    if (!file.exists(desc_path)) {
      desc_files <- list.files(package_dir, pattern="DESCRIPTION", recursive=TRUE, full.names=TRUE)
      if (length(desc_files) > 0) {
        desc_path <- desc_files[1]
      }
    }
    
    if (!file.exists(desc_path)) {
      stop(paste("DESCRIPTION file not found for", package_name))
    }
    
    dependencies <- parse_dcf_dependencies_version(package_dir)
    dependencies <- dependencies %>% 
      mutate(parent_package = package_name)
    
    unlink(temp_dir, recursive = TRUE)
    return(dependencies)
    
  }, error = function(e) {
    message(paste("Failed to download or parse", package_name, "-", e$message))
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
#' The recursion stops at a depth of 3 levels (or until base package).
#'
#' @param package_name A character string specifying the name of the package.
#' @param level An integer indicating the current recursion depth (default: 1).
#'
#' @return A nested list representing the dependency tree, where base packages are marked as "base".
#'
#' @examples
#' \dontrun{
#' build_dependency_tree("ggplot2")
#' }
#'
#' @export
build_dependency_tree <- function(package_name, level = 1) {
  
  message("Dependency tree in progress for " , package_name, " package")
  
  if (level > 3) return(NULL)  # Stop at 3 levels
  
  deps <- download_and_parse_dependencies(package_name)
  package_version <- extract_package_version(package_name)
  dep_list <- list(version = package_version)
  
  for (dep in deps$package) {
    dep_name <- gsub("\\s*\\(.*\\)", "", dep)
    
    if (is_base(dep_name)) {
      dep_list[[dep_name]] <- "base"
    } else {
      dep_list[[dep_name]] <- build_dependency_tree(dep_name, level + 1)
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
#' 
#' @return A nested list representing the dependency tree of the package.
#' 
#' @examples
#' \dontrun{
#' fetch_all_dependencies("ggplot2")
#' }
#'
#' @export
fetch_all_dependencies <- function(package_name) {
  
  message("Building dependency tree for: ", package_name, "\n")
  dep_tree <- list()
  dep_tree[[package_name]] <- build_dependency_tree(package_name)
  
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
    n <- length(tree)
    i <- 1
    for (pkg in names(tree)) {
      
      # Check if it's a base package
      is_base_pkg <- identical(tree[[pkg]], "base")
      
      # Extract version 
      pkg_version <- ""
      if (!is_base_pkg && show_version && is.list(tree[[pkg]]) && "version" %in% names(tree[[pkg]])) {
        pkg_version <- paste0(" (v", tree[[pkg]]$version, ")")
      }
      
      # Append "(base)" for base packages
      base_tag <- if (is_base_pkg) " (base)" else ""
      
      # Formatting for tree structure using Unicode escapes
      connector <- if (i == n) "\u2514\u2500\u2500 " else "\u251c\u2500\u2500 "
      cat(prefix, connector, pkg, pkg_version, base_tag, "\n", sep = "")
      
      # If it's not a base package, recurse into sub-tree
      if (!is_base_pkg) {
        sub_tree <- tree[[pkg]]
        if (is.list(sub_tree)) {
          sub_tree$version <- NULL
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
