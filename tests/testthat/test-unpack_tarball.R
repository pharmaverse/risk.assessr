# Helper: build a tar.gz from a temp source dir laid out by `setup_fn`.
# `setup_fn(src_dir)` populates `src_dir` with whatever layout the test needs,
# then this helper packs `src_dir`'s top-level entries into a fresh .tar.gz
# and returns the tarball path. The source dir is removed afterwards.
make_test_tarball <- function(setup_fn) {
  src_dir <- tempfile("src_")
  dir.create(src_dir, recursive = TRUE)
  # Register cleanup immediately so an error in setup_fn(), list.files(),
  # tempfile(), or utils::tar() still removes src_dir and does not leak
  # state into subsequent tests.
  on.exit(
    if (dir.exists(src_dir)) unlink(src_dir, recursive = TRUE, force = TRUE),
    add = TRUE
  )
  
  setup_fn(src_dir)
  
  entries <- list.files(src_dir, all.files = FALSE, no.. = TRUE)
  tar_file <- tempfile(fileext = ".tar.gz")
  
  withr::with_dir(src_dir, {
    # On some Linux containers (e.g. CI) utils::tar(..., tar = "internal")
    # emits benign warnings such as
    #   "invalid uid value replaced by that for user 'nobody'"
    #   "invalid gid value replaced by that for user 'nobody'"
    # when it cannot resolve the file owner. These are environment-specific
    # and do not affect the produced tarball, so suppress them here.
    suppressWarnings(
      utils::tar(
        tar_file,
        files = entries,
        compression = "gzip",
        tar = "internal"
      )
    )
  })
  
  tar_file
}

test_that("Unpacking a tar file works correctly", {
  
  old_repos <- getOption("repos")
  withr::defer(options(repos = old_repos), envir = parent.frame())
  
  r <- old_repos
  r["CRAN"] <- "http://cran.us.r-project.org"
  options(repos = r)
  
  pkg_orig <- system.file("test-data", "here-1.0.1.tar.gz",
                          package = "test.assessr")
  pkg <- tempfile(fileext = ".tar.gz")
  file.copy(pkg_orig, pkg)
  withr::defer(unlink(pkg), envir = parent.frame())
  
  extract_files <-
    suppressMessages(unpack_tarball(pkg))
  
  expect_true(checkmate::checkVector(extract_files))
  
  expect_true(checkmate::check_class(extract_files, "fs_path"))
  
  expect_true(checkmate::check_string(extract_files))
  
  expect_true(checkmate::check_directory_exists(extract_files))
})

test_that("Unpacking an empty tar file returns empty path with a diagnostic message", {
  
  pkg_orig <- system.file("test-data", "empty.tar.gz",
                          package = "test.assessr")
  pkg <- tempfile(fileext = ".tar.gz")
  file.copy(pkg_orig, pkg)
  withr::defer(unlink(pkg), envir = parent.frame())
  
  expect_message(
    extract_files <- unpack_tarball(pkg),
    regexp = "is empty|no top-level directory"
  )
  
  expect_true(checkmate::checkVector(extract_files))
  
  expect_true(checkmate::check_class(extract_files, "fs_path"))
  
  expect_identical(checkmate::check_string(extract_files),
                   "Must have length 1"
  )
  
  expect_identical(checkmate::check_directory_exists(extract_files),
                   "No directory provided"
  )
})

test_that("A tar file with only top-level files (no directory) returns empty path", {
  
  pkg <- make_test_tarball(function(src_dir) {
    writeLines("a", file.path(src_dir, "file1.txt"))
    writeLines("b", file.path(src_dir, "file2.txt"))
  })
  withr::defer(unlink(pkg), envir = parent.frame())
  
  expect_message(
    extract_files <- unpack_tarball(pkg),
    regexp = "no top-level directory.*top-level file"
  )
  
  expect_true(checkmate::check_class(extract_files, "fs_path"))
  expect_length(extract_files, 0)
})

test_that("A tar file with multiple top-level directories returns empty path", {
  
  pkg <- make_test_tarball(function(src_dir) {
    dir.create(file.path(src_dir, "pkg1"))
    dir.create(file.path(src_dir, "pkg2"))
    writeLines("Package: pkg1", file.path(src_dir, "pkg1", "DESCRIPTION"))
    writeLines("Package: pkg2", file.path(src_dir, "pkg2", "DESCRIPTION"))
  })
  withr::defer(unlink(pkg), envir = parent.frame())
  
  expect_message(
    extract_files <- unpack_tarball(pkg),
    regexp = "2 top-level directories"
  )
  
  expect_true(checkmate::check_class(extract_files, "fs_path"))
  expect_length(extract_files, 0)
})

test_that("A tar file whose top-level directory has no DESCRIPTION returns empty path", {
  
  pkg <- make_test_tarball(function(src_dir) {
    dir.create(file.path(src_dir, "notapkg"))
    writeLines("x", file.path(src_dir, "notapkg", "NAMESPACE"))
  })
  withr::defer(unlink(pkg), envir = parent.frame())
  
  expect_message(
    extract_files <- unpack_tarball(pkg),
    regexp = "no DESCRIPTION"
  )
  
  expect_true(checkmate::check_class(extract_files, "fs_path"))
  expect_length(extract_files, 0)
})

test_that("An invalid / corrupted tar file returns empty path with a diagnostic message", {
  
  pkg <- tempfile(fileext = ".tar.gz")
  writeLines("this is not a tarball", pkg)
  withr::defer(unlink(pkg), envir = parent.frame())
  
  extract_files <- suppressMessages(unpack_tarball(pkg))
  
  expect_true(checkmate::checkVector(extract_files))
  expect_true(checkmate::check_class(extract_files, "fs_path"))
  expect_length(extract_files, 0)
})

test_that("A non-existent tar file returns empty path without raising an error", {
  
  pkg <- file.path(tempdir(), "does_not_exist_xyz.tar.gz")
  if (file.exists(pkg)) unlink(pkg)
  
  extract_files <- suppressMessages(unpack_tarball(pkg))
  
  expect_true(checkmate::check_class(extract_files, "fs_path"))
  expect_length(extract_files, 0)
})

test_that("unpack_tarball never signals warnings or errors on bad input", {
  
  bad_inputs <- list(
    nonexistent = file.path(tempdir(), "missing_pkg_xyz.tar.gz"),
    not_a_tar   = local({
      f <- tempfile(fileext = ".tar.gz")
      writeLines("garbage", f)
      withr::defer(unlink(f), envir = parent.frame())
      f
    })
  )
  
  for (label in names(bad_inputs)) {
    # Nest the assertions so unpack_tarball() runs ONCE per input. Warnings
    # do not halt execution, so they propagate through expect_no_error
    # (which only catches errors) and reach expect_no_warning. A single
    # invocation therefore satisfies both checks and avoids doubling the
    # temp-dir creation side effects.
    #
    # Note: `message =` on expect_no_*() is a regex matched against the
    # condition text, not a custom failure label. Passing per-iteration
    # info there would silently mask the assertion. Leave it unset so any
    # warning/error fails the test as intended.
    expect_no_warning(
      expect_no_error(
        suppressMessages(unpack_tarball(bad_inputs[[label]]))
      )
    )
  }
})

test_that("dir.create() failure: emits diagnostic message and returns empty fs_path", {
  # `dir.create()` on a freshly-generated tempfile() name effectively never
  # fails under normal test conditions, so stub it to deterministically
  # exercise the failure branch:
  #   if (!dir.create(temp_pkg_dir)) {
  #     message("Unable to create temp dir for ", pkg_disp, "; returning empty path.")
  #     proceed <- FALSE
  #   }
  mockery::stub(unpack_tarball, "dir.create", FALSE)
  
  expect_message(
    extract_files <- unpack_tarball("dummy/path/to/package.tar.gz"),
    regexp = "Unable to create temp dir"
  )
  
  expect_true(checkmate::check_class(extract_files, "fs_path"))
  expect_length(extract_files, 0)
})

test_that("dir.create() failure: short-circuits and never calls utils::untar()", {
  # Mock untar so that, if the `proceed <- FALSE` short-circuit ever fails,
  # the test breaks loudly instead of silently passing.
  untar_mock <- mockery::mock(stop("utils::untar() must not be reached"))
  
  mockery::stub(unpack_tarball, "dir.create",  FALSE)
  mockery::stub(unpack_tarball, "utils::untar", untar_mock)
  
  suppressMessages(
    extract_files <- unpack_tarball("dummy/path/to/package.tar.gz")
  )
  
  mockery::expect_called(untar_mock, 0)
  
  expect_true(checkmate::check_class(extract_files, "fs_path"))
  expect_length(extract_files, 0)
})

test_that("dir.create() failure: never raises warnings or errors (CRAN-safe)", {
  mockery::stub(unpack_tarball, "dir.create", FALSE)
  
  expect_no_warning(
    suppressMessages(unpack_tarball("dummy/path/to/package.tar.gz"))
  )
  expect_no_error(
    suppressMessages(unpack_tarball("dummy/path/to/package.tar.gz"))
  )
})

test_that("failure path removes the temp directory it created", {
  # Stub tempfile() to a known path so we can inspect the filesystem after
  # the call and verify the on.exit cleanup ran.
  known_temp <- tempfile("unpack_cleanup_")
  withr::defer(
    if (dir.exists(known_temp)) unlink(known_temp, recursive = TRUE, force = TRUE),
    envir = parent.frame()
  )
  
  mockery::stub(unpack_tarball, "tempfile", known_temp)
  
  # Pass a non-existent tarball so untar emits a (now-muffled) warning and the
  # function returns an empty fs_path -> on.exit cleanup must remove the dir.
  extract_files <- suppressMessages(
    unpack_tarball(file.path(tempdir(), "definitely_missing_pkg_xyz.tar.gz"))
  )
  
  expect_length(extract_files, 0)
  expect_false(
    dir.exists(known_temp),
    info = "temp_pkg_dir should be removed when unpack_tarball returns empty path"
  )
})

test_that("success path preserves the extracted package directory", {
  pkg_orig <- system.file("test-data", "here-1.0.1.tar.gz",
                          package = "test.assessr")
  pkg <- tempfile(fileext = ".tar.gz")
  file.copy(pkg_orig, pkg)
  withr::defer(unlink(pkg), envir = parent.frame())
  
  extract_files <- suppressMessages(unpack_tarball(pkg))
  
  # Caller relies on the extracted contents -> must still exist after return.
  expect_true(checkmate::check_directory_exists(extract_files))
  
  # Tidy up so this test does not leak the (intentionally preserved) dir.
  withr::defer(
    unlink(dirname(extract_files), recursive = TRUE, force = TRUE),
    envir = parent.frame()
  )
})
