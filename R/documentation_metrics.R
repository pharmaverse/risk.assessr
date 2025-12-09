#' Assess Rd files for example or examples
#'
#' @param pkg_name - name of the package 
#' @param pkg_source_path - source path for install local
#'
#' @return has_examples - variable with score
#' @keywords internal
assess_examples <- function(pkg_name, pkg_source_path) {
  
  # get all information on Rd objects
  db <- tools::Rd_db(dir = pkg_source_path)
  
  # omit whole package rd
  db <- db[!names(db) %in% c(paste0(pkg_name, "-package.Rd"), paste0(pkg_name,".Rd"))]
  
  extract_section <- function(rd, section) {
    lines <- unlist(strsplit(as.character(rd), "\n"))
    start <- grep(paste0("^\\\\", section), lines)
    if (length(start) == 0) return(NULL)
    end <- grep("^\\\\", lines[-(1:start)], fixed = TRUE)
    end <- if (length(end) == 0) length(lines) else start + end[1] - 2
    paste(lines[(start + 1):end], collapse = "\n")
  }
  # check Rd objects for example examples usage
  examples <- lapply(db, extract_section, section = "examples")
  example <- lapply(db, extract_section, section = "example")
  
  # filter out NULL values
  examples <- Filter(Negate(is.null), examples)
  example <- Filter(Negate(is.null), example)
  
  if (length(examples) > 0 | length(example) > 0) {
    message(glue::glue("{pkg_name} has examples"))
    has_examples <- 1
  } else {
    message(glue::glue("{pkg_name} has no examples"))
    has_examples <- 0
  }
 return(has_examples)
}

#' Assess exported functions to namespace
#'
#' @param data pkg source path
#' @keywords internal
assess_exports <- function(data) {
  
  exports <- parseNamespaceFile(basename(data), dirname(data), mustExist = FALSE)$exports
  if (length(exports) > 0) {
    export_calc <- 1
  } else {
    export_calc <- 0
  }
} 

#' assess_export_help
#'
#' @param pkg_name - name of the package 
#' @param pkg_source_path - pkg_source_path - source path for install local
#'
#' @return - export_help - variable with score
#' @keywords internal
assess_export_help <- function(pkg_name, pkg_source_path) {
  
  exported_functions <- getNamespaceExports(pkg_name)
  if (length(exported_functions) > 0) {
    db <- tools::Rd_db(pkg_name, pkg_source_path)
    missing_docs <- setdiff(exported_functions, gsub("\\.Rd$", "", names(db)))
    if (length(missing_docs) == 0) {
      message(glue::glue("All exported functions have corresponding help files in {pkg_name}"))
      export_help <- 1
    } else {
      message(glue::glue("Some exported functions are missing help files in {pkg_name}"))
      # message(glue::glue("The following exported functions are missing help files in {pkg_name}"))
      # print(missing_docs) comment out - reactivate if needed
      export_help <- 0
    }
  } else {
    message(glue::glue("No exported functions in {pkg_name}"))
    export_help <- 0
  }
  return(export_help)
}

#' assess_description_file_elements
#'
#' @param pkg_name - name of the package 
#' @param pkg_source_path - pkg_source_path - source path for install local
#'
#' @return - list - list with scores for description file elements
#' @keywords internal
assess_description_file_elements <- function(pkg_name, pkg_source_path) {
  
  desc_elements <- get_pkg_desc(pkg_source_path, fields = c(
                                                            "Package", 
                                                            "BugReports",
                                                            "Maintainer",
                                                            "URL"
                                                            ))
  
  if (is.null(desc_elements$BugReports) | (is.na(desc_elements$BugReports))) {
    message(glue::glue("{pkg_name} does not have bug reports URL"))
    has_bug_reports_url <- NULL
  } else {
    message(glue::glue("{pkg_name} has bug reports URL"))
    has_bug_reports_url <- desc_elements$BugReports
  }
  
  has_maintainer <- desc::desc_get_author(role = "cre",
                                       file = pkg_source_path)
  if (length(has_maintainer) == 0) {
    has_maintainer <-  NULL
    message(glue::glue("{pkg_name} does not have a maintainer"))
  } else {
    message(glue::glue("{pkg_name} has a maintainer"))
  }  
  
  if (is.null(desc_elements$URL) | (is.na(desc_elements$URL))) {
    message(glue::glue("{pkg_name} does not have a website"))
    has_website <- NULL
  } else {
    message(glue::glue("{pkg_name} has a website"))
    has_website <- desc_elements$URL
  }
  
  if (is.null(desc_elements$URL) | (is.na(desc_elements$URL))) {
    message(glue::glue("{pkg_name} does not have a website"))
    has_website <- NULL
  } else {
    message(glue::glue("{pkg_name} has a website"))
    has_website <- desc_elements$URL
  }
  
  if (is.null(desc_elements$URL) | (is.na(desc_elements$URL))) {
    message(glue::glue("{pkg_name} does not have a source control"))
    has_source_control <- NULL
  } else {
    patterns <- "github\\.com|bitbucket\\.org|gitlab\\.com|\\.ac\\.uk|\\.edu\\.au|bioconductor\\.org"
    url_matches <- grep(patterns, desc_elements$URL, value = TRUE)
    if (length(url_matches) == 0) {
      message(glue::glue("{pkg_name} does not have a source control"))
      has_source_control <- NULL
    } else {
      message(glue::glue("{pkg_name} has a source control"))
      has_source_control <- url_matches
    }
  }
  
  desc_elements_scores <- list(
    has_bug_reports_url = has_bug_reports_url,
    has_maintainer = has_maintainer,
    has_website = has_website,
    has_source_control = has_source_control
  )

  return(desc_elements_scores)
}

