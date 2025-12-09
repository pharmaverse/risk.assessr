#' Parse DCF of description file
#'
#' @param path pkg_ref path
#' 
#' @keywords internal
parse_dcf_dependencies <- function(path){
  
  deps <- desc::desc_get_deps(file.path(path, "DESCRIPTION"))
  deps <- deps[, c("type", "package"), drop = FALSE]
  
  # Check CRAN availability before filtering base/recommended packages
  cran_check <- capture_cran_warning("http://cran.us.r-project.org", "src/contrib/Meta/archive.rds")
  
  if (is.null(cran_check$message)) {
    deps <- remove_base_packages(deps)
  } else {
    message("CRAN not available, skipping base/recommended package filtering: ", cran_check$message)
  }
  
  rownames(deps) <- NULL
  return(deps)
}

#' Helper function to remove base and recommended packages
#'
#' @param df Data frame of dependencies of a package.
#' 
#' @keywords internal
remove_base_packages <- function(df) {
  # Create a temporary file to store the downloaded RDS
  local <- tempfile(fileext = ".rds")
  on.exit(unlink(local), add = TRUE)
  
  # Try downloading the CRAN package metadata
  cp <- tryCatch({
    utils::download.file(
      "https://cran.r-project.org/web/packages/packages.rds",
      local,
      mode = "wb",
      quiet = TRUE
    )
    readRDS(local)
  }, error = function(e) {
    stop("Failed to download or read CRAN package metadata: ", e$message)
  })
  
  # Identify base and recommended packages from the metadata
  inst_priority <- cp[, "Priority"]
  inst_is_base_rec <- !is.na(inst_priority) & inst_priority %in% c("base", "recommended")
  base_rec_pkgs <- cp[inst_is_base_rec, "Package"]
  
  # Filter out "R" and base/recommended packages from the input df
  deps <- df[!(df$package == "R" | df$package %in% base_rec_pkgs), ]
  
  return(deps)
}


#' Get dependencies
#'
#' @param pkg_source_path package source path
#' 
#' @keywords internal
get_dependencies <- function(pkg_source_path) {
  
  pkg_name <- basename(pkg_source_path)
  message(glue::glue("getting package dependencies for {pkg_name}"))
  deps <- parse_dcf_dependencies(pkg_source_path)
  message(glue::glue("package dependencies successful for {pkg_name}"))
  return(deps)
}


#' Get reverse dependencies
#'
#' @param pkg_source_path package source path
#' @keywords internal
get_reverse_dependencies <- function(pkg_source_path) {
  
  pkg_name <- basename(pkg_source_path)
  
  #extract package name without version to pass to the revdep function
  name <- stringr::str_extract(pkg_name, "[^_|-]+")
  message(glue::glue("getting reverse dependencies for {pkg_name}"))
  rev_deps <- find_reverse_dependencies(name)
  message(glue::glue("reverse dependencies successful for {pkg_name}"))
  
  return(rev_deps)
}

#' find reverse dependencies
#'
#' @param path pkg_ref path
#' 
#' @keywords internal
find_reverse_dependencies <- function(path){
  
  rev_deps <- cran_revdep(path)
  return(rev_deps)
}

#' Find Reverse Dependencies of a CRAN Package
#'
#' This function finds the reverse dependencies of a CRAN package, i.e., packages that depend on the specified package.
#'
#' @param pkg A character string representing the name of the package.
#' @param dependencies A character vector specifying the types of dependencies to consider. Default is c("Depends", "Imports", "Suggests", "LinkingTo").
#' @param recursive A logical value indicating whether to find dependencies recursively. Default is FALSE.
#' @param ignore A character vector of package names to ignore. Default is NULL.
#' @param installed A matrix of installed packages.
#'
#' @return deps - A sorted character vector of package names that depend on the specified package.
#'
#' @examples
#' \dontrun{
#' cran_revdep("ggplot2")
#' }
#'
#' @export
cran_revdep <- function(pkg,
                   dependencies = c("Depends", "Imports", "Suggests", "LinkingTo"),
                   recursive = FALSE, ignore = NULL,
                   installed = NULL) {
  if (missing(pkg)) {
    message("Package name is required")
    deps <- NULL
  } else {
    if (is.null(installed)) {
      installed <- cran_packages()
    }
    
    deps <- dependsOnPkgs(pkg, dependencies = dependencies,
                          recursive = recursive,
                          installed = installed)
    deps <- setdiff(deps, ignore)
    sort(deps, method = "radix")
  }
  return(deps)
}



