#' Assess Rd files for examples (exported functions only)
#'
#' Scans the package Rd database at `pkg_source_path` and reports whether each
#' **exported function** has examples. Resolution supports shared topics via
#' roxygen `@rdname` (multiple functions documented on the same Rd page) and
#' multiple `\\alias{}` entries.
#'
#' @param pkg_name Character scalar; package name (must be loadable so exports can be read).
#' @param pkg_source_path Directory path where Rd files can be found by `tools::Rd_db()`.
#'
#' @return A list with:
#' \describe{
#'   \item{data}{A data.frame with columns `function_name`, `documentation_name`,
#'               `documentation_location`, and `example`.}
#'   \item{example_score}{Numeric; percentage of exported functions with examples.}
#' }
#' @examples
#' \dontrun{
#'   res <- assess_examples("stringr", "<path-to-stringr-source>")
#'   head(res$data)
#'   res$example_score
#' }
#' @keywords internal
assess_examples <- function(pkg_name, pkg_source_path) {
  # Load Rd database for the source path
  db <- tools::Rd_db(dir = pkg_source_path)
  
  # Remove only the package-level Rd file (pkgname-package.Rd)
  db <- db[!names(db) %in% paste0(pkg_name, "-package.Rd")]
  
  # Exported function names, resilient to the package not being loadable
  # (e.g. R CMD INSTALL failed on stricter R versions because the package
  # has no R/ folder). See `get_exported_function_names()`.
  exported_funs <- get_exported_function_names(pkg_name, pkg_source_path)
  
  if (length(exported_funs) == 0) {
    df <- data.frame(
      function_name = character(0),
      documentation_name = character(0),
      documentation_location = character(0),
      example = character(0),
      stringsAsFactors = FALSE
    )
    example_score <- 0
    message(sprintf("%s: no exported functions found; example score = %.2f%%",
                    pkg_name, example_score))
    return(list(data = df, example_score = example_score))
  }
  
  # Build Rd index once for performance and correctness
  idx <- build_rd_index(db)
  
  rows <- lapply(exported_funs, function(fun) {
    hit <- find_rd_for_fun(fun, db, idx)  # returns list(rd, filename) or NULL
    if (is.null(hit)) {
      return(data.frame(
        function_name = fun,
        documentation_name = "No documentation found",
        documentation_location = NA_character_,
        example = "no Rd file",
        stringsAsFactors = FALSE
      ))
    }
    
    ex_txt <- extract_examples_text(hit$rd)
    data.frame(
      function_name = fun,
      documentation_name = rd_name(hit$rd),
      documentation_location = file.path("man", hit$filename),
      example = if (is.null(ex_txt)) "no example" else ex_txt,
      stringsAsFactors = FALSE
    )
  })
  
  df <- do.call(rbind, rows)
  
  # Example score: % of exported functions that have examples
  has_example <- df$example != "no example" & df$example != "no Rd file"
  total <- nrow(df)
  example_score <- if (total > 0) round(sum(has_example) / total, 2) else 0
  
  
  
  message(sprintf("%s: %.2f%% of exported functions have examples", 
                  pkg_name, 
                  example_score * 100))
  return(list(data = df, 
              example_score = example_score))
}


#' Get all Rd sections by tag
#'
#' Recursively collects all nodes whose `Rd_tag` matches a given section
#' name, e.g., "alias", "examples", "example", "name".
#'
#' @param rd An Rd object (a nested list with "Rd_tag" attributes on nodes).
#' @param section Section name without leading backslash (e.g., "alias", "examples").
#' @return A list of Rd nodes matching the section (possibly empty).
#' @keywords internal
get_rd_sections <- function(rd, section) {
  target <- paste0("\\", section)
  out <- list()
  dfs <- function(node) {
    tag <- attr(node, "Rd_tag")
    if (!is.null(tag) && identical(tag, target)) {
      out[[length(out) + 1L]] <<- node
    }
    if (is.list(node)) {
      for (child in node) dfs(child)
    }
    NULL
  }
  dfs(rd)
  out
}

