#' Convert input to ISO 8601 date (YYYY-MM-DD)
#'
#' @description
#' Formats inputs as ISO 8601 calendar dates (`"YYYY-MM-DD"`).
#'
#' @param x A vector coercible to `Date` (e.g., character, `Date`, or `POSIXct`).
#'   If `NULL`, the function returns `NULL`.
#'
#' @return
#' A character vector the same length as `x` (or `NULL` if `x` is `NULL`)
#' with dates formatted as `"YYYY-MM-DD"`. Unparseable elements or `NA`s
#' become `NA_character_`.
#'
#' @details
#' Coercion uses [base::as.Date()], so time-of-day and timezone information are
#' dropped. For `POSIXct` inputs, the date is computed by `as.Date.POSIXct`
#' (which uses `tz = "UTC"` by default). Be aware that ambiguous character
#' dates (e.g., `"01/02/2024"`) depend on your R locale/format unless you
#' specify a format before calling this function.
#'
#' @examples
#' as_iso_date(Sys.Date())
#' as_iso_date(NULL)              
#' as_iso_date("not-a-date")
#'
#' @export
as_iso_date <- function(x) {
  
  if (is.null(x)) return(NULL)
  
  tryCatch({
    d <- as.Date(x)
    format(d, "%Y-%m-%d")
  }, error = function(e) {
    NULL
  })
}

#' Get Internal Package URL
#'
#' This function retrieves the URL of an internal package on Mirror, its latest version, 
#' and a list of all available versions.
#'
#' @param package_name A character string specifying the name of the package.
#' @param version An optional character string specifying the version of the package.
#' Defaults to `NULL`, in which case the latest version will be used.
#' @param base_url A character string specifying the base URL of the internal package manager.
#' 
#' @return A list containing:
#'   - `url`: A character string of the package URL (or `NULL` if not found).
#'   - `last_version`: A list with `version` and `date` of the latest version (or `NULL`).
#'   - `version`: The version used to generate the URL (or `NULL`).
#'   - `all_versions`: A list of all available versions, each as a list with `version` and `date`.
#'
#' @examples
#' \dontrun{
#' result <- get_internal_package_url("internalpackage", version = "1.0.1")
#' print(result)
#' }
#'
#' @importFrom curl curl_fetch_memory
#' @importFrom jsonlite fromJSON
#' @export
get_internal_package_url <- function(package_name, version = NULL,
                                     base_url = NULL) {
  
  if (is.null(base_url)) {
    repos <- getOption("repos")
    
    if (is.null(repos) || !("INTERNAL_RSPM" %in% names(repos))) {
        message("NO INTERNAL_RSPM FOUND")
        return(list(url = NULL, last_version = NULL, all_versions = list(), repo_id = NULL, repo_name = NULL))
    }
    base_url <- repos["INTERNAL_RSPM"]
  }
  
  # Function to fetch JSON data from a URL
  fetch_json <- function(url) {
    response <- tryCatch(curl::curl_fetch_memory(url), error = function(e) NULL)
    if (is.null(response) || response$status_code != 200) return(NULL)
    tryCatch({
      json_content <- rawToChar(response$content)
      jsonlite::fromJSON(json_content)
    }, error = function(e) {
      message("Failed to parse JSON:", conditionMessage(e))
      NULL
    })
  }
  
  # Fetch the list of repositories
  repos_url <- paste0(base_url, "/__api__/repos/")
  repos_data <- fetch_json(repos_url)
  
  if (is.null(repos_data)) {
    return(list(url = NULL, last_version = NULL, all_versions = list(), repo_id = NULL, repo_name = NULL))
  }
  
  # Get all repository IDs 
  repo_ids <- repos_data$id
  repo_names <- repos_data$name
  names(repo_ids) <- repo_names
  
  found_data <- NULL
  found_repo_id <- NULL
  found_repo_name <- NULL
  
  for (i in seq_along(repo_ids)) {
    repo_id <- repo_ids[i]
    repo_name <- repo_names[i]
    
    package_url <- paste0(base_url, "/__api__/repos/", repo_id, "/packages/", package_name)
    data <- fetch_json(package_url)
    
    if (!is.null(data) && !is.null(data$version)) {
      found_data <- data
      found_repo_id <- repo_id
      found_repo_name <- repo_name
      break
    }
  }
  
  if (is.null(found_data)) {
    return(list(url = NULL, last_version = NULL, all_versions = list(), repo_id = NULL, repo_name = NULL))
  }
  
  # Process versions
  last_version <- NULL
  all_versions <- list()
  
  if (!is.null(found_data$version) && !is.null(found_data$date_publication)) {
    last_version <- list(
      version = found_data$version,
      date = as.Date(substr(found_data$date_publication, 1, 10))
    )
    all_versions[[length(all_versions) + 1]] <- last_version
  }
  
  if (!is.null(found_data$archived)) {
    if (is.data.frame(found_data$archived)) {
      for (i in seq_len(nrow(found_data$archived))) {
        ver <- found_data$archived$version[i]
        date <- as.Date(substr(found_data$archived$date[i], 1, 10))
        all_versions[[length(all_versions) + 1]] <- list(version = ver, date = date)
      }
    } else if (is.list(found_data$archived)) {
      for (av in found_data$archived) {
        if (!is.null(av$version) && !is.null(av$date)) {
          ver <- av$version
          date <- as.Date(substr(av$date, 1, 10))
          all_versions[[length(all_versions) + 1]] <- list(version = ver, date = date)
        }
      }
    }
  }
  
  # Determine the URL for the chosen version
  chosen_version <- if (is.null(version)) last_version$version else version
  url <- NULL
  
  # Construct the URL based on repository name and version
  if (!is.null(chosen_version)) {
    if (!is.null(last_version) && chosen_version == last_version$version) {
      # Latest version URL
      url <- paste0(base_url, "/", found_repo_name, "/latest/src/contrib/", 
                    package_name, "_", chosen_version, ".tar.gz")
    } else {
      # Archived version URL
      version_list <- sapply(all_versions, function(x) x$version)
      if (!is.null(version_list) && chosen_version %in% version_list) {
        url <- paste0(base_url, "/", found_repo_name, "/latest/src/contrib/Archive/", 
                      package_name, "/", package_name, "_", chosen_version, ".tar.gz")
      }
    }
  }
  
  return(list(
    url = url, 
    last_version = last_version, 
    all_versions = all_versions, 
    repo_id = found_repo_id,
    repo_name = found_repo_name
  ))
}


