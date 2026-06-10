# Mock function for remove_base_packages to avoid network calls
mock_remove_base <- function(df) {
  base_rec_pkgs <- c("base", "compiler", "datasets", "graphics", "grDevices", 
                     "grid", "methods", "parallel", "splines", "stats", 
                     "stats4", "tcltk", "tools", "utils")
  df[!(df$package == "R" | df$package %in% base_rec_pkgs), ]
}

test_that("parse deps for tar file works correctly", {
  skip_on_cran()
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  mockery::stub(parse_dcf_dependencies, "remove_base_packages", mock_remove_base)
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz", 
                    package = "risk.assessr")
  skip_if_test_data_missing(dp)
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  # Defer cleanup: remove test package from temp dirs
  withr::defer({
    unlink(pkg_source_path, recursive = TRUE, force = TRUE)
  })
  
  # install package locally to ensure test works
  package_installed <- install_package_local(pkg_source_path)
  package_installed <- TRUE
  
  if (package_installed == TRUE ) {	
    deps <- parse_dcf_dependencies(pkg_source_path)
    
    expect_identical(length(deps), 2L)
    
    expect_true(checkmate::check_data_frame(deps, 
                                            any.missing = FALSE))
    
    expect_true(checkmate::check_data_frame(deps, 
                                            col.names = "named")
    )
  }
  
})

test_that("parse deps for tar file works correctly", {
  skip_on_cran()
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  mockery::stub(parse_dcf_dependencies, "remove_base_packages", mock_remove_base)
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0001_0.1.0.tar.gz", 
                         package = "risk.assessr")
  skip_if_test_data_missing(dp_orig)
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  # install package locally to ensure test works
  package_installed <- 
    install_package_local(pkg_source_path)
  package_installed <- TRUE
  
  if (package_installed == TRUE ) {	
    deps <- parse_dcf_dependencies(pkg_source_path)
    
    expect_identical(length(deps), 2L)
    
    expect_true(checkmate::check_data_frame(deps, 
                                            any.missing = FALSE))
    
    expect_true(checkmate::check_data_frame(deps, 
                                            col.names = "named")
    )
  }
})

test_that("parse_dcf_dependencies extracts dependencies when CRAN is available", {
  skip_if_repo_unavailable(repo = "http://cran.us.r-project.org")
  
  mockery::stub(parse_dcf_dependencies, "remove_base_packages", mock_remove_base)
  
  temp_dir <- tempdir()
  desc_path <- file.path(temp_dir, "DESCRIPTION")
  
  writeLines(c(
    "Package: testpackage",
    "Title: A Sample Package",
    "Version: 0.1.0",
    "Depends: R (>= 3.5.0)",
    "Imports: dplyr, tidyr, ggplot2",
    "Suggests: testthat",
    "License: MIT"
  ), desc_path)
  
  deps <- parse_dcf_dependencies(temp_dir)
  
  expected_deps <- data.frame(
    type = c("Imports", "Imports", "Imports", "Suggests"),
    package = c("dplyr", "tidyr", "ggplot2", "testthat"),
    stringsAsFactors = FALSE
  )
  
  expect_equal(deps, expected_deps)
})

test_that("parse_dcf_dependencies extracts dependencies when CRAN is not available", {
  # Check CRAN availability
  cran_status <- capture_cran_warning("http://cran.us.r-project.org", "src/contrib/Meta/archive.rds")
  
  skip_if(
    is.null(cran_status$message),
    message = "Skipping test because CRAN is available"
  )
  
  temp_dir <- tempdir()
  desc_path <- file.path(temp_dir, "DESCRIPTION")
  
  writeLines(c(
    "Package: testpackage",
    "Title: A Sample Package",
    "Version: 0.1.0",
    "Depends: R (>= 3.5.0)",
    "Imports: dplyr, tidyr, ggplot2",
    "Suggests: testthat",
    "License: MIT"
  ), desc_path)
  
  deps <- parse_dcf_dependencies(temp_dir)
  
  expected_deps <- data.frame(
    type = c("Depends", "Imports", "Imports", "Imports", "Suggests"),
    package = c("R", "dplyr", "tidyr", "ggplot2", "testthat"),
    stringsAsFactors = FALSE
  )
  
  expect_equal(deps, expected_deps)
})


test_that("parse_dcf_dependencies extracts dependencies different format", {
  # Mock remove_base_packages to ensure the test works regardless of CRAN availability
  mockery::stub(parse_dcf_dependencies, "remove_base_packages", mock_remove_base)
  
  temp_dir <- tempdir()
  desc_path <- file.path(temp_dir, "DESCRIPTION")
  
  writeLines(c(
    "Package: testpackage",
    "Title: A Sample Package",
    "Version: 0.1.0",
    "Imports: ",
    "    rprojroot (>= 2.0.2)",
    "Suggests: ",
    "    conflicted,",
    "    covr,",
    "    fs,",
    "    knitr,",
    "    palmerpenguins,",
    "    plyr,",
    "    readr,",
    "    rlang,",
    "    rmarkdown,",
    "    testthat,",
    "    uuid,",
    "    withr"
  ), desc_path)
  
  deps <- parse_dcf_dependencies(temp_dir)
  
  expected_deps <- data.frame(
    type = c("Imports", "Suggests", "Suggests", "Suggests", "Suggests", "Suggests", "Suggests",
             "Suggests", "Suggests", "Suggests", "Suggests", "Suggests", "Suggests"),
    package = c("rprojroot", "conflicted", "covr", "fs", "knitr", "palmerpenguins",
                "plyr", "readr", "rlang", "rmarkdown", "testthat", "uuid", "withr"),
    stringsAsFactors = FALSE
  )
  
  expect_equal(deps, expected_deps)
})