#' Get the first Rd section by tag
#'
#' Depth-first search returning the first node whose `Rd_tag` equals
#' `paste0("\\\\", section)`.
#'
#' @inheritParams get_rd_sections
#' @return The first matching Rd node or `NULL` if not found.
#' @keywords internal
get_rd_section <- function(rd, section) {
  target <- paste0("\\", section)
  dfs <- function(node) {
    tag <- attr(node, "Rd_tag")
    if (!is.null(tag) && identical(tag, target)) {
      return(node)
    }
    if (is.list(node)) {
      for (child in node) {
        found <- dfs(child)
        if (!is.null(found)) return(found)
      }
    }
    NULL
  }
  dfs(rd)
}

#' Flatten an Rd node to plain text
#'
#' Recursively flattens a node (or list of nodes) into a character string.
#'
#' @param node An Rd node or list of nodes.
#' @return Character scalar containing the concatenated text.
#' @keywords internal
rd_flatten_text <- function(node) {
  if (is.list(node)) {
    paste(vapply(node, rd_flatten_text, "", USE.NAMES = FALSE), collapse = "")
  } else {
    as.character(node)
  }
}

#' Extract all aliases from an Rd document
#'
#' Collects text from **all** `\\alias{}` nodes, trimming whitespace and
#' de-duplicating.
#'
#' @param rd An Rd object.
#' @return A character vector of aliases (possibly empty).
#' @keywords internal
rd_aliases <- function(rd) {
  alias_nodes <- get_rd_sections(rd, "alias")
  if (length(alias_nodes) == 0) return(character(0))
  vals <- trimws(vapply(alias_nodes, rd_flatten_text, "", USE.NAMES = FALSE))
  unique(vals[nzchar(vals)])
}

#' Extract the topic name from an Rd document
#'
#' Returns the `\\name{}` (roxygen `@rdname`) of the Rd document.
#'
#' @param rd An Rd object.
#' @return A length-1 character scalar (topic name) or `NA_character_` if missing.
#' @keywords internal
rd_name <- function(rd) {
  nm_node <- get_rd_section(rd, "name")
  if (is.null(nm_node)) return(NA_character_)
  trimws(rd_flatten_text(nm_node))
}

#' Build a fast lookup index for an Rd database
#'
#' Provides (1) an alias index, mapping `alias -> filename`, and
#' (2) a topic index, mapping `filename -> \\name` (topic).
#'
#' @param db An Rd database list as returned by `tools::Rd_db()`.
#' @return A list with elements `alias_index` (environment) and `topic_by_file` (named character vector).
#' @keywords internal
build_rd_index <- function(db) {
  alias_index <- new.env(parent = emptyenv())
  topic_by_file <- setNames(
    vapply(names(db), function(nm) rd_name(db[[nm]]), "", USE.NAMES = FALSE),
    names(db)
  )
  for (nm in names(db)) {
    als <- rd_aliases(db[[nm]])
    for (a in als) {
      if (nzchar(a) && is.null(alias_index[[a]])) {
        alias_index[[a]] <- nm
      }
    }
  }
  list(alias_index = alias_index, topic_by_file = topic_by_file)
}

#' Find an Rd document for a function using an index
#'
#' Tries `fun.Rd`, then alias-based resolution via the index, and as a last
#' resort matches the topic name if it equals the function name.
#'
#' @param fun Function name (character scalar).
#' @param db An Rd database list as returned by `tools::Rd_db()`.
#' @param idx Optional index from `build_rd_index()`. If `NULL`, it is built on demand.
#' @return `NULL` if not found, otherwise a list with `rd` (the Rd object) and `filename` (the Rd filename).
#' @keywords internal
find_rd_for_fun <- function(fun, db, idx = NULL) {
  if (is.null(idx)) idx <- build_rd_index(db)
  # 1) conventional filename
  direct <- paste0(fun, ".Rd")
  if (!is.null(db[[direct]])) {
    return(list(rd = db[[direct]], filename = direct))
  }
  # 2) alias-based via index
  nm <- idx$alias_index[[fun]]
  if (!is.null(nm)) {
    return(list(rd = db[[nm]], filename = nm))
  }
  # 3) topic name equals function name (rare fallback)
  topic_match <- names(idx$topic_by_file)[idx$topic_by_file == fun]
  if (length(topic_match) > 0) {
    nm <- topic_match[[1]]
    return(list(rd = db[[nm]], filename = nm))
  }
  NULL
}


