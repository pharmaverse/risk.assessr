test_that("install_package_local works correctly", {
  
  # remotes::install_local(..., dependencies = TRUE) can be slow and hit CRAN
  # check time/network limits 
  skip_on_cran()
  
  # get system file
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  withr::local_options(list(repos = r))
  skip_if_repo_unavailable()
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0001_0.1.0.tar.gz", 
                         package = "risk.assessr")
  skip_if_test_data_missing(dp_orig)
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  suppressWarnings(pkg_source_path <-   
                     unpack_tarball(dp))
  
  
  # Test the install_package_local function
  result <- suppressWarnings(install_package_local(pkg_source_path))
  expect_true(result)
  
  # Clean up
  withr::defer(unlink(pkg_source_path, recursive = TRUE))  # Test directory cleanup
  
  # Attempt to unload the namespace without checking installed.packages()
  try(unloadNamespace("test.package.0001"), silent = TRUE)
  
})



test_that("install_package_local handles errors correctly", {
  
  temp_dir <- tempdir()
  
  # Create an invalid path to generate an error
  invalid_pkg_path <- file.path(temp_dir, "invalidPackage")
  
  expect_message(
    result <- install_package_local(invalid_pkg_path),
    regexp = "No such file or directory"
  )
  
  expect_false(result)
  # Clean up
  unlink(temp_dir, recursive = TRUE)
})

# Mock function for remotes::install_local
mock_install_local <- function(pkg_source_path, dependencies, upgrade, force, quiet, INSTALL_opts) {
  message(paste0(basename(pkg_source_path), " installed locally"))
}

test_that("install_package_local installs package successfully", {
  # Mock the remotes::install_local function
  mockery::stub(install_package_local, "remotes::install_local", mock_install_local)
  
  # Create a temporary directory to simulate the package source path
  temp_dir <- tempdir()
  
  if (!dir.exists(temp_dir)) {
    dir.create(temp_dir, recursive = TRUE)  # Ensure parent directory exists
  }
  if (!dir.exists(file.path(temp_dir, "mock_package"))) {
    dir.create(file.path(temp_dir, "mock_package"))
  }
  
  # Test the function
  result <- install_package_local(file.path(temp_dir, "mock_package"))
  expect_true(result)
})

test_that("install_package_local handles non-existent directory", {
  # Test the function with a non-existent directory
  result <- install_package_local("non_existent_directory")
  expect_false(result)
})

test_that("install_package_local handles already installed package", {
  # Mock the requireNamespace function to simulate an already installed package
  mockery::stub(install_package_local, "requireNamespace", function(...) TRUE)
  
  # Create a temporary directory to simulate the package source path
  temp_dir <- tempdir()
  if (!dir.exists(file.path(temp_dir, "mock_package"))) {
    dir.create(file.path(temp_dir, "mock_package"))
  }
  
  # Test the function
  result <- install_package_local(file.path(temp_dir, "mock_package"))
  expect_true(result)
})

test_that("error handler emits 'Local installation issue is:' message and returns FALSE when remotes::install_local throws", {
  # Use a real temp dir so dir.exists() returns TRUE naturally -> reaches the tryCatch else branch
  pkg_path <- withr::local_tempdir()
  
  mockery::stub(install_package_local, "get_pkg_name",           function(...) "fakepkg")
  mockery::stub(install_package_local, "requireNamespace",       function(...) FALSE)
  mockery::stub(install_package_local, "remotes::install_local", function(...) stop("network error: cannot reach CRAN"))
  
  expect_message(
    result <- install_package_local(pkg_path),
    regexp = "Local installation issue is:"
  )
  expect_false(result)
})

test_that("error handler emits '<pkg> not installed locally' message and returns FALSE when remotes::install_local throws", {
  pkg_path <- withr::local_tempdir()
  
  mockery::stub(install_package_local, "get_pkg_name",           function(...) "fakepkg")
  mockery::stub(install_package_local, "requireNamespace",       function(...) FALSE)
  mockery::stub(install_package_local, "remotes::install_local", function(...) stop("install failed"))
  
  expect_message(
    result <- install_package_local(pkg_path),
    regexp = "fakepkg not installed locally"
  )
  expect_false(result)
})
