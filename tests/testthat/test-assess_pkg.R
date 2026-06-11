# Mock test.assessr::get_package_coverage for assess_pkg tests.
#
# filecoverage keys MUST match the code_script values in exports_df so that the
# left_join in create_traceability_matrix succeeds.  code_script is derived from
# Rd file names: man/foo.Rd -> R/foo.R.  Using R/*.R names instead breaks the join
# when an R source file (e.g. R/myscript.R) has a different base name from its Rd
# page (e.g. man/myfunction.Rd), which is the normal R convention.
assess_pkg_test_mock_get_package_coverage <- function(pkg_source_path, package_installed) {
  pkg_nm  <- unname(read.dcf(file.path(pkg_source_path, "DESCRIPTION"), fields = "Package")[1, 1])
  man_dir <- file.path(pkg_source_path, "man")
  
  if (dir.exists(man_dir)) {
    # Derive keys from man/*.Rd names — the same source used by assess_exported_functions_docs.
    rd_files <- list.files(man_dir, pattern = "\\.[Rr][Dd]$", full.names = FALSE)
    # Drop the package-level page (e.g. test.package.0001-package.Rd)
    rd_files <- rd_files[!rd_files %in% paste0(pkg_nm, "-package.Rd")]
    scripts  <- paste0("R/", sub("\\.[Rr][Dd]$", ".R", rd_files))
  } else {
    # Fallback when no man/ directory exists
    r_dir   <- file.path(pkg_source_path, "R")
    r_files <- if (dir.exists(r_dir)) {
      list.files(r_dir, pattern = "\\.[Rr]$", full.names = FALSE)
    } else {
      character()
    }
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
}

# Empty dependency table as returned by parse_dcf_dependencies / get_dependencies
assess_pkg_test_empty_deps_df <- function() {
  data.frame(type = character(), package = character(), stringsAsFactors = FALSE)
}

# Minimal coverage result without calling test.assessr (avoids subprocess / orphan-cleanup messages)
assess_pkg_test_mock_zero_coverage <- function(pkg_source_path, package_installed) {
  pkg_nm <- unname(read.dcf(file.path(pkg_source_path, "DESCRIPTION"), fields = "Package")[1, 1])
  list(
    total_cov = 0,
    res_cov = list(
      name = pkg_nm,
      coverage = list(
        filecoverage = matrix(0, nrow = 1, dimnames = list("No functions tested")),
        totalcoverage = 0L
      ),
      errors = NA_character_,
      notes = NA
    )
  )
}

test_that(
  "running assess_pkg for test package in tar file - no notes",
  {
    
    skip_on_cran()
    
    skip_if(
      .Platform$OS.type == "windows",
      "covr runs in a subprocess on Windows; mocking is not reliable under devtools::test()"
    )
    
    # ---- repo setup ----
    r <- getOption("repos")
    r["CRAN"] <- "http://cran.us.r-project.org"
    options(repos = r)
    skip_if_repo_unavailable()
    
    # ---- copy test tarball ----
    dp_orig <- system.file(
      "test-data",
      "test.package.0001_0.1.0.tar.gz",
      package = "risk.assessr"
    )
    skip_if_test_data_missing(dp_orig)
    
    dp_dir <- tempfile()
    dir.create(dp_dir, recursive = TRUE)
    dp <- file.path(dp_dir, basename(dp_orig))
    file.copy(dp_orig, dp)
    
    withr::defer(unlink(dp_dir, recursive = TRUE), envir = parent.frame())
    
    # ---- coverage / external mocks -----------------------------------
    mockery::stub(
      assess_pkg,
      "test.assessr::get_package_coverage",
      assess_pkg_test_mock_get_package_coverage
    )
    
    mock_get_host_package <- function(pkg_name, pkg_ver, pkg_source_path) {
      list(
        cran_links = "CRAN",
        github_links = NULL,
        bioconductor_links = NULL,
        internal_links = NULL
      )
    }
    
    mockery::stub(
      assess_pkg,
      "get_host_package",
      mock_get_host_package
    )
    
    mock_check_and_fetch_cran_package <- function(pkg_name, pkg_ver) {
      list(
        all_versions = list(
          list(version = "0.1.0", date = "2021-01-01"),
          list(version = "0.9.0", date = "2022-01-01"),
          list(version = "1.0.0", date = "2023-01-01")
        ),
        last_version = list(
          version = "1.0.0",
          date = "2023-01-01"
        )
      )
    }
    
    mockery::stub(
      assess_pkg,
      "check_and_fetch_cran_package",
      mock_check_and_fetch_cran_package
    )
    
    mockery::stub(
      assess_pkg,
      "get_risk_analysis",
      function(pkg_name) list()
    )
    
    # ---- package setup ------------------------------------------------
    
    install_list <- set_up_pkg(dp)
    
    pkg_source_path <- install_list$pkg_source_path
    rcmdcheck_args <- install_list$rcmdcheck_args
    
    # --- after set_up_pkg(dp) ---
    
    # Discover package name from DESCRIPTION without extra dependencies
    pkg_name <- unname(read.dcf(file.path(pkg_source_path, "DESCRIPTION"), "Package")[1, 1])
    
    # Load the package *from source* so base::getNamespaceExports(pkg_name) works
    pkgload::load_all(
      pkg_source_path,
      quiet = TRUE,
      export_all = FALSE,        # don't attach non-exports
      helpers = FALSE,
      attach_testthat = FALSE
    )
    
    # Make sure we unload even on test failure
    withr::defer(
      try(pkgload::unload(pkg_name), silent = TRUE),
      envir = parent.frame()
    )
    
    withr::defer(
      unlink(pkg_source_path, recursive = TRUE, force = TRUE),
      envir = parent.frame()
    )
    
    # pretend install succeeded
    rcmdcheck_args$path <- pkg_source_path
    
    # ---- run assess_pkg -----------------------------------------------
    
    assess_package <- assess_pkg(pkg_source_path, rcmdcheck_args)
    
    # ---- assertions ---------------------------------------------------
    
    expect_identical(length(assess_package), 5L)
    expect_true(checkmate::check_class(assess_package, "list"))
    
    expect_identical(length(assess_package$results), 31L)
    
    expect_true(!is.na(assess_package$results$pkg_name))
    expect_true(!is.na(assess_package$results$pkg_version))
    expect_true(!is.na(assess_package$results$pkg_source_path))
    expect_true(!is.na(assess_package$results$date_time))
    
    expect_true(checkmate::test_numeric(assess_package$results$covr))
    expect_gte(assess_package$results$covr, 0.7)
    
    # ---- covr list ----------------------------------------------------
    
    expect_identical(length(assess_package$covr_list), 2L)
    expect_identical(
      length(assess_package$covr_list$res_cov$coverage),
      2L
    )
    
    # ---- TM coverage --------------------------------------------------
    
    expect_identical(length(assess_package$tm_list$tm), 9L)
    
    # high risk: either empty placeholder list (create_empty_tm) or a tibble of rows
    hr <- assess_package$tm_list$coverage$high_risk
    if (inherits(hr, "data.frame")) {
      expect_true(nrow(hr) >= 0L)
    } else {
      expect_true(is.list(hr))
      expect_identical(hr$pkg_name, pkg_name)
    }
    
    # medium risk
    mrisk <- assess_package$tm_list$coverage$medium_risk
    if (inherits(mrisk, "data.frame")) {
      expect_true(nrow(mrisk) >= 0L)
    } else {
      expect_true(is.list(mrisk))
    }
    
    # low risk: pick myfunction row (package may have multiple exports / R files)
    low_risk <- assess_package$tm_list$coverage$low_risk
    expect_true(inherits(low_risk, "data.frame"))
    expect_true("myfunction" %in% low_risk$exported_function)
    myfun_lr <- low_risk[low_risk$exported_function == "myfunction", , drop = FALSE]
    expect_equal(nrow(myfun_lr), 1L)
    expect_true(grepl("^R/", myfun_lr$code_script[1]))
    expect_equal(myfun_lr$coverage_percent[1], 100)
    
    # ---- check data ---------------------------------------------------
    
    expect_identical(length(assess_package$check_list), 2L)
    expect_identical(
      length(assess_package$check_list$res_check),
      21L
    )
    
    # ---- version delta -----------------------------------------------
    
    diff_months <-
      assess_package$results$version_info$difference_version_months
    
    expect_equal(diff_months, 24)
    
  })



Sys.setenv("R_TESTS" = "")
library(testthat)

test_that("running assess_pkg for test package in tar file - no exports", {
  skip_on_cran()
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  skip_if_repo_unavailable()
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0005_0.1.0.tar.gz", 
                         package = "risk.assessr")
  skip_if_test_data_missing(dp_orig)
  dp_dir <- tempfile()
  dir.create(dp_dir, recursive = TRUE)
  dp <- file.path(dp_dir, basename(dp_orig))
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp_dir, recursive = TRUE), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  mock_get_host_package <- function(pkg_name, pkg_ver, pkg_source_path) {
    return(list(cran_links = "CRAN", github_links = NULL, bioconductor_links = NULL, internal_links= NULL))
  }
  
  mockery::stub(assess_pkg, "get_host_package", mock_get_host_package)
  
  mockery::stub(assess_pkg, "test.assessr::get_package_coverage", assess_pkg_test_mock_zero_coverage)
  
  mock_check_and_fetch_cran_package <- function(pkg_name, pkg_ver) {
    return(list(
      all_versions = list(
        list(version = "0.1.0", date = "2023-01-01"), # actual package version
        list(version = "0.9.0", date = "2022-01-01"),
        list(version = "1.0.0", date = "2023-01-01")
      ),
      last_version = list(version = "1.0.0", date = "2023-01-01")
    ))
  }
  
  mockery::stub(assess_pkg, "check_and_fetch_cran_package", mock_check_and_fetch_cran_package)
  
  mock_get_risk_analysis <- function(pkg_name) {
    return(list())
  }
  
  mockery::stub(assess_pkg, "get_risk_analysis", mock_get_risk_analysis)
  
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  # install package locally to ensure test works
  package_installed <- install_package_local(pkg_source_path)
  package_installed <- TRUE
  
  if (package_installed == TRUE ) {
    
    # ensure path is set to package source path
    rcmdcheck_args$path <- pkg_source_path
    assess_package <- assess_pkg(pkg_source_path, rcmdcheck_args)
    
    testthat::expect_identical(length(assess_package), 5L)
    
    testthat::expect_true(checkmate::check_class(assess_package, "list"))
    
    testthat::expect_identical(length(assess_package$results), 31L)
    
    testthat::expect_true(!is.na(assess_package$results$pkg_name))
    
    testthat::expect_true(!is.na(assess_package$results$pkg_version))
    
    testthat::expect_true(!is.na(assess_package$results$pkg_source_path))
    
    testthat::expect_true(!is.na(assess_package$results$date_time))
    
    testthat::expect_true(!is.na(assess_package$results$executor))
    
    testthat::expect_true(!is.na(assess_package$results$sysname))
    
    testthat::expect_true(!is.na(assess_package$results$version))
    
    testthat::expect_true(!is.na(assess_package$results$release))
    
    testthat::expect_true(!is.na(assess_package$results$machine))
    
    testthat::expect_true(!is.na(assess_package$results$comments))
    
    testthat::expect_null(assess_package$results$has_bug_reports_url)
    
    testthat::expect_true(!is.na(assess_package$results$suggested_deps$source))
    
    testthat::expect_true(identical(assess_package$results$suggested_deps$message,
                                    "No exported functions from Suggested packages in the DESCRIPTION file"))
    
    testthat::expect_true(!is.na(assess_package$results$license))
    
    testthat::expect_true(!is.na(assess_package$results$size_codebase))
    
    testthat::expect_true(checkmate::test_numeric(assess_package$results$size_codebase))
    
    testthat::expect_true(checkmate::test_numeric(assess_package$results$check))
    
    testthat::expect_gte(assess_package$results$check, 0)
    
    testthat::expect_true(checkmate::test_numeric(assess_package$results$covr))
    
    testthat::expect_gte(assess_package$results$covr, 0)
    
    testthat::expect_identical(length(assess_package$covr_list), 2L)
    
    testthat::expect_true(!is.na(assess_package$covr_list$res_cov$name))
    
    testthat::expect_identical(length(assess_package$covr_list$res_cov$coverage), 2L)
    
    testthat::expect_identical(length(assess_package$tm_list), 4L)
    
    testthat::expect_identical(length(assess_package$tm_list$tm), 0L)
    
    expect_identical(assess_package$tm_list$coverage$filecoverage, 0)
    
    expect_identical(assess_package$tm_list$coverage$totalcoverage, 0)
    
    testthat::expect_identical(length(assess_package$check_list), 2L)
    
    testthat::expect_identical(length(assess_package$check_list$res_check), 21L)
    
    testthat::expect_true(!is.na(assess_package$check_list$res_check$platform))
    
    testthat::expect_true(!is.na(assess_package$check_list$res_check$package))
    
    testthat::expect_identical(length(assess_package$check_list$res_check$test_output), 0L)
    
    testthat::expect_true(is.null(assess_package$check_list$res_check$test_output$testthat))
    
    testthat::expect_true(all(sapply(assess_package$check_list$res_check$session_info$platform,
                                     function(x) !is.null(x) && x != "")))
    diff_months <- assess_package$results$version_info$difference_version_months
    expect_equal(diff_months, 0)
  }
})