#' Flatten example nodes to a text block
#'
#' Recursively collects example text from nodes that carry R code or text,
#' unwrapping containers such as `\\dontrun{}`, `\\donttest{}`, and `\\dontshow{}`.
#'
#' @param node An Rd node.
#' @return Character scalar containing example text or `""` if none.
#' @keywords internal
rd_examples_to_text <- function(node) {
  tag <- attr(node, "Rd_tag")
  if (is.list(node)) {
    paste(vapply(node, rd_examples_to_text, "", USE.NAMES = FALSE), collapse = "")
  } else {
    # Keep code + text comments in examples. If you only want code, drop "TEXT".
    if (!is.null(tag) && tag %in% c("RCODE", "VERB", "TEXT")) {
      as.character(node)
    } else {
      ""
    }
  }
}

#' Extract examples text from an Rd document
#'
#' Supports both `\\examples{}` and `\\example{}` sections. If multiple
#' sections exist, their contents are concatenated with blank lines.
#'
#' @param rd_doc An Rd document.
#' @return Character scalar of combined examples text, or `NULL` if none/non‑informative.
#' @keywords internal
extract_examples_text <- function(rd_doc) {
  nodes <- c(get_rd_sections(rd_doc, "examples"),
             get_rd_sections(rd_doc, "example"))
  if (length(nodes) == 0) return(NULL)
  chunks <- vapply(nodes, rd_examples_to_text, "", USE.NAMES = FALSE)
  txt <- paste(chunks[nzchar(chunks)], collapse = "\n\n")
  # Trim outer whitespace
  txt <- gsub("^[ \t\r\n]+|[ \t\r\n]+$", "", txt)
  if (nzchar(txt)) txt else NULL
}


#' Assess documentation coverage for exported functions
#'
#' Scans the package Rd database at `pkg_source_path` and resolves exported
#' functions to their Rd pages to determine whether documentation exists.
#' Resolution supports shared topics and multiple `\\alias{}` entries, and the
#' returned data includes only `function_name`, `documentation_name`, and
#' `documentation_location`, together with a score representing the fraction of
#' exported functions that have any Rd documentation.
#'
#' @param pkg_name Character scalar; package name (must be loadable).
#' @param pkg_source_path Directory path where Rd files can be found by `tools::Rd_db()`.
#'
#' @return A list with:
#' \describe{
#'   \item{data}{A `data.frame` with columns `function_name`,
#'     `documentation_name`, and `documentation_location`.}
#'   \item{has_docs_score}{Numeric in \[0, 1\]; fraction of exported functions
#'     that have an Rd page.}
#' }
#'
#' @keywords internal
assess_exported_functions_docs <- function(pkg_name, pkg_source_path) {
  
  # Load Rd database for the source path
  db <- tools::Rd_db(dir = pkg_source_path)
  
  # Remove only the package-level Rd file (pkgname-package.Rd).
  # Keep files like "<pkg_name>.Rd" as they may document a function with the same name.
  db <- db[!names(db) %in% paste0(pkg_name, "-package.Rd")]
  
  # Exported function names, resilient to the package not being loadable
  # (e.g. R CMD INSTALL failed on stricter R versions because the package
  # has no R/ folder). See `get_exported_function_names()`.
  exported_funs <- get_exported_function_names(pkg_name, pkg_source_path)
  
  # --- Handle packages with NO exported functions ---------------------------
  if (length(exported_funs) == 0) {
    df <- data.frame(
      function_name          = character(0),
      documentation_name     = character(0),
      documentation_location = character(0),
      stringsAsFactors = FALSE
    )
    doc_score <- 0
    message(sprintf("%s: no exported functions found; documentation score = %.2f%%",
                    pkg_name, doc_score))
    return(list(data = df, has_docs_score = doc_score))
  }
  
  # Build Rd index once (reuses helpers from assess_examples)
  idx <- build_rd_index(db)
  
  # Resolve each exported function to its Rd page
  rows <- lapply(exported_funs, function(fun) {
    
    hit <- find_rd_for_fun(fun, db, idx)  # -> list(rd, filename) or NULL
    if (is.null(hit)) {
      return(data.frame(
        function_name          = fun,
        documentation_name     = "No documentation found",
        documentation_location = NA_character_,
        stringsAsFactors = FALSE
      ))
    }
    
    topic <- rd_name(hit$rd)
    if (is.na(topic) || !nzchar(topic)) topic <- fun
    
    data.frame(
      function_name          = fun,
      documentation_name     = topic,
      documentation_location = file.path("man", hit$filename),
      stringsAsFactors = FALSE
    )
  })
  
  df <- do.call(rbind, rows)
  
  # Documentation score: % of exported functions that have any Rd doc
  has_doc <- !is.na(df$documentation_location) &
    df$documentation_name != "No documentation found"
  total <- nrow(df)
  doc_score <- if (total > 0) round(sum(has_doc) / total, 2) else 0
  
  message(sprintf("%s: %.2f%% of exported functions have documentation",
                  pkg_name, doc_score * 100))
  
  return(list(data = df, has_docs_score = doc_score))
}

