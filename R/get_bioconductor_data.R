#' Fetch Bioconductor Release Announcements
#' 
#' This function retrieves the Bioconductor release announcements page and returns
#' its HTML content for further processing.
#' 
#' @return An XML document from bioconductor version page.
#' 
#' @importFrom curl curl_fetch_memory
#' @importFrom xml2 read_html
#' 
#' @examples
#' \dontrun{
#' html_content <- fetch_bioconductor_releases()
#' }
#' @export
fetch_bioconductor_releases <- function() {
  url <- "https://bioconductor.org/about/release-announcements/"
  
  # Perform GET request
  response <- curl::curl_fetch_memory(url)
  
  # If status code is not 200, return FALSE
  if (response$status_code != 200) {
    return(FALSE)
  }
  
  html_content <- xml2::read_html(rawToChar(response$content))
  return(html_content)
}

#' Parse Bioconductor Release Announcements
#' 
#' This function extracts Bioconductor release details such as version number,
#' release date, number of software packages, and required R version from the 
#' release announcements HTML page.
#' 
#' @param html_content The parsed HTML document from `fetch_bioconductor_releases`.
#' 
#' @return A list of lists containing Bioconductor release details: release version, date,
#'         number of software packages, and corresponding R version.
#' 
#' @importFrom xml2 xml_find_first xml_find_all xml_text
#' @importFrom stringr str_trim
#' 
#' @examples
#' \dontrun{
#' html_content <- fetch_bioconductor_releases()
#' release_data <- parse_bioconductor_releases(html_content)
#' print(release_data)
#' }
#' @export
parse_bioconductor_releases <- function(html_content) {
  data <- list()
  
  table <- xml2::xml_find_first(html_content, "//table")
  rows <- xml2::xml_find_all(table, ".//tr")[-1]  # Skip the header row
  
  for (row in rows) {
    cols <- xml2::xml_find_all(row, ".//td")
    
    if (length(cols) == 4) {
      release <- xml2::xml_text(cols[1])
      date <- xml2::xml_text(cols[2])
      software_packages <- xml2::xml_text(cols[3])
      r_version <- xml2::xml_text(cols[4])
      
      data <- append(data, list(list(
        release = stringr::str_trim(release),
        date = stringr::str_trim(date),
        software_packages = stringr::str_trim(software_packages),
        r_version = stringr::str_trim(r_version)
      )))
    }
  }
  return(data)
}

#' Parse HTML Content for Package Versions
#' 
#' This function extracts version information from an HTML page listing
#' available versions of a Bioconductor package.
#' 
#' @param html_content A character string containing the HTML content.
#' @param package_name A character string specifying the name of the package.
#' 
#' @return A list of lists containing package details such as package name, version, link,
#'         date, and size. Returns an empty list if no versions are found.
#' 
#' @importFrom xml2 read_html xml_find_all xml_find_first xml_text xml_attr
#' @importFrom stringr str_trim
#' 
#' @examples
#' \dontrun{
#' parse_html_version(html_content, "GenomicRanges")
#' }
#' @export
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

#' Extract Package Version from File Path
#' 
#' This function extracts the version number from a package source file name
#' based on the package name and expected file pattern.
#' 
#' @param path A character string specifying the file path or URL.
#' @param package_name A character string specifying the name of the package.
#' 
#' @return A character string representing the extracted version number, or `NULL` if no match is found.
#' 
#' @examples
#' \dontrun{
#' link <- "https://bioconductor.org/packages/3.14/bioc/src/contrib/GenomicRanges_1.42.0.tar.gz"
#' extract_version(link, "GenomicRanges")
#' }
#' @export
extract_version <- function(path, package_name) {
  pattern <- paste0(package_name, "_([0-9\\.]+)\\.tar\\.gz$")
  match <- regexpr(pattern, path, perl = TRUE)
  
  if (match == -1) {
    return(NULL) # No match found
  }
  
  version <- regmatches(path, regexec(pattern, path))[[1]][2]
  return(version)
}

