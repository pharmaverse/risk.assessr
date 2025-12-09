test_that("contains_r_folder works correctly", {

  # Create a temporary directory for testing
  temp_dir <- tempdir()

  # Create a toy dataset
  toy_dataset <- function(dir_name) {
    fs::dir_create(fs::path(temp_dir, dir_name))
  }

  # Case 1: Directory with 'R' folder
  toy_dataset("package_with_R")
  fs::dir_create(fs::path(temp_dir, "package_with_R", "R"))
  expect_true(contains_r_folder(fs::path(temp_dir, "package_with_R")))
  
  # Case 2: Directory without 'R' folder
  toy_dataset("package_without_R")
  expect_false(contains_r_folder(fs::path(temp_dir, "package_without_R")))
  
  # Clean up
  fs::dir_delete(fs::path(temp_dir, "package_with_R"))
  fs::dir_delete(fs::path(temp_dir, "package_without_R"))
})