#' Assess exported functions to namespace
#'
#' @description Returns 1L if the package's NAMESPACE declares any exports
#'   (`export`, `exportClasses`, `exportMethods`, 
#'   `exportPattern` or `exportClassPatterns`), 0L
#'   otherwise.
#'
#' @param data pkg source path
#' @return integer scalar: 1L if any exports are declared, 0L otherwise.
#' @keywords internal
assess_exports <- function(data) {
  
  ns_file <- file.path(data, "NAMESPACE")
  if (!file.exists(ns_file)) return(0L)
  ns_lines <- readLines(ns_file, warn = FALSE)
  has_export <- any(grepl(
    "^\\s*(export|exportClasses|exportMethods|exportPattern|exportClassPattern)\\s*\\(",
    ns_lines
  ))
  if (has_export) { 
    export_calc <- 1L} 
  else { 
    export_calc <-0L
  }
  
  return(export_calc)
} 

#' Parse exported names from a package's NAMESPACE on disk.
#'
#' Used as a fallback when the package is not loaded as a namespace
#' (for example when `R CMD INSTALL` failed because the package has
#' no R/ folder on stricter R versions).
#'
#' @param pkg_source_path Path to the unpacked package source.
#' @return Character vector of exported names (possibly empty).
#' @keywords internal
get_exports_from_source <- function(pkg_source_path) {
  if (is.null(pkg_source_path) || !nzchar(pkg_source_path) ||
      !dir.exists(pkg_source_path)) {
    return(character(0))
  }
  ns_file <- file.path(pkg_source_path, "NAMESPACE")
  if (!file.exists(ns_file)) return(character(0))
  parsed <- tryCatch(
    parseNamespaceFile(basename(pkg_source_path),
                       dirname(pkg_source_path),
                       mustExist = FALSE),
    error = function(e) NULL
  )
  if (is.null(parsed)) return(character(0))
  # Expand any export patterns against Rd file names in man/
  pattern_exports <- character(0)
  if (length(parsed$exportPatterns) > 0) {
    rd_dir <- file.path(pkg_source_path, "man")
    if (dir.exists(rd_dir)) {
      rd_names <- tools::file_path_sans_ext(
        list.files(rd_dir, pattern = "\\.Rd$")
      )
      pattern_exports <- unlist(lapply(parsed$exportPatterns, function(p) {
        grep(p, rd_names, value = TRUE)
      }))
    }
  }
  unique(c(parsed$exports, pattern_exports))
}

