test_that("setup_rcmdcheck_args() returns the basic R CMD check shape for check_type = \"1\"", {
  
  rcmdcheck_args <- setup_rcmdcheck_args(check_type = "1",
                                         build_vignettes = FALSE)
  
  expect_identical(length(rcmdcheck_args), 5L)
  expect_true(checkmate::check_list(rcmdcheck_args, all.missing = FALSE))
  expect_true(checkmate::check_list(rcmdcheck_args, any.missing = FALSE))
  
  expect_true("--no-examples"      %in% rcmdcheck_args$args)
  expect_true("--ignore-vignettes" %in% rcmdcheck_args$args)
  expect_true("--no-vignettes"     %in% rcmdcheck_args$args)
  expect_true("--no-manual"        %in% rcmdcheck_args$args)
  expect_false("--no-tests"        %in% rcmdcheck_args$args)
  expect_false("--as-cran"         %in% rcmdcheck_args$args)
})

test_that("setup_rcmdcheck_args() returns the frugal shape for check_type = \"2\"", {
  # check_type = "2" is the frugal mode used by get_frugal_metrics():
  #   * args = basic-check args + --no-tests
  #   * build_args mirrors the basic branch (OS-aware)
  #   * shape is independent of build_vignettes (always length 5)
  
  for (bv in c(TRUE, FALSE)) {
    rcmdcheck_args <- setup_rcmdcheck_args(check_type = "2",
                                           build_vignettes = bv)
    
    expect_identical(length(rcmdcheck_args), 5L)
    expect_true(checkmate::check_list(rcmdcheck_args, all.missing = FALSE))
    expect_true(checkmate::check_list(rcmdcheck_args, any.missing = FALSE))
    
    expect_true("--no-tests"         %in% rcmdcheck_args$args)
    expect_true("--no-examples"      %in% rcmdcheck_args$args)
    expect_true("--ignore-vignettes" %in% rcmdcheck_args$args)
    expect_true("--no-vignettes"     %in% rcmdcheck_args$args)
    expect_true("--no-manual"        %in% rcmdcheck_args$args)
    expect_false("--as-cran"         %in% rcmdcheck_args$args)
    
    expect_named(rcmdcheck_args,
                 c("timeout", "args", "build_args", "env", "quiet"),
                 ignore.order = TRUE)
  }
})

test_that("setup_rcmdcheck_args() preserves CRAN-like behaviour for non-\"1\"/non-\"2\" check_type values", {
  # The original CRAN-as-cran branch is now reachable via any check_type
  # that is neither "1" nor "2" (e.g. "3").
  
  cran_no_bv <- setup_rcmdcheck_args(check_type = "3", build_vignettes = FALSE)
  expect_identical(length(cran_no_bv), 5L)
  expect_true(checkmate::check_list(cran_no_bv, all.missing = FALSE))
  expect_true(checkmate::check_list(cran_no_bv, any.missing = FALSE))
  expect_true("--as-cran" %in% cran_no_bv$args)
  expect_true("build_args" %in% names(cran_no_bv))
  
  cran_bv <- setup_rcmdcheck_args(check_type = "3", build_vignettes = TRUE)
  # When build_vignettes = TRUE the CRAN branch intentionally omits build_args
  # so the package's vignettes get built during R CMD check (length 4).
  expect_identical(length(cran_bv), 4L)
  expect_true(checkmate::check_list(cran_bv, all.missing = FALSE))
  expect_true(checkmate::check_list(cran_bv, any.missing = FALSE))
  expect_true("--as-cran" %in% cran_bv$args)
  expect_false("build_args" %in% names(cran_bv))
})

test_that("setup_rcmdcheck_args() build_args is OS-aware for check_type = \"1\"", {
  skip_if_not_installed("mockery")
  
  mockery::stub(setup_rcmdcheck_args, "Sys.info",
                function() c(sysname = "Windows"))
  expect_equal(
    setup_rcmdcheck_args(check_type = "1", build_vignettes = FALSE)$build_args,
    c("--no-build-vignettes", "--no-manual")
  )
  
  mockery::stub(setup_rcmdcheck_args, "Sys.info",
                function() c(sysname = "Linux"))
  expect_equal(
    setup_rcmdcheck_args(check_type = "1", build_vignettes = FALSE)$build_args,
    "--no-build-vignettes"
  )
})

test_that("setup_rcmdcheck_args() build_args is OS-aware for check_type = \"2\" (frugal)", {
  skip_if_not_installed("mockery")
  
  mockery::stub(setup_rcmdcheck_args, "Sys.info",
                function() c(sysname = "Windows"))
  expect_equal(
    setup_rcmdcheck_args(check_type = "2", build_vignettes = FALSE)$build_args,
    c("--no-build-vignettes", "--no-manual")
  )
  
  mockery::stub(setup_rcmdcheck_args, "Sys.info",
                function() c(sysname = "Linux"))
  expect_equal(
    setup_rcmdcheck_args(check_type = "2", build_vignettes = FALSE)$build_args,
    "--no-build-vignettes"
  )
})
