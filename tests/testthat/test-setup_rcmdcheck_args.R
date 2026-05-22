test_that("test setup_rcmdcheck_args", {

  check_type <- "1"
  
  rcmdcheck_args <- setup_rcmdcheck_args(check_type, 
                                                             build_vignettes)
  
  expect_identical(length(rcmdcheck_args), 5L)
  
  expect_true(checkmate::check_list(rcmdcheck_args, all.missing = FALSE))
  
  expect_true(checkmate::check_list(rcmdcheck_args, any.missing = FALSE))
  
  check_type <- "2"
  
  build_vignettes <- FALSE
  
  rcmdcheck_args <- setup_rcmdcheck_args(check_type, 
                                                             build_vignettes)
  
  expect_identical(length(rcmdcheck_args), 5L)
  
  expect_true(checkmate::check_list(rcmdcheck_args, all.missing = FALSE))
  
  expect_true(checkmate::check_list(rcmdcheck_args, any.missing = FALSE))
  
  check_type <- "2"
  
  build_vignettes <- TRUE
  
  rcmdcheck_args <- setup_rcmdcheck_args(check_type, 
                                                             build_vignettes)
  
  expect_identical(length(rcmdcheck_args), 4L)
  
  expect_true(checkmate::check_list(rcmdcheck_args, all.missing = FALSE))
  
  expect_true(checkmate::check_list(rcmdcheck_args, any.missing = FALSE))

})

test_that("build_args is set correctly based on OS", {
  # Mock Sys.info to return "Windows"
  mock_sys_info <- mockery::mock(list(sysname = "Windows"))
  mockery::stub(Sys.info, "Sys.info", mock_sys_info)
  
  build_args <- if (mock_sys_info()[["sysname"]] == "Windows") {
    c("--no-build-vignettes", # do not build vignette outputs
      "--no-manual") # disable pdf manual rendering on Windows
  } else {
    c("--no-build-vignettes") # do not build vignette outputs
  }
  
  expect_equal(build_args, c("--no-build-vignettes", "--no-manual"))
  
  # Mock Sys.info to return "Linux"
  mock_sys_info <- mockery::mock(list(sysname = "Linux"))
  mockery::stub(Sys.info, "Sys.info", mock_sys_info)
  
  build_args <- if (mock_sys_info()[["sysname"]] == "Windows") {
    c("--no-build-vignettes", # do not build vignette outputs
      "--no-manual") # disable pdf manual rendering on Windows
  } else {
    c("--no-build-vignettes") # do not build vignette outputs
  }
  
  expect_equal(build_args, c("--no-build-vignettes"))
})