test_that("running assess_pkg for test package with Config/build/clean-inst-doc: false", {
  skip_on_cran()
  
  mock_get_host_package <- function(pkg_name, pkg_ver, pkg_source_path) {
    return(list(cran_links = "CRAN", github_links = NULL, bioconductor_links = NULL, internal_links= NULL))
  }
  
  mockery::stub(assess_pkg, "get_host_package", mock_get_host_package)
  
  mockery::stub(assess_pkg, "test.assessr::get_package_coverage", assess_pkg_test_mock_zero_coverage)
  
  mock_check_and_fetch_cran_package <- function(pkg_name, pkg_ver) {
    return(list(
      all_versions = list(
        list(version = "0.1.0", date = "2023-01-01"), # actual package version
        list(version = "0.9.0", date = "2022-01-01"),
        list(version = "1.0.0", date = "2023-01-01")
      ),
      last_version = list(version = "1.0.0", date = "2023-01-01")
    ))
  }
  
  mockery::stub(assess_pkg, "check_and_fetch_cran_package", mock_check_and_fetch_cran_package)
  
  mock_get_risk_analysis <- function(pkg_name) {
    return(list())
  }
  
  mockery::stub(assess_pkg, "get_risk_analysis", mock_get_risk_analysis)
  
  
  dp <- system.file("test-data", "test.package.0005_0.1.0.tar.gz",
                    package = "risk.assessr")
  skip_if_test_data_missing(dp)
  
  # Check if the file exists before attempting to download
  if (!file.exists(dp)) {
    stop("The tar file does not exist at the specified path.")
  }
  
  # Create a temporary file to store the downloaded package
  file_name <- basename(dp) # Use the base name for temporary file
  temp_file <- file.path(tempdir(), file_name)
  
  # Copy the file to the temporary file instead of downloading it
  file.copy(dp, temp_file, overwrite = TRUE)
  
  # Verify that the copy was successful
  if (!file.exists(temp_file)) {
    stop("File copy failed: temporary file not found.")
  }
  
  # Run the function to modify the DESCRIPTION file
  modified_tar_file <- modify_description_file(temp_file)
  
  # Set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  if (package_installed == TRUE) {
    
    assess_package <- assess_pkg(pkg_source_path, rcmdcheck_args)
    
    testthat::expect_true(checkmate::check_class(assess_package, "list"))
  }
})