#' Check if a Package Exists on CRAN
#'
#' This function checks if a given package is available on CRAN. 
#'
#' @param package_name A character string specifying the name of the package to check.
#'
#' @return A logical value: `TRUE` if the package exists on CRAN, `FALSE` otherwise.
#'
#' @examples
#' \dontrun{
#' # Check if the package "ggplot2" exists on CRAN
#' check_cran_package("ggplot2")
#' }
#' @importFrom curl curl_fetch_memory
#' @export
check_cran_package <- function(package_name) {
  base_url <- "https://cran.r-project.org/web/packages/"
  package_url <- paste0(base_url, package_name, "/index.html")
  
  # Perform GET request
  response <- curl::curl_fetch_memory(package_url)
  
  # If package does not exist, return FALSE
  if (response$status_code != 200) {
    return(FALSE)
  }
  
  content <- rawToChar(response$content)
  html_doc <- xml2::read_html(content)
  clean_content <- xml2::xml_text(html_doc)
  clean_content <- tolower(clean_content)
  
  clean_content <- gsub("[[:punct:]]", "", clean_content)
  clean_content <- gsub("\\s+", " ", clean_content)
  
  escaped_package_name <- gsub("\\.", "\\\\.", package_name)
  escaped_package_name <- gsub("[[:punct:]]", "", escaped_package_name)  
  
  removed_pattern <- paste0("package ", escaped_package_name, " was removed from the cran repository")
  
  # Check if the package has been removed
  if (grepl(removed_pattern, clean_content, ignore.case = TRUE, perl = TRUE)) {
    return(FALSE)
  }
  return(TRUE)
}


#' Parse Package Information from CRAN Archive
#'
#' This function retrieves the package archive information from the CRAN Archive.
#'
#' @param name A character string specifying the name of the package to fetch information for.
#'
#' @return A character string containing the raw HTML content of the package archive page, or `NULL`
#' if the request fails or the package is not found.
#'
#' @examples
#' \dontrun{
#' # Fetch package archive information for "dplyr"
#' parse_package_info("dplyr")
#'
#'}
#' @importFrom curl curl_fetch_memory
#' @export
parse_package_info <- function(name) {
  url <- paste0("https://cran.r-project.org/src/contrib/Archive/", name, "/")
  
  # Perform GET request
  response <- curl::curl_fetch_memory(url)
  
  if (response$status_code == 200) {
    return(rawToChar(response$content))
  } else {
    return(NULL)
  }
}

