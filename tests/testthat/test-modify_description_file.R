# Helper: build a minimal .tar.gz from a package directory.
# An isolated staging directory is created internally so that utils::tar()
# embeds only `basename(pkg_dir)/…` paths (no absolute prefixes).
# Cleanup of the staging directory is registered with on.exit() immediately
# after creation, guaranteeing removal even if file.copy() or utils::tar()
# errors — no artefacts are left behind for subsequent tests.
make_tar <- function(pkg_dir, tar_file) {
  stage_dir <- tempfile("make_tar_stage_")
  dir.create(stage_dir)
  on.exit(unlink(stage_dir, recursive = TRUE, force = TRUE), add = TRUE)
  
  file.copy(pkg_dir, stage_dir, recursive = TRUE)
  
  # withr::with_dir() changes the working directory for the duration of the
  # block and restores it afterwards, even on error.
  # suppressWarnings() muffles benign "invalid uid/gid value replaced by that
  # for user 'nobody'" warnings emitted by utils::tar() on Linux CI containers
  # when it cannot resolve the file owner; they do not affect the tarball.
  withr::with_dir(stage_dir, {
    suppressWarnings(
      utils::tar(tar_file, files = basename(pkg_dir),
                 compression = "gzip", tar = "internal")
    )
  })
}

test_that("modify_description_file modifies DESCRIPTION correctly", {
  
  dp <- system.file("test-data", "test.package.0001_0.1.0.tar.gz",
                    package = "risk.assessr")
  skip_if(!file.exists(dp), "Test data not found")
  
  temp_file        <- withr::local_tempfile(fileext = ".tar.gz")
  temp_dir_extract <- withr::local_tempdir()
  
  file.copy(dp, temp_file, overwrite = TRUE)
  
  modified_tar_file <- modify_description_file(temp_file)
  
  # A new tarball was produced — the return path is different from the input
  expect_false(identical(modified_tar_file, temp_file))
  
  utils::untar(modified_tar_file, exdir = temp_dir_extract)
  description_file <- file.path(temp_dir_extract, "test.package.0001", "DESCRIPTION")
  expect_true(file.exists(description_file))
  expect_true("Config/build/clean-inst-doc: false" %in% readLines(description_file))
})


test_that("modify_description_file modifies DESCRIPTION correctly 1bis", {
  
  dp <- system.file("test-data", "test.package.0005_0.1.0.tar.gz",
                    package = "risk.assessr")
  skip_if(!file.exists(dp), "Test data not found")
  
  temp_file        <- withr::local_tempfile(fileext = ".tar.gz")
  temp_dir_extract <- withr::local_tempdir()
  
  file.copy(dp, temp_file, overwrite = TRUE)
  
  modified_tar_file <- modify_description_file(temp_file)
  
  expect_false(identical(modified_tar_file, temp_file))
  
  utils::untar(modified_tar_file, exdir = temp_dir_extract)
  description_file <- file.path(temp_dir_extract, "test.package.0005", "DESCRIPTION")
  expect_true(file.exists(description_file))
  expect_true("Config/build/clean-inst-doc: false" %in% readLines(description_file))
})


test_that("modify_description_file modifies DESCRIPTION correctly from a minimal tarball", {
  
  temp_dir_create  <- withr::local_tempdir()
  temp_dir_extract <- withr::local_tempdir()
  
  package_dir <- file.path(temp_dir_create, "my_package")
  dir.create(package_dir)
  writeLines(c("Package: my_package", "Version: 0.1.0"),
             file.path(package_dir, "DESCRIPTION"))
  
  tar_file <- withr::local_tempfile(fileext = ".tar.gz")
  make_tar(package_dir, tar_file)
  
  modified_tar_file <- modify_description_file(tar_file)
  
  expect_false(identical(modified_tar_file, tar_file))
  
  utils::untar(modified_tar_file, exdir = temp_dir_extract)
  desc_lines <- readLines(file.path(temp_dir_extract, "my_package", "DESCRIPTION"))
  expect_true("Config/build/clean-inst-doc: false" %in% desc_lines)
})


