test_that("execute_coverage=FALSE runs coverage when tests are present", {
  
  # Safe stub: copy the fixture to a temp file
  fake_dl <- function(...) {
    tmp <- tempfile(fileext = ".tar.gz")
    file.copy(
      system.file("test-data", "stringr-1.5.1.tar.gz", 
                  package = "sanofi.risk.assessr"),
      tmp
    )
    tmp
  }
  
  fake_setup <- function(x) list(package_installed = TRUE, pkg_source_path = tempdir())
  
  mockery::stub(generate_traceability_matrix, "check_cran_package", TRUE)
  mockery::stub(generate_traceability_matrix, "remotes::download_version", fake_dl)
  
  mockery::stub(generate_traceability_matrix, "modify_description_file", function(x) x)
  mockery::stub(generate_traceability_matrix, "set_up_pkg", function(x) {
    list(package_installed = TRUE, pkg_source_path = tempdir())
  })
  
  mockery::stub(generate_traceability_matrix, "install_package_local", TRUE)
  mockery::stub(generate_traceability_matrix, "check_pkg_tests_and_snaps", function(path) {
    list(has_testthat = TRUE, has_testit = FALSE)
  })
  
  mockery::stub(generate_traceability_matrix, "run_coverage", function(...) list())
  mockery::stub(generate_traceability_matrix, "create_traceability_matrix", function(...) list())
  
  out <- generate_traceability_matrix("stringr", "1.5.1", execute_coverage = FALSE)
  expect_equal(out, list())
})

test_that("falls back to Bioconductor if CRAN download fails", {
  
  mockery::stub(generate_traceability_matrix, "tempfile", function(...) {
    file.path(tempdir(), "fallback_package.tar")
  })
  
  mockery::stub(generate_traceability_matrix, "check_cran_package", TRUE)
  mockery::stub(generate_traceability_matrix, "remotes::download_version", function(...) {
    stop("CRAN download failed due to timeout")
  })
  
  mockery::stub(generate_traceability_matrix, "fetch_bioconductor_releases", function() "html_content")
  mockery::stub(generate_traceability_matrix, "parse_bioconductor_releases", function(html) "release_data")
  mockery::stub(generate_traceability_matrix, "get_bioconductor_package_url", function(...) {
    list(url = "http://dummybioc.org/fallback.tar")
  })
  
  mockery::stub(generate_traceability_matrix, "download.file", function(url, destfile, ...) {
    pkg_dir <- file.path(tempdir(), "fallbackpkg")
    dir.create(pkg_dir, showWarnings = FALSE, recursive = TRUE)
    writeLines("Package: fallbackpkg\nVersion: 0.1\nAuthors@R: person('Fallback', 'User', email = 'fallback@example.com', role = 'aut')\n",
               file.path(pkg_dir, "DESCRIPTION"))
    old_wd <- getwd()
    on.exit(setwd(old_wd), add = TRUE)
    setwd(tempdir())
    utils::tar(destfile, files = "fallbackpkg", tar = "internal")
    0
  })
  
  mockery::stub(generate_traceability_matrix, "modify_description_file", function(x) x)
  mockery::stub(generate_traceability_matrix, "install_package_local", TRUE)
  mockery::stub(generate_traceability_matrix, "set_up_pkg", function(x) {
    list(package_installed = TRUE, pkg_source_path = tempdir())
  })
  mockery::stub(generate_traceability_matrix, "check_pkg_tests_and_snaps", function(path) {
    list(has_testthat = FALSE, has_testit = FALSE)
  })
  mockery::stub(generate_traceability_matrix, "run_coverage", function(...) list())
  mockery::stub(generate_traceability_matrix, "create_traceability_matrix", function(...) "fallback-success")
  
  result <- generate_traceability_matrix("SomePkg")
  expect_equal(result, "fallback-success")
})


