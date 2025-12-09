test_that("falls back to Bioconductor if CRAN download fails", {

  mockery::stub(assess_pkg_r_package, "tempfile", function(...) {
    file.path(tempdir(), "fallback_package.tar")
  })
  
  mockery::stub(assess_pkg_r_package, "risk.assessr::check_cran_package", TRUE)
  mockery::stub(assess_pkg_r_package, "remotes::download_version", function(...) {
    stop("CRAN download failed due to timeout")
  })
  
  mockery::stub(assess_pkg_r_package, "fetch_bioconductor_releases", function() "html_content")
  mockery::stub(assess_pkg_r_package, "parse_bioconductor_releases", function(html) "release_data")
  mockery::stub(assess_pkg_r_package, "get_bioconductor_package_url", function(...) {
    list(url = "http://dummybioc.org/fallback.tar")
  })
  
  mockery::stub(assess_pkg_r_package, "download.file", function(url, destfile, ...) {
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
  
  mockery::stub(assess_pkg_r_package, "modify_description_file", function(x) x)
  mockery::stub(assess_pkg_r_package, "install_package_local", TRUE)
  mockery::stub(assess_pkg_r_package, "assess_pkg", "fallback-success")
  
  result <- assess_pkg_r_package("SomePkg")
  expect_equal(result, "fallback-success")
})


test_that("downloads a package from Bioconductor if not on CRAN", {

  mockery::stub(assess_pkg_r_package, "tempfile", function(...) {
    file.path(tempdir(), "fake_package.tar")
  })

  mockery::stub(assess_pkg_r_package, "risk.assessr::check_cran_package", FALSE)
  mockery::stub(assess_pkg_r_package, "fetch_bioconductor_releases", function() "html_content")
  mockery::stub(assess_pkg_r_package, "parse_bioconductor_releases", function(html) "release_data")
  mockery::stub(assess_pkg_r_package, "get_bioconductor_package_url", function(...) {
    list(url = "http://dummybioc.org/pkg.tar")
  })

  mockery::stub(assess_pkg_r_package, "download.file", function(url, destfile, ...) {
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

  mockery::stub(assess_pkg_r_package, "modify_description_file", function(x) x)
  mockery::stub(assess_pkg_r_package, "install_package_local", TRUE)
  mockery::stub(assess_pkg_r_package, "assess_pkg", "bioc-success")

  result <- assess_pkg_r_package("Biobase")
  expect_equal(result, "bioc-success")
})


test_that("downloads a package from internal mirror if not on CRAN or Bioconductor", {
  
  mockery::stub(assess_pkg_r_package, "tempfile", function(...) {
    file.path(tempdir(), "internal_package.tar")
  })
  
  mockery::stub(assess_pkg_r_package, "risk.assessr::check_cran_package", FALSE)
  
  mockery::stub(assess_pkg_r_package, "fetch_bioconductor_releases", function() "html")
  mockery::stub(assess_pkg_r_package, "parse_bioconductor_releases", function(html) "release_data")
  mockery::stub(assess_pkg_r_package, "get_bioconductor_package_url", function(...) {
    list(url = NULL)
  })
  
  # Mock get_internal_package_url to return a valid URL
  mockery::stub(assess_pkg_r_package, "get_internal_package_url", function(package_name, version = NULL, base_url = NULL) {
    list(
      url = "https://internal-repo.com/repo/latest/src/contrib/InternalPkg_0.1.tar.gz",
      last_version = list(version = "0.1", date = as.Date("2023-01-01")),
      all_versions = list(list(version = "0.1", date = as.Date("2023-01-01"))),
      repo_id = "123",
      repo_name = "internal-repo"
    )
  })
  
  # Mock download.file to simulate successful download
  mockery::stub(assess_pkg_r_package, "download.file", function(url, destfile, mode = "wb", quiet = TRUE) {
    # Create a mock package tar file
    pkg_dir <- file.path(tempdir(), "internalpkg")
    dir.create(pkg_dir, showWarnings = FALSE, recursive = TRUE)
    writeLines("Package: internalpkg\nVersion: 0.1\nAuthors@R: person('Jane', 'Smith', email = 'jane@example.com', role = 'aut')\n",
               file.path(pkg_dir, "DESCRIPTION"))
    old_wd <- getwd()
    on.exit(setwd(old_wd), add = TRUE)
    setwd(tempdir())
    utils::tar(destfile, files = "internalpkg", tar = "internal")
    return(0) # Return 0 to indicate success
  })
  
  mockery::stub(assess_pkg_r_package, "modify_description_file", function(x) x)
  mockery::stub(assess_pkg_r_package, "install_package_local", TRUE)
  mockery::stub(assess_pkg_r_package, "assess_pkg", "internal-success")
  
  result <- assess_pkg_r_package("InternalPkg")
  expect_equal(result, "internal-success")
})




test_that("return if package not found on CRAN, Bioconductor, or internal", {

  mockery::stub(assess_pkg_r_package, "tempfile", function(...) {
    file.path(tempdir(), "notfound_package.tar")
  })

  mockery::stub(assess_pkg_r_package, "risk.assessr::check_cran_package", FALSE)
  mockery::stub(assess_pkg_r_package, "fetch_bioconductor_releases", function() "html")
  mockery::stub(assess_pkg_r_package, "parse_bioconductor_releases", function(html) "release_data")
  mockery::stub(assess_pkg_r_package, "get_bioconductor_package_url", function(...) {
    list(url = NULL)
  })

  mockery::stub(assess_pkg_r_package, "remotes::download_version", function(...) {
    stop("couldn't find package 'GhostPkg'")
  })

  expect_message(
    assess_pkg_r_package("GhostPkg"),
    regexp = "Failed to download the package from any source"
  )

  expect_null(assess_pkg_r_package("GhostPkg"))
})


test_that("downloads a package successfully from CRAN", {

  mockery::stub(assess_pkg_r_package, "risk.assessr::check_cran_package", TRUE)
  mockery::stub(assess_pkg_r_package, "remotes::download_version", function(...) {
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

  mockery::stub(assess_pkg_r_package, "modify_description_file", function(x) x)
  mockery::stub(assess_pkg_r_package, "install_package_local", TRUE)
  mockery::stub(assess_pkg_r_package, "assess_pkg", "cran-success")
  result <- assess_pkg_r_package("ggplot2")  # Any known CRAN package name works here
  expect_equal(result, "cran-success")
})

test_that("uses manually specified repos when provided", {

  # dummy repo
  dummy_repo <- c(CRAN = "https://my.custom.repo")

  # Track if options() is called correctly
  original_options <- options()
  on.exit(options(original_options), add = TRUE)

  # Stub everything downstream so we don't rely on actual download
  mockery::stub(assess_pkg_r_package, "risk.assessr::check_cran_package", FALSE)
  mockery::stub(assess_pkg_r_package, "fetch_bioconductor_releases", function() "")
  mockery::stub(assess_pkg_r_package, "parse_bioconductor_releases", function(html) NULL)
  mockery::stub(assess_pkg_r_package, "get_bioconductor_package_url", function(...) list(url = NULL))
  mockery::stub(assess_pkg_r_package, "remotes::download_version", function(...) {
    stop("all fallback failed")
  })

  expect_message(
    assess_pkg_r_package("nonexistentpkg", repos = dummy_repo),
    "Failed to download the package from any source"
  )

  expect_null(assess_pkg_r_package("nonexistentpkg", repos = dummy_repo))

  current_repos <- getOption("repos")
  expect_equal(current_repos[["CRAN"]], dummy_repo[["CRAN"]])
})

