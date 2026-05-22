#' @keywords internal
#' @noRd
normalize_codecov <- function(u) {
  if (is.na(u) || !nzchar(u)) return(u)
  sub("/graph/badge\\.svg(\\?.*)?$", "/badge.svg\\1", u, perl = TRUE)
}

#' @keywords internal
#' @noRd
parse_doc_safe <- function(txt) {
  doc <- tryCatch(xml2::read_html(txt), error = function(e) NULL)
  if (!is.null(doc)) {
    return(doc)
  }
  tryCatch(xml2::read_xml(txt), error = function(e) NULL)
}

#' @keywords internal
#' @noRd
fetch_badge_value <- function(url, timeout_secs = 5, ua = "risk.assessr") {
  if (is.na(url) || !nzchar(url)) {
    return(NULL)
  }
  url <- normalize_codecov(url)
  if (!grepl("\\.svg($|\\?)", url, ignore.case = TRUE)) {
    return(NULL)
  }
  h <- curl::new_handle(
    connecttimeout = timeout_secs,
    timeout = timeout_secs,
    followlocation = TRUE,
    useragent = ua
  )
  tryCatch({
    res <- curl::curl_fetch_memory(url, handle=h)
    if (res$status_code != 200) {
      stop("Error while fetching badge url:", url, ". Error:", res$status_code)
    }
    doc <- rawToChar(res$content) |>
       parse_doc_safe()
    
    if (is.null(doc)) {
      return(NULL)
    }
    vals <- doc |>
      xml2::xml_find_all(".//text") |>
      xml2::xml_text() |>
      trimws()
    
    if (length(vals)>0) {
      return(list(name = vals[1], value=rev(vals)[1]))
    }
    ttl <- doc |>
      xml2::xml_find_first(".//title") |>
      xml2::xml_text() |>
      trimws()
    
    if (nzchar(ttl)) {
      return(ttl)
    }
    NULL
  }, 
  error = function(e) NULL
  )
}


#' List badges image URLs from a local README
#'
#' Scans a local README (Markdown) and returns badge image URLs.
#'
#' @param path Character scalar; path to a local README file (e.g., "README.md").
#' @return data.frame with badge info
#'
#' @examples
#' \dontrun{
#' tmp <- tempfile(fileext = ".md")
#' writeLines(c(
#'   "# MyPkg",
#'   "![build](build-status.svg)",
#'   "![cov](coverage.svg)"
#' ), tmp)
#' out <- list_badges(tmp)
#' print(out)
#' }
#' @export
list_badges <- function(path) {
  links <- c()
  stopifnot(is.character(path), length(path) == 1L, !is.na(path))
  if (!file.exists(path)) {
    stop("File not found: ", path, call. = FALSE)
  }

  # Single robust read: if it fails, warn and move on (no second pass)
  txt <- tryCatch(
    path |>
     readLines(warn = FALSE, encoding = "UTF-8") |>
      paste(collapse = "\n"),
    error = function(e) {
      warning(sprintf("Failed to read '%s': %s", path, conditionMessage(e)))
      NULL
  })
  if (is.null(txt)) {
    return(links)
  } 
  txt <- enc2utf8(txt)
  
  # Linked badges: [![...](IMG)](LINK)
  pat_linked <- "\\[!\\[[^\\]]*\\]\\(([^)]+)\\)\\]\\(([^)]+)\\)"
  mA     <- gregexpr(pat_linked, txt, perl = TRUE)
  hitsA  <- if (mA[[1]][1] != -1L) regmatches(txt, mA)[[1]] else character(0)
  if (length(hitsA)) {
    links <- c(
      links, 
      vapply(hitsA, function(x) sub(pat_linked, "\\1", x, perl = TRUE), character(1L))
      )
  }
  
  # Standalone badges: ![...](IMG)
  pat_img <- "!\\[[^\\]]*\\]\\(([^)]+)\\)"
  mB <- gregexpr(pat_img, txt, perl = TRUE)
  spansB <- mB[[1]]
  hitsB_full <- if (length(spansB) == 1L && spansB[1] == -1L) character(0) else regmatches(txt, list(spansB))[[1]]
  
  # Remove B hits that sit inside any A hit (avoid dupes)
  spansA <- gregexpr(pat_linked, txt, perl = TRUE)[[1]]
  lenA   <- attr(spansA, "match.length")
  inA <- function(start, length) {
    if (is.null(lenA) || (length(spansA) == 1L && spansA[1] == -1L)) return(FALSE)
    any(start >= spansA & (start + length - 1L) <= (spansA + lenA - 1L))
  }
  lenB <- attr(spansB, "match.length")
  keepB <- if (length(hitsB_full)) which(!mapply(inA, spansB, lenB)) else integer(0)
  hitsB <- if (length(keepB)) hitsB_full[keepB] else character(0)
  
  if (length(hitsB) >0) {
    links <- c(
      links, 
      vapply(hitsB, function(x) sub(pat_img, "\\1", x, perl = TRUE), character(1L))
    )
  }
  
  links |>
    unique() |>
    lapply(\(x) fetch_badge_value(x)) |>
    Filter(f = Negate(is.null)) |>
    as.data.frame()
  
}
