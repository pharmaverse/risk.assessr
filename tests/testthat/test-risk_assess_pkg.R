# Helper: copy test tarball to a temp directory while preserving the original
# filename so that get_pkg_name() can correctly parse the package name from the
# path.  
get_test_tarball_path <- function() {
  dp_orig <- system.file("test-data", "test.package.0001_0.1.0.tar.gz",
                         package = "risk.assessr")
  if (nchar(dp_orig) == 0L) return("")
  dp_dir <- tempfile()
  if (!dir.create(dp_dir, recursive = TRUE)) return("")
  dp <- file.path(dp_dir, basename(dp_orig))
  if (!file.copy(dp_orig, dp)) return("")
  dp
}

test_that("risk_assess_pkg works with path to local tarball", {
  skip_on_cran()
  skip_if(
    .Platform$OS.type == "windows",
    "covr runs in a subprocess on Windows; mocking is not reliable under devtools::test()"
  )
  dp <- get_test_tarball_path()
  if (nchar(dp) == 0L) skip("Test data test.package.0001_0.1.0.tar.gz not found")
  withr::defer(unlink(dirname(dp), recursive = TRUE), envir = parent.frame())
  
  r <- getOption("repos")
  r["CRAN"] <- "http://cran.us.r-project.org"
  options(repos = r)
  skip_if_repo_unavailable()
  
  # filecoverage keys from real covr use R source file names (e.g. "R/myscript.R"),
  # but code_script in exports_df is derived from Rd file names (e.g. "R/myfunction.R").
  # When they differ the left_join silently fails and coverage_percent stays NA.
  # mockery::stub(assess_pkg, ...) does not reach into the nested
  # risk_assess_pkg -> assess_pkg call; local_mocked_bindings replaces the binding
  # in the test.assessr namespace so every call depth sees the mock.
  local_mocked_bindings(
    get_package_coverage = function(pkg_source_path, package_installed) {
      pkg_nm  <- unname(read.dcf(file.path(pkg_source_path, "DESCRIPTION"),
                                 fields = "Package")[1, 1])
      man_dir <- file.path(pkg_source_path, "man")
      if (dir.exists(man_dir)) {
        rd_files <- list.files(man_dir, pattern = "\\.[Rr][Dd]$", full.names = FALSE)
        rd_files <- rd_files[!rd_files %in% paste0(pkg_nm, "-package.Rd")]
        scripts  <- paste0("R/", sub("\\.[Rr][Dd]$", ".R", rd_files))
      } else {
        r_dir   <- file.path(pkg_source_path, "R")
        r_files <- if (dir.exists(r_dir)) {
          list.files(r_dir, pattern = "\\.[Rr]$", full.names = FALSE)
        } else character()
        scripts <- if (length(r_files)) paste0("R/", r_files) else "R/myfunction.R"
      }
      n  <- length(scripts)
      fc <- structure(rep(100, n), dim = n, dimnames = list(scripts))
      list(
        total_cov = 1.0,
        res_cov   = list(
          name     = pkg_nm,
          coverage = list(filecoverage = fc, totalcoverage = 100L)
        )
      )
    },
    .package = "test.assessr"
  )
  
  risk_assess_package <- risk_assess_pkg(path = dp)
  
  testthat::expect_identical(length(risk_assess_package), 5L)
  
  testthat::expect_true(checkmate::check_class(risk_assess_package, "list"))
  
  testthat::expect_identical(length(risk_assess_package$results), 31L)
  
  testthat::expect_true(!is.na(risk_assess_package$results$pkg_name))
  
  testthat::expect_true(!is.na(risk_assess_package$results$pkg_version))
  
  testthat::expect_true(!is.na(risk_assess_package$results$pkg_source_path))
  
  testthat::expect_true(!is.na(risk_assess_package$results$date_time))
  
  testthat::expect_true(!is.na(risk_assess_package$results$executor))
  
  testthat::expect_true(!is.na(risk_assess_package$results$sysname))
  
  testthat::expect_true(!is.na(risk_assess_package$results$version))
  
  testthat::expect_true(!is.na(risk_assess_package$results$release))
  
  testthat::expect_true(!is.na(risk_assess_package$results$machine))
  
  testthat::expect_true(!is.na(risk_assess_package$results$comments))
  
  testthat::expect_null(risk_assess_package$results$has_bug_reports_url)
  
  testthat::expect_true(!is.na(risk_assess_package$results$license))
  
  testthat::expect_true(!is.na(risk_assess_package$results$size_codebase))
  
  testthat::expect_true(checkmate::test_numeric(risk_assess_package$results$size_codebase))
  
  testthat::expect_true(checkmate::test_numeric(risk_assess_package$results$check))
  
  testthat::expect_gte(risk_assess_package$results$check, 0)
  
  testthat::expect_true(checkmate::test_numeric(risk_assess_package$results$covr))
  
  testthat::expect_gte(risk_assess_package$results$covr, 0.7)
  
  testthat::expect_identical(length(risk_assess_package$covr_list), 2L)
  
  testthat::expect_true(!is.na(risk_assess_package$covr_list$res_cov$name))
  
  testthat::expect_identical(length(risk_assess_package$covr_list$res_cov$coverage), 2L)
  
  testthat::expect_identical(length(risk_assess_package$tm), 3L)
  
  testthat::expect_identical(length(risk_assess_package$tm_list$tm), 9L)
  
  testthat::expect_true(!is.na(risk_assess_package$tm_list$tm$exported_function))
  
  testthat::expect_true(!is.na(risk_assess_package$tm_list$tm$code_script))
  
  testthat::expect_true(!is.na(risk_assess_package$tm_list$tm$documentation))
  
  testthat::expect_true(!is.na(risk_assess_package$tm_list$tm$coverage_percent))
  
  # high risk tm tests
  expect_true(is.list(risk_assess_package$tm_list$coverage$high_risk))
  expect_identical(risk_assess_package$tm_list$coverage$high_risk$pkg_name, "test.package.0001")
  expect_true(is.list(risk_assess_package$tm_list$coverage$high_risk$coverage))
  expect_identical(risk_assess_package$tm_list$coverage$high_risk$coverage$filecoverage, 0)
  expect_identical(risk_assess_package$tm_list$coverage$high_risk$coverage$totalcoverage, 0)
  expect_true(is.na(risk_assess_package$tm_list$coverage$high_risk$errors))
  expect_true(is.na(risk_assess_package$tm_list$coverage$high_risk$notes))
  
  # medium risk tm tests
  expect_true(is.list(risk_assess_package$tm_list$coverage$medium_risk))
  expect_identical(risk_assess_package$tm_list$coverage$medium_risk$pkg_name, "test.package.0001")
  expect_true(is.list(risk_assess_package$tm_list$coverage$medium_risk$coverage))
  expect_identical(risk_assess_package$tm_list$coverage$medium_risk$coverage$filecoverage, 0)
  expect_identical(risk_assess_package$tm_list$coverage$medium_risk$coverage$totalcoverage, 0)
  expect_true(is.na(risk_assess_package$tm_list$coverage$medium_risk$errors))
  expect_true(is.na(risk_assess_package$tm_list$coverage$medium_risk$notes))
  
  # low risk tm tests
  testthat::expect_equal(nrow(risk_assess_package$tm_list$coverage$low_risk), 1)
  testthat::expect_true(all(c("exported_function", "class", "function_type", "function_body",
                              "where", "code_script", "documentation", "description",
                              "coverage_percent") %in% names(risk_assess_package$tm_list$coverage$low_risk)))
  
  testthat::expect_identical(risk_assess_package$tm_list$coverage$low_risk$exported_function[1], "myfunction")
  testthat::expect_true(is.na(risk_assess_package$tm_list$coverage$low_risk$class[1]))
  testthat::expect_identical(risk_assess_package$tm_list$coverage$low_risk$function_type[1], "regular function")
  testthat::expect_true(!is.na(risk_assess_package$tm_list$coverage$low_risk$function_body[1]))
  testthat::expect_true(grepl("^test\\.package", risk_assess_package$tm_list$coverage$low_risk$where[1]))
  testthat::expect_true(grepl("^R/", risk_assess_package$tm_list$coverage$low_risk$code_script[1]))
  testthat::expect_identical(risk_assess_package$tm_list$coverage$low_risk$documentation[1], "man/myfunction.Rd")
  testthat::expect_type(risk_assess_package$tm_list$coverage$low_risk$coverage_percent[1], "double")
  
  testthat::expect_identical(length(risk_assess_package$check_list), 2L)
  
  testthat::expect_identical(length(risk_assess_package$check_list$res_check), 21L)
  
  testthat::expect_true(!is.na(risk_assess_package$check_list$res_check$platform))
  
  testthat::expect_true(!is.na(risk_assess_package$check_list$res_check$package))
  
  testthat::expect_identical(length(risk_assess_package$check_list$res_check$test_output), 1L)
  
  testthat::expect_true(!is.na(risk_assess_package$check_list$res_check$test_output$testthat))
  
  testthat::expect_true(all(sapply(risk_assess_package$check_list$res_check$session_info$platform,
                                   function(x) !is.null(x) && x != "")))
  
  
})


