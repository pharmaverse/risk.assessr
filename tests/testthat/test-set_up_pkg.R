test_that("set up package for tar file with default check type", {
  dp_orig <- system.file("test-data", 
                         "test.package.0001_0.1.0.tar.gz", 
                         package = "risk.assessr")
  skip_if_test_data_missing(dp_orig)
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  install_list <- set_up_pkg(dp)
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(install_list$pkg_source_path, 
                      recursive = TRUE, force = TRUE), 
               envir = parent.frame())
  
  expect_identical(length(install_list), 4L)
  expect_true(checkmate::check_list(install_list, any.missing = FALSE))
  expect_true(checkmate::check_list(install_list, types = c("logical", 
                                                            "character", 
                                                            "list")))
})


test_that("set up package for tar file with check type 1", {
  dp_orig <- system.file("test-data", "test.package.0001_0.1.0.tar.gz", 
                         package = "risk.assessr")
  skip_if_test_data_missing(dp_orig)
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  withr::defer(unlink(dp), envir = parent.frame())
  
  check_type <- "1"
  install_list <- set_up_pkg(dp, check_type)
  
  withr::defer(unlink(install_list$pkg_source_path, 
                      recursive = TRUE, force = TRUE), envir = parent.frame())
  
  expect_identical(length(install_list), 4L)
  expect_true(checkmate::check_list(install_list, any.missing = FALSE))
  expect_true(checkmate::check_list(install_list, types = c("logical", 
                                                            "character", 
                                                            "list")))
})


test_that("set up package for tar file with check type 1", {    
  dp <- system.file("test-data", "test.package.0001_0.1.0.tar.gz", 
                    package = "risk.assessr")
  skip_if_test_data_missing(dp)
  
  check_type <- "1"
  
  # set up package
  install_list <- set_up_pkg(dp, 
                             check_type 
  )
  
  expect_identical(length(install_list), 4L)
  
  expect_true(checkmate::check_list(install_list, 
                                    any.missing = FALSE)
  )
  
  expect_true(checkmate::check_list(install_list, 
                                    types = c("logical",
                                              "character",
                                              "list")))
  
})  


test_that("set up package for tar file with check type 2", {
  dp_orig <- system.file("test-data", 
                         "test.package.0001_0.1.0.tar.gz", 
                         package = "risk.assessr")
  skip_if_test_data_missing(dp_orig)
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  withr::defer(unlink(dp), envir = parent.frame())
  
  check_type <- "2"
  install_list <- set_up_pkg(dp, check_type)
  
  withr::defer(unlink(install_list$pkg_source_path, 
                      recursive = TRUE, force = TRUE), 
               envir = parent.frame())
  
  expect_identical(length(install_list), 4L)
  expect_true(checkmate::check_list(install_list, any.missing = FALSE))
  expect_true(checkmate::check_list(install_list, types = c("logical", 
                                                            "character", 
                                                            "list")))
})


test_that("set_up_pkg handles zero-length pkg_source_path", {
  dp <- tempfile(fileext = ".tar.gz")
  file.create(dp)
  withr::defer(unlink(dp), envir = parent.frame())
  
  mockery::stub(set_up_pkg, "unpack_tarball", function(...) character(0))
  mockery::stub(set_up_pkg, "contains_vignette_folder", function(...) FALSE)
  
  install_list <- set_up_pkg(dp)
  
  expect_identical(length(install_list), 4L)
  expect_false(install_list$package_installed)
  expect_null(install_list$rcmdcheck_args)
  expect_true(checkmate::check_list(install_list,
                                    types = c("logical",
                                              "character",
                                              "NULL")))
})


test_that("set_up_pkg sets build_vignettes to TRUE when bv_result is FALSE", {
  dp <- tempfile(fileext = ".tar.gz")
  file.create(dp)
  withr::defer(unlink(dp), envir = parent.frame())
  
  mockery::stub(set_up_pkg, "unpack_tarball", function(...) "mock/path")
  mockery::stub(set_up_pkg, "contains_vignette_folder", function(...) FALSE)
  mockery::stub(set_up_pkg, "fs::file_exists", function(...) TRUE)
  mockery::stub(set_up_pkg, "setup_rcmdcheck_args",
                function(...) list(timeout = Inf,
                                   args = "--no-manual",
                                   build_args = NULL,
                                   env = "mockenv",
                                   quiet = TRUE))
  
  install_list <- set_up_pkg(dp)
  
  expect_true(install_list$build_vignettes)
})


test_that("set_up_pkg sets build_vignettes to FALSE when bv_result is TRUE", {
  dp <- tempfile(fileext = ".tar.gz")
  file.create(dp)
  withr::defer(unlink(dp), envir = parent.frame())
  
  mockery::stub(set_up_pkg, "unpack_tarball", function(...) "mock/path")
  mockery::stub(set_up_pkg, "contains_vignette_folder", function(...) TRUE)
  mockery::stub(set_up_pkg, "fs::file_exists", function(...) TRUE)
  mockery::stub(set_up_pkg, "setup_rcmdcheck_args",
                function(...) list(timeout = Inf,
                                   args = "--no-manual",
                                   build_args = NULL,
                                   env = "mockenv",
                                   quiet = TRUE))
  
  install_list <- set_up_pkg(dp)
  
  expect_false(install_list$build_vignettes)
})


test_that("set_up_pkg returns NULL rcmdcheck_args when pkg_source_path does not exist", {
  dp <- tempfile(fileext = ".tar.gz")
  file.create(dp)
  withr::defer(unlink(dp), envir = parent.frame())
  
  mockery::stub(set_up_pkg, "unpack_tarball", function(...) "non/existent/path")
  mockery::stub(set_up_pkg, "contains_vignette_folder", function(...) FALSE)
  mockery::stub(set_up_pkg, "fs::file_exists", function(...) FALSE)
  
  install_list <- set_up_pkg(dp)
  
  expect_false(install_list$package_installed)
  expect_null(install_list$rcmdcheck_args)
})