test_that("downloads a package from Bioconductor if not on CRAN", {
  
  mockery::stub(generate_traceability_matrix, "tempfile", function(...) {
    file.path(tempdir(), "fake_package.tar")
  })
  
  mockery::stub(generate_traceability_matrix, "check_cran_package", FALSE)
  mockery::stub(generate_traceability_matrix, "fetch_bioconductor_releases", function() "html_content")
  mockery::stub(generate_traceability_matrix, "parse_bioconductor_releases", function(html) "release_data")
  mockery::stub(generate_traceability_matrix, "get_bioconductor_package_url", function(...) {
    list(url = "http://dummybioc.org/pkg.tar")
  })
  
  mockery::stub(generate_traceability_matrix, "download.file", function(url, destfile, ...) {
    pkg_dir <- file.path(tempdir(), "dummybiocpkg")
    dir.create(pkg_dir, showWarnings = FALSE, recursive = TRUE)
    writeLines("Package: dummybiocpkg\nVersion: 0.1\nAuthors@R: person('John', 'Doe', email = 'john@example.com', role = 'aut')\n",
               file.path(pkg_dir, "DESCRIPTION"))
    old_wd <- getwd()
    on.exit(setwd(old_wd), add = TRUE)
    setwd(tempdir())
    utils::tar(destfile, files = "dummybiocpkg", tar = "internal")
    0
  })
  
  mockery::stub(generate_traceability_matrix, "modify_description_file", function(x) x)
  mockery::stub(generate_traceability_matrix, "install_package_local", TRUE)
  mockery::stub(generate_traceability_matrix, "set_up_pkg", function(x) {
    list(package_installed = TRUE, pkg_source_path = tempdir())
  })
  mockery::stub(generate_traceability_matrix, "check_pkg_tests_and_snaps", function(path) {
    list(has_testthat = FALSE, has_testit = FALSE)
  })
  mockery::stub(generate_traceability_matrix, "run_coverage", function(...) list())
  mockery::stub(generate_traceability_matrix, "create_traceability_matrix", function(...) "bioc-success")
  
  result <- generate_traceability_matrix("Biobase")
  expect_equal(result, "bioc-success")
})

test_that("downloads a package from internal mirror if not on CRAN or Bioconductor", {
  
  mockery::stub(generate_traceability_matrix, "tempfile", function(...) {
    file.path(tempdir(), "internal_package.tar")
  })
  
  mockery::stub(generate_traceability_matrix, "check_cran_package", FALSE)
  
  mockery::stub(generate_traceability_matrix, "fetch_bioconductor_releases", function() "html")
  mockery::stub(generate_traceability_matrix, "parse_bioconductor_releases", function(html) "release_data")
  mockery::stub(generate_traceability_matrix, "get_bioconductor_package_url", function(...) {
    list(url = NULL)
  })
  
  mockery::stub(generate_traceability_matrix, "remotes::download_version", function(...) {
    destfile <- file.path(tempdir(), "internal_package.tar")
    pkg_dir <- file.path(tempdir(), "internalpkg")
    dir.create(pkg_dir, showWarnings = FALSE, recursive = TRUE)
    writeLines("Package: internalpkg\nVersion: 0.1\nAuthors@R: person('Jane', 'Smith', email = 'jane@example.com', role = 'aut')\n",
               file.path(pkg_dir, "DESCRIPTION"))
    old_wd <- getwd()
    on.exit(setwd(old_wd), add = TRUE)
    setwd(tempdir())
    utils::tar(destfile, files = "internalpkg", tar = "internal")
    return(destfile)
  })
  
  mockery::stub(generate_traceability_matrix, "modify_description_file", function(x) x)
  mockery::stub(generate_traceability_matrix, "install_package_local", TRUE)
  mockery::stub(generate_traceability_matrix, "set_up_pkg", function(x) {
    list(package_installed = TRUE, pkg_source_path = tempdir())
  })
  mockery::stub(generate_traceability_matrix, "check_pkg_tests_and_snaps", function(path) {
    list(has_testthat = FALSE, has_testit = FALSE)
  })
  mockery::stub(generate_traceability_matrix, "run_coverage", function(...) list())
  mockery::stub(generate_traceability_matrix, "create_traceability_matrix", function(...) "internal-success")
  
  result <- generate_traceability_matrix("InternalPkg")
  expect_equal(result, "internal-success")
})

