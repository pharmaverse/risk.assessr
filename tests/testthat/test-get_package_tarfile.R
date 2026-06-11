test_that("falls back to Bioconductor if CRAN download fails", {
  # Counter to simulate first download (CRAN) failing, second (Bioc) succeeding
  call_i <- 0
  
  # Fail the configured-repos attempt offline so it does not hit the network
  # (utils::available.packages() otherwise warns "unable to access index").
  mockery::stub(get_package_tarfile, "remotes::download_version",
                function(...) stop("simulated: package not in configured repos"))
  mockery::stub(get_package_tarfile, "check_cran_package", TRUE)
  mockery::stub(get_package_tarfile, "check_and_fetch_cran_package", function(package_name, package_version = NULL) {
    list(package_url = sprintf("https://cran.r-project.org/src/contrib/%s_%s.tar.gz",
                               package_name, ifelse(is.null(package_version), "0.1", package_version)))
  })
  
  # download.file: first call throws, second call creates tarball
  mockery::stub(get_package_tarfile, "download.file", function(url, destfile, ...) {
    call_i <<- call_i + 1
    if (call_i == 1) stop("CRAN download failed due to timeout")
    make_tarball(destfile, pkg_name = "fallbackpkg", version = "0.1")
    0
  })
  
  mockery::stub(get_package_tarfile, "fetch_bioconductor_releases", function() "html_content")
  mockery::stub(get_package_tarfile, "parse_bioconductor_releases", function(html) "release_data")
  mockery::stub(get_package_tarfile, "get_bioconductor_package_url", function(...) {
    list(url = "http://dummybioc.org/fallback.tar")
  })
  
  path <- get_package_tarfile("SomePkg")
  expect_true(file.exists(path))
  expect_match(normalizePath(path), "tar\\.gz$")
})

test_that("downloads a package from Bioconductor if not on CRAN", {
  mockery::stub(get_package_tarfile, "remotes::download_version",
                function(...) stop("simulated: package not in configured repos"))
  mockery::stub(get_package_tarfile, "check_cran_package", FALSE)
  mockery::stub(get_package_tarfile, "fetch_bioconductor_releases", function() "html_content")
  mockery::stub(get_package_tarfile, "parse_bioconductor_releases", function(html) "release_data")
  mockery::stub(get_package_tarfile, "get_bioconductor_package_url", function(...) {
    list(url = "http://dummybioc.org/pkg.tar")
  })
  mockery::stub(get_package_tarfile, "download.file", function(url, destfile, ...) {
    make_tarball(destfile, pkg_name = "dummybiocpkg", version = "0.1")
    0
  })
  
  path <- get_package_tarfile("Biobase")
  expect_true(file.exists(path))
})

test_that("downloads a package from internal mirror if not on CRAN or Bioconductor", {
  mockery::stub(get_package_tarfile, "remotes::download_version",
                function(...) stop("simulated: package not in configured repos"))
  mockery::stub(get_package_tarfile, "check_cran_package", FALSE)
  mockery::stub(get_package_tarfile, "fetch_bioconductor_releases", function() "html")
  mockery::stub(get_package_tarfile, "parse_bioconductor_releases", function(html) "release_data")
  mockery::stub(get_package_tarfile, "get_bioconductor_package_url", function(...) list(url = NULL))
  
  # NOTE: your function must call: get_internal_package_url(package_name, version)
  mockery::stub(get_package_tarfile, "get_internal_package_url", function(package_name, version = NULL, base_url = NULL) {
    list(
      url = "https://internal.example/repo/src/contrib/InternalPkg_0.1.tar.gz",
      last_version = list(version = "0.1", date = as.Date("2023-01-01")),
      all_versions = list(list(version = "0.1", date = as.Date("2023-01-01"))),
      repo_id = "123", repo_name = "internal-repo"
    )
  })
  
  mockery::stub(get_package_tarfile, "download.file", function(url, destfile, mode = "wb", quiet = TRUE) {
    make_tarball(destfile, pkg_name = "internalpkg", version = "0.1")
    0
  })
  
  path <- get_package_tarfile("InternalPkg")
  expect_true(file.exists(path))
})

test_that("errors if package not found on CRAN, Bioconductor, or internal", {
  mockery::stub(get_package_tarfile, "remotes::download_version",
                function(...) stop("simulated: package not in configured repos"))
  mockery::stub(get_package_tarfile, "check_cran_package", FALSE)
  mockery::stub(get_package_tarfile, "fetch_bioconductor_releases", function() "html")
  mockery::stub(get_package_tarfile, "parse_bioconductor_releases", function(html) "release_data")
  mockery::stub(get_package_tarfile, "get_bioconductor_package_url", function(...) list(url = NULL))
  
  # Internal returns nothing useful
  mockery::stub(get_package_tarfile, "get_internal_package_url", function(package_name, version = NULL, base_url = NULL) {
    list(url = NULL)
  })
  
  # Now we expect an error, not a message + NULL
  expect_error(
    get_package_tarfile("GhostPkg"),
    regexp = "Failed to obtain package tarball|Failed to find the package URL|Failed to download"
  )
})



test_that("downloads a package successfully from CRAN", {
  mockery::stub(get_package_tarfile, "remotes::download_version",
                function(...) stop("simulated: package not in configured repos"))
  mockery::stub(get_package_tarfile, "check_cran_package", TRUE)
  mockery::stub(get_package_tarfile, "check_and_fetch_cran_package", function(package_name, package_version = NULL) {
    list(package_url = sprintf("https://cran.r-project.org/src/contrib/%s_%s.tar.gz",
                               package_name, ifelse(is.null(package_version), "0.1", package_version)))
  })
  mockery::stub(get_package_tarfile, "download.file", function(url, destfile, ...) {
    make_tarball(destfile, pkg_name = "cranpkg", version = "0.1")
    0
  })
  
  path <- get_package_tarfile("ggplot2")
  expect_true(file.exists(path))
})

test_that("uses manually specified repos when provided (and restores them afterward)", {
  
  # Save original repos to check restoration
  old_repos <- getOption("repos")
  
  # Dummy repo to set during the call
  dummy_repo <- c(CRAN = "https://my.custom.repo")
  
  mockery::stub(
    get_package_tarfile,
    "remotes::download_version",
    function(...) stop("simulated download failure")
  )
  
  # Force a failure path so that get_package_tarfile errors
  mockery::stub(get_package_tarfile, "check_cran_package", FALSE)
  mockery::stub(get_package_tarfile, "fetch_bioconductor_releases", function() "")
  mockery::stub(get_package_tarfile, "parse_bioconductor_releases", function(html) NULL)
  mockery::stub(get_package_tarfile, "get_bioconductor_package_url", function(...) list(url = NULL))
  mockery::stub(get_package_tarfile, "get_internal_package_url", function(...) list(url = NULL))
  
  expect_error(
    get_package_tarfile("nonexistentpkg", repos = dummy_repo),
    regexp = "Failed to obtain package tarball|Failed to find the package URL|Failed to download"
  )
  
  # Optional: ensure repos are restored after error
  expect_identical(getOption("repos"), old_repos)
})