#' Assess Rd files for news
#'
#' @param pkg_name - name of the package 
#' @param pkg_source_path - source path for install local
#'
#' @return has_news - variable with score
#' @keywords internal
assess_news <- function(pkg_name, pkg_source_path) {
  
  news <- list.files(pkg_source_path, 
                     pattern = "^NEWS\\.", 
                     full.names = TRUE)
  
  if (length(news) > 0) {
    message(glue::glue("{pkg_name} has news"))
    has_news <- 1
  } else {
    message(glue::glue("{pkg_name} has no news"))
    has_news <- 0
  }
  return(has_news)
}

#' Assess Rd files for news
#'
#' @param pkg_name - name of the package
#' @param pkg_ver - package version 
#' @param pkg_source_path - source path for install local
#'
#' @return news_current - variable with score
#' @keywords internal
assess_news_current <- function(pkg_name, pkg_ver, pkg_source_path) {
  
  # get NEWS.md filepath
  news_path <- file.path(pkg_source_path, "NEWS.md")
  
  # check news for latest package version
  if (file.exists(news_path)) {
    news_content <- readLines(news_path)
    version_pattern <- paste0("^# ",
                              pkg_name,
                              " ",
                              pkg_ver)
    version_lines <- grep(version_pattern, 
                          news_content, 
                          value = TRUE)
  } else {
    message(glue::glue("{pkg_name} has no news path"))
    version_lines <- character(0)
  }
  
  if (length(version_lines) == 0) {
    message(glue::glue("{pkg_name} has no current news"))
    news_current <- 0
  } else {
    message(glue::glue("{pkg_name} has current news"))
    news_current <- 1
  }
  return(news_current)
}


#' assess codebase size
#'
#' @description Scores packages based on its codebase size, 
#' as determined by number of lines of code.
#'
#' @param pkg_source_path - source path for install local 
#'
#' @return - size_codebase - numeric value between \code{0} (for small codebase) and \code{1} (for large codebase)
#' @keywords internal
assess_size_codebase <- function(pkg_source_path) {
  
    # create character vector of function files
    files <- list.files(path = file.path(pkg_source_path, "R"), full.names = T)
    
    # define the function for counting code base
    count_lines <- function(x){
      # read the lines of code into a character vector
      code_base <- readLines(x)
      
      # count all the lines
      n_tot <- length(code_base)
      
      # count lines for roxygen headers starting with #
      n_head <- length(grep("^#+", code_base))
      
      # count the comment lines with leading spaces
      n_comment <- length(grep("^\\s+#+", code_base))
      
      # count the line breaks or only white space lines
      n_break <- length(grep("^\\s*$", code_base))
      
      # compute the line of code base
      n_tot - (n_head + n_comment + n_break)
    }
    
    # count number of lines for all functions
    nloc <- sapply(files, count_lines)
    
    # sum the number of lines
    size_codebase <- sum(nloc)
      
    return(size_codebase)
}

#' Assess vignettes
#'
#' @param pkg_name - name of the package 
#' @param pkg_source_path - source path for install local 
#' 
#' @return - has_vignettes - variable with score
#' @keywords internal
assess_vignettes <- function(pkg_name, pkg_source_path) {
  
  folder <- c(source = "/vignettes", bundle = "/inst/doc", binary = "/doc")
  files <- unlist(lapply(paste0(pkg_source_path, folder), list.files, full.names = TRUE))
  
  file_path = unique(tools::file_path_sans_ext(files))
  filename = basename(file_path)
  names(file_path) <- filename
  
  if (length(filename) == 0) {
    message(glue::glue("{pkg_name} has no vignettes"))
    has_vignettes <- 0
  } else {
    message(glue::glue("{pkg_name} has vignettes"))
    has_vignettes <- 1
  }
  
  return(has_vignettes)
}