#' Fetch Bioconductor Package Information
#' 
#' This function retrieves information about a specific Bioconductor package
#' for a given Bioconductor version. It fetches the package details, such as
#' version, source package URL, and archived versions if available.
#' 
#' @param bioconductor_version A character string specifying the Bioconductor version (e.g., "3.14").
#' @param package_name A character string specifying the name of the package.
#' 
#' @return A list containing package details, including the latest version, package URL,
#'         source package link, and any archived versions if available.
#'         Returns `FALSE` if the package does not exist or cannot be retrieved.
#' 
#' @importFrom curl curl_fetch_memory
#' @importFrom xml2 read_html xml_find_all xml_find_first xml_text xml_attr
#' 
#' @examples
#' \dontrun{
#' info <- fetch_bioconductor_package_info("3.14", "GenomicRanges")
#' print(info)
#' }
#' @export
fetch_bioconductor_package_info <- function(bioconductor_version, package_name) {
  
  repo_list <- list()
  url_page <- paste0("https://bioconductor.org/packages/", bioconductor_version, "/bioc/html/", package_name, ".html")
  
  message("url_page: ", url_page)
  
  # Perform GET request with proper error handling
  response <- tryCatch({
    curl::curl_fetch_memory(url_page)  # Remove handle argument
  }, error = function(e) {
    message(paste("Error fetching:", url_page, "->", e$message))
    return(NULL)
  })
  
  # If package does not exist, return FALSE
  if (is.null(response) || response$status_code != 200) {
    return(FALSE)
  }
  
  # Ensure content is not empty before parsing HTML
  if (is.null(response$content) || length(response$content) == 0) {
    stop("Response is NULL or empty for URL: ", url_page)
  }
  
  html_content <- tryCatch({
    read_html(rawToChar(response$content))
  }, error = function(e) {
    message("Failed to parse HTML content for: ", package_name)
    return(NULL)
  })
  
  if (is.null(html_content)) return(FALSE)  
  
  data_dict <- list()
  rows <- xml_find_all(html_content, "//tr")
  keys_to_keep <- c("version", "url", "source_package")
  
  for (row in rows) {
    cells <- xml_find_all(row, "td")
    if (length(cells) == 2) {
      key <- tolower(gsub(" ", "_", xml_text(cells[1])))
      
      if (key %in% keys_to_keep) {
        data_dict[[key]] <- trimws(xml_text(cells[2]))
      }
    }
  }
  
  # Ensure we have a proper version
  if (!"version" %in% names(data_dict)) {
    return(FALSE)
  }
  
  # Get latest version for the Bioconductor version
  data_dict$bioconductor_version <- bioconductor_version
  data_dict$url_package <- data_dict$url
  data_dict$archived <- FALSE
  
  # Extract source package from links on the page
  page <- tryCatch({
    read_html(url_page)
  }, error = function(e) {
    message("Failed to fetch page: ", url_page)
    return(NULL)
  })
  
  if (!is.null(page)) {
    links <- xml_find_all(page, "//a")
    hrefs <- xml_attr(links, "href")
    tar_gz_links <- hrefs[grepl("\\.tar\\.gz$", hrefs)]
    
    package_version <- extract_version(tar_gz_links, package_name)
    if (!is.null(package_version)) {
      source_package_main <- paste0("https://bioconductor.org/packages/", bioconductor_version, "/bioc/src/contrib/", package_name, "_", package_version, ".tar.gz")
      data_dict$source_package <- source_package_main
    } else {
      data_dict$source_package <- NA  # Ensure there's always a value
    }
  }
  
  # Get archived versions
  url_archive <- paste0("https://bioconductor.org/packages/", bioconductor_version, "/bioc/src/contrib/Archive/", package_name, "/")
  
  archive_page <- tryCatch({
    read_html(url_archive)
  }, error = function(e) {
    return(NULL)
  })
  
  repo_list <- list(data_dict)
  
  archive_page <- tryCatch({
    read_html(url_archive)
  }, error = function(e) {
    return(NULL)
  })
  
  if (!is.null(archive_page)) {
    links <- xml_find_all(archive_page, "//a")
    hrefs <- xml_attr(links, "href")
    archive_tar_gz_links <- hrefs[grepl("\\.tar\\.gz$", hrefs)]
    
    if (length(archive_tar_gz_links) > 0) {
      full_archive_links <- rev(paste0(url_archive, archive_tar_gz_links))
      
      for (link in full_archive_links) {
        version <- extract_version(link, package_name)
        repo <- list(
          version = version, 
          url = data_dict$url_package, 
          source_package = link, 
          archived = TRUE, 
          bioconductor_version = bioconductor_version
        )
        repo_list <- append(repo_list, list(repo))
      }
    }
  }
  
  return(repo_list)
}