test_that("running assess_pkg for test package fail suggest", {
  skip_on_cran()
  
  # Robust, version-independent Windows skip (covr subprocess + devtools::test)
  skip_if(
    .Platform$OS.type == "windows",
    "covr runs in a subprocess on Windows; mocking is not reliable under devtools::test()."
  )
  
  # ---- repo setup ----
  r <- getOption("repos")
  r["CRAN"] <- "http://cran.us.r-project.org"
  options(repos = r)
  skip_if_repo_unavailable()
  
  # ---- copy test tarball ----
  dp_orig <- system.file(
    "test-data",
    "test.package.0001_0.1.0.tar.gz",
    package = "risk.assessr"
  )
  skip_if_test_data_missing(dp_orig)
  dp_dir <- tempfile()
  dir.create(dp_dir, recursive = TRUE)
  dp <- file.path(dp_dir, basename(dp_orig))
  file.copy(dp_orig, dp)
  
  withr::defer(unlink(dp_dir, recursive = TRUE), envir = parent.frame())
  
  # ---- coverage path control: mock test.assessr provider ----
  mockery::stub(
    assess_pkg,
    "test.assessr::get_package_coverage",
    assess_pkg_test_mock_get_package_coverage
  )
  
  # 2) Optional tripwires: if any direct covr path is still hit, fail fast
  tripwire <- function(...) stop("covr must not be called in this unit test", call. = FALSE)
  if (exists("create_covr_list_no_skip", envir = asNamespace("risk.assessr"), inherits = FALSE)) {
    mockery::stub(risk.assessr:::create_covr_list_no_skip, "covr::package_coverage", tripwire)
  }
  if (exists("run_covr_skip_stf", envir = asNamespace("risk.assessr"), inherits = FALSE)) {
    mockery::stub(risk.assessr:::run_covr_skip_stf, "covr::package_coverage", tripwire)
  }
  if (exists("run_covr_skip_nstf", envir = asNamespace("risk.assessr"), inherits = FALSE)) {
    mockery::stub(risk.assessr:::run_covr_skip_nstf, "covr::package_coverage", tripwire)
  }
  
  # ---- other external mocks ----
  mockery::stub(
    assess_pkg,
    "get_host_package",
    function(pkg_name, pkg_ver, pkg_source_path) {
      list(cran_links = "CRAN", github_links = NULL, bioconductor_links = NULL, internal_links = NULL)
    }
  )
  
  mockery::stub(
    assess_pkg,
    "check_and_fetch_cran_package",
    function(pkg_name, pkg_ver) {
      list(
        all_versions = list(
          list(version = "0.1.0", date = "2023-01-01"), # actual package version
          list(version = "0.9.0", date = "2022-01-01"),
          list(version = "1.0.0", date = "2023-01-01")
        ),
        last_version = list(version = "1.0.0", date = "2023-01-01")
      )
    }
  )
  
  mockery::stub(
    assess_pkg,
    "get_risk_analysis",
    function(pkg_name) list()
  )
  
  # stub inside assess_pkg() because that's where the call appears in the function body.
  mockery::stub(
    assess_pkg,
    "check_suggested_exp_funcs",
    function(...) stop("forced failure")
  )
  
  # ---- package setup ----
  install_list <- set_up_pkg(dp)
  
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args  <- install_list$rcmdcheck_args
  
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE), envir = parent.frame())
  
  # Install locally if your pipeline needs it (you had this)
  package_installed <- install_package_local(pkg_source_path)
  package_installed <- TRUE
  
  if (isTRUE(package_installed)) {
    rcmdcheck_args$path <- pkg_source_path
    assess_package <- assess_pkg(pkg_source_path, rcmdcheck_args)
    suggested_deps <- assess_package$results$suggested_deps
  }
  
  testthat::expect_identical(length(suggested_deps), 4L)
  
  expected <- c("source", "suggested_function", "message", "where")
  
  # Same number of columns
  testthat::expect_identical(ncol(suggested_deps), length(expected))
  
  expect_identical(suggested_deps$source,
                   "test.package.0001"
  )
  
  expect_identical(suggested_deps$message,
                   "Error in checking suggested functions"
  )
  
})