test_that("Config/build/clean-inst-doc: false already in DESCRIPTION returns original path", {
  
  dp <- system.file("test-data", "test.package.0008_0.1.0.tar.gz",
                    package = "risk.assessr")
  skip_if(!file.exists(dp), "Test data not found")
  
  temp_file        <- withr::local_tempfile(fileext = ".tar.gz")
  temp_dir_extract <- withr::local_tempdir()
  
  file.copy(dp, temp_file, overwrite = TRUE)
  
  result <- modify_description_file(temp_file)
  
  # Field already present — original path returned unchanged
  expect_equal(result, temp_file)
  
  # Extract and confirm the field appears exactly once (not duplicated)
  utils::untar(result, exdir = temp_dir_extract)
  desc_lines <- readLines(
    file.path(temp_dir_extract, "test.package.0008", "DESCRIPTION")
  )
  expect_equal(
    sum(grepl("Config/build/clean-inst-doc: false", desc_lines, ignore.case = TRUE)),
    1L
  )
})

test_that("Error writing modified DESCRIPTION returns original tarball with message", {
  # Reach writeLines() by supplying a real tarball whose DESCRIPTION does NOT
  # yet contain the field.  Stub writeLines() to throw so the error handler
  # (lines 93-95) is exercised and proceed becomes FALSE.
  temp_dir_create <- withr::local_tempdir()
  package_dir <- file.path(temp_dir_create, "my_package")
  dir.create(package_dir)
  writeLines(c("Package: my_package", "Version: 0.1.0"),
             file.path(package_dir, "DESCRIPTION"))
  tar_file <- withr::local_tempfile(fileext = ".tar.gz")
  make_tar(package_dir, tar_file)
  mockery::stub(modify_description_file, "writeLines",
                function(...) stop("permission denied"))
  result <- NULL
  expect_message(
    { result <- modify_description_file(tar_file) },
    regexp = "Error writing modified DESCRIPTION: permission denied"
  )
  expect_equal(result, tar_file)
})

test_that("No DESCRIPTION file in package returns original tarball with message", {
  
  temp_dir_create <- withr::local_tempdir()
  
  package_dir <- file.path(temp_dir_create, "my_package")
  dir.create(package_dir)
  writeLines("This is a dummy file.", file.path(package_dir, "dummy_file.txt"))
  
  tar_file <- withr::local_tempfile(fileext = ".tar.gz")
  make_tar(package_dir, tar_file)
  
  result <- NULL
  expect_message(
    { result <- modify_description_file(tar_file) },
    regexp = "Package directory not found"
  )
  
  expect_equal(result, tar_file)
})

test_that("dir.create failure returns original tarball with message", {
  # Stub dir.create to simulate an environment where the temp directory
  # cannot be created (e.g. no write permission, disk full).
  mockery::stub(modify_description_file, "dir.create",
                function(...) FALSE)
  result <- NULL
  expect_message(
    { result <- modify_description_file("path/to/any.tar.gz") },
    regexp = "Unable to create temp dir"
  )
  expect_equal(result, "path/to/any.tar.gz")
})

test_that("warnings from utils::untar are rerouted to message() and do not abort", {
  # Stub utils::untar to emit a warning (simulating the benign uid/gid
  # warnings seen on Linux CI containers).  The withCallingHandlers block
  # must catch it, emit "untar note: …" via message(), muffle the warning,
  # and let execution continue (proceed stays TRUE)
  mockery::stub(modify_description_file, "utils::untar",
                function(...) warning("invalid uid value replaced by that for user 'nobody'"))
  result <- NULL
  expect_message(
    { result <- modify_description_file("path/to/any.tar.gz") },
    regexp = "untar note: invalid uid value replaced"
  )
  expect_equal(result, "path/to/any.tar.gz")
})