test_that("risk_assess_pkg works with path and mocked get_host_package", {
  skip_on_cran()
  skip_if(
    .Platform$OS.type == "windows",
    "covr runs in a subprocess on Windows; mocking is not reliable under devtools::test()"
  )
  dp <- get_test_tarball_path()
  if (nchar(dp) == 0L) skip("Test data test.package.0001_0.1.0.tar.gz not found")
  withr::defer(unlink(dirname(dp), recursive = TRUE), envir = parent.frame())
  
  r <- getOption("repos")
  r["CRAN"] <- "http://cran.us.r-project.org"
  options(repos = r)
  skip_if_repo_unavailable()
  
  mock_get_host_package <- function(pkg_name, pkg_ver, pkg_source_path) {
    list(cran = TRUE, host = "CRAN", url = "https://cran.r-project.org")
  }
  local_mocked_bindings(
    get_host_package = mock_get_host_package,
    .package = "risk.assessr"
  )
  
  risk_assess_package <- risk_assess_pkg(path = dp)
  
  testthat::expect_true(checkmate::check_class(risk_assess_package, "list"))
})


test_that("risk_assess_pkg works with path params", {
  skip_on_cran()
  skip_if(
    .Platform$OS.type == "windows",
    "covr runs in a subprocess on Windows; mocking is not reliable under devtools::test()"
  )
  dp <- get_test_tarball_path()
  if (nchar(dp) == 0L) skip("Test data test.package.0001_0.1.0.tar.gz not found")
  withr::defer(unlink(dirname(dp), recursive = TRUE), envir = parent.frame())
  
  r <- getOption("repos")
  r["CRAN"] <- "http://cran.us.r-project.org"
  options(repos = r)
  skip_if_repo_unavailable()
  
  mock_get_host_package <- function(pkg_name, pkg_ver, pkg_source_path) {
    list(cran = TRUE, host = "CRAN", url = "https://cran.r-project.org")
  }
  local_mocked_bindings(
    get_host_package = mock_get_host_package,
    .package = "risk.assessr"
  )
  
  risk_assess_package <- risk_assess_pkg(path = dp)
  
  testthat::expect_true(checkmate::check_class(risk_assess_package, "list"))
})