#' Get exported function names with a NAMESPACE-source fallback.
#'
#' Attempts to obtain exported function names from the installed
#' namespace. If the namespace is not available - for example when
#' `R CMD INSTALL` failed because the package has no `R/` folder on
#' stricter R versions - falls back to parsing `NAMESPACE` from
#' `pkg_source_path` via [get_exports_from_source()]. In the fallback
#' path the result includes every declared export, because
#' function-ness cannot be verified without a loaded namespace.
#'
#' @param pkg_name Character scalar; package name.
#' @param pkg_source_path Path to the unpacked package source.
#' @return Character vector of exported names (possibly empty).
#' @keywords internal
get_exported_function_names <- function(pkg_name, pkg_source_path) {
  ns <- tryCatch(asNamespace(pkg_name), error = function(e) NULL)
  if (is.null(ns)) {
    return(get_exports_from_source(pkg_source_path))
  }
  exported <- getNamespaceExports(ns)
  is_fun <- function(name) {
    obj <- try(getExportedValue(ns, name), silent = TRUE)
    is.function(obj)
  }
  Filter(is_fun, exported)
}


#' assess_export_help
#'
#' @param pkg_name - name of the package 
#' @param pkg_source_path - pkg_source_path - source path for install local
#'
#' @return - export_help - variable with score
#' @keywords internal
assess_export_help <- function(pkg_name, pkg_source_path) {
  
  # Prefer the installed namespace, but fall back to parsing NAMESPACE
  # from source so packages that fail to install (e.g. no R/ folder on
  # stricter R versions) still produce a score instead of erroring.
  exported_functions <- tryCatch(
    getNamespaceExports(pkg_name),
    error = function(e) {
      get_exports_from_source(pkg_source_path)
    }
  )
  
  if (length(exported_functions) > 0) {
    
    # Use get_func_descriptions to retrieve documentation
    func_descriptions <- get_func_descriptions(pkg_name)
    
    documented_names <- names(func_descriptions)
    missing_docs <- setdiff(exported_functions, documented_names)
    
    if (length(missing_docs) == 0) {
      message(glue::glue("All exported functions have corresponding help files in {pkg_name}"))
      export_help <- 1
    } else {
      message(glue::glue("Some exported functions are missing help files in {pkg_name}"))
      # message(glue::glue("The following exported functions are missing help files in {pkg_name}"))
      # print(missing_docs) # Uncomment if needed
      export_help <- 0
    }
  } else {
    message(glue::glue("No exported functions in {pkg_name}"))
    export_help <- 0
  }
  
  return(export_help)
}


