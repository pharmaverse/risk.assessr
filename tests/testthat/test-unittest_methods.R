# testthat

test_that("check_pkg_tests_and_snaps works as expected", {
  # Create a temp directory to act as our package
  pkg_dir <- tempfile("dummyPkg")
  dir.create(pkg_dir)
  
  # Create tests/testthat/_snaps structure
  testthat_dir <- file.path(pkg_dir, "tests", "testthat")
  snaps_dir <- file.path(testthat_dir, "_snaps")
  dir.create(snaps_dir, recursive = TRUE)
  
  # Create some dummy golden snapshot files
  file.create(file.path(snaps_dir, "snapshot1.md"))
  file.create(file.path(snaps_dir, "snapshot2.md"))
  
  # Call the function
  result <- check_pkg_tests_and_snaps(pkg_dir)
  
  # Check the results
  expect_true(result$has_testthat)
  expect_false(result$has_testit)
  expect_true(result$has_snaps)
  expect_equal(result$n_golden_tests, 2)
  
  # Clean up (optional)
  unlink(pkg_dir, recursive = TRUE)
})

test_that("works when both testthat and _snaps exist with files", {
  pkg_dir <- tempfile("dummyPkg1")
  dir.create(pkg_dir)
  
  testthat_dir <- file.path(pkg_dir, "tests", "testthat")
  snaps_dir <- file.path(testthat_dir, "_snaps")
  dir.create(snaps_dir, recursive = TRUE)
  
  file.create(file.path(snaps_dir, "snapshot1.md"))
  file.create(file.path(snaps_dir, "snapshot2.md"))
  
  result <- check_pkg_tests_and_snaps(pkg_dir)
  
  expect_true(result$has_testthat)
  expect_false(result$has_testit)  
  expect_true(result$has_snaps)
  expect_equal(result$n_golden_tests, 2)
  
  unlink(pkg_dir, recursive = TRUE)
})


test_that("works when testthat exists but _snaps does not", {
  pkg_dir <- tempfile("dummyPkg2")
  dir.create(pkg_dir)
  
  testthat_dir <- file.path(pkg_dir, "tests", "testthat")
  dir.create(testthat_dir, recursive = TRUE)
  
  result <- check_pkg_tests_and_snaps(pkg_dir)
  
  expect_true(result$has_testthat)
  expect_false(result$has_testit)  
  expect_false(result$has_snaps)
  expect_equal(result$n_golden_tests, 0)
  
  unlink(pkg_dir, recursive = TRUE)
})


test_that("works when neither testthat nor _snaps exist", {
  pkg_dir <- tempfile("dummyPkg3")
  dir.create(pkg_dir)
  
  result <- check_pkg_tests_and_snaps(pkg_dir)
  
  expect_false(result$has_testthat)
  expect_false(result$has_testit)  
  expect_false(result$has_snaps)
  expect_equal(result$n_golden_tests, 0)
  
  unlink(pkg_dir, recursive = TRUE)
})


test_that("works when _snaps exists but is empty", {
  pkg_dir <- tempfile("dummyPkg4")
  dir.create(pkg_dir)
  
  testthat_dir <- file.path(pkg_dir, "tests", "testthat")
  snaps_dir <- file.path(testthat_dir, "_snaps")
  dir.create(snaps_dir, recursive = TRUE)
  
  result <- check_pkg_tests_and_snaps(pkg_dir)
  
  expect_true(result$has_testthat)
  expect_false(result$has_testit)  
  expect_true(result$has_snaps)
  expect_equal(result$n_golden_tests, 0)
  
  unlink(pkg_dir, recursive = TRUE)
})


test_that("counts nested snapshot files", {
  pkg_dir <- tempfile("dummyPkg5")
  dir.create(pkg_dir)
  
  testthat_dir <- file.path(pkg_dir, "tests", "testthat")
  snaps_dir <- file.path(testthat_dir, "_snaps")
  nested_dir <- file.path(snaps_dir, "nested")
  dir.create(nested_dir, recursive = TRUE)
  
  file.create(file.path(snaps_dir, "snapshot1.md"))
  file.create(file.path(nested_dir, "snapshot2.md"))
  
  result <- check_pkg_tests_and_snaps(pkg_dir)
  
  expect_true(result$has_testthat)
  expect_false(result$has_testit)  
  expect_true(result$has_snaps)
  expect_equal(result$n_golden_tests, 2)
  
  unlink(pkg_dir, recursive = TRUE)
})


# testit

test_that("detects testit framework presence", {
  pkg_dir <- tempfile("dummyPkg_testit")
  dir.create(pkg_dir)
  
  testit_dir <- file.path(pkg_dir, "tests", "testit")
  dir.create(testit_dir, recursive = TRUE)
  
  result <- check_pkg_tests_and_snaps(pkg_dir)
  
  expect_false(result$has_testthat)
  expect_true(result$has_testit)  
  unlink(pkg_dir, recursive = TRUE)
})