#' Retrieve Bioconductor Package URL
#'
#' This function fetches the source package URL for a given Bioconductor package.
#' If no version is specified, it retrieves the latest available version.
#'
#' @param package_name A character string specifying the name of the Bioconductor package.
#' @param package_version (Optional) A character string specifying the package version. Defaults to `NULL`, which retrieves the latest version.
#' @param release_data A list containing Bioconductor release information.
#'
#' @return A list containing:
#'  \item{url}{The URL of the source package (if available).}
#'  \item{version}{The specified or latest available package version.}
#'  \item{last_version}{A list with version, date, and Bioconductor version.}
#'  \item{all_versions}{A list of all discovered versions with version, date, and Bioconductor version.}
#'  \item{bioconductor_version_package}{The Bioconductor version matched to the selected version.}
#'  \item{archived}{A logical value indicating whether the package is archived.}
#'
#' @examples
#' \dontrun{
#' release_data <- list(
#'   list(release = "3.17", date = "October 14, 2005"),
#'   list(release = "3.18", date = "October 4, 2006"),
#'   list(release = "3.19", date = "October 8, 2007")
#' )
#' 
#' get_bioconductor_package_url("GenomicRanges", release_data = release_data)
#' 
#'}
#' @export
get_bioconductor_package_url <- function(package_name, package_version = NULL, release_data) {
  
  all_versions <- list()
  source_code <- NULL
  bioconductor_version_package <- NULL
  archived <- NULL
  last_version <- NULL
  Sys.setlocale("LC_TIME", "C")
  
  for (version_info in release_data) {
    
    bioconductor_version <- version_info$release
    parsed_date <- strptime(version_info$date, format = "%B %d, %Y")
    
    # Convert to Date type
    if (!is.na(parsed_date)) {
      bioconductor_date <- format(as.Date(parsed_date), "%Y-%m-%d")
    } else {
      bioconductor_date <- NA
    }
    
    message(paste("Checking Bioconductor version:", bioconductor_version))
    
    # Get Bioconductor package info
    package_info <- tryCatch({
      fetch_bioconductor_package_info(bioconductor_version, package_name)
    }, error = function(e) {
      message(paste("Skipping Bioconductor version", bioconductor_version, "due to error:", e$message))
      return(NULL)
    })
    
    if (is.null(package_info) || !is.list(package_info)) next
    
    # Ensure package_info is treated as a list of packages
    if (!is.null(package_info$version)) {
      package_info <- list(package_info)
    }
    
    for (pkg in package_info) {
      if (!is.list(pkg) || is.null(pkg$version)) next
      
      pkg_version <- pkg$version
      message(paste("Checking package version:", pkg_version, "Date:", bioconductor_date))
      
      version_record <- list(
        version = pkg_version,
        date = bioconductor_date,
        bioconductor_version = bioconductor_version
      )
      
      # Add to all_versions (no deduplication needed if you trust the data)
      all_versions <- append(all_versions, list(version_record))
      
      # Update last_version if this version is newer
      if (is.null(last_version)) {
        last_version <- version_record
      } else if (!is.na(bioconductor_date) && !is.na(last_version$date) && bioconductor_date > last_version$date) {
        last_version <- version_record
      } else if (is.na(last_version$date) && !is.na(bioconductor_date)) {
        last_version <- version_record
      }
      
      # Set default package version if not specified
      if (is.null(package_version) || length(package_version) == 0 || is.na(package_version)) {
        package_version <- last_version$version
      }
      
      # Check if this version matches the requested version
      if (!is.null(pkg_version) && !is.null(package_version) &&
          !is.na(pkg_version) && !is.na(package_version) &&
          pkg_version == package_version) {
        
        bioconductor_version_package <- bioconductor_version
        source_code <- pkg$source_package
        archived <- ifelse(!is.null(pkg$archived), pkg$archived, FALSE)
      }
    }
  }
  
  if (is.null(source_code)) {
    message("Package URL not found on Bioconductor")
  }
  
  return(list(
    url = source_code,
    version = package_version,
    last_version = last_version,
    all_versions = all_versions,
    bioconductor_version_package = bioconductor_version_package,
    archived = archived
  ))
}