test_that("return if package not found on CRAN, Bioconductor, or internal", {
  
  mockery::stub(generate_traceability_matrix, "tempfile", function(...) {
    file.path(tempdir(), "notfound_package.tar")
  })
  
  mockery::stub(generate_traceability_matrix, "check_cran_package", FALSE)
  mockery::stub(generate_traceability_matrix, "fetch_bioconductor_releases", function() "html")
  mockery::stub(generate_traceability_matrix, "parse_bioconductor_releases", function(html) "release_data")
  mockery::stub(generate_traceability_matrix, "get_bioconductor_package_url", function(...) {
    list(url = NULL)
  })
  
  mockery::stub(generate_traceability_matrix, "remotes::download_version", function(...) {
    stop("couldn't find package 'GhostPkg'")
  })
  
  expect_message(
    generate_traceability_matrix("GhostPkg"),
    regexp = "Failed to download the package from any source"
  )
  
  expect_null(generate_traceability_matrix("GhostPkg"))
})

test_that("downloads a package successfully from CRAN", {
  
  mockery::stub(generate_traceability_matrix, "check_cran_package", TRUE)
  mockery::stub(generate_traceability_matrix, "remotes::download_version", function(...) {
    destfile <- file.path(tempdir(), "cran_package.tar")
    pkg_dir <- file.path(tempdir(), "cranpkg")
    dir.create(pkg_dir, showWarnings = FALSE, recursive = TRUE)
    writeLines("Package: cranpkg\nVersion: 0.1\nAuthors@R: person('Chris', 'Doe', email = 'chris@example.com', role = 'aut')\n",
               file.path(pkg_dir, "DESCRIPTION"))
    old_wd <- getwd()
    on.exit(setwd(old_wd), add = TRUE)
    setwd(tempdir())
    utils::tar(destfile, files = "cranpkg", tar = "internal")
    return(destfile)
  })
  
  mockery::stub(generate_traceability_matrix, "modify_description_file", function(x) x)
  mockery::stub(generate_traceability_matrix, "install_package_local", TRUE)
  mockery::stub(generate_traceability_matrix, "set_up_pkg", function(x) {
    list(package_installed = TRUE, pkg_source_path = tempdir())
  })
  mockery::stub(generate_traceability_matrix, "check_pkg_tests_and_snaps", function(path) {
    list(has_testthat = FALSE, has_testit = FALSE)
  })
  mockery::stub(generate_traceability_matrix, "run_coverage", function(...) list())
  mockery::stub(generate_traceability_matrix, "create_traceability_matrix", function(...) "cran-success")
  
  result <- generate_traceability_matrix("ggplot2")  # Any known CRAN package name works here
  expect_equal(result, "cran-success")
})

test_that("uses manually specified repos when provided", {
  
  # dummy repo
  dummy_repo <- c(CRAN = "https://my.custom.repo")
  
  # Track if options() is called correctly
  original_options <- options()
  on.exit(options(original_options), add = TRUE)
  
  # Stub everything downstream so we don't rely on actual download
  mockery::stub(generate_traceability_matrix, "check_cran_package", FALSE)
  mockery::stub(generate_traceability_matrix, "fetch_bioconductor_releases", function() "")
  mockery::stub(generate_traceability_matrix, "parse_bioconductor_releases", function(html) NULL)
  mockery::stub(generate_traceability_matrix, "get_bioconductor_package_url", function(...) list(url = NULL))
  mockery::stub(generate_traceability_matrix, "remotes::download_version", function(...) {
    stop("all fallback failed")
  })
  
  expect_message(
    generate_traceability_matrix("nonexistentpkg", repos = dummy_repo),
    "Failed to download the package from any source"
  )
  
  expect_null(generate_traceability_matrix("nonexistentpkg", repos = dummy_repo))
  
  current_repos <- getOption("repos")
  expect_equal(current_repos[["CRAN"]], dummy_repo[["CRAN"]])
})