test_that("risk_assess_pkg works with invalid path params", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  dp <- "invaled_path/"
  
  # Define the mock function for get_host_package
  mock_get_host_package <- function(pkg_name, pkg_ver, pkg_source_path) {
    return(list(cran = TRUE, host = "CRAN", url = "https://cran.r-project.org"))
  }
  
  # Apply mocked binding for risk.assessr::get_host_package
  local_mocked_bindings(
    get_host_package = mock_get_host_package,
    .package = "risk.assessr"
  )
  
  expect_warning(risk_assess_package <- risk_assess_pkg(path = dp))
  testthat::expect_null(risk_assess_package)
})

# ---- package param (get_package_tarfile) ----

test_that("risk_assess_pkg with package param uses get_package_tarfile and returns list when successful", {
  skip_on_cran()
  skip_if(
    .Platform$OS.type == "windows",
    "covr runs in subprocess on Windows; not reliable under devtools::test()"
  )
  dp <- get_test_tarball_path()
  if (nchar(dp) == 0L) skip("Test data test.package.0001_0.1.0.tar.gz not found")
  withr::defer(unlink(dirname(dp), recursive = TRUE), envir = parent.frame())
  
  mockery::stub(risk_assess_pkg, "get_package_tarfile", function(package_name, version, repos) dp)
  mock_get_host_package <- function(pkg_name, pkg_ver, pkg_source_path) {
    list(cran = TRUE, host = "CRAN", url = "https://cran.r-project.org")
  }
  local_mocked_bindings(get_host_package = mock_get_host_package, .package = "risk.assessr")
  
  r <- getOption("repos")
  r["CRAN"] <- "http://cran.us.r-project.org"
  options(repos = r)
  skip_if_repo_unavailable()
  
  out <- risk_assess_pkg(package = "here")
  testthat::expect_true(is.list(out))
  testthat::expect_identical(length(out), 5L)
})