#' Combine example/docs scores into a single metric (sum).
#'
#' @param example_score Numeric (scalar or vector) in [0, 1] or NA.
#' @param has_docs_score Numeric (scalar or vector) in [0, 1] or NA.
#' @return Numeric vector: example_score + has_docs_score in [0, 2],
#'   with NA where both inputs are NA at that position.
#' @keywords internal
create_has_ex_docs_score <- function(example_score, has_docs_score) {
  
  vals <- c(example_score, has_docs_score)
  if (all(is.na(vals))) {
    has_ex_docs_score <- NA_real_
  } else {
    has_ex_docs_score <- mean(vals, na.rm = TRUE)  
  }
  
  return(has_ex_docs_score)
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
  
  # Check for source control URL
  # Pattern covers widely-used and historically significant R package hosting platforms:
  #   - GitHub (including GitHub Pages)
  #   - GitLab (including self-hosted public instances, e.g. gitlab.opencode.de)
  #   - Bitbucket
  #   - R-Forge (https://r-forge.r-project.org/) — historically major R host
  #   - Codeberg (https://codeberg.org/) — growing FOSS alternative
  #   - SourceForge (https://sourceforge.net/) — legacy host, still used by some packages
  #   - Sourcehut (https://sr.ht/) — lightweight forge, used by some R authors
  #   - Bioconductor
  #   - Academic / institutional domains (.ac.uk, .edu.au)
  patterns <- paste(
    "github\\.com",
    "pages\\.github\\.io",
    "github\\.io",
    "gitlab\\.com",
    "gitlab\\.",          # self-hosted GitLab instances (e.g. gitlab.opencode.de)
    "bitbucket\\.org",
    "r-forge\\.r-project\\.org",
    "codeberg\\.org",
    "sourceforge\\.net",
    "sr\\.ht",
    "bioconductor\\.org",
    "\\.ac\\.uk",
    "\\.edu\\.au",
    sep = "|"
  )
  
  # First check URL field
  url_to_check <- desc_elements$URL
  url_matches <- character(0)
  
  if (!is.null(url_to_check) && !is.na(url_to_check)) {
    url_matches <- grep(patterns, url_to_check, value = TRUE)
  }
  
  # If URL field doesn't match, check BugReports as fallback
  if (length(url_matches) == 0 && !is.null(desc_elements$BugReports) && !is.na(desc_elements$BugReports)) {
    bugreports_matches <- grep(patterns, desc_elements$BugReports, value = TRUE)
    if (length(bugreports_matches) > 0) {
      url_matches <- bugreports_matches
      message(glue::glue("{pkg_name} source control detected via BugReports URL"))
    }
  }
  
  if (length(url_matches) == 0) {
    message(glue::glue("{pkg_name} does not have a source control"))
    has_source_control <- NULL
  } else {
    message(glue::glue("{pkg_name} has a source control"))
    has_source_control <- url_matches
  }
  
  desc_elements_scores <- list(
    has_bug_reports_url = has_bug_reports_url,
    has_maintainer = has_maintainer,
    has_website = has_website,
    has_source_control = has_source_control
  )
  
  return(desc_elements_scores)
}

#' Paths to NEWS files for a package source tree
#'
#' Searches the same locations and basenames that \code{utils::news} uses for
#' an installed package (via \code{tools:::.build_news_db}): \code{NEWS.Rd},
#' \code{NEWS.md}, and extensionless \code{NEWS}. For a source checkout,
#' those files are collected from the package root, \code{doc/},
#' \code{vignettes/}, and under \code{inst/} (recursively, including
#' \code{inst/NEWS} as in \code{tools::news2Rd}).
#'
#' @param pkg_source_path Source path of the package.
#'
#' @return Character vector of absolute file paths (possibly empty).
#' @keywords internal
find_news_files <- function(pkg_source_path) {
  if (!dir.exists(pkg_source_path)) {
    return(character(0))
  }
  # Same three files as tools:::.build_news_db() for library/<pkg>/
  news_basenames <- c("NEWS.Rd", "NEWS.md", "NEWS")
  pick_news <- function(paths) {
    paths[basename(paths) %in% news_basenames]
  }
  out <- character(0)
  # Package root (non-recursive)
  out <- c(out, pick_news(list.files(
    pkg_source_path,
    full.names = TRUE,
    include.dirs = FALSE
  )))
  # doc/ and vignettes/ (non-recursive)
  for (sub in c("doc", "vignettes")) {
    d <- file.path(pkg_source_path, sub)
    if (dir.exists(d)) {
      out <- c(out, pick_news(list.files(
        d,
        full.names = TRUE,
        include.dirs = FALSE
      )))
    }
  }
  # inst/ and all subfolders (recursive)
  inst <- file.path(pkg_source_path, "inst")
  if (dir.exists(inst)) {
    out <- c(out, pick_news(list.files(
      inst,
      full.names = TRUE,
      recursive = TRUE,
      include.dirs = FALSE
    )))
  }
  out <- unique(out[file.exists(out)])
  if (length(out) == 0L) {
    return(character(0))
  }
  out <- normalizePath(out, winslash = "/", mustWork = TRUE)
  return(out)
}