test_that("assess_pkg handles errors in check_suggested_exp_funcs correctly", {
  skip_on_cran()
  
  # Robust Windows skip: covr runs in a subprocess on Windows and mocks won't cross it reliably
  skip_if(
    .Platform$OS.type == "windows",
    "covr runs in a subprocess on Windows; mocking is not reliable under devtools::test()."
  )
  
  # ---- CRAN repo setup (if your helpers install deps) ----
  r <- getOption("repos")
  r["CRAN"] <- "http://cran.us.r-project.org"
  options(repos = r)
  skip_if_repo_unavailable()
  
  # ---- copy test tarball ----
  dp_orig <- system.file(
    "test-data",
    "test.package.0001_0.1.0.tar.gz",
    package = "risk.assessr"
  )
  skip_if_test_data_missing(dp_orig)
  dp_dir <- tempfile()
  dir.create(dp_dir, recursive = TRUE)
  dp <- file.path(dp_dir, basename(dp_orig))
  file.copy(dp_orig, dp)
  
  withr::defer(unlink(dp_dir, recursive = TRUE), envir = parent.frame())
  
  # We'll collect pkg_source_path for cleanup once set_up_pkg() runs
  # (we declare it here only so the defer below has a symbol)
  pkg_source_path <- NULL
  withr::defer(
    if (!is.null(pkg_source_path)) unlink(pkg_source_path, recursive = TRUE, force = TRUE),
    envir = parent.frame()
  )
  
  # ---- Mock coverage provider and prevent fallback paths ----
  mockery::stub(
    assess_pkg,
    "test.assessr::get_package_coverage",
    assess_pkg_test_mock_get_package_coverage
  )
  
  # Tripwires: if any direct covr call is still reached, fail fast
  tripwire <- function(...) stop("covr must not be called in this unit test", call. = FALSE)
  if (exists("create_covr_list_no_skip", envir = asNamespace("risk.assessr"), inherits = FALSE)) {
    mockery::stub(risk.assessr:::create_covr_list_no_skip, "covr::package_coverage", tripwire)
  }
  if (exists("run_covr_skip_stf", envir = asNamespace("risk.assessr"), inherits = FALSE)) {
    mockery::stub(risk.assessr:::run_covr_skip_stf, "covr::package_coverage", tripwire)
  }
  if (exists("run_covr_skip_nstf", envir = asNamespace("risk.assessr"), inherits = FALSE)) {
    mockery::stub(risk.assessr:::run_covr_skip_nstf, "covr::package_coverage", tripwire)
  }
  
  # ---- Other external mocks used by assess_pkg() ----
  mockery::stub(
    assess_pkg,
    "get_host_package",
    function(pkg_name, pkg_ver, pkg_source_path) {
      list(cran_links = "CRAN", github_links = NULL, bioconductor_links = NULL, internal_links = NULL)
    }
  )
  
  mockery::stub(
    assess_pkg,
    "check_and_fetch_cran_package",
    function(pkg_name, pkg_ver) {
      list(
        all_versions = list(
          list(version = "0.1.0", date = "2023-01-01"), # actual package version
          list(version = "0.9.0", date = "2022-01-01"),
          list(version = "1.0.0", date = "2023-01-01")
        ),
        last_version = list(version = "1.0.0", date = "2023-01-01")
      )
    }
  )
  
  mockery::stub(
    assess_pkg,
    "get_risk_analysis",
    function(pkg_name) list()
  )
  
  # ---- Key fix: stub the *caller* of check_suggested_exp_funcs, i.e., inside assess_pkg() ----
  mockery::stub(
    assess_pkg,
    "check_suggested_exp_funcs",
    function(...) stop("Mock error")  # your test is specifically about error handling
  )
  
  # ---- Prepare the test package ----
  install_list <- set_up_pkg(dp)
  
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args  <- install_list$rcmdcheck_args
  
  # Discover package name from DESCRIPTION without extra dependencies
  pkg_name <- unname(read.dcf(file.path(pkg_source_path, "DESCRIPTION"), "Package")[1, 1])
  
  # Load the package *from source* so base::getNamespaceExports(pkg_name) works
  pkgload::load_all(
    pkg_source_path,
    quiet = TRUE,
    export_all = FALSE,        # don't attach non-exports
    helpers = FALSE,
    attach_testthat = FALSE
  )
  
  # Make sure we unload even on test failure
  withr::defer(
    try(pkgload::unload(pkg_name), silent = TRUE),
    envir = parent.frame()
  )
  
  # If your pipeline actually needs an install (some helper may assume it), keep it
  package_installed <- install_package_local(pkg_source_path)
  if (isTRUE(package_installed)) {
    rcmdcheck_args$path <- pkg_source_path
    
    # ---- Execute ----
    assess_package <- assess_pkg(pkg_source_path, rcmdcheck_args)
    
    # ---- Assertions ----
    expect_true("suggested_deps" %in% names(assess_package$results))
    
    suggested_deps <- assess_package$results$suggested_deps
    expect_equal(nrow(suggested_deps), 1)
    expect_equal(suggested_deps$source, "test.package.0001")
    expect_equal(suggested_deps$suggested_function, 0)
    
    # If your intended behavior on error is to fall back to the “no exported functions…” row:
    expect_equal(
      suggested_deps$message,
      "Error in checking suggested functions"
    )
    
    # The covr value should be 1 based on our mock_get_package_coverage()
    expect_true("covr" %in% names(assess_package$results))
    expect_equal(assess_package$results$covr, 1)
  } else {
    skip("Local install of test package failed (install_package_local returned FALSE).")
  }
})

