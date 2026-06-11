skip_if_repo_unavailable <- function(repo = getOption("repos")[["CRAN"]],
                                     timeout = 5) {
  testthat::skip_on_cran()
  
  if (is.null(repo) || length(repo) != 1L || is.na(repo) ||
      !nzchar(repo) || identical(repo, "@CRAN@")) {
    testthat::skip("No CRAN repo configured.")
  }
  
  repo <- sub("/+$", "", repo)
  
  url <- paste0(repo, "/src/contrib/PACKAGES.gz")
  
  ok <- withr::with_options(list(timeout = timeout), {
    tryCatch(
      {
        if (requireNamespace("curl", quietly = TRUE)) {
          h <- curl::new_handle(nobody = TRUE)
          curl::handle_setopt(h, timeout = timeout)
          
          curl::curl_fetch_memory(url, handle = h)
          TRUE
        } else {
          con <- base::url(url, open = "rb")
          on.exit(base::close(con), add = TRUE)
          
          base::readBin(con, what = "raw", n = 1L)
          TRUE
        }
      },
      error = function(e) FALSE,
      warning = function(w) FALSE
    )
  })
  
  if (!isTRUE(ok)) {
    testthat::skip(paste0("Repository unavailable: ", repo))
  }
  
  invisible(TRUE)
}

# Skip a test when a required test-data fixture is not available.
# system.file() returns "" when the file is absent (e.g. large tarballs that
# are not shipped with the installed package on CRAN check machines), which
# otherwise causes downstream set_up_pkg()/install_package_local() calls to
# error. Guarding here keeps such tests CRAN-safe.
skip_if_test_data_missing <- function(path) {
  if (length(path) != 1L || is.na(path) || !nzchar(path) ||
      !file.exists(path)) {
    testthat::skip(
      paste0("test-data fixture not available: ",
             if (length(path) == 1L && !is.na(path) && nzchar(path)) {
               path
             } else {
               "<missing>"
             })
    )
  }
  invisible(TRUE)
}