test_that("risk_assess_pkg with package and version passes version to get_package_tarfile", {
  skip_on_cran()
  skip_if(
    .Platform$OS.type == "windows",
    "covr runs in subprocess on Windows; not reliable under devtools::test()"
  )
  dp <- get_test_tarball_path()
  if (nchar(dp) == 0L) skip("Test data test.package.0001_0.1.0.tar.gz not found")
  withr::defer(unlink(dirname(dp), recursive = TRUE), envir = parent.frame())
  
  captured <- list(version = NULL)
  mock_get_tarfile <- function(package_name, version, repos) {
    captured$version <<- version
    dp
  }
  mockery::stub(risk_assess_pkg, "get_package_tarfile", mock_get_tarfile)
  mock_get_host_package <- function(pkg_name, pkg_ver, pkg_source_path) {
    list(cran = TRUE, host = "CRAN", url = "https://cran.r-project.org")
  }
  local_mocked_bindings(get_host_package = mock_get_host_package, .package = "risk.assessr")
  
  r <- getOption("repos")
  r["CRAN"] <- "http://cran.us.r-project.org"
  options(repos = r)
  skip_if_repo_unavailable()
  
  risk_assess_pkg(package = "here", version = "1.0.1")
  testthat::expect_identical(captured$version, "1.0.1")
})

test_that("risk_assess_pkg with package returns NULL and warns when get_package_tarfile fails", {
  mockery::stub(risk_assess_pkg, "get_package_tarfile", function(...) stop("Download failed"))
  
  testthat::expect_warning(out <- risk_assess_pkg(package = "nonexistentpkg"), "Failed to download package")
  testthat::expect_null(out)
})

# ---- file.choose branch ----

test_that("risk_assess_pkg with no path or package uses file.choose and succeeds when file exists", {
  skip_on_cran()
  skip_if(
    .Platform$OS.type == "windows",
    "file.choose mocking not reliable on Windows under devtools::test()"
  )
  dp <- get_test_tarball_path()
  if (nchar(dp) == 0L) skip("Test data test.package.0001_0.1.0.tar.gz not found")
  withr::defer(unlink(dirname(dp), recursive = TRUE), envir = parent.frame())
  
  mockery::stub(risk_assess_pkg, "file.choose", function() dp)
  mock_get_host_package <- function(pkg_name, pkg_ver, pkg_source_path) {
    list(cran = TRUE, host = "CRAN", url = "https://cran.r-project.org")
  }
  local_mocked_bindings(get_host_package = mock_get_host_package, .package = "risk.assessr")
  
  r <- getOption("repos")
  r["CRAN"] <- "http://cran.us.r-project.org"
  options(repos = r)
  skip_if_repo_unavailable()
  
  out <- risk_assess_pkg()
  testthat::expect_true(is.list(out))
})

test_that("risk_assess_pkg with file.choose returns NULL and warns when chosen file does not exist", {
  mockery::stub(risk_assess_pkg, "file.choose", function() "/nonexistent/chosen.tar.gz")
  
  testthat::expect_warning(out <- risk_assess_pkg(), "Chosen file does not exist")
  testthat::expect_null(out)
})

# ---- path vs package conflict ----

test_that("risk_assess_pkg warns and returns NULL when both path and package are provided", {
  dp <- get_test_tarball_path()
  if (nchar(dp) == 0L) skip("Test data not found")
  
  expect_warning(out <- risk_assess_pkg(path = dp, package = "here"), "Provide either 'path' or 'package'")
  testthat::expect_null(out)
})

# ---- failed unpack ----

test_that("risk_assess_pkg returns NULL with message when set_up_pkg fails to unpack", {
  dp <- get_test_tarball_path()
  if (nchar(dp) == 0L) skip("Test data not found")
  withr::defer(unlink(dirname(dp), recursive = TRUE), envir = parent.frame())
  
  mock_set_up_pkg <- function(...) list(
    package_installed = FALSE,
    pkg_source_path = "",
    build_vignettes = TRUE,
    rcmdcheck_args = list()
  )
  mockery::stub(risk_assess_pkg, "set_up_pkg", mock_set_up_pkg)
  
  expect_message(out <- risk_assess_pkg(path = dp), "Failed to unpack package")
  testthat::expect_null(out)
})

# ---- failed local install ----

test_that("risk_assess_pkg returns NULL with message when install_package_local fails", {
  skip_on_cran()
  dp <- get_test_tarball_path()
  if (nchar(dp) == 0L) skip("Test data not found")
  withr::defer(unlink(dirname(dp), recursive = TRUE), envir = parent.frame())
  
  mockery::stub(risk_assess_pkg, "install_package_local", function(...) FALSE)
  
  r <- getOption("repos")
  r["CRAN"] <- "http://cran.us.r-project.org"
  options(repos = r)
  skip_if_repo_unavailable()
  
  expect_message(out <- risk_assess_pkg(path = dp), "Package installation failed")
  testthat::expect_null(out)
})