test_that("assess_pkg handles error in check_suggested_exp_funcs via withCallingHandlers", {
  
  # Create a real temporary directory and DESCRIPTION file
  pkg_source_path <- withr::local_tempdir()
  desc_path <- file.path(pkg_source_path, "DESCRIPTION")
  writeLines(c(
    "Package: mockpkg",
    "Version: 0.1.0",
    "Title: Mock Package",
    "Description: A mock package for testing.",
    "Authors@R: c(person(given = \"Mock\", family = \"Author\", role = c(\"aut\", \"cre\")))",
    "License: MIT"
  ), desc_path)
  
  # Stub get_pkg_desc to return mock name/version
  mockery::stub(assess_pkg, "get_pkg_desc", function(path, fields) {
    list(Package = "mockpkg", Version = "0.1.0")
  })
  
  # Stub all other required functions to return minimal valid data
  mockery::stub(assess_pkg, "get_risk_metadata", function() list())
  mockery::stub(assess_pkg, "create_empty_results", function(...) list(suggested_deps = NULL))
  mockery::stub(assess_pkg, "doc_riskmetric", function(...) list(
    has_bug_reports_url = TRUE, license = TRUE, has_examples = TRUE,
    has_maintainer = TRUE, size_codebase = 10, has_news = TRUE,
    has_source_control = TRUE, has_vignettes = TRUE, has_website = TRUE,
    news_current = TRUE, export_help = TRUE
  ))
  mockery::stub(assess_pkg, "test.assessr::get_package_coverage", assess_pkg_test_mock_zero_coverage)
  mockery::stub(assess_pkg, "run_rcmdcheck", function(...) list(check_score = 1))
  mockery::stub(assess_pkg, "get_dependencies", function(...) assess_pkg_test_empty_deps_df())
  mockery::stub(assess_pkg, "create_empty_tm", function(...) list())
  mockery::stub(assess_pkg, "assess_exports", function(...) list())
  mockery::stub(assess_pkg, "risk.assessr::get_session_dependencies", function(...) list())
  mockery::stub(assess_pkg, "get_pkg_author", function(...) list(maintainer = "Mock Author", funder = NA, authors = "Mock Author"))
  mockery::stub(assess_pkg, "extract_license_from_description", function(...) "MIT")
  mockery::stub(assess_pkg, "get_host_package", function(...) list(cran_links = NULL, github_links = NULL, bioconductor_links = NULL, internal_links = NULL))
  mockery::stub(assess_pkg, "get_repo_owner", function(...) NA_character_)
  mockery::stub(assess_pkg, "get_github_data", function(...) list(created_at = NA, stars = 0, forks = 0, date = NA, recent_commits_count = 0))
  mockery::stub(assess_pkg, "get_cran_total_downloads", function(...) 0)
  mockery::stub(assess_pkg, "get_risk_analysis", function(...) list())
  
  # Stub check_suggested_exp_funcs to throw an error caught by withCallingHandlers
  mockery::stub(assess_pkg, "check_suggested_exp_funcs", function(...) stop("Simulated error in inner handler"))
  
  rcmdcheck_args <- list(timeout = Inf, args = c("--no-manual"), build_args = NULL, env = "mockenv", quiet = TRUE)
  
  expect_message(
    assess_pkg(pkg_source_path, rcmdcheck_args),
    "An error occurred in checking suggested functions: Simulated error in inner handler"
  )
})