test_that("Error in untarring the file returns original tarball with message", {
  
  mockery::stub(modify_description_file, "utils::untar",
                function(...) stop("Untar failed"))
  
  result <- NULL
  expect_message(
    { result <- modify_description_file("path/to/invalid.tar.gz") },
    regexp = "Error in untarring the file: Untar failed"
  )
  
  expect_equal(result, "path/to/invalid.tar.gz")
})


test_that("Error in tarring the file returns original tarball with message", {
  
  temp_dir_create <- withr::local_tempdir()
  
  package_dir <- file.path(temp_dir_create, "my_package")
  dir.create(package_dir)
  writeLines(c("Package: my_package", "Version: 0.1.0"),
             file.path(package_dir, "DESCRIPTION"))
  
  tar_file <- withr::local_tempfile(fileext = ".tar.gz")
  make_tar(package_dir, tar_file)
  
  mockery::stub(modify_description_file, "utils::tar",
                function(...) stop("Tar failed"))
  
  result <- NULL
  expect_message(
    { result <- modify_description_file(tar_file) },
    regexp = "Error in creating the tar.gz file: Tar failed"
  )
  
  expect_equal(result, tar_file)
})

test_that("Partial tar.gz left by failed utils::tar() is unlinked (line 126)", {
  # Targets the `else if (file.exists(modified_tar_file))` cleanup branch.
  # Setup must succeed up to the re-pack block, so a real minimal tarball
  # is built (same pattern as the "Error in tarring" test above).
  temp_dir_create <- withr::local_tempdir()
  
  package_dir <- file.path(temp_dir_create, "my_package")
  dir.create(package_dir)
  writeLines(c("Package: my_package", "Version: 0.1.0"),
             file.path(package_dir, "DESCRIPTION"))
  
  tar_file <- withr::local_tempfile(fileext = ".tar.gz")
  make_tar(package_dir, tar_file)
  
  # Capture the tempfile path utils::tar() is called with so the test can
  # confirm the unlink() actually removed it. partial_path lives in
  # tempdir() (not in withr's local temp), so register a safety-net
  # cleanup in case the assertion fails before the production code runs.
  partial_path <- NULL
  withr::defer(if (!is.null(partial_path)) unlink(partial_path, force = TRUE))
  
  # Stub utils::tar() to reproduce the documented failure mode: write a
  # partial file at `tarfile`, then error. This forces tar_ok == FALSE
  # AND file.exists(modified_tar_file) == TRUE, the only combination
  # that reaches line 126.
  #
  # The stub uses `function(...)` (not `function(tarfile, ...)`) on
  # purpose: utils::tar() is called with `tar = "internal"`, and R's
  # partial-name argument matching would otherwise bind that to a
  # `tarfile` formal, masking the real first positional argument.
  mockery::stub(
    modify_description_file,
    "utils::tar",
    function(...) {
      tarfile_path <- list(...)[[1]]
      partial_path <<- tarfile_path
      writeLines("partial garbage", tarfile_path)
      stop("Tar failed mid-write")
    }
  )
  
  result <- NULL
  expect_message(
    { result <- modify_description_file(tar_file) },
    regexp = "Error in creating the tar.gz file: Tar failed mid-write"
  )
  
  # Original tarball path returned unchanged (result defaulted to tar_file)
  expect_equal(result, tar_file)
  
  # The stub did create a partial file
  expect_false(is.null(partial_path))
  
  # Line 126 must have removed it
  expect_false(file.exists(partial_path))
})