#' Assess Rd files for news
#'
#' @param pkg_name - name of the package 
#' @param pkg_source_path - source path for install local
#'
#' @return has_news - variable with score
#' @keywords internal
assess_news <- function(pkg_name, pkg_source_path) {
  
  news <- find_news_files(pkg_source_path)
  
  if (length(news) > 0) {
    message(glue::glue("{pkg_name} has news"))
    has_news <- 1
  } else {
    message(glue::glue("{pkg_name} has no news"))
    has_news <- 0
  }
  return(has_news)
}

#' Escape a string for use as a literal inside a Perl regex
#' @keywords internal
#' @noRd
escape_regex <- function(x) {
  gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", x, perl = TRUE)
}

#' Whether NEWS lines document the exact package version
#'
#' Uses anchored patterns where appropriate and, for free-text \code{name ver}
#' matches, a suffix guard \code{(?![0-9.])} so \code{1.2} does not match
#' \code{1.2.3}. Matches \code{utils:::.news_reader_default} conventions:
#' markdown title lines, \verb{Changes in version}, and \code{pkg ver} spans.
#'
#' @keywords internal
#' @noRd
news_lines_have_pkg_version <- function(pkg_name, pkg_ver, lines) {
  e_pkg <- escape_regex(pkg_name)
  e_ver <- escape_regex(pkg_ver)
  # After the version token, do not allow a longer numeric version to continue
  ver_suffix <- "(?![0-9.])"
  any(
    grepl(
      paste0("^#\\s*", e_pkg, "\\s+", e_ver, ver_suffix),
      lines,
      perl = TRUE
    ),
    grepl(
      paste0("^Changes in version\\s+", e_ver, ver_suffix),
      lines,
      perl = TRUE,
      ignore.case = TRUE
    ),
    grepl(
      paste0("\\b", e_pkg, "\\s+", e_ver, ver_suffix),
      lines,
      perl = TRUE
    )
  )
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
  
  # Find candidate NEWS files across supported locations
  news_paths <- find_news_files(pkg_source_path)
  
  if (length(news_paths) == 0) {
    
    version_found <- FALSE
  } else {
    news_content <- unlist(
      lapply(news_paths, function(p) readLines(p, warn = FALSE)),
      use.names = FALSE
    )
    version_found <- news_lines_have_pkg_version(pkg_name, 
                                                 pkg_ver, 
                                                 news_content)
  }
  
  if (!version_found) {
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
  
  # Check that package has an R folder
  scb_possible <- contains_r_folder(pkg_source_path) 
  # 
  if (!scb_possible) { 
    size_codebase <- 0
  } else {
    
    # create character vector of function files
    # (now recursively scans all subdirectories under R/)
    files <- list.files(
      path = file.path(pkg_source_path, "R"),
      full.names = TRUE,
      recursive = TRUE,
      include.dirs = FALSE
    )
    
    # define the function for counting code base
    count_lines <- function(x){
      # read the lines of code into a character vector
      code_base <- readLines(x, warn = FALSE)
      
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
    if (length(files) == 0) {
      nloc <- integer(0)
    } else {
      nloc <- sapply(files, count_lines)
    }
    
    
    # sum the number of lines
    size_codebase <- sum(nloc)
  }
  
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
  has_docs <- assess_exported_functions_docs(pkg_name, pkg_source_path)
  has_ex_docs_score <- create_has_ex_docs_score(has_examples$example_score, 
                                                has_docs$has_docs_score)
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
    has_docs = has_docs,
    has_ex_docs_score = has_ex_docs_score, 
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
  # Handle NA, NULL, or non-character inputs
  if (is.null(x) || (length(x) == 1 && is.na(x))) {
    return(NULL)
  }
  
  # Convert to character if needed
  if (!is.character(x)) {
    x <- as.character(x)
  }
  
  # Handle empty strings
  if (length(x) == 0 || nchar(x) == 0) {
    return(NULL)
  }
  
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
  
  # Return NULL for empty result to match existing test expectations
  if (length(base_license_names) == 0) {
    return(NULL)
  }
  
  return(base_license_names)
}