#' Find Bioconductor Package Reverse Dependencies 
#'
#' This function returns the reverse dependencies for a given Bioconductor package.
#'
#' @param pkg Character string. The name of the package for which to find reverse dependencies.
#' @param which Character vector. The dependency categories to check.
#'   One or more of \code{"Depends"}, \code{"Imports"}, \code{"LinkingTo"},
#'   \code{"Suggests"}, or \code{"Enhances"}. Defaults to \code{"Imports"}.
#' @param only.bioc Logical. If \code{TRUE} (default), only reverse dependencies
#'   that are Bioconductor packages are returned.
#' @param version Bioconductor version to use. Defaults to the current version.
#' @param db Optional. A pre-loaded package database to use for lookups.
#' @param biocdb Optional. A pre-loaded Bioconductor package database.
#'
#' @return A named list of reverse dependency package names.
#'
#' @examples
#' \dontrun{
#' # Get reverse Imports dependencies as a list:
#' bioconductor_reverse_deps("limma")
#' 
#' # Get multiple categories:
#' bioconductor_reverse_deps("limma", which = c("Depends", "Suggests"))
#' }
#' @importFrom BiocManager version
#' @importFrom BiocManager repositories
#' @export
bioconductor_reverse_deps <- function(
  pkg,
  which = "Imports",
  only.bioc = FALSE,
  version = BiocManager::version(),
  db = NULL,          
  biocdb = NULL   
) {
  valid_which <- c("Depends", "Imports", "LinkingTo", "Suggests", "Enhances")

  if ("all" %in% which) {
    which_vec <- valid_which
  } else if (!all(which %in% valid_which)) {
    message("Invalid 'which' value. Must be one or more of: ",
            paste(valid_which, collapse = ", "), " or 'all'.")
    return(NULL)
  } else {
    which_vec <- which
  }

  # data source
  if (is.null(db)) {
    repos <- BiocManager::repositories(version = version, replace = TRUE)

    read_packages_index <- function(repo_url) {
      
      idx <- utils::contrib.url(repo_url, type = "source")
      urls <- c(file.path(idx, "PACKAGES.gz"), file.path(idx, "PACKAGES"))
      
      read_one <- function(u) {
        con <- NULL
        on.exit(try(close(con), silent = TRUE), add = TRUE)
        con <- if (grepl("\\.gz$", u)) gzcon(url(u, "rb")) else url(u, "rb")
        dcf <- tryCatch(read.dcf(con), error = function(e) NULL)
        if (is.null(dcf)) return(NULL)
        df <- as.data.frame(dcf, stringsAsFactors = FALSE, optional = TRUE)
        if (!nrow(df)) return(NULL)
        needed <- c("Package","Depends","Imports","LinkingTo","Suggests","Enhances")
        for (nm in setdiff(needed, names(df))) df[[nm]] <- NA_character_
        rownames(df) <- df$Package
        df[ , needed, drop = FALSE]
      }
      for (u in urls) {
        out <- tryCatch(read_one(u), error = function(e) NULL)
        if (!is.null(out)) return(out)
      }
      NULL
    }

    db_list <- lapply(unname(repos), read_packages_index)
    db_list <- Filter(Negate(is.null), db_list)

    if (!length(db_list)) {
      message("Error fetching package database: could not read any PACKAGES indexes.")
      return(NULL)
    }
    db <- do.call(rbind, db_list)
  } else {
    db <- as.data.frame(db, stringsAsFactors = FALSE)
    if (is.null(rownames(db)) && "Package" %in% names(db)) rownames(db) <- db$Package
    needed <- c("Package","Depends","Imports","LinkingTo","Suggests","Enhances")
    for (nm in setdiff(needed, names(db))) db[[nm]] <- NA_character_
    db <- db[, needed, drop = FALSE]
  }

  if (isTRUE(only.bioc)) {
    if (is.null(biocdb)) {
      repos <- BiocManager::repositories(version = version, replace = TRUE)
      biocdb <- db
    } else {
      biocdb <- as.data.frame(biocdb, stringsAsFactors = FALSE)
      if (is.null(rownames(biocdb)) && "Package" %in% names(biocdb)) rownames(biocdb) <- biocdb$Package
    }
    db <- db[rownames(db) %in% rownames(biocdb), , drop = FALSE]
  }

  out <- lapply(which_vec, function(w) {
    res <- tools::package_dependencies(packages = pkg, db = db, reverse = TRUE, which = w)[[pkg]]
    if (is.null(res)) character(0) else unname(res)
  })
  names(out) <- which_vec
  out
}
