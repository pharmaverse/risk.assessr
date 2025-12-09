test_that("contains_vignette_folder handles non-existent file", {
  expect_error(contains_vignette_folder("nonexistent_file.tar.gz"), "File does not exist")
})

test_that("contains_vignette_folder handles non-existent file", {
  expect_error(contains_vignette_folder("eezrfrfrr"), "File does not exist")
})

test_that("empty folder", {
  
  # Temporary directory for testing
  temp_dir <- tempdir()
  
  # Define the folder structure using the temporary directory
  main_dir <- file.path(temp_dir, "old_structure")
  
  # Step 1: Create the Folder Structure and Multiple .Rmd Files
  dir.create(main_dir, showWarnings = FALSE)
  
  # Step 2: Create the .tar Archive
  tar_file <- file.path(temp_dir, "old_structure.tar.gz")
  tar(tar_file, files = main_dir)
  
  # Ensure cleanup happens even if the test fails
  withr::defer(unlink(main_dir, recursive = TRUE))
  withr::defer(unlink(tar_file))
  
  # Check that the tar file contains .Rmd files
  expect_error(contains_vignette_folder(tar_file), "Error in untar: file is empty")
})

test_that("correct repo with Non-tar file throws an error", {
  tar_file <- system.file("test-data/check_vignettes", "got_vignette.teeeeeeear", package = "risk.assessr")
  expect_error(contains_vignette_folder(tar_file), "Unsupported file type. Please provide a .tar file.")
})

test_that("test on package with vignette folder", {
  tar_file <- system.file("test-data/check_vignettes", "got_vignette.tar.gz", package = "risk.assessr")
  expect_true(contains_vignette_folder(tar_file))
  expect_silent(contains_vignette_folder(tar_file))
})

test_that("test on package without vignette folder", {
  
  tar_file <- system.file("test-data/check_vignettes", "no_vignette.tar.gz", package = "risk.assessr")
  expect_false(contains_vignette_folder(tar_file))
  expect_silent(contains_vignette_folder(tar_file))
})

test_that("test on package with vignette folder but no .rmd file", {
  
  tar_file <- system.file("test-data/check_vignettes", "just_vignette_folder.tar.gz", package = "risk.assessr")
  expect_false(contains_vignette_folder(tar_file))
  expect_silent(contains_vignette_folder(tar_file))
})