#' Parse HTML Version Information for a Package
#'
#' This function extracts version information from the HTML content of a CRAN archive page.
#'
#' @param html_content A character string containing the HTML content of a CRAN package archive page.
#' @param package_name A character string specifying the name of the package to extract version information for.
#'
#' @return A list of lists, where each sublist contains:
#'   - `package_name`: package name.
#'   - `package_version`: package version.
#'   - `link`: link to the package tarball.
#'   - `date`: The date associated with the package version.
#'   - `size`: The size of the package tarball.
#'
#' @examples
#' \dontrun{
#' html_content <- parse_package_info("dplyr")
#' parse_html_version(html_content, "dplyr")
#'}
#' @importFrom xml2 read_html xml_find_all xml_find_first xml_text xml_attr
#' @keywords internal
parse_html_version <- function(html_content, package_name) {
  
  data <- list()
  
  if (!is.null(html_content)) {
    # Parse the HTML content
    doc <- xml2::read_html(html_content)
    rows <- xml2::xml_find_all(doc, "//tr")
    
    for (row in rows) {
      cols <- xml2::xml_find_all(row, "td")
      if (length(cols) >= 4) {  # Ensure it's not a divider row
        link_tag <- xml2::xml_find_first(cols[2], "a")
        
        if (!is.na(xml2::xml_text(link_tag))) {
          href <- xml2::xml_attr(link_tag, "href")
          text <- xml2::xml_text(link_tag)
          date <- xml2::xml_text(cols[3])
          size <- xml2::xml_text(cols[4])
          version <- ""
          
          if (grepl(paste0("^", package_name, "(?:_|$)"), text)) {
            version <- gsub(paste0("^", package_name, "(?:_|$)|\\.tar\\.gz$"), "", text)
          } else {
            version <- ""  
          }
          
          if (version == "Parent Directory" | version == "") {
            next
          }
          
          data <- append(data, list(
            list(
              package_name = package_name,
              package_version = version,
              link = href,
              date = date,
              size = size
            )
          ))
        }
      }
    }
  }
  
  return(data)
}


#' Get Package Versions
#'
#' This function retrieves all available versions of a package, including the latest version,
#' by parsing the provided version table and querying the RStudio Package Manager.
#'
#' @param table A list of parsed package data (e.g., from `parse_html_version()`), where each element contains package details such as `package_version` and `date`.
#' @param package_name A character string specifying the name of the package to fetch versions for.
#'
#' @return A list with the following elements:
#' \describe{
#'   \item{all_versions}{A list of named lists, each containing:
#'     \describe{
#'       \item{version}{The version number of the package.}
#'       \item{date}{The associated publication date as a string.}
#'     }
#'   }
#'   \item{last_version}{A named list containing the latest version of the package with:
#'     \describe{
#'       \item{version}{The latest version number.}
#'       \item{date}{The publication date of the latest version.}
#'     }
#'     May be \code{NULL} if the API call fails.
#'   }
#' }
#'
#' @examples
#' \dontrun{
#' # Define the input table
#' table <- list(
#'   list(
#'     package_name = "here",
#'     package_version = "0.1",
#'     link = "here_0.1.tar.gz",
#'     date = "2017-05-28 08:13",
#'     size = "3.5K"
#'   ),
#'   list(
#'     package_name = "here",
#'     package_version = "1.0.0",
#'     link = "here_1.0.0.tar.gz",
#'     date = "2020-11-15 18:10",
#'     size = "32K"
#'   )
#' )
#'
#' result <- get_versions(table, "here")
#' print(result)
#' }
#'
#' @importFrom curl curl_fetch_memory
#' @importFrom jsonlite fromJSON
#' @export
get_versions <- function(table, package_name) {
  
  # From the CRAN Archive table
  all_versions <- lapply(table, function(item) {
    if (!is.null(item$package_version)) {
      list(
        version = item$package_version,
        date = as_iso_date(item$date)  # handles "YYYY-MM-DD hh:mm"
      )
    } else {
      NULL
    }
  })
  
  # From Posit Package Manager (latest)
  url_latest_version <- paste0("https://packagemanager.posit.co/__api__/repos/1/packages/", package_name)
  response <- curl::curl_fetch_memory(url_latest_version)
  
  if (response$status_code == 200) {
    data <- jsonlite::fromJSON(rawToChar(response$content))
    if (!is.null(data$version) && !is.null(data$date_publication)) {
      last_version <- list(
        version = data$version,
        date = as_iso_date(substr(data$date_publication, 1, 10))
      )
      existing_versions <- sapply(all_versions, function(x) x$version)
      if (!(last_version$version %in% existing_versions)) {
        all_versions <- append(all_versions, list(last_version))
      }
    } else {
      last_version <- NULL
    }
  } else {
    last_version <- NULL
  }
  
  if (is.null(table)) {
    return(list(
      all_versions = if (!is.null(last_version)) list(last_version) else NULL,
      last_version = last_version
    ))
  }
  
  list(all_versions = all_versions, last_version = last_version)
}