#' Run all relevant documentation riskmetric checks
#'
#' @param pkg_name name of the package
#' @param pkg_ver version of the package
#' @param pkg_source_path path to package source code (untarred)
#'
#' @returns raw riskmetric outputs
#'@keywords internal
doc_riskmetric <- function(pkg_name, pkg_ver, pkg_source_path) {
  
  
  export_help <- assess_export_help(pkg_name, pkg_source_path)
  desc_elements <- assess_description_file_elements(pkg_name, pkg_source_path)
  
  if (fs::dir_exists(fs::path(pkg_source_path, "R"))) {
    size_codebase <- assess_size_codebase(pkg_source_path)
  } else {
    size_codebase <- 0
    message(glue::glue("{pkg_name} has no R folder to assess codebase size"))
  }
  has_vignettes <- assess_vignettes(pkg_name, pkg_source_path)
  has_examples <- assess_examples(pkg_name, pkg_source_path)
  has_news <- assess_news(pkg_name, pkg_source_path)
  news_current <- assess_news_current(pkg_name, pkg_ver, pkg_source_path)
  
  doc_scores <- list(
    export_help = export_help,
    has_bug_reports_url = desc_elements$has_bug_reports_url,
    has_source_control = desc_elements$has_source_control,
    has_maintainer = desc_elements$has_maintainer,
    has_website = desc_elements$has_website,
    size_codebase = size_codebase,
    has_vignettes = has_vignettes,
    has_examples = has_examples,
    has_news = has_news,
    news_current = news_current
  )
  
  return(doc_scores)
}


#' Assess Authors
#'
#' @param pkg_name - name of the package 
#' @param pkg_source_path - source path for install local 
#' 
#' @return - Authors related variable
#' @importFrom desc description desc_coerce_authors_at_r
#' @keywords internal
get_pkg_author <- function(pkg_name, pkg_source_path) {
  message(glue::glue("Checking for author in {pkg_name}"))
  
  # Path to the DESCRIPTION file
  pkg_desc_path <- file.path(pkg_source_path, "DESCRIPTION")
  
  # Load the DESCRIPTION file
  d <- description$new(file = pkg_desc_path)
  
  # Check if Authors@R exists, and if not, convert from Author and Maintainer
  if (!d$has_fields("Authors@R")) {
    if (d$has_fields("Author") || d$has_fields("Maintainer")) {
      desc_coerce_authors_at_r(file = pkg_desc_path)
    }
  }
  
    # check for package creator
    pkg_creator <- desc::desc_get_author(role = "cre",
                                         file = pkg_desc_path)
    
    if (length(pkg_creator) == 0) pkg_creator <-  NULL

    # check for package funder
    pkg_fnd <- desc::desc_get_author(role = "fnd",
                                     file = pkg_desc_path)
    if (length(pkg_fnd) == 0) pkg_fnd <- NULL

    # check for package authors
    pkg_author <- desc::desc_get_authors(file = pkg_desc_path)
    if (length(pkg_author) == 0) pkg_author <- NULL

    # Combine all elements into a list for return
    result <- list(
      maintainer = pkg_creator,
      funder = pkg_fnd,
      authors = pkg_author
    )

    return(result)
}

#' Assess License
#'
#' @param pkg_name - name of the package 
#' @param pkg_source_path - source path for install local 
#' 
#' @return - Authors related variable
#' @importFrom desc description 
#' @keywords internal
get_pkg_license <- function(pkg_name, pkg_source_path) {
  message(glue::glue("Checking for License in {pkg_name}"))
  
  # Path to the DESCRIPTION file
  pkg_desc_path <- file.path(pkg_source_path, "DESCRIPTION")
  # Load the DESCRIPTION file
  d <- description$new(file = pkg_desc_path)
  
  if (d$has_fields("License")) {
    License <- d$get_list("License")
  } else {
    License <- NULL
  }  

  return(License)
}

#' Clean and normalize license names
#'
#' Splits a license string on commas, plus signs, or pipes,
#' trims whitespace, removes trailing noise like "file LICENSE",
#' and normalizes each part to uppercase letters only.
#'
#' @param x A character string containing license information.
#'
#' @return A character vector of normalized license names.
#'
#' @keywords internal
clean_license <- function(x) {
  parts <- unlist(strsplit(x, "[,+|]"))
  base_license_names <- c()
  
  for (part in parts) {
    part <- trimws(part)
    part <- gsub("\\b(file\\s+)?license\\b.*", "", part, ignore.case = TRUE)
    # FIXED: do toupper AFTER keeping A-Za-z
    normalized <- toupper(gsub("[^A-Za-z]", "", part))
    if (nchar(normalized) > 0) {
      base_license_names <- c(base_license_names, normalized)
    }
  }
  
  return(base_license_names)
}


