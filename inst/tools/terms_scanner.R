trim_ws <- function(x, width = 160) {
  x <- gsub("^[[:space:]]+|[[:space:]]+$", "", x, perl = TRUE)
  if (nchar(x) > width) paste0(substr(x, 1, width - 3), "...") else x
}

build_patterns <- function() {
  list(
    list(label = "sanofi_term", regex = "sanofi"),
    list(
      label = "sanofi_email",
      regex = "(?i)\\b[\\w._%+-]+@sanofi\\.(?:com|net|org)\\b"
    ),
    list(
      label = "api_key_like",
      regex = "(?i)\\b(api[_ -]?key|secret|token|password|passwd|pwd|client[_ -]?secret)\\b\\s*[:=]\\s*(['\"][^'\"]+['\"]|[A-Za-z0-9_./+=-]{8,})"
    ),
    list(label = "aws_access_key_id", regex = "\\bAKIA[0-9A-Z]{16}\\b"),
    list(
      label = "aws_secret_key",
      regex = "(?i)aws[^\\n]{0,30}secret[^\\n]{0,30}key\\s*[:=]\\s*[A-Za-z0-9/+=]{40}"
    ),
    list(label = "github_token", regex = "\\bgh[oprsu]_[A-Za-z0-9]{36,}\\b"),
    list(
      label = "pem_private_key_block",
      regex = "-----BEGIN (?:RSA |EC |)PRIVATE KEY-----"
    )
  )
}

read_file_safely <- function(path, n_max_lines = Inf) {
  out <- tryCatch(
    readLines(path, warn = FALSE, encoding = "UTF-8"),
    error = function(e) character()
  )
  if (!length(out))
    out <- tryCatch(
      readLines(path, warn = FALSE),
      error = function(e) character()
    )
  if (is.finite(n_max_lines)) out <- out[seq_len(min(length(out), n_max_lines))]
  out
}

scan_file <- function(file, patterns) {
  lines <- read_file_safely(file)
  res <- list()
  if (!length(lines)) {
    return(res)
  }
  for (p in patterns) {
    m <- grepl(p$regex, lines, perl = TRUE, ignore.case = TRUE)
    if (any(m)) {
      idx <- which(m)
      for (i in idx) {
        mobj <- regexpr(p$regex, lines[i], perl = TRUE)
        snippet <- if (mobj[1] > 0)
          substr(
            lines[i],
            mobj[1],
            mobj[1] + attr(mobj, "match.length")[1] - 1
          ) else lines[i]
        res[[length(res) + 1]] <- list(
          file = file,
          line = i,
          type = p$label,
          snippet = trim_ws(snippet, 160),
          line_text = trim_ws(lines[i], 300)
        )
      }
    }
  }
  if (length(res) == 0) {
    return(data.frame(
      file = character(),
      line = integer(),
      type = character(),
      snippet = character(),
      line_text = character(),
      stringsAsFactors = FALSE
    ))
  }
  do.call("rbind", res) |>
    as.data.frame()
}


code_scanner <- function() {
  folders <- c("inst", "R", "vignettes", "tests", ".github")
  message("Start scan")
  message("Directories: ", paste(folders, collapse = ", "))

  files <- list.files(folders, full.names = TRUE, recursive = TRUE)
  message("Found ", length(files), " files to scan")

  if (!length(files)) {
    message("No files to scan")
    return(NULL)
  }

  patterns <- build_patterns()
  results <- files |>
    lapply(function(x) {
      data <- scan_file(x, patterns)
      message("Found ", nrow(data), " terms in ", x)
      data
    })
  df <- do.call("rbind", results)
  df[] <- lapply(df, as.character)
  write.csv(df, "scan-results.csv")
  message("Report created ", file.path(getwd(), "scan-results.csv"))
}

code_scanner()
