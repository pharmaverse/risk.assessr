test_that("modify_description_file modifies DESCRIPTION correctly", {

  dp <- system.file("test-data", "test.package.0001_0.1.0.tar.gz",
                    package = "risk.assessr")

  # Check if the file exists before attempting to download
  if (!file.exists(dp)) {
    stop("The tar file does not exist at the specified path.")
  }

  # Create a temporary file to store the downloaded package
  file_name <- basename(dp) # Use the base name for temporary file
  temp_file <- file.path(tempdir(), file_name)

  # Copy the file to the temporary file instead of downloading it
  file.copy(dp, temp_file, overwrite = TRUE)

  # Verify that the copy was successful
  if (!file.exists(temp_file)) {
    stop("File copy failed: temporary file not found.")
  }

  # Run the function to modify the DESCRIPTION file
  package_name <- "test.package.0001"
  modified_tar_file <- modify_description_file(temp_file)

  # Extract the modified tarball to a temporary directory
  temp_dir <- tempdir()
  untar(modified_tar_file, exdir = temp_dir)

  # Check if the DESCRIPTION file exists in the modified package directory
  package_dir <- file.path(temp_dir, package_name)

  if (!dir.exists(package_dir)) {
    stop("Package directory not found after untarring.")
  }

  description_file <- file.path(package_dir, "DESCRIPTION")
  expect_true(file.exists(description_file))

  # Check if the DESCRIPTION file contains the new line
  description_content <- readLines(description_file)
  expect_true("Config/build/clean-inst-doc: false" %in% description_content)

  # Clean up temporary files
  withr::defer(unlink(temp_file))  # Remove the temporary tar file
  withr::defer(unlink(temp_dir, recursive = TRUE))
})


test_that("modify_description_file modifies DESCRIPTION correctly 1bis", {

  dp <- system.file("test-data", "test.package.0005_0.1.0.tar.gz",
                    package = "risk.assessr")

  # Check if the file exists before attempting to download
  if (!file.exists(dp)) {
    stop("The tar file does not exist at the specified path.")
  }

  # Create a temporary file to store the downloaded package
  file_name <- basename(dp) # Use the base name for temporary file
  temp_file <- file.path(tempdir(), file_name)

  # Copy the file to the temporary file instead of downloading it
  file.copy(dp, temp_file, overwrite = TRUE)

  # Verify that the copy was successful
  if (!file.exists(temp_file)) {
    stop("File copy failed: temporary file not found.")
  }

  # Run the function to modify the DESCRIPTION file
  package_name <- "test.package.0005"
  modified_tar_file <- modify_description_file(temp_file)

  # Extract the modified tarball to a temporary directory
  temp_dir <- tempdir()
  untar(modified_tar_file, exdir = temp_dir)

  # Check if the DESCRIPTION file exists in the modified package directory
  package_dir <- file.path(temp_dir, package_name)

  if (!dir.exists(package_dir)) {
    stop("Package directory not found after untarring.")
  }

  description_file <- file.path(package_dir, "DESCRIPTION")
  expect_true(file.exists(description_file))

  # Check if the DESCRIPTION file contains the new line
  description_content <- readLines(description_file)
  expect_true("Config/build/clean-inst-doc: false" %in% description_content)

  # Clean up temporary files
  withr::defer(unlink(temp_file))  # Remove the temporary tar file
  withr::defer(unlink(temp_dir, recursive = TRUE))
})

test_that("modify_description_file modifies DESCRIPTION correctly 2", {
  
  # Create separate temporary directories for creation and extraction
  temp_dir_create <- tempdir()
  temp_dir_extract <- tempdir()
  
  # Create a subdirectory to mimic a package directory
  package_dir <- file.path(temp_dir_create, "my_package")
  dir.create(package_dir)
  
  # Path to the DESCRIPTION file inside the package directory
  description_file <- file.path(package_dir, "DESCRIPTION")
  writeLines("This is a DESCRIPTION file.", description_file)
  
  # Create the .tar Archive including the entire package directory
  tar_file <- file.path(temp_dir_create, "my_package.tar.gz")
  suppressWarnings(tar(tar_file, files = "my_package", compression = "gzip", tar = "internal"))
  
  # Run the function to modify the DESCRIPTION file
  modified_tar_file <- modify_description_file(tar_file)
  
  # Extract the modified tarball to a separate temporary directory
  suppressWarnings(untar(modified_tar_file, exdir = temp_dir_extract))
  
  # Check if the DESCRIPTION file exists in the modified package directory
  description_file <- file.path(temp_dir_extract, "my_package", "DESCRIPTION")
  expect_true(file.exists(description_file))
  
  # Check if the DESCRIPTION file contains the new line
  description_content <- readLines(description_file)
  expect_true("Config/build/clean-inst-doc: false" %in% description_content)
  
  # Ensure cleanup happens even if the test fails
  withr::defer(unlink(temp_dir_create, recursive = TRUE))
  withr::defer(unlink(temp_dir_extract, recursive = TRUE))
  withr::defer(unlink(tar_file))
})