#' Check and Fetch CRAN Package
#'
#' This function checks if a package exists on CRAN and retrieves the corresponding package URL and version details.
#' If a specific version is not provided, the latest version is used.
#'
#' @param package_name A character string specifying the name of the package to check and fetch.
#' @param package_version An optional character string specifying the version of the package to fetch. Defaults to `NULL`.
#'
#' @return A list with one of the following structures:
#' 
#' \describe{
#'   \item{package_url}{Character string; the URL to download the package tarball.}
#'   \item{last_version}{A named list with \code{version} and \code{date} for the latest available version.}
#'   \item{version}{Character string; the requested version (or \code{NULL} if not specified).}
#'   \item{all_versions}{A list of named lists, each with \code{version} and \code{date}, representing all available versions.}
#' }
#' 
#'
#' @examples
#' \dontrun{
#' # Check and fetch a specific version of "ggplot2"
#' result <- check_and_fetch_cran_package("ggplot2", package_version = "3.3.5")
#' print(result)
#' }
#'
#' @importFrom curl curl_fetch_memory
#' @importFrom jsonlite fromJSON
#' @export
check_and_fetch_cran_package <- function(package_name, package_version = NULL) {
  if (!check_cran_package(package_name)) {
    return(list(package_url = NULL, last_version = NULL, version = NULL, all_versions = NULL))
  }
  
  html <- parse_package_info(package_name)
  table <- if (!is.null(html)) parse_html_version(html, package_name) else NULL
  versions <- get_versions(table, package_name)
  
  url <- get_cran_package_url(package_name, package_version, versions$last_version, versions$all_versions)
  
  # Ensure all dates are ISO strings
  all_versions_list <- lapply(versions$all_versions, function(x) {
    list(version = x$version, date = as_iso_date(x$date))
  })
  
  if (is.null(url) && !is.null(package_version) &&
      !(package_version %in% sapply(versions$all_versions, function(x) x$version))) {
    return(list(
      error = paste("Version", package_version, "for", package_name, "not found"),
      versions_available = all_versions_list
    ))
  }
  
  list(
    package_url = url,
    last_version = if (is.null(versions$last_version)) NULL else list(
      version = versions$last_version$version,
      date = as_iso_date(versions$last_version$date)
    ),
    version = package_version,
    all_versions = all_versions_list
  )
}



#' Get CRAN Package URL
#'
#' This function constructs the CRAN package URL for a specified package and version.
#'
#' @param package_name A character string specifying the name of the package.
#' @param version An optional character string specifying the version of the package.
#' If `NULL`, the latest version is assumed.
#' @param last_version A named list with elements version and date, 
#' representing the latest available version and its publication date.
#' @param all_versions A list of named lists, each with elements version and date, 
#' representing all known versions of the package and their publication dates.
#'
#' @return A character string containing the URL to download the package tarball,
#' or "No valid URL found" if the version is not found in the list of available versions.
#'
#' @examples
#' \dontrun{
#' # Example data structure
#' last_version <- list(version = "1.0.10", date = "2024-01-01")
#' all_versions <- list(
#'   list(version = "1.0.0", date = "2023-01-01"),
#'   list(version = "1.0.10", date = "2024-01-01")
#' )
#'
#' # Get the URL for the latest version of "dplyr"
#' url <- get_cran_package_url("dplyr", NULL, last_version, all_versions)
#' print(url)
#' }
#' @export
get_cran_package_url <- function(package_name, version, last_version, all_versions) {
  # Extract just the version strings from the all_versions list
  version_list <- sapply(all_versions, function(x) x$version)
  
  # Set version to the latest version if not provided
  if (is.null(version)) {
    version <- last_version$version
  }
  
  # Check if the version exists in version_list
  if (version %in% version_list) {
    # If it's the latest version
    if (!is.null(last_version) && version == last_version$version) {
      return(paste0("https://cran.r-project.org/src/contrib/", package_name, "_", version, ".tar.gz"))
    }
    
    # Otherwise, it's an archived version
    return(paste0("https://cran.r-project.org/src/contrib/Archive/", package_name, "/", package_name, "_", version, ".tar.gz"))
  }
  
  # Return fallback message
  return("No valid URL found")
}



