test_that("execute_coverage=FALSE runs coverage when tests are present", {
  
  # Stub get_package_tarfile() directly. Stubbing its internals
  # (check_cran_package / remotes::download_version) has no effect because
  # mockery only intercepts calls made directly in generate_traceability_matrix(),
  # which would otherwise make a live network request and time out.
  tar_path <- fake_tar()
  mockery::stub(generate_traceability_matrix, "get_package_tarfile", function(...) tar_path)
  
  
  mockery::stub(generate_traceability_matrix, "modify_description_file", function(x) x)
  mockery::stub(generate_traceability_matrix, "set_up_pkg", function(x) {
    list(package_installed = TRUE, pkg_source_path = tempdir())
  })
  mockery::stub(generate_traceability_matrix, "install_package_local", TRUE)
  
  # These should not be consulted for coverage when execute_coverage = FALSE,
  # but we can keep them harmless.
  mockery::stub(
    generate_traceability_matrix, "test.assessr::get_package_coverage",
    function(...) stop("should not run when execute_coverage=FALSE")
  )
  mockery::stub(generate_traceability_matrix, "create_traceability_matrix", function(...) list())
  
  out <- generate_traceability_matrix("stringr", "1.5.1", execute_coverage = FALSE)
  expect_equal(out, list())
})

test_that("‘Bioconductor fallback’ case works once a tarball is provided", {
  # We don't test fallback logic here; just that the pipeline works with a tarball.
  tar_path <- fake_tar()
  mockery::stub(generate_traceability_matrix, "get_package_tarfile", function(...) tar_path)
  mockery::stub(generate_traceability_matrix, "modify_description_file", identity)
  mockery::stub(generate_traceability_matrix, "set_up_pkg", function(x) {
    list(package_installed = TRUE, pkg_source_path = tempdir())
  })
  mockery::stub(generate_traceability_matrix, "install_package_local", TRUE)
  mockery::stub(
    generate_traceability_matrix, "test.assessr::get_package_coverage",
    function(...) stop("should not run when execute_coverage=FALSE")
  )
  mockery::stub(generate_traceability_matrix, "create_traceability_matrix", function(...) "fallback-success")
  
  result <- generate_traceability_matrix("SomePkg")
  expect_equal(result, "fallback-success")
})

test_that("‘Bioconductor direct’ case works once a tarball is provided", {
  tar_path <- fake_tar()
  mockery::stub(generate_traceability_matrix, "get_package_tarfile", function(...) tar_path)
  mockery::stub(generate_traceability_matrix, "modify_description_file", identity)
  mockery::stub(generate_traceability_matrix, "set_up_pkg", function(x) {
    list(package_installed = TRUE, pkg_source_path = tempdir())
  })
  mockery::stub(generate_traceability_matrix, "install_package_local", TRUE)
  mockery::stub(
    generate_traceability_matrix, "test.assessr::get_package_coverage",
    function(...) stop("should not run when execute_coverage=FALSE")
  )
  mockery::stub(generate_traceability_matrix, "create_traceability_matrix", function(...) "bioc-success")
  
  result <- generate_traceability_matrix("Biobase")
  expect_equal(result, "bioc-success")
})

test_that("‘internal mirror’ case works once a tarball is provided", {
  tar_path <- fake_tar()
  mockery::stub(generate_traceability_matrix, "get_package_tarfile", function(...) tar_path)
  mockery::stub(generate_traceability_matrix, "modify_description_file", identity)
  mockery::stub(generate_traceability_matrix, "set_up_pkg", function(x) {
    list(package_installed = TRUE, pkg_source_path = tempdir())
  })
  mockery::stub(generate_traceability_matrix, "install_package_local", TRUE)
  mockery::stub(
    generate_traceability_matrix, "test.assessr::get_package_coverage",
    function(...) stop("should not run when execute_coverage=FALSE")
  )
  mockery::stub(generate_traceability_matrix, "create_traceability_matrix", function(...) "internal-success")
  
  result <- generate_traceability_matrix("InternalPkg")
  expect_equal(result, "internal-success")
})

test_that("returns NULL when get_package_tarfile() returns NULL", {
  mockery::stub(generate_traceability_matrix, "get_package_tarfile", function(...) NULL)
  
  # Ensure we don't proceed past early return
  called_mod <- FALSE
  mockery::stub(generate_traceability_matrix, "modify_description_file", function(x) { called_mod <<- TRUE; x })
  
  out <- generate_traceability_matrix("GhostPkg")
  expect_null(out)
  expect_false(called_mod)
})

test_that("‘CRAN success’ case works once a tarball is provided", {
  tar_path <- fake_tar()
  mockery::stub(generate_traceability_matrix, "get_package_tarfile", function(...) tar_path)
  mockery::stub(generate_traceability_matrix, "modify_description_file", identity)
  mockery::stub(generate_traceability_matrix, "set_up_pkg", function(x) {
    list(package_installed = TRUE, pkg_source_path = tempdir())
  })
  mockery::stub(generate_traceability_matrix, "install_package_local", TRUE)
  mockery::stub(
    generate_traceability_matrix, "test.assessr::get_package_coverage",
    function(...) stop("should not run when execute_coverage=FALSE")
  )
  mockery::stub(generate_traceability_matrix, "create_traceability_matrix", function(...) "cran-success")
  
  result <- generate_traceability_matrix("ggplot2")
  expect_equal(result, "cran-success")
})

