test_that("get package description works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz", 
                    package = "risk.assessr")
 
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  if (package_installed == TRUE ) {	
    pkg_desc <- get_pkg_desc(pkg_source_path)
    
    expect_identical(length(pkg_desc), 17L)
    
    expect_true(checkmate::check_list(pkg_desc, 
                                            any.missing = FALSE)
    )
    
    expect_true(checkmate::check_list(pkg_desc, 
                                      types = "character")
    )
    
  }
  
})


test_that("get_risk_metadata returns correct metadata with executor", {
  # Mocked values
  fake_time <- "2025-09-30 12:00:00"
  fake_sysinfo <- list(
    sysname = "Linux",
    version = "#1 SMP Debian",
    release = "5.10.0-8-amd64",
    machine = "x86_64"
  )
  
  # Stub system functions
  mockery::stub(get_risk_metadata, "Sys.time", function() fake_time)
  mockery::stub(get_risk_metadata, "Sys.info", function() fake_sysinfo)
  
  result <- get_risk_metadata(executor = "edward")
  
  expect_equal(result$datetime, fake_time)
  expect_equal(result$executor, "edward")
  expect_equal(result$info$sys, fake_sysinfo)
})

test_that("get_risk_metadata returns correct metadata without executor", {
  # Mocked values
  fake_time <- "2025-09-30 12:00:00"
  fake_user <- "mock_user"
  fake_sysinfo <- list(
    sysname = "Darwin",
    version = "22.6.0",
    release = "macOS",
    machine = "arm64"
  )
  
  # Stub system functions
  mockery::stub(get_risk_metadata, "Sys.time", function() fake_time)
  mockery::stub(get_risk_metadata, "Sys.getenv", function(var) {
    if (var == "USER") return(fake_user)
  })
  mockery::stub(get_risk_metadata, "Sys.info", function() fake_sysinfo)
  
  result <- get_risk_metadata()
  
  expect_equal(result$datetime, fake_time)
  expect_equal(result$executor, fake_user)
  expect_equal(result$info$sys, fake_sysinfo)
})


test_that("get_result_path returns correct path for check.rds", {
  # Stub basename and file.path
  mockery::stub(get_result_path, "basename", function(path) "mockpkg")
  mockery::stub(get_result_path, "file.path", function(out_dir, filename) {
    paste0(out_dir, "/", filename)
  })
  
  result <- get_result_path("some/fake/path", ext = "check.rds")
  expect_equal(result, "some/fake/path/mockpkg.check.rds")
})

test_that("get_result_path returns correct path for covr.rds", {
  mockery::stub(get_result_path, "basename", function(path) "mockpkg")
  mockery::stub(get_result_path, "file.path", function(out_dir, filename) {
    paste0(out_dir, "/", filename)
  })
  
  result <- get_result_path("another/path", ext = "covr.rds")
  expect_equal(result, "another/path/mockpkg.covr.rds")
})

test_that("get_result_path defaults to check.rds when ext is not specified", {
  mockery::stub(get_result_path, "basename", function(path) "mockpkg")
  mockery::stub(get_result_path, "file.path", function(out_dir, filename) {
    paste0(out_dir, "/", filename)
  })
  
  result <- get_result_path("default/path")
  expect_equal(result, "default/path/mockpkg.check.rds")
})