#' Extract and Validate Package Hosting Information
#' 
#' This function retrieves hosting links for an R package from various sources such as GitHub, CRAN, internal repositories, or Bioconductor.
#' 
#' @param pkg_name Character. The name of the package.
#' @param pkg_version Character. The version of the package.
#' @param pkg_source_path Character. The file path to the package source directory containing the DESCRIPTION file.
#' 
#' @return A list containing the following elements:
#' 
#' - `github_links`: GitHub links related to the package.
#' - `cran_links`: CRAN links
#' - `internal_links`: internal repository links.
#' - `bioconductor_links`: Bioconductor links 
#' 
#' If links are found, return empty or NULL.
#' 
#' @details
#' The function extracts hosting links by:
#' 1. Parsing the `DESCRIPTION` file for GitHub and BugReports URLs.
#' 2. Checking if the package is valid on CRAN and others host repository
#' 
#' If no links are found in the `DESCRIPTION` file, returns `NULL`
#' 
#' @examples
#' \dontrun{
#' result <- get_host_package(pkg_name, pkg_version, pkg_source_path)
#' print(result)
#' }
#' @export
get_host_package <- function(pkg_name, pkg_version, pkg_source_path) {
  
  message(glue::glue("Checking host package"))
  
  # Path to the DESCRIPTION file
  pkg_desc_path <- file.path(pkg_source_path, "DESCRIPTION")
  
  # Load the DESCRIPTION file
  d <- description$new(file = pkg_desc_path)
  description_text <- d$str()
  
  # Extract URLs from $get_urls() and $get_list("BugReports")
  urls <- d$get_urls()
  
  if (d$has_fields("BugReports")) {
    bug_reports <- d$get_list("BugReports")
  } else {
    bug_reports <- NULL  
  }  
  
  all_links <- c(urls, bug_reports)
  github_pattern <- "https://github.com/([^/]+)/([^/]+).*"
  matching_links <- grep(github_pattern, all_links, value = TRUE)
  owner_names <- sub(github_pattern, "\\1", matching_links)
  package_names_github <- sub(github_pattern, "\\2", matching_links)
  
  valid <- which(owner_names != "" & package_names_github != "")
  
  if (length(valid) > 0) {
    github_links <- unique(paste0("https://github.com/", owner_names[valid], "/", package_names_github[valid]))
  } else {
    github_links <- NULL
  }
  
  is_package_valid <- check_cran_package(pkg_name)
  
  if (is_package_valid) {
    # Fetch the archive content
    result_cran <- check_and_fetch_cran_package(pkg_name, pkg_version)  
    # get CRAN links
    cran_links <- get_cran_package_url(pkg_name, pkg_version, result_cran$last_version, result_cran$all_versions)
    
  } else {
    cran_links <- NULL
    
  }
  
  # get internal package link
  result_internal <- get_internal_package_url(pkg_name, pkg_version)
  internal_links <- result_internal$url
  
  bioconductor_links <-  NULL
  
  # Define the Bioconductor pattern
  bioconductor_pattern <- paste0("https://(git\\.)?bioconductor\\.org/packages/", pkg_name, "/?(?=[\\s,]|$)")
  
  # Find the first match in the text for Bioconductor
  bioconductor_match <- regexpr(bioconductor_pattern, description_text, perl = TRUE)
  
  if (bioconductor_match != -1) {
    bioconductor_links <- regmatches(description_text, bioconductor_match)
  }
  
  result <- list(
    github_links = github_links,
    cran_links = cran_links,
    internal_links = internal_links,
    bioconductor_links = bioconductor_links
  )
  
  return(result)
}