#' Determine Packages that Depend on Given Packages
#'
#' This function identifies packages that depend on the specified packages,
#' considering various types of dependencies (e.g., strong, most, all).
#'
#' @param pkgs A character vector of package names to check dependencies for.
#' @param dependencies A character string specifying the types of dependencies
#'   to consider. Can be "strong", "most", "all", or a custom vector of dependency types.
#' @param recursive A logical value indicating whether to recursively check dependencies.
#' @param lib.loc A character vector of library locations to search for installed packages.
#' @param installed A matrix of installed packages, obtained from cran_packages function.
#'   .
#'
#' @return A character vector of package names that depend on the specified packages.
#'
#' @examples
#' \dontrun{
#' installed <- cran_packages()
#' dependsOnPkgs("here", installed = installed)
#' }
#'
#' @export
dependsOnPkgs <- function(pkgs, dependencies = "most",
                          recursive = TRUE, lib.loc = NULL,
                          installed = NULL) {
  dependencies <- expand_dependency_type_spec(dependencies)
  
  av <- installed[, dependencies, drop = FALSE]
  rn <- as.character(installed[, "Package"])
  
  need <- apply(av, 1L, function(x)
    any(pkgs %in% clean_up_dependencies(x)))
  
  uses <- rn[need]
  
  if (recursive) {
    p <- pkgs
    repeat {
      p <- unique(c(p, uses))
      need <- apply(av, 1L, function(x)
        any(p %in% clean_up_dependencies(x)))
      uses <- unique(c(p, rn[need]))
      if (length(uses) <= length(p)) break
    }
  }
  
  setdiff(uses, pkgs)
}


#' Expand Dependency Type Specification
#'
#' Expands a dependency type specification into a character vector of dependency types.
#'
#' @param x A character string specifying the dependency type ("strong", "most", "all", or custom).
#'
#' @return A character vector of dependency types.
#'
#' @keywords internal
expand_dependency_type_spec <- function(x) {
  if (identical(x, "strong"))
    c("Depends", "Imports", "LinkingTo")
  else if (identical(x, "most"))
    c("Depends", "Imports", "LinkingTo", "Suggests")
  else if (identical(x, "all"))
    c("Depends", "Imports", "LinkingTo", "Suggests", "Enhances")
  else
    x
}

#' Clean Up Dependencies
#'
#' Cleans up a list of dependency strings by extracting unique package names.
#'
#' @param x A character vector of dependency strings.
#'
#' @return A character vector of unique package names.
#'
#' @keywords internal
clean_up_dependencies <- function(x) {
  if (length(x) == 0) return(character())
  unique.default(unlist(lapply(x, extract_dependency_package_names)))
}


#' Extract Package Names from a Dependency String
#'
#' Parses a single package dependency string and extracts valid package names,
#' excluding "R" and ignoring version constraints or comments.
#'
#' @param x A character string representing a package dependency specification,
#' such as `"pkgA (>= 1.0), pkgB, R (>= 3.5.0)"`.
#'
#' @return A character vector of package names extracted from the input string.
#' The result excludes "R" and any version information.
#'
#' @keywords internal
extract_dependency_package_names <- function(x) {
  if (is.na(x)) return(character())
  
  # Split by commas
  parts <- strsplit(x, ",", fixed = TRUE)[[1L]]
  
  # Extract the first alphanumeric token from each part
  pkgs <- sub("[[:space:]]*([[:alnum:].]+).*", "\\1", parts)
  
  # Trim whitespace from each package name
  pkgs <- trimws(pkgs) 
  
  # Filter out empty strings and "R"
  pkgs[nzchar(pkgs) & pkgs != "R"]
}

#' Retrieve the List of CRAN Packages (Internal)
#'
#' Downloads and caches the current list of packages available on CRAN.
#' 
#' @param cache Logical. If \code{TRUE} (default), the result is cached using \code{memoise::memoise()} 
#' with a timeout of 30 minutes to avoid repeated downloads. If \code{FALSE}, the metadata is fetched 
#' directly from CRAN each time the function is called.
#'
#' @return A matrix of package metadata similar to the output of \code{utils::available.packages()},
#' with package names as row names.
#'
#' @details The function downloads the \code{packages.rds} file from the CRAN website,
#' which contains metadata about all available packages. The result is cached using
#' \code{memoise::memoise()} with a timeout of 30 minutes.
#'
#' @examples
#' \donttest{
#' pkgs <- cran_packages()
#' head(rownames(pkgs))
#' }
#'
#' @importFrom memoise memoise timeout
#' @importFrom utils download.file
#' @export
cran_packages <- function(cache = TRUE) {
  get_cran_packages <- function() {
    local <- tempfile(fileext = ".rds")
    on.exit(unlink(local), add = TRUE)
    
    tryCatch({
      utils::download.file("https://cran.r-project.org/web/packages/packages.rds", local,
                           mode = "wb", quiet = TRUE)
      cp <- readRDS(local)
      rownames(cp) <- unname(cp[, 1])
      cp
    }, error = function(e) {
      stop("Failed to download or read CRAN package metadata: ", e$message)
    })
  }
  
  if (cache && requireNamespace("memoise", quietly = TRUE)) {
    memoise::memoise(get_cran_packages, ~memoise::timeout(30 * 60))()
  } else {
    get_cran_packages()
  }
}


