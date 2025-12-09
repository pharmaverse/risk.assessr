
test_that("set up package for tar file with default check type", {
  dp_orig <- system.file("test-data", 
                         "test.package.0001_0.1.0.tar.gz", 
                         package = "risk.assessr")
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
  # Create a dummy tarball path
  dp <- tempfile(fileext = ".tar.gz")
  file.create(dp)
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Stub unpack_tarball to simulate failure
  mockery::stub(set_up_pkg, "unpack_tarball", function(...) character(0))
  
  # Stub contains_vignette_folder to return FALSE
  mockery::stub(set_up_pkg, "contains_vignette_folder", function(...) FALSE)
  
  # Stub setup_rcmdcheck_args to avoid error if called
  mockery::stub(set_up_pkg, "rcmdcheck_args", 
                function(...) list(timeout = Inf, 
                                   args = "--no-manual", 
                                   build_args = NULL, 
                                   env = "mockenv", 
                                   quiet = TRUE))
  
  install_list <- set_up_pkg(dp)
  
  expect_identical(length(install_list), 4L)
  expect_true(checkmate::check_list(install_list, any.missing = FALSE))
  expect_true(checkmate::check_list(install_list, 
                                    types = c("logical", 
                                              "character", 
                                              "list",
                                              "function")))
})


test_that("set_up_pkg sets build_vignettes to TRUE when bv_result is FALSE", {
  dp <- tempfile(fileext = ".tar.gz")
  file.create(dp)
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Stub unpack_tarball to return a dummy path
  mockery::stub(set_up_pkg, "unpack_tarball", function(...) "mock/path")
  
  # Stub contains_vignette_folder to return FALSE
  mockery::stub(set_up_pkg, "contains_vignette_folder", function(...) FALSE)
  
  # Stub fs::file_exists to return TRUE
  mockery::stub(set_up_pkg, "fs::file_exists", function(...) TRUE)
  
  # Stub setup_rcmdcheck_args to return dummy args
  mockery::stub(set_up_pkg, "rcmdcheck_args", 
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
  
  # Stub unpack_tarball to return a dummy path
  mockery::stub(set_up_pkg, "unpack_tarball", function(...) "mock/path")
  
  # Stub contains_vignette_folder to return TRUE
  mockery::stub(set_up_pkg, "contains_vignette_folder", function(...) TRUE)
  
  # Stub fs::file_exists to return TRUE
  mockery::stub(set_up_pkg, "fs::file_exists", function(...) TRUE)
  
  # Stub setup_rcmdcheck_args to return dummy args
  mockery::stub(set_up_pkg, "rcmdcheck_args", 
                function(...) list(timeout = Inf, 
                                   args = "--no-manual", 
                                   build_args = NULL, 
                                   env = "mockenv", 
                                   quiet = TRUE))
  
  install_list <- set_up_pkg(dp)
  
  expect_false(install_list$build_vignettes)
})