test_that("Config/build/clean-inst-doc: false already in DESCRIPTION file", {
  dp <- system.file("test-data", "test.package.0008_0.1.0.tar.gz",
                    package = "risk.assessr")

  # Check if the file exists before attempting to download
  if (!file.exists(dp)) {
    stop("The tar file does not exist at the specified path.")
  }

  # Create a temporary file to store the downloaded package
  file_name <- basename(dp) # Use the base name for temporary file
  temp_file <- file.path(tempdir(), file_name)

  # Copy the file to the temporary file instead of downloading it
  file.copy(dp, temp_file, overwrite = TRUE)

  # Verify that the copy was successful
  if (!file.exists(temp_file)) {
    stop("File copy failed: temporary file not found.")
  }

  # Run the function to modify the DESCRIPTION file
  package_name <- "test.package.0008"
  modified_tar_file <- modify_description_file(temp_file)

  # Extract the modified tarball to a temporary directory
  temp_dir <- tempdir()
  untar(modified_tar_file, exdir = temp_dir)

  # Check if the DESCRIPTION file exists in the modified package directory
  package_dir <- file.path(temp_dir, package_name)

  if (!dir.exists(package_dir)) {
    stop("Package directory not found after untarring.")
  }

  description_file <- file.path(package_dir, "DESCRIPTION")
  expect_true(file.exists(description_file))

  # Check if the DESCRIPTION file contains the expected content
  description_content <- readLines(description_file)
  config_line_count <- sum(grepl("Config/build/clean-inst-doc: false",
                                 description_content,
                                 ignore.case = TRUE))
  
  expect_equal(config_line_count, 1)

  # Clean up temporary files
  withr::defer(unlink(temp_file))  # Remove the temporary tar file
  withr::defer(unlink(temp_dir, recursive = TRUE))
})

test_that("No DESCRIPTION file in package", {
  # Create separate temporary directories for creation and extraction
  temp_dir_create <- tempdir()
  
  # Create a directory for the package
  package_dir <- file.path(temp_dir_create, "my_package")
  dir.create(package_dir)
  
  # Create a dummy file in the package directory (but no DESCRIPTION file)
  dummy_file <- file.path(package_dir, "dummy_file.txt")
  writeLines("This is a dummy file.", dummy_file)
  
  # Switch to the temporary directory to create tar archive with proper structure
  old_wd <- setwd(temp_dir_create)
  on.exit(setwd(old_wd))  # Ensure we return to the original directory
  
  # Create the .tar.gz archive without a DESCRIPTION file
  tar_file <- file.path(temp_dir_create, "my_package.tar.gz")
  suppressWarnings(tar(tar_file, files = "my_package", compression = "gzip", tar = "internal"))
  
  expect_error(modify_description_file(tar_file),
               regexp = "Package directory not found")
  
  
  # Ensure cleanup happens even if the test fails
  withr::defer(unlink(package_dir, recursive = TRUE))  # Package directory cleanup
  withr::defer(unlink(tar_file))  # Tar file cleanup
})


test_that("Error in untarring the file", {
  # Mock the untar function to force it to throw an error
  mock_untar <- mockery::mock(stop("Untar failed"))

  mockery::stub(modify_description_file, "untar", mock_untar)

  # Now call the function, expecting it to throw the custom error
  expect_error(modify_description_file("path/to/invalid.tar.gz"),
               "Error in untarring the file: Untar failed")
})

test_that("Error in tarring the file", {

  # Create a temporary directory for the package
  temp_dir_create <- tempdir()

  # Create a fake package directory structure
  package_name <- "test.package.0001"
  package_dir <- file.path(temp_dir_create, package_name)
  dir.create(package_dir)

  # Path to the DESCRIPTION file in the package directory
  description_file <- file.path(package_dir, "DESCRIPTION")
  writeLines("This is a DESCRIPTION file.", description_file)

  # Create the .tar Archive with only the necessary files
  tar_file <- file.path(temp_dir_create, "my_package.tar.gz")
  suppressWarnings(tar(tar_file, files = temp_dir_create, compression = "gzip", tar = "internal"))

  # Mock the tar function to simulate an error during the tarring process
  mock_tar <- mockery::mock(stop("Tar failed"))
  mockery::stub(modify_description_file, "tar", mock_tar)

  # Ensure cleanup happens even if the test fails
  withr::defer(unlink(temp_dir_create, recursive = TRUE))
  withr::defer(unlink(tar_file))

  # Now call the function, expecting it to throw the custom error
  expect_error(modify_description_file(tar_file),
               "Error in creating the tar.gz file: Tar failed")

})



test_that("insensitive case", {
  
  # Create a temporary directory for the package
  temp_dir_create <- tempdir()
  
  # Create a fake package directory structure
  package_name <- "test.package.0001"
  package_dir <- file.path(temp_dir_create, package_name)
  dir.create(package_dir)
  
  # Path to the DESCRIPTION file in the package directory
  description_file <- file.path(package_dir, "DESCRIPTION")
  writeLines("Config/build/clean-inst-doc: false", description_file)
  
  # Create the .tar Archive with only the necessary files
  tar_file <- file.path(temp_dir_create, "my_package.tar.gz")
  suppressWarnings(tar(tar_file, files = temp_dir_create, compression = "gzip", tar = "internal"))
  
  # Mock the tar function to simulate an error during the tarring process
  mock_tar <- mockery::mock(stop("Tar failed"))
  mockery::stub(modify_description_file, "tar", mock_tar)
  
  # Ensure cleanup happens even if the test fails
  withr::defer(unlink(temp_dir_create, recursive = TRUE))
  withr::defer(unlink(tar_file))
  
  # Check if the DESCRIPTION file contains the new line
  description_content <- readLines(description_file)
  config_line_count <- sum(grepl("Config/build/clean-inst-doc: false",
                                 description_content,
                                 ignore.case = TRUE))
  expect_equal(config_line_count, 1)
  expect_true("Config/build/clean-inst-doc: false" %in% description_content)
})