test_that("Successful utils::tar() assigns modified_tar_file to result (lines 121-122)", {
  # Targets the `if (isTRUE(tar_ok)) { result <- modified_tar_file }`
  # branch with an explicit mock, independent of the real tar() succeeding.
  temp_dir_create <- withr::local_tempdir()
  
  package_dir <- file.path(temp_dir_create, "my_package")
  dir.create(package_dir)
  writeLines(c("Package: my_package", "Version: 0.1.0"),
             file.path(package_dir, "DESCRIPTION"))
  
  tar_file <- withr::local_tempfile(fileext = ".tar.gz")
  make_tar(package_dir, tar_file)
  
  produced_path <- NULL
  withr::defer(if (!is.null(produced_path)) unlink(produced_path, force = TRUE))
  
  # Stub utils::tar() to succeed quietly and emit a non-empty file at the
  # path it was given (so the result path is real and inspectable).
  #
  # `function(...)` + list(...)[[1]] is used instead of `function(tarfile, ...)`
  # because utils::tar() is called with `tar = "internal"`, which would
  # otherwise be partial-matched to a `tarfile` formal and corrupt the
  # captured path.
  mockery::stub(
    modify_description_file,
    "utils::tar",
    function(...) {
      tarfile_path <- list(...)[[1]]
      produced_path <<- tarfile_path
      writeLines("stubbed tar contents", tarfile_path)
      invisible(0)
    }
  )
  
  result <- modify_description_file(tar_file)
  
  # Assert structural properties only. The exact tempfile path is
  # generated at runtime (tempfile(fileext = ".tar.gz")) and differs
  # on every run, so it must not be hardcoded.
  
  # The success branch fires: result is NOT the original tar_file
  expect_false(identical(result, tar_file))
  
  # result is a non-empty string ending in .tar.gz
  expect_type(result, "character")
  expect_length(result, 1L)
  expect_true(nzchar(result))
  expect_match(result, "\\.tar\\.gz$")
  
  # result points to the file the stub actually created
  expect_true(file.exists(result))
  
  # Both `result` and `produced_path` were captured at runtime from the
  # same call, so they must agree (no literal path values asserted).
  expect_identical(result, produced_path)
})

test_that("trailing blank lines in DESCRIPTION do not create a second DCF record", {
  
  temp_dir_create  <- withr::local_tempdir()
  temp_dir_extract <- withr::local_tempdir()
  
  package_name <- "trailing_blank_pkg"
  package_dir  <- file.path(temp_dir_create, package_name)
  dir.create(package_dir)
  
  # DESCRIPTION ending with a blank line (mimics CRAN tarballs)
  writeLines(c("Package: trailing_blank_pkg", "Version: 0.1.0", ""),
             file.path(package_dir, "DESCRIPTION"))
  
  tar_file <- withr::local_tempfile(fileext = ".tar.gz")
  make_tar(package_dir, tar_file)
  
  modified_tar_file <- modify_description_file(tar_file)
  
  utils::untar(modified_tar_file, exdir = temp_dir_extract)
  
  desc_out <- file.path(temp_dir_extract, package_name, "DESCRIPTION")
  expect_true(file.exists(desc_out))
  
  lines <- readLines(desc_out)
  expect_true("Config/build/clean-inst-doc: false" %in% lines)
  
  # Must parse as a single DCF record — no error, exactly one row
  expect_no_error(read.dcf(desc_out))
  expect_equal(nrow(read.dcf(desc_out)), 1L)
})


test_that("already-present field is detected and original tarball is returned unchanged", {
  
  temp_dir_create <- withr::local_tempdir()
  
  package_dir <- file.path(temp_dir_create, "test.package.0001")
  dir.create(package_dir)
  writeLines(
    c("Package: test.package.0001", "Version: 0.1.0",
      "Config/build/clean-inst-doc: false"),
    file.path(package_dir, "DESCRIPTION")
  )
  
  tar_file <- withr::local_tempfile(fileext = ".tar.gz")
  make_tar(package_dir, tar_file)
  
  result <- modify_description_file(tar_file)
  
  # Field already present — original path returned, utils::tar never called
  expect_equal(result, tar_file)
})