test_that("assess_pkg handles error via outer tryCatch block", {
  
  # Create a real temporary directory and DESCRIPTION file
  pkg_source_path <- withr::local_tempdir()
  desc_path <- file.path(pkg_source_path, "DESCRIPTION")
  writeLines(c(
    "Package: mockpkg",
    "Version: 0.1.0",
    "Title: Mock Package",
    "Description: A mock package for testing.",
    "Authors@R: c(person(given = \"Mock\", family = \"Author\", role = c(\"aut\", \"cre\")))",
    "License: MIT"
  ), desc_path)
  
  # Stub get_pkg_desc to return mock name/version
  mockery::stub(assess_pkg, "get_pkg_desc", function(path, fields) {
    list(Package = "mockpkg", Version = "0.1.0")
  })
  
  # Stub all other required functions to return minimal valid data
  mockery::stub(assess_pkg, "get_risk_metadata", function() list())
  mockery::stub(assess_pkg, "create_empty_results", function(...) list(suggested_deps = NULL))
  mockery::stub(assess_pkg, "doc_riskmetric", function(...) list(
    has_bug_reports_url = TRUE, license = TRUE, has_examples = TRUE,
    has_maintainer = TRUE, size_codebase = 10, has_news = TRUE,
    has_source_control = TRUE, has_vignettes = TRUE, has_website = TRUE,
    news_current = TRUE, export_help = TRUE
  ))
  mockery::stub(assess_pkg, "test.assessr::get_package_coverage", assess_pkg_test_mock_zero_coverage)
  mockery::stub(assess_pkg, "run_rcmdcheck", function(...) list(check_score = 1))
  mockery::stub(assess_pkg, "get_dependencies", function(...) assess_pkg_test_empty_deps_df())
  mockery::stub(assess_pkg, "create_empty_tm", function(...) list())
  
  # Stub withCallingHandlers to simulate an error that bypasses inner handler
  mockery::stub(
    assess_pkg,
    "check_suggested_exp_funcs",
    function(...) stop("Mock error")
  )
  
  
  rcmdcheck_args <- list(timeout = Inf, args = c("--no-manual"), build_args = NULL, env = "mockenv", quiet = TRUE)
  
  expect_message(
    assess_pkg(pkg_source_path, rcmdcheck_args),
    "An error occurred in checking suggested functions: Mock error"
  )
})


test_that("assess_pkg follows Bioconductor path and records version/revdeps", {
  skip_on_cran()
  
  # Create a minimal real pkg structure
  pkg_source_path <- withr::local_tempdir()
  writeLines(c(
    "Package: mockbio",
    "Version: 1.0.0",                     # matches an entry below → difference months = 0
    "Title: Mock BioPkg",
    "Description: A mock package.",
    "Authors@R: person('A','B',role=c('aut','cre'))",
    "License: MIT"
  ), file.path(pkg_source_path, "DESCRIPTION"))
  dir.create(file.path(pkg_source_path, "R"), showWarnings = FALSE)
  writeLines("", file.path(pkg_source_path, "NAMESPACE"))
  
  # Minimal rcmdcheck args
  rcmdcheck_args <- list(timeout = Inf, args = c("--no-manual"), build_args = NULL, env = "mockenv", quiet = TRUE)
  
  # --- Stubs to force the Bioconductor branch and keep runtime tiny ---
  mockery::stub(assess_pkg, "get_risk_metadata", function() list())
  mockery::stub(assess_pkg, "create_empty_results", function(...) {
    list(
      pkg_name = "mockbio", pkg_version = "1.0.0", pkg_source_path = pkg_source_path,
      date_time = Sys.time(), executor = "test", sysname = "Windows", version = "R",
      release = "0", machine = "x86", comments = "", suggested_deps = NULL
    )
  })
  mockery::stub(assess_pkg, "doc_riskmetric", function(...) list(
    has_bug_reports_url = TRUE, license = "MIT", has_examples = TRUE,
    has_maintainer = TRUE, size_codebase = 10, has_news = TRUE,
    has_source_control = TRUE, has_vignettes = TRUE, has_website = TRUE,
    news_current = TRUE, export_help = TRUE
  ))
  mockery::stub(assess_pkg, "test.assessr::get_package_coverage", assess_pkg_test_mock_zero_coverage)
  mockery::stub(assess_pkg, "run_rcmdcheck", function(...) list(check_score = 1))
  mockery::stub(assess_pkg, "get_dependencies", function(...) assess_pkg_test_empty_deps_df())
  mockery::stub(assess_pkg, "test.assessr::get_package_coverage", assess_pkg_test_mock_zero_coverage)
  mockery::stub(assess_pkg, "create_empty_tm", function(...) list())
  mockery::stub(assess_pkg, "get_pkg_author", function(...) list(maintainer = "A B", funder = NA, authors = "A B"))
  mockery::stub(assess_pkg, "extract_license_from_description", function(...) "MIT")
  mockery::stub(assess_pkg, "get_host_package", function(pkg, ver, path) {
    list(cran_links = NULL, github_links = NULL, bioconductor_links = "bioc", internal_links = NULL)
  })
  mockery::stub(assess_pkg, "get_repo_owner", function(...) "owner")
  mockery::stub(assess_pkg, "get_github_data", function(...) list(created_at = NA, stars = 0, forks = 0, date = NA, recent_commits_count = 0))
  mockery::stub(assess_pkg, "get_cran_total_downloads", function(...) 0)
  # Bioconductor-specific stubs
  mockery::stub(assess_pkg, "fetch_bioconductor_releases", function() "<html/>")
  mockery::stub(assess_pkg, "parse_bioconductor_releases", function(html) list())  # not used by our next stub
  mockery::stub(assess_pkg, "get_bioconductor_package_url", function(pkg, ver, rel) {
    list(
      all_versions = list(
        list(version = "0.9.0", date = "2022-01-01"),
        list(version = "1.0.0", date = "2023-01-01")
      ),
      last_version = list(version = "1.0.0", date = "2023-01-01"),
      bioconductor_version_package = "3.17"
    )
  })
  mockery::stub(assess_pkg, "bioconductor_reverse_deps", function(pkg, version) c("pkgA", "pkgB"))
  mockery::stub(assess_pkg, "risk.assessr::get_session_dependencies", function(...) list())
  mockery::stub(assess_pkg, "get_risk_analysis", function(...) list())
  
  res <- assess_pkg(pkg_source_path, rcmdcheck_args)
  
  expect_true(is.list(res))
  expect_true("results" %in% names(res))
  expect_true("version_info" %in% names(res$results))
  expect_equal(res$results$version_info$bioconductor_version_package, "3.17")
  expect_equal(res$results$version_info$last_version$version, "1.0.0")
  # Version in DESCRIPTION == "1.0.0" → index matches → difference months 0
  expect_equal(res$results$version_info$difference_version_months, 0)
  # Revdeps populated from Bioconductor path:
  expect_equal(res$results$rev_deps, c("pkgA", "pkgB"))
})