test_that("remove_base_packages removes base and recommended packages", {
  # Fake CRAN metadata
  fake_cp <- data.frame(
    Package = c("stats", "utils", "dplyr", "ggplot2"),
    Priority = c("base", "recommended", NA, NA),
    stringsAsFactors = FALSE
  )
  
  # Input df
  df <- data.frame(
    package = c("stats", "utils", "dplyr", "R"),
    stringsAsFactors = FALSE
  )
  
  # Stub download.file to do nothing
  mockery::stub(remove_base_packages, "utils::download.file", NULL)
  
  # Stub readRDS to return our fake metadata
  mockery::stub(remove_base_packages, "readRDS", fake_cp)
  
  result <- remove_base_packages(df)
  
  expect_equal(result, "dplyr")
})


test_that("remove_base_packages keeps non-base packages", {
  fake_cp <- data.frame(
    Package = c("basepkg", "recpkg"),
    Priority = c("base", "recommended"),
    stringsAsFactors = FALSE
  )
  
  df <- data.frame(
    package = c("nonbase1", "nonbase2"),
    stringsAsFactors = FALSE
  )
  
  mockery::stub(remove_base_packages, "utils::download.file", NULL)
  mockery::stub(remove_base_packages, "readRDS", fake_cp)
  
  result <- remove_base_packages(df)
  
  expect_equal(result, c("nonbase1", "nonbase2"))
})


test_that("remove_base_packages removes 'R' even if not in CRAN metadata", {
  fake_cp <- data.frame(
    Package = c("foo"),
    Priority = c(NA),
    stringsAsFactors = FALSE
  )
  
  df <- data.frame(
    package = c("R", "foo"),
    stringsAsFactors = FALSE
  )
  
  mockery::stub(remove_base_packages, "utils::download.file", NULL)
  mockery::stub(remove_base_packages, "readRDS", fake_cp)
  
  result <- remove_base_packages(df)
  
  expect_equal(result, "foo")
})


test_that("remove_base_packages errors if download fails", {
  # Stub download.file to error
  mockery::stub(
    remove_base_packages,
    "utils::download.file",
    function(...) stop("network failure")
  )
  
  df <- data.frame(package = "dplyr", stringsAsFactors = FALSE)
  
  expect_message(
    remove_base_packages(df),
    "Failed to download or read CRAN package metadata"
  )
})


test_that("get_dependencies calls parse_dcf_dependencies and returns its value", {
  fake_path <- "/some/path/mypkg"
  fake_deps <- data.frame(package = c("dplyr", "rlang"), stringsAsFactors = FALSE)
  
  # Stub out parse_dcf_dependencies
  mockery::stub(get_dependencies, "parse_dcf_dependencies", fake_deps)
  
  # Stub basename to control the printed name
  mockery::stub(get_dependencies, "basename", "mypkg")
  
  # Capture messages
  msgs <- capture.output({
    result <- get_dependencies(fake_path)
  }, type = "message")
  
  # Expectations
  expect_equal(result, fake_deps)
  expect_true(any(grepl("getting package dependencies for mypkg", msgs)))
  expect_true(any(grepl("package dependencies successful for mypkg", msgs)))
})


test_that("get_dependencies passes pkg_source_path correctly to parse_dcf_dependencies", {
  fake_path <- "/tmp/testpkg"
  called_with <- NULL
  
  # stub parse_dcf_dependencies but record its argument
  mock_parse <- function(x) {
    called_with <<- x
    data.frame(package = "foo", stringsAsFactors = FALSE)
  }
  
  mockery::stub(get_dependencies, "parse_dcf_dependencies", mock_parse)
  mockery::stub(get_dependencies, "basename", "testpkg")
  
  get_dependencies(fake_path)
  
  expect_equal(called_with, fake_path)
})


test_that("get_dependencies prints messages with correct package name", {
  fake_path <- "/path/to/anotherpkg"
  
  mockery::stub(get_dependencies, "parse_dcf_dependencies",
                data.frame(package = "bar", stringsAsFactors = FALSE))
  mockery::stub(get_dependencies, "basename", "anotherpkg")
  
  msgs <- capture.output({
    get_dependencies(fake_path)
  }, type = "message")
  
  expect_true(any(grepl("getting package dependencies for anotherpkg", msgs)))
  expect_true(any(grepl("package dependencies successful for anotherpkg", msgs)))
})


test_that("get_dependencies returns what parse_dcf_dependencies provides", {
  fake_return <- data.frame(package = "test", stringsAsFactors = FALSE)
  
  mockery::stub(get_dependencies, "parse_dcf_dependencies", fake_return)
  mockery::stub(get_dependencies, "basename", "pkgname")
  
  result <- get_dependencies("whatever/path")
  
  expect_identical(result, fake_return)
})