test_that("Coverage logic runs when tests are present", {
  # Setup
  mockery::stub(generate_traceability_matrix, 'check_pkg_tests_and_snaps', function(pkg_source_path) {
    list(has_testthat = TRUE, has_testit = FALSE)
  })
  mockery::stub(generate_traceability_matrix, 'run_coverage', function(pkg_source_path, covr_timeout) {
    list(res_cov = "mock_cov_results")
  })
  mockery::stub(generate_traceability_matrix, 'create_traceability_matrix', function(pkg_name, pkg_source_path, func_covr, execute_coverage) {
    list(traceability_matrix = "mock_matrix", coverage = func_covr)
  })
  mockery::stub(generate_traceability_matrix, 'check_cran_package', function(package_name) TRUE)
  mockery::stub(generate_traceability_matrix, 'remotes::download_version', function(package, version) tempfile())
  mockery::stub(generate_traceability_matrix, 'modify_description_file', function(temp_file) tempfile())
  mockery::stub(generate_traceability_matrix, 'set_up_pkg', function(modified_tar_file) list(package_installed = TRUE, pkg_source_path = "mock_path"))
  mockery::stub(generate_traceability_matrix, 'install_package_local', function(pkg_source_path) TRUE)
  
  # Execute
  result <- generate_traceability_matrix("mockpkg", execute_coverage = TRUE)
  expect_equal(result$coverage, "mock_cov_results")
})

test_that("Coverage logic skips when no tests are present", {
  # Setup
  mockery::stub(generate_traceability_matrix, 'check_pkg_tests_and_snaps', function(pkg_source_path) {
    list(has_testthat = FALSE, has_testit = FALSE)
  })
  mockery::stub(generate_traceability_matrix, 'run_coverage', function(pkg_source_path, covr_timeout) {
    stop("Should not be called")
  })
  mockery::stub(generate_traceability_matrix, 'create_traceability_matrix', function(pkg_name, pkg_source_path, func_covr, execute_coverage) {
    list(traceability_matrix = "mock_matrix", coverage = func_covr)
  })
  mockery::stub(generate_traceability_matrix, 'check_cran_package', function(package_name) TRUE)
  mockery::stub(generate_traceability_matrix, 'remotes::download_version', function(package, version) tempfile())
  mockery::stub(generate_traceability_matrix, 'modify_description_file', function(temp_file) tempfile())
  mockery::stub(generate_traceability_matrix, 'set_up_pkg', function(modified_tar_file) list(package_installed = TRUE, pkg_source_path = "mock_path"))
  mockery::stub(generate_traceability_matrix, 'install_package_local', function(pkg_source_path) TRUE)
  
  # Execute
  result <- generate_traceability_matrix("mockpkg", execute_coverage = TRUE)
  expect_null(result$coverage)
})

test_that("Coverage logic does not run when execute_coverage is FALSE", {
  # Setup
  mockery::stub(generate_traceability_matrix, 'check_pkg_tests_and_snaps', function(pkg_source_path) {
    stop("Should not be called")
  })
  mockery::stub(generate_traceability_matrix, 'run_coverage', function(pkg_source_path, covr_timeout) {
    stop("Should not be called")
  })
  mockery::stub(generate_traceability_matrix, 'create_traceability_matrix', function(pkg_name, pkg_source_path, func_covr, execute_coverage) {
    list(traceability_matrix = "mock_matrix", coverage = func_covr)
  })
  mockery::stub(generate_traceability_matrix, 'check_cran_package', function(package_name) TRUE)
  mockery::stub(generate_traceability_matrix, 'remotes::download_version', function(package, version) tempfile())
  mockery::stub(generate_traceability_matrix, 'modify_description_file', function(temp_file) tempfile())
  mockery::stub(generate_traceability_matrix, 'set_up_pkg', function(modified_tar_file) list(package_installed = TRUE, pkg_source_path = "mock_path"))
  mockery::stub(generate_traceability_matrix, 'install_package_local', function(pkg_source_path) TRUE)
  
  # Execute
  result <- generate_traceability_matrix("mockpkg", execute_coverage = FALSE)
  expect_null(result$coverage)
})