test_that("passes version and repos to get_package_tarfile()", {
  tar_path <- fake_tar()
  seen <- new.env(parent = emptyenv())
  mockery::stub(generate_traceability_matrix, "get_package_tarfile", function(package_name, version = NA, repos = NULL) {
    seen$package_name <- package_name
    seen$version <- version
    seen$repos <- repos
    tar_path
  })
  mockery::stub(generate_traceability_matrix, "modify_description_file", identity)
  mockery::stub(generate_traceability_matrix, "set_up_pkg", function(x) {
    list(package_installed = TRUE, pkg_source_path = tempdir())
  })
  mockery::stub(generate_traceability_matrix, "install_package_local", TRUE)
  mockery::stub(generate_traceability_matrix, "create_traceability_matrix", function(...) "ok")
  
  custom_repos <- c(CRAN = "https://my.custom.repo")
  res <- generate_traceability_matrix("pkgpass", version = "9.9.9", repos = custom_repos, execute_coverage = FALSE)
  expect_equal(res, "ok")
  expect_equal(seen$package_name, "pkgpass")
  expect_equal(seen$version, "9.9.9")
  expect_equal(seen$repos, custom_repos)
})

test_that("Coverage logic runs when tests are present", {
  tar_path <- fake_tar()
  mockery::stub(generate_traceability_matrix, "get_package_tarfile", function(...) tar_path)
  mockery::stub(generate_traceability_matrix, "modify_description_file", identity)
  mockery::stub(generate_traceability_matrix, "set_up_pkg", function(x) {
    list(package_installed = TRUE, pkg_source_path = "mock_path")
  })
  mockery::stub(generate_traceability_matrix, "install_package_local", TRUE)
  
  mockery::stub(
    generate_traceability_matrix, "test.assessr::get_package_coverage",
    function(pkg_source_path, package_installed) {
      list(res_cov = "mock_cov_results")
    }
  )
  mockery::stub(generate_traceability_matrix, "create_traceability_matrix", function(pkg_name, pkg_source_path, func_covr, execute_coverage) {
    list(traceability_matrix = "mock_matrix", coverage = func_covr)
  })
  
  result <- generate_traceability_matrix("mockpkg", execute_coverage = TRUE)
  expect_equal(result$coverage, "mock_cov_results")
})

test_that("Coverage logic skips when no tests are present", {
  tar_path <- fake_tar()
  mockery::stub(generate_traceability_matrix, "get_package_tarfile", function(...) tar_path)
  mockery::stub(generate_traceability_matrix, "modify_description_file", identity)
  mockery::stub(generate_traceability_matrix, "set_up_pkg", function(x) {
    list(package_installed = TRUE, pkg_source_path = "mock_path")
  })
  mockery::stub(generate_traceability_matrix, "install_package_local", TRUE)
  
  mockery::stub(
    generate_traceability_matrix, "test.assessr::get_package_coverage",
    function(pkg_source_path, package_installed) {
      list(res_cov = NULL)
    }
  )
  mockery::stub(generate_traceability_matrix, "create_traceability_matrix", function(pkg_name, pkg_source_path, func_covr, execute_coverage) {
    list(traceability_matrix = "mock_matrix", coverage = func_covr)
  })
  
  result <- generate_traceability_matrix("mockpkg", execute_coverage = TRUE)
  expect_null(result$coverage)
})

test_that("Coverage logic does not run when execute_coverage is FALSE", {
  tar_path <- fake_tar()
  mockery::stub(generate_traceability_matrix, "get_package_tarfile", function(...) tar_path)
  mockery::stub(generate_traceability_matrix, "modify_description_file", identity)
  mockery::stub(generate_traceability_matrix, "set_up_pkg", function(x) {
    list(package_installed = TRUE, pkg_source_path = "mock_path")
  })
  mockery::stub(generate_traceability_matrix, "install_package_local", TRUE)
  
  mockery::stub(
    generate_traceability_matrix, "test.assessr::get_package_coverage",
    function(...) stop("Should not be called")
  )
  mockery::stub(generate_traceability_matrix, "create_traceability_matrix", function(pkg_name, pkg_source_path, func_covr, execute_coverage) {
    list(traceability_matrix = "mock_matrix", coverage = func_covr)
  })
  
  result <- generate_traceability_matrix("mockpkg", execute_coverage = FALSE)
  expect_null(result$coverage)
})

test_that("returns NULL and emits message when package installation fails", {
  tar_path <- fake_tar()
  mockery::stub(generate_traceability_matrix, "get_package_tarfile", function(...) tar_path)
  mockery::stub(generate_traceability_matrix, "modify_description_file", identity)
  mockery::stub(generate_traceability_matrix, "set_up_pkg", function(x) {
    list(package_installed = FALSE, pkg_source_path = tempdir())
  })
  mockery::stub(generate_traceability_matrix, "install_package_local", FALSE)
  mockery::stub(
    generate_traceability_matrix, "create_traceability_matrix",
    function(...) stop("should not be called when installation fails")
  )
  
  expect_message(
    result <- generate_traceability_matrix("failpkg", execute_coverage = FALSE),
    "Package installation failed."
  )
  expect_null(result)
})

test_that("cleans up temp tarball after run", {
  tar_path <- fake_tar()
  expect_true(file.exists(tar_path))
  
  mockery::stub(generate_traceability_matrix, "get_package_tarfile", function(...) tar_path)
  mockery::stub(generate_traceability_matrix, "modify_description_file", identity)
  mockery::stub(generate_traceability_matrix, "set_up_pkg", function(x) {
    list(package_installed = TRUE, pkg_source_path = tempdir())
  })
  mockery::stub(generate_traceability_matrix, "install_package_local", TRUE)
  mockery::stub(generate_traceability_matrix, "create_traceability_matrix", function(...) "ok-cleanup")
  
  res <- generate_traceability_matrix("cleanpkg", execute_coverage = FALSE)
  expect_equal(res, "ok-cleanup")
  expect_false(file.exists(tar_path))
})