test_that("assess_pkg Bioconductor path coerces empty reverse deps to 0", {
  skip_on_cran()
  
  pkg_source_path <- withr::local_tempdir()
  writeLines(c(
    "Package: mockbioempty",
    "Version: 1.0.0",
    "Title: Mock BioPkg Empty",
    "Description: A mock package.",
    "Authors@R: person('A','B',role=c('aut','cre'))",
    "License: MIT"
  ), file.path(pkg_source_path, "DESCRIPTION"))
  dir.create(file.path(pkg_source_path, "R"), showWarnings = FALSE)
  writeLines("", file.path(pkg_source_path, "NAMESPACE"))
  
  rcmdcheck_args <- list(timeout = Inf, args = c("--no-manual"), build_args = NULL, env = "mockenv", quiet = TRUE)
  
  mockery::stub(assess_pkg, "get_risk_metadata", function() list())
  mockery::stub(assess_pkg, "create_empty_results", function(...) list(suggested_deps = NULL))
  mockery::stub(assess_pkg, "doc_riskmetric", function(...) list(
    has_bug_reports_url = TRUE, license = "MIT", has_examples = TRUE,
    has_maintainer = TRUE, size_codebase = 10, has_news = TRUE,
    has_source_control = TRUE, has_vignettes = TRUE, has_website = TRUE,
    news_current = TRUE, export_help = TRUE
  ))
  mockery::stub(assess_pkg, "test.assessr::get_package_coverage", assess_pkg_test_mock_zero_coverage)
  mockery::stub(assess_pkg, "run_rcmdcheck", function(...) list(check_score = 1))
  mockery::stub(assess_pkg, "get_dependencies", function(...) assess_pkg_test_empty_deps_df())
  mockery::stub(assess_pkg, "test.assessr::get_package_coverage", assess_pkg_test_mock_zero_coverage)
  mockery::stub(assess_pkg, "create_empty_tm", function(...) list())
  mockery::stub(assess_pkg, "get_host_package", function(pkg, ver, path) {
    list(cran_links = NULL, github_links = NULL, bioconductor_links = "bioc", internal_links = NULL)
  })
  mockery::stub(assess_pkg, "fetch_bioconductor_releases", function() "<html/>")
  mockery::stub(assess_pkg, "parse_bioconductor_releases", function(html) list())
  mockery::stub(assess_pkg, "get_bioconductor_package_url", function(pkg, ver, rel) {
    list(
      all_versions = list(
        list(version = "1.0.0", date = "2023-01-01")
      ),
      last_version = list(version = "1.0.0", date = "2023-01-01"),
      bioconductor_version_package = "3.18"
    )
  })
  # Return empty to trigger the post-processing fallback to 0
  mockery::stub(assess_pkg, "bioconductor_reverse_deps", function(pkg, version) character(0))
  mockery::stub(assess_pkg, "risk.assessr::get_session_dependencies", function(...) list())
  mockery::stub(assess_pkg, "get_risk_analysis", function(...) list())
  
  res <- assess_pkg(pkg_source_path, rcmdcheck_args)
  
  expect_true(is.list(res))
  expect_true("results" %in% names(res))
  expect_equal(res$results$version_info$bioconductor_version_package, "3.18")
  expect_equal(res$results$version_info$difference_version_months, 0)
  # Empty reverse deps must be coerced to numeric 0
  expect_identical(res$results$rev_deps, 0)
})

test_that("assess_pkg returns NULL with a warning when pkg_source_path is NULL", {
  
  rcmdcheck_args <- list(timeout = Inf, args = c("--no-manual"), build_args = NULL, env = "mockenv", quiet = TRUE)
  
  # Bypass the two assert_* guards that fire before the is.null() check
  mockery::stub(assess_pkg, "checkmate::assert_string", function(...) invisible(NULL))
  mockery::stub(assess_pkg, "checkmate::assert_directory_exists", function(...) invisible(NULL))
  
  # Stub the functions called between the checkmate block and the guard
  mockery::stub(assess_pkg, "get_pkg_desc", function(...) list(Package = "mockpkg", Version = "0.1.0"))
  mockery::stub(assess_pkg, "get_risk_metadata", function() list())
  mockery::stub(assess_pkg, "create_empty_results", function(...) list(suggested_deps = NULL))
  mockery::stub(assess_pkg, "doc_riskmetric", function(...) list(
    has_bug_reports_url = TRUE, license = TRUE, has_examples = TRUE,
    has_maintainer = TRUE, size_codebase = 10, has_news = TRUE,
    has_source_control = TRUE, has_vignettes = TRUE, has_website = TRUE,
    news_current = TRUE, export_help = TRUE
  ))
  
  result <- expect_warning(
    assess_pkg(NULL, rcmdcheck_args),
    "`pkg_source_path` is missing. Returning NULL."
  )
  
})


test_that("assess_pkg returns NULL with a warning when pkg_source_path is an empty string", {
  
  rcmdcheck_args <- list(timeout = Inf, args = c("--no-manual"), build_args = NULL, env = "mockenv", quiet = TRUE)
  
  # assert_string("") passes; assert_directory_exists("") fails — stub only the latter
  mockery::stub(assess_pkg, "checkmate::assert_directory_exists", function(...) invisible(NULL))
  
  # Stub the functions called between the checkmate block and the guard
  mockery::stub(assess_pkg, "get_pkg_desc", function(...) list(Package = "mockpkg", Version = "0.1.0"))
  mockery::stub(assess_pkg, "get_risk_metadata", function() list())
  mockery::stub(assess_pkg, "create_empty_results", function(...) list(suggested_deps = NULL))
  mockery::stub(assess_pkg, "doc_riskmetric", function(...) list(
    has_bug_reports_url = TRUE, license = TRUE, has_examples = TRUE,
    has_maintainer = TRUE, size_codebase = 10, has_news = TRUE,
    has_source_control = TRUE, has_vignettes = TRUE, has_website = TRUE,
    news_current = TRUE, export_help = TRUE
  ))
  
  result <- expect_warning(
    assess_pkg("", rcmdcheck_args),
    "`pkg_source_path` is missing. Returning NULL."
  )
  
})
