test_that("running tm for created package in tar file with no notes", {
  skip_on_cran()
  skip_if_repo_unavailable()
  dp <- system.file("test-data", "stringr-1.5.1.tar.gz",
                    package = "risk.assessr")
  skip_if_test_data_missing(dp)
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  # Defer cleanup: remove test package from temp dirs
  withr::defer({
    unlink(pkg_source_path, recursive = TRUE, force = TRUE)
  })
  
  if (package_installed == TRUE ) {
    
    # setup parameters for running covr
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)
    
    covr_timeout <- Inf
    
    covr_list <- test.assessr::get_package_coverage(
      pkg_source_path,
      package_installed
    )
    
    tm_list <- create_traceability_matrix(pkg_name,
                                          pkg_source_path,
                                          covr_list$res_cov
    )
    
    testthat::expect_identical(length(tm_list), 3L)
    
    testthat::expect_identical(length(tm_list$tm), 9L)
    
    # Column to check
    column_name <- "exported_function"
    
    # Test to check if there are no missing values in the specified column
    testthat::expect_true(all(!is.na(tm_list$tm[[column_name]])))
    
    testthat::expect_true(checkmate::check_data_frame(tm_list$tm,
                                                      col.names = "named")
    )
    
  } else {
    message(glue::glue("cannot run traceability matrix for {basename(pkg_source_path)}"))
  }
  
})


# The following test is commented out temporarily
# the test with devtools::test() but the problem is caused by
#  https://github.com/hadley/testthat/issues/144
# and https://github.com/r-lib/testthat/issues/86
test_that("running tm for created package in tar file with no tests", {
  skip_on_cran()
  skip_if_repo_unavailable()
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0004_0.1.0.tar.gz", 
                         package = "risk.assessr")
  skip_if_test_data_missing(dp_orig)
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # install package locally to ensure test works
  package_installed <- 
    install_package_local(pkg_source_path)
  package_installed <- TRUE
  
  if (package_installed == TRUE ) {
    
    # ensure path is set to package source path
    rcmdcheck_args$path <- pkg_source_path
    
    # setup parameters for running covr
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)
    
    covr_timeout <- Inf
    
    covr_list <- suppressMessages(
      test.assessr::get_package_coverage(
        pkg_source_path,
        package_installed
      )
    )
    
    tm_list <- create_traceability_matrix(pkg_name,
                                          pkg_source_path,
                                          covr_list$res_cov)
    
    testthat::expect_identical(length(tm_list), 3L)
    
    testthat::expect_identical(length(tm_list$tm), 9L)
    
    testthat::expect_true(checkmate::check_data_frame(tm_list$tm,
                                                      any.missing = TRUE))
    
    testthat::expect_true(checkmate::check_data_frame(tm_list$tm,
                                                      col.names = "named")
    )
    
    testthat::expect_equal(covr_list$total_cov, 0)
    
    testthat::expect_equal(covr_list$res_cov$coverage$totalcoverage, 0)
    
  } else {
    message(glue::glue("cannot run traceability matrix for {basename(pkg_source_path)}"))
  }
  
})

test_that("running tm for created package in tar file with no R directory", {
  skip_on_cran()
  skip_if_repo_unavailable()
  
  dp_orig <- system.file("test-data",
                         "test.package.0006_0.1.0.tar.gz", 
                         package = "risk.assessr")
  skip_if_test_data_missing(dp_orig)
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  if (package_installed == TRUE ) {
    
    # setup parameters for running covr
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)
    
    covr_timeout <- Inf
    
    covr_list <- suppressMessages(
      test.assessr::get_package_coverage(
        pkg_source_path,
        package_installed
      )
    )
    
    testthat::expect_message(
      tm_list <- create_traceability_matrix(pkg_name, 
                                            pkg_source_path, 
                                            covr_list$res_cov),
      glue::glue("creating traceability matrix for {basename(pkg_source_path)}"),
      fixed = TRUE
    )
    
    testthat::expect_message(
      tm_list <- create_traceability_matrix(pkg_name, 
                                            pkg_source_path, 
                                            covr_list$res_cov),
      glue::glue("traceability matrix for {basename(pkg_source_path)} unsuccessful"),
      fixed = TRUE
    )
    
    testthat::expect_message(
      tm_list <- create_traceability_matrix(pkg_name, 
                                            pkg_source_path, 
                                            covr_list$res_cov),
      glue::glue("no R folder to create traceability matrix for {basename(pkg_source_path)}"),
      fixed = TRUE
    )
    
  } else {
    message(glue::glue("cannot run traceability matrix for {basename(pkg_source_path)}"))
  } 
  
})

test_that("running tm for created package in tar file with empty R directory", {
  skip_on_cran()
  skip_if_repo_unavailable()
  
  dp_orig <- system.file("test-data",
                         "test.package.0005_0.1.0.tar.gz", 
                         package = "risk.assessr")
  skip_if_test_data_missing(dp_orig)
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  if (package_installed == TRUE ) {
    
    # setup parameters for running covr
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)
    
    covr_timeout <- Inf
    
    covr_list <- suppressMessages(
      test.assessr::get_package_coverage(
        pkg_source_path,
        package_installed
      )
    )
    
    testthat::expect_message(
      {
        tm <- try(
          create_traceability_matrix(pkg_name, pkg_source_path, covr_list$res_cov),
          silent = TRUE
        )
      },
      "creating traceability matrix for test.package.0005",
      fixed = TRUE
    )
    
  } else {
    message(glue::glue("cannot run traceability matrix for {basename(pkg_source_path)}"))
  }
  
})


test_that("fine_grained_tms correctly categorizes coverage levels", {
  tm <- data.frame(
    function_name = c("f1", "f2", "f3"),
    coverage_percent = c(50, 70, 90),
    function_body = c("", "", ""),
    code_script = c("", "", ""),
    description = c("", "", ""),
    documentation = c("", "", ""),
    stringsAsFactors = FALSE
  )
  
  result <- fine_grained_tms(tm, "testpkg")
  
  expect_equal(nrow(result$coverage$high_risk), 1)
  expect_equal(nrow(result$coverage$medium_risk), 1)
  expect_equal(nrow(result$coverage$low_risk), 1)
})

test_that("fine_grained_tms handles defunct functions", {
  tm <- data.frame(
    function_name = "f_defunct",
    coverage_percent = 100,
    function_body = "This function is defunct",
    code_script = "",
    description = "",
    documentation = "",
    stringsAsFactors = FALSE
  )
  
  result <- fine_grained_tms(tm, "testpkg")
  
  expect_equal(nrow(result$function_type$defunct), 1)
})

test_that("fine_grained_tms handles imported functions", {
  tm <- data.frame(
    function_name = "f_imported",
    coverage_percent = 100,
    function_body = "",
    code_script = "This function is imported",
    description = "",
    documentation = "",
    stringsAsFactors = FALSE
  )
  
  result <- fine_grained_tms(tm, "testpkg")
  
  expect_equal(nrow(result$function_type$imported), 1)
})

test_that("fine_grained_tms handles reexported functions", {
  tm <- data.frame(
    function_name = "f_reexported",
    coverage_percent = 100,
    function_body = "",
    code_script = "This function is re-exported",
    description = "",
    documentation = "",
    stringsAsFactors = FALSE
  )
  
  result <- fine_grained_tms(tm, "testpkg")
  
  expect_equal(nrow(result$function_type$rexported), 1)
})

test_that("fine_grained_tms handles experimental functions", {
  tm <- data.frame(
    function_name = "f_experimental",
    coverage_percent = 100,
    function_body = "",
    code_script = "This function is experimental",
    description = "",
    documentation = "",
    stringsAsFactors = FALSE
  )
  
  result <- fine_grained_tms(tm, "testpkg")
  
  expect_equal(nrow(result$function_type$experimental), 1)
})


test_that("fine_grained_tms correctly categorizes coverage levels", {
  tm <- data.frame(
    function_name = c("f1", "f2", "f3"),
    coverage_percent = c(50, 70, 90),
    function_body = c("", "", ""),
    code_script = c("", "", ""),
    description = c("", "", ""),
    documentation = c("", "", ""),
    stringsAsFactors = FALSE
  )
  
  result <- fine_grained_tms(tm, "testpkg")
  
  expect_equal(nrow(result$coverage$high_risk), 1)
  expect_equal(nrow(result$coverage$medium_risk), 1)
  expect_equal(nrow(result$coverage$low_risk), 1)
})


test_that("create_traceability_matrix works without coverage", {
  pkg_name <- "mockpkg"
  pkg_source_path <- "mock/path"
  func_covr <- NULL
  
  mock_exports_df <- data.frame(
    exported_function = c("func1", "func2"),
    class = c(NA_character_, NA_character_),
    function_type = c(NA_character_, NA_character_),
    function_body = c(NA_character_, NA_character_),
    where = c("mockpkg", "mockpkg"),
    stringsAsFactors = FALSE
  )
  
  mock_docs_result <- list(
    data = data.frame(
      function_name = c("func1", "func2"),
      documentation_name = c("func1", "func2"),
      documentation_location = c("man/func1.Rd", "man/func2.Rd"),
      stringsAsFactors = FALSE
    ),
    has_docs_score = 1
  )
  
  mockery::stub(create_traceability_matrix, "contains_r_folder", TRUE)
  mockery::stub(create_traceability_matrix, "get_exports", mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions", list(func1 = "desc1", func2 = "desc2"))
  mockery::stub(create_traceability_matrix, "fine_grained_tms", function(tm, pkg_name) {
    list(total_tm = tm)
  })
  
  result <- create_traceability_matrix(pkg_name, pkg_source_path, func_covr, execute_coverage = FALSE)
  
  expect_type(result, "list")
  expect_true("total_tm" %in% names(result))
  expect_equal(nrow(result$total_tm), 2)
  expect_equal(result$total_tm$coverage_percent, c(0, 0))
  expect_equal(result$total_tm$code_script, c("R/func1.R", "R/func2.R"))
})

test_that("create_traceability_matrix sets coverage_percent to 0 when func_covr is NULL", {
  pkg_name <- "mockPkg"
  pkg_source_path <- "mock/path"
  
  mock_exports_df <- data.frame(
    exported_function = c("fun1", "fun2"),
    class = c(NA_character_, NA_character_),
    function_type = c(NA_character_, NA_character_),
    function_body = c(NA_character_, NA_character_),
    where = c("mockPkg", "mockPkg"),
    stringsAsFactors = FALSE
  )
  
  mock_docs_result <- list(
    data = data.frame(
      function_name = c("fun1", "fun2"),
      documentation_name = c("fun1", "fun2"),
      documentation_location = c("man/fun1.Rd", "man/fun2.Rd"),
      stringsAsFactors = FALSE
    ),
    has_docs_score = 1
  )
  
  mockery::stub(create_traceability_matrix, "contains_r_folder", function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports", function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions", function(pkg) list(fun1 = "desc1", fun2 = "desc2"))
  mockery::stub(create_traceability_matrix, "fine_grained_tms", function(tm, pkg) list(tm = tm))
  
  result <- create_traceability_matrix(pkg_name, pkg_source_path, func_covr = NULL, execute_coverage = TRUE)
  
  expect_type(result, "list")
  expect_true("tm" %in% names(result))
  expect_equal(result$tm$coverage_percent, c(0, 0))
  expect_equal(result$tm$code_script, c("R/fun1.R", "R/fun2.R"))
})

test_that("create_traceability_matrix sets coverage_percent to 0 when coverage object is missing", {
  pkg_name <- "mockPkg"
  pkg_source_path <- "mock/path"
  
  mock_exports_df <- data.frame(
    exported_function = c("fun1", "fun2"),
    class = c(NA_character_, NA_character_),
    function_type = c(NA_character_, NA_character_),
    function_body = c(NA_character_, NA_character_),
    where = c("mockPkg", "mockPkg"),
    stringsAsFactors = FALSE
  )
  
  mock_docs_result <- list(
    data = data.frame(
      function_name = c("fun1", "fun2"),
      documentation_name = c("fun1", "fun2"),
      documentation_location = c("man/fun1.Rd", "man/fun2.Rd"),
      stringsAsFactors = FALSE
    ),
    has_docs_score = 1
  )
  
  bad_func_covr <- list(name = pkg_name, coverage = NULL, errors = NA, notes = NA)
  
  mockery::stub(create_traceability_matrix, "contains_r_folder", function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports", function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions", function(pkg) list(fun1 = "desc1", fun2 = "desc2"))
  mockery::stub(create_traceability_matrix, "fine_grained_tms", function(tm, pkg) list(tm = tm))
  
  result <- create_traceability_matrix(pkg_name, pkg_source_path, func_covr = bad_func_covr, execute_coverage = TRUE)
  
  expect_type(result, "list")
  expect_true("tm" %in% names(result))
  expect_equal(result$tm$coverage_percent, c(0, 0))
})

test_that("create_traceability_matrix joins coverage correctly via documentation-derived code_script", {
  # code_script is derived from documentation_location ("man/fun1.Rd" -> "R/fun1.R"),
  # so coverage is joined by matching R-script paths from the filecoverage array.
  pkg_name <- "mockPkg"
  pkg_source_path <- "mock/path"
  
  mock_exports_df <- data.frame(
    exported_function = c("fun1", "fun2"),
    class = c(NA_character_, NA_character_),
    function_type = c(NA_character_, NA_character_),
    function_body = c(NA_character_, NA_character_),
    where = c("mockPkg", "mockPkg"),
    stringsAsFactors = FALSE
  )
  
  mock_docs_result <- list(
    data = data.frame(
      function_name = c("fun1", "fun2"),
      documentation_name = c("fun1", "fun2"),
      documentation_location = c("man/fun1.Rd", "man/fun2.Rd"),
      stringsAsFactors = FALSE
    ),
    has_docs_score = 1
  )
  
  # filecoverage dimnames use "R/fun1.R" / "R/fun2.R" — the same paths derived
  # from the documentation_location column, so the join should succeed.
  func_covr <- list(
    name = pkg_name,
    coverage = list(
      filecoverage  = structure(c(42.5, 85.0), dim = 2L, dimnames = list(c("R/fun1.R", "R/fun2.R"))),
      totalcoverage = 0.635
    ),
    errors = NA,
    notes  = NA
  )
  
  mockery::stub(create_traceability_matrix, "contains_r_folder", function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports", function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions", function(pkg) list(fun1 = "desc1", fun2 = "desc2"))
  mockery::stub(create_traceability_matrix, "fine_grained_tms", function(tm, pkg) list(tm = tm))
  
  result <- create_traceability_matrix(pkg_name, pkg_source_path,
                                       func_covr = func_covr, execute_coverage = TRUE)
  
  expect_type(result, "list")
  expect_true("tm" %in% names(result))
  expect_type(result$tm$coverage_percent, "double")
  # coverage rows are matched by derived code_script — values come through
  expect_equal(result$tm$coverage_percent, c(42.5, 85.0))
  expect_equal(result$tm$code_script, c("R/fun1.R", "R/fun2.R"))
})

test_that("create_traceability_matrix backward compatible when Rd and covr names already match", {
  # No R/ directory at pkg_source_path: resolution is skipped; join uses
  # normalize_code_script_key so identical paths still match as before.
  mock_exports_df <- data.frame(
    exported_function = c("fun1", "fun2"),
    class = c(NA_character_, NA_character_),
    function_type = c(NA_character_, NA_character_),
    function_body = c(NA_character_, NA_character_),
    where = c("mockPkg", "mockPkg"),
    stringsAsFactors = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name = c("fun1", "fun2"),
      documentation_name = c("fun1", "fun2"),
      documentation_location = c("man/fun1.Rd", "man/fun2.Rd"),
      stringsAsFactors = FALSE
    ),
    has_docs_score = 1
  )
  func_covr <- list(
    name = "mockPkg",
    coverage = list(
      filecoverage = structure(
        c(42.5, 85.0),
        dim = 2L,
        dimnames = list(c("R/fun1.r", "R/fun2.R"))
      ),
      totalcoverage = 0.635
    ),
    errors = NA,
    notes = NA
  )
  
  mockery::stub(create_traceability_matrix, "contains_r_folder", function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports", function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions", function(pkg) list(fun1 = "desc1", fun2 = "desc2"))
  mockery::stub(create_traceability_matrix, "fine_grained_tms", function(tm, pkg) list(tm = tm))
  
  result <- create_traceability_matrix(
    "mockPkg",
    "mock/path",
    func_covr = func_covr,
    execute_coverage = TRUE
  )
  
  expect_equal(result$tm$code_script, c("R/fun1.R", "R/fun2.R"))
  expect_equal(result$tm$coverage_percent, c(42.5, 85.0))
})

test_that("create_traceability_matrix joins when Rd and R source names differ", {
  mock_exports_df <- data.frame(
    exported_function = "geom_alluvium",
    class = NA_character_,
    function_type = "regular function",
    function_body = NA_character_,
    where = "ggalluvial",
    stringsAsFactors = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name = "geom_alluvium",
      documentation_name = "geom_alluvium",
      documentation_location = "man/geom_alluvium.Rd",
      stringsAsFactors = FALSE
    ),
    has_docs_score = 1
  )
  func_covr <- list(
    name = "ggalluvial",
    coverage = list(
      filecoverage = structure(
        53.73,
        dim = 1L,
        dimnames = list("R/geom-alluvium.r")
      ),
      totalcoverage = 53.73
    ),
    errors = NA,
    notes = NA
  )
  mock_r_script_lookup <- c(geomalluvium = "R/geom-alluvium.r")
  
  mockery::stub(create_traceability_matrix, "contains_r_folder", function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports", function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions", function(pkg) list(geom_alluvium = "desc"))
  mockery::stub(create_traceability_matrix, "build_r_script_lookup", function(pkg_source_path) mock_r_script_lookup)
  mockery::stub(create_traceability_matrix, "fine_grained_tms", function(tm, pkg) list(tm = tm))
  
  result <- create_traceability_matrix(
    "ggalluvial",
    "mock/path",
    func_covr = func_covr,
    execute_coverage = TRUE
  )
  
  expect_equal(result$tm$code_script, "R/geom-alluvium.r")
  expect_equal(result$tm$coverage_percent, 53.73)
})

test_that("create_traceability_matrix resolves ggproto code_script from R sources", {
  mock_exports_df <- data.frame(
    exported_function = "GeomAlluvium",
    class = NA_character_,
    function_type = "ggproto",
    function_body = NA_character_,
    where = "ggalluvial",
    stringsAsFactors = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name = character(0),
      documentation_name = character(0),
      documentation_location = character(0),
      stringsAsFactors = FALSE
    ),
    has_docs_score = 0
  )
  func_covr <- list(
    name = "ggalluvial",
    coverage = list(
      filecoverage = structure(
        0,
        dim = 1L,
        dimnames = list("R/geom-alluvium.r")
      ),
      totalcoverage = 0
    ),
    errors = NA,
    notes = NA
  )
  mock_r_script_lookup <- c(geomalluvium = "R/geom-alluvium.r")
  
  mockery::stub(create_traceability_matrix, "contains_r_folder", function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports", function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions", function(pkg) list())
  mockery::stub(create_traceability_matrix, "build_r_script_lookup", function(pkg_source_path) mock_r_script_lookup)
  mockery::stub(create_traceability_matrix, "fine_grained_tms", function(tm, pkg) list(tm = tm))
  
  result <- create_traceability_matrix(
    "ggalluvial",
    "mock/path",
    func_covr = func_covr,
    execute_coverage = TRUE
  )
  
  expect_equal(result$tm$code_script, "R/geom-alluvium.r")
  expect_equal(result$tm$coverage_percent, 0)
})

test_that("path normalisation strips Linux/macOS absolute temp-path prefix", {
  # covr on Linux/macOS produces paths like /tmp/RtmpXXX/<pkg>/R/fun1.R.
  # The absolute-path branch (grepl "^(/|[A-Za-z]:)") fires, the prefix up to
  # and including /mockPkg/ is stripped, leaving "R/fun1.R" ready for the join.
  mock_exports_df <- data.frame(
    exported_function = c("fun1", "fun2"),
    class = c(NA_character_, NA_character_),
    function_type = c(NA_character_, NA_character_),
    function_body = c(NA_character_, NA_character_),
    where = c("mockPkg", "mockPkg"),
    stringsAsFactors = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name = c("fun1", "fun2"),
      documentation_name = c("fun1", "fun2"),
      documentation_location = c("man/fun1.Rd", "man/fun2.Rd"),
      stringsAsFactors = FALSE
    ),
    has_docs_score = 1
  )
  mockery::stub(create_traceability_matrix, "contains_r_folder", function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports", function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions", function(pkg) list(fun1 = "desc1", fun2 = "desc2"))
  mockery::stub(create_traceability_matrix, "fine_grained_tms", function(tm, pkg) list(tm = tm))
  
  func_covr <- list(
    name = "mockPkg",
    coverage = list(
      filecoverage = structure(
        c(42.5, 85.0), dim = 2L,
        dimnames = list(c(
          "/tmp/RtmpABCDEF/mockPkg/R/fun1.R",
          "/tmp/RtmpABCDEF/mockPkg/R/fun2.R"
        ))
      ),
      totalcoverage = 0.635
    ),
    errors = NA, notes = NA
  )
  
  result <- create_traceability_matrix("mockPkg", "mock/path",
                                       func_covr = func_covr,
                                       execute_coverage = TRUE)
  
  expect_equal(result$tm$code_script,      c("R/fun1.R", "R/fun2.R"))
  expect_equal(result$tm$coverage_percent, c(42.5, 85.0))
})

test_that("path normalisation converts Windows backslashes then strips absolute prefix", {
  # covr on Windows produces paths like C:\\Users\\...\\mockPkg\\R\\fun1.R.
  # The code first converts \\ to /, then strips the prefix up to /mockPkg/.
  mock_exports_df <- data.frame(
    exported_function = c("fun1", "fun2"),
    class = c(NA_character_, NA_character_),
    function_type = c(NA_character_, NA_character_),
    function_body = c(NA_character_, NA_character_),
    where = c("mockPkg", "mockPkg"),
    stringsAsFactors = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name = c("fun1", "fun2"),
      documentation_name = c("fun1", "fun2"),
      documentation_location = c("man/fun1.Rd", "man/fun2.Rd"),
      stringsAsFactors = FALSE
    ),
    has_docs_score = 1
  )
  mockery::stub(create_traceability_matrix, "contains_r_folder", function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports", function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions", function(pkg) list(fun1 = "desc1", fun2 = "desc2"))
  mockery::stub(create_traceability_matrix, "fine_grained_tms", function(tm, pkg) list(tm = tm))
  
  func_covr <- list(
    name = "mockPkg",
    coverage = list(
      filecoverage = structure(
        c(42.5, 85.0), dim = 2L,
        dimnames = list(c(
          "C:\\Users\\test\\AppData\\Local\\Temp\\RtmpXXX\\mockPkg\\R\\fun1.R",
          "C:\\Users\\test\\AppData\\Local\\Temp\\RtmpXXX\\mockPkg\\R\\fun2.R"
        ))
      ),
      totalcoverage = 0.635
    ),
    errors = NA, notes = NA
  )
  
  result <- create_traceability_matrix("mockPkg", "mock/path",
                                       func_covr = func_covr,
                                       execute_coverage = TRUE)
  
  expect_equal(result$tm$code_script,      c("R/fun1.R", "R/fun2.R"))
  expect_equal(result$tm$coverage_percent, c(42.5, 85.0))
})

test_that("path normalisation prepends 'R/' when filecoverage contains bare filenames", {
  # Some covr configurations emit bare filenames ("fun1.R") with no directory
  # separator. Step 3 detects the missing "/" and prepends "R/" so the join key
  # matches the "R/fun1.R" form derived from documentation_location.
  mock_exports_df <- data.frame(
    exported_function = c("fun1", "fun2"),
    class = c(NA_character_, NA_character_),
    function_type = c(NA_character_, NA_character_),
    function_body = c(NA_character_, NA_character_),
    where = c("mockPkg", "mockPkg"),
    stringsAsFactors = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name = c("fun1", "fun2"),
      documentation_name = c("fun1", "fun2"),
      documentation_location = c("man/fun1.Rd", "man/fun2.Rd"),
      stringsAsFactors = FALSE
    ),
    has_docs_score = 1
  )
  mockery::stub(create_traceability_matrix, "contains_r_folder", function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports", function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions", function(pkg) list(fun1 = "desc1", fun2 = "desc2"))
  mockery::stub(create_traceability_matrix, "fine_grained_tms", function(tm, pkg) list(tm = tm))
  
  func_covr <- list(
    name = "mockPkg",
    coverage = list(
      filecoverage = structure(
        c(42.5, 85.0), dim = 2L,
        dimnames = list(c("fun1.R", "fun2.R"))
      ),
      totalcoverage = 0.635
    ),
    errors = NA, notes = NA
  )
  
  result <- create_traceability_matrix("mockPkg", "mock/path",
                                       func_covr = func_covr,
                                       execute_coverage = TRUE)
  
  expect_equal(result$tm$code_script,      c("R/fun1.R", "R/fun2.R"))
  expect_equal(result$tm$coverage_percent, c(42.5, 85.0))
})

test_that("plain named numeric vector for filecoverage is coerced to array and joined", {
  # filecoverage supplied as c("R/fun1.R" = 42.5, "R/fun2.R" = 85.0).
  # is.numeric() TRUE, !is.array() TRUE -> branch fires.
  # names(fc) provides dimnames directly, no seq_along fallback needed.
  mock_exports_df <- data.frame(
    exported_function = c("fun1", "fun2"),
    class = c(NA_character_, NA_character_),
    function_type = c(NA_character_, NA_character_),
    function_body = c(NA_character_, NA_character_),
    where = c("mockPkg", "mockPkg"),
    stringsAsFactors = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name = c("fun1", "fun2"),
      documentation_name = c("fun1", "fun2"),
      documentation_location = c("man/fun1.Rd", "man/fun2.Rd"),
      stringsAsFactors = FALSE
    ),
    has_docs_score = 1
  )
  mockery::stub(create_traceability_matrix, "contains_r_folder", function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports", function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions", function(pkg) list(fun1 = "desc1", fun2 = "desc2"))
  mockery::stub(create_traceability_matrix, "fine_grained_tms", function(tm, pkg) list(tm = tm))
  
  func_covr <- list(
    name = "mockPkg",
    coverage = list(
      filecoverage  = c("R/fun1.R" = 42.5, "R/fun2.R" = 85.0),
      totalcoverage = 0.635
    ),
    errors = NA, notes = NA
  )
  
  result <- create_traceability_matrix("mockPkg", "mock/path",
                                       func_covr = func_covr,
                                       execute_coverage = TRUE)
  
  expect_equal(result$tm$code_script,      c("R/fun1.R", "R/fun2.R"))
  expect_equal(result$tm$coverage_percent, c(42.5, 85.0))
})

test_that("plain unnamed numeric vector for filecoverage uses seq_along as dimnames", {
  # filecoverage supplied as c(42.5, 85.0) with no names.
  # names(fc) is NULL -> dn falls back to as.character(seq_along(fc)) = c("1","2").
  # After the R/ prepend step, code_script becomes c("R/1","R/2"), which does not
  # match the exports_df keys "R/fun1.R"/"R/fun2.R", so coverage_percent is NA.
  # The test confirms the code handles this gracefully without error.
  mock_exports_df <- data.frame(
    exported_function = c("fun1", "fun2"),
    class = c(NA_character_, NA_character_),
    function_type = c(NA_character_, NA_character_),
    function_body = c(NA_character_, NA_character_),
    where = c("mockPkg", "mockPkg"),
    stringsAsFactors = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name = c("fun1", "fun2"),
      documentation_name = c("fun1", "fun2"),
      documentation_location = c("man/fun1.Rd", "man/fun2.Rd"),
      stringsAsFactors = FALSE
    ),
    has_docs_score = 1
  )
  mockery::stub(create_traceability_matrix, "contains_r_folder", function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports", function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions", function(pkg) list(fun1 = "desc1", fun2 = "desc2"))
  mockery::stub(create_traceability_matrix, "fine_grained_tms", function(tm, pkg) list(tm = tm))
  
  func_covr <- list(
    name = "mockPkg",
    coverage = list(
      filecoverage  = c(42.5, 85.0),   # no names
      totalcoverage = 0.635
    ),
    errors = NA, notes = NA
  )
  
  result <- create_traceability_matrix("mockPkg", "mock/path",
                                       func_covr = func_covr,
                                       execute_coverage = TRUE)
  
  # Index-based dimnames ("R/1","R/2") cannot join with function-name keys.
  expect_true(all(is.na(result$tm$coverage_percent)))
})

test_that("plain named integer vector for filecoverage is coerced via as.numeric()", {
  # filecoverage supplied as an integer vector: c("R/fun1.R" = 42L, "R/fun2.R" = 85L).
  # is.integer() TRUE, !is.array() TRUE -> branch fires.
  # as.numeric() coerces integer values to double before building the array.
  mock_exports_df <- data.frame(
    exported_function = c("fun1", "fun2"),
    class = c(NA_character_, NA_character_),
    function_type = c(NA_character_, NA_character_),
    function_body = c(NA_character_, NA_character_),
    where = c("mockPkg", "mockPkg"),
    stringsAsFactors = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name = c("fun1", "fun2"),
      documentation_name = c("fun1", "fun2"),
      documentation_location = c("man/fun1.Rd", "man/fun2.Rd"),
      stringsAsFactors = FALSE
    ),
    has_docs_score = 1
  )
  mockery::stub(create_traceability_matrix, "contains_r_folder", function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports", function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions", function(pkg) list(fun1 = "desc1", fun2 = "desc2"))
  mockery::stub(create_traceability_matrix, "fine_grained_tms", function(tm, pkg) list(tm = tm))
  
  func_covr <- list(
    name = "mockPkg",
    coverage = list(
      filecoverage  = c("R/fun1.R" = 42L, "R/fun2.R" = 85L),
      totalcoverage = 0.635
    ),
    errors = NA, notes = NA
  )
  
  result <- create_traceability_matrix("mockPkg", "mock/path",
                                       func_covr = func_covr,
                                       execute_coverage = TRUE)
  
  expect_equal(result$tm$code_script,      c("R/fun1.R", "R/fun2.R"))
  # integer inputs coerced to double by as.numeric()
  expect_equal(result$tm$coverage_percent, c(42.0, 85.0))
})

test_that(".doc_key: S3 method with 'S3 generic function' type resolves to generic.class", {
  mock_exports_df <- data.frame(
    exported_function = "format",
    class             = "myclass",
    function_type     = "S3 generic function",
    function_body     = "",
    where             = "mockPkg",
    stringsAsFactors  = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name          = "format.myclass",
      documentation_name     = "format.myclass",
      documentation_location = "man/format.myclass.Rd",
      stringsAsFactors       = FALSE
    ),
    has_docs_score = 1
  )
  mockery::stub(create_traceability_matrix, "contains_r_folder",             function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports",                    function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions",          function(pkg) list())
  mockery::stub(create_traceability_matrix, "fine_grained_tms",               function(tm, pkg) list(tm = tm))
  
  result <- create_traceability_matrix("mockPkg", "mock/path",
                                       func_covr = NULL, execute_coverage = FALSE)
  expect_equal(result$tm$documentation, "man/format.myclass.Rd")
})

test_that(".doc_key: S3 method relabelled to 'regular function' still resolves to generic.class", {
  # classify_function_body() strips the "S3" label when the method body
  # has no UseMethod() call.  The old grepl("S3", ...) guard fell back to
  # exported_function = "print", missing the Rd page.  The new !grepl("S4",...)
  # guard treats any non-NA-class row without "S4" in function_type as S3-origin.
  mock_exports_df <- data.frame(
    exported_function = "print",
    class             = "myclass",
    function_type     = "regular function",
    function_body     = "",
    where             = "mockPkg",
    stringsAsFactors  = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name          = "print.myclass",
      documentation_name     = "print.myclass",
      documentation_location = "man/print.myclass.Rd",
      stringsAsFactors       = FALSE
    ),
    has_docs_score = 1
  )
  mockery::stub(create_traceability_matrix, "contains_r_folder",             function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports",                    function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions",          function(pkg) list())
  mockery::stub(create_traceability_matrix, "fine_grained_tms",               function(tm, pkg) list(tm = tm))
  
  result <- create_traceability_matrix("mockPkg", "mock/path",
                                       func_covr = NULL, execute_coverage = FALSE)
  expect_equal(result$tm$documentation, "man/print.myclass.Rd")
})

test_that(".doc_key: S3 method relabelled to 'regular function, R6 class' still resolves to generic.class", {
  # get_s3_method() appends ", R6 class" when it detects an R6 environment,
  # giving e.g. "regular function, R6 class".  The "not S4" discriminator must
  # still treat this as an S3-origin row.
  mock_exports_df <- data.frame(
    exported_function = "summary",
    class             = "r6obj",
    function_type     = "regular function, R6 class",
    function_body     = "",
    where             = "mockPkg",
    stringsAsFactors  = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name          = "summary.r6obj",
      documentation_name     = "summary.r6obj",
      documentation_location = "man/summary.r6obj.Rd",
      stringsAsFactors       = FALSE
    ),
    has_docs_score = 1
  )
  mockery::stub(create_traceability_matrix, "contains_r_folder",             function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports",                    function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions",          function(pkg) list())
  mockery::stub(create_traceability_matrix, "fine_grained_tms",               function(tm, pkg) list(tm = tm))
  
  result <- create_traceability_matrix("mockPkg", "mock/path",
                                       func_covr = NULL, execute_coverage = FALSE)
  expect_equal(result$tm$documentation, "man/summary.r6obj.Rd")
})

test_that(".doc_key: S4 method with 'S4 function' type resolves on generic name only", {
  # getNamespaceExports() returns only "show", never "show,MyS4Class-method",
  # so docs_df has no class-qualified entry.  .doc_key must remain "show".
  mock_exports_df <- data.frame(
    exported_function = "show",
    class             = "MyS4Class",
    function_type     = "S4 function",
    function_body     = "",
    where             = "mockPkg",
    stringsAsFactors  = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name          = "show",
      documentation_name     = "show",
      documentation_location = "man/show.Rd",
      stringsAsFactors       = FALSE
    ),
    has_docs_score = 1
  )
  mockery::stub(create_traceability_matrix, "contains_r_folder",             function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports",                    function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions",          function(pkg) list())
  mockery::stub(create_traceability_matrix, "fine_grained_tms",               function(tm, pkg) list(tm = tm))
  
  result <- create_traceability_matrix("mockPkg", "mock/path",
                                       func_covr = NULL, execute_coverage = FALSE)
  expect_equal(result$tm$documentation, "man/show.Rd")
})

test_that(".doc_key: S4 method with 'S4 method, S4 generic' type resolves on generic name only", {
  mock_exports_df <- data.frame(
    exported_function = "initialize",
    class             = "SomeClass",
    function_type     = "S4 method, S4 generic",
    function_body     = "",
    where             = "mockPkg",
    stringsAsFactors  = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name          = "initialize",
      documentation_name     = "initialize",
      documentation_location = "man/initialize.Rd",
      stringsAsFactors       = FALSE
    ),
    has_docs_score = 1
  )
  mockery::stub(create_traceability_matrix, "contains_r_folder",             function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports",                    function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions",          function(pkg) list())
  mockery::stub(create_traceability_matrix, "fine_grained_tms",               function(tm, pkg) list(tm = tm))
  
  result <- create_traceability_matrix("mockPkg", "mock/path",
                                       func_covr = NULL, execute_coverage = FALSE)
  expect_equal(result$tm$documentation, "man/initialize.Rd")
})

test_that(".doc_key: multiple S4 methods for same generic all resolve to the same Rd page", {
  # Two S4 methods ("show" for ClassA and ClassB) must both join to "man/show.Rd"
  # because docs_df only has the generic entry.
  mock_exports_df <- data.frame(
    exported_function = c("show",       "show"),
    class             = c("ClassA",     "ClassB"),
    function_type     = c("S4 function", "S4 function"),
    function_body     = c("", ""),
    where             = c("mockPkg",    "mockPkg"),
    stringsAsFactors  = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name          = "show",
      documentation_name     = "show",
      documentation_location = "man/show.Rd",
      stringsAsFactors       = FALSE
    ),
    has_docs_score = 1
  )
  mockery::stub(create_traceability_matrix, "contains_r_folder",             function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports",                    function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions",          function(pkg) list())
  mockery::stub(create_traceability_matrix, "fine_grained_tms",               function(tm, pkg) list(tm = tm))
  
  result <- suppressWarnings(
    create_traceability_matrix("mockPkg", "mock/path",
                               func_covr = NULL, execute_coverage = FALSE)
  )
  expect_equal(nrow(result$tm), 2L)
  expect_true(all(result$tm$documentation == "man/show.Rd"))
})

test_that(".doc_key: mixed S3 relabelled + S4 + regular functions all resolve correctly", {
  # Three rows exercising all three case_when branches simultaneously:
  #   "print" / "myclass" / "regular function"  -> "print.myclass" (S3-origin)
  #   "show"  / "S4Class" / "S4 function"       -> "show"          (S4-origin)
  #   "helper"/ NA        / "regular function"  -> "helper"        (NA-class)
  mock_exports_df <- data.frame(
    exported_function = c("print",           "show",        "helper"),
    class             = c("myclass",          "S4Class",    NA_character_),
    function_type     = c("regular function", "S4 function", "regular function"),
    function_body     = c("", "", ""),
    where             = c("mockPkg", "mockPkg", "mockPkg"),
    stringsAsFactors  = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name          = c("print.myclass",        "show",         "helper"),
      documentation_name     = c("print.myclass",        "show",         "helper"),
      documentation_location = c("man/print.myclass.Rd", "man/show.Rd",  "man/helper.Rd"),
      stringsAsFactors       = FALSE
    ),
    has_docs_score = 1
  )
  mockery::stub(create_traceability_matrix, "contains_r_folder",             function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports",                    function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions",          function(pkg) list())
  mockery::stub(create_traceability_matrix, "fine_grained_tms",               function(tm, pkg) list(tm = tm))
  
  result <- create_traceability_matrix("mockPkg", "mock/path",
                                       func_covr = NULL, execute_coverage = FALSE)
  expect_equal(nrow(result$tm), 3L)
  tm <- result$tm[order(result$tm$exported_function), ]
  expect_equal(tm$documentation,
               c("man/helper.Rd", "man/print.myclass.Rd", "man/show.Rd"))
})

test_that(".doc_key: NA function_type with non-NA class falls back to exported_function key", {
  # !is.na(function_type) guard prevents NA propagation; the row falls through
  # case_when to the TRUE branch and uses exported_function as the key.
  mock_exports_df <- data.frame(
    exported_function = "print",
    class             = "myclass",
    function_type     = NA_character_,
    function_body     = "",
    where             = "mockPkg",
    stringsAsFactors  = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name          = "print",
      documentation_name     = "print",
      documentation_location = "man/print.Rd",
      stringsAsFactors       = FALSE
    ),
    has_docs_score = 1
  )
  mockery::stub(create_traceability_matrix, "contains_r_folder",             function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports",                    function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions",          function(pkg) list())
  mockery::stub(create_traceability_matrix, "fine_grained_tms",               function(tm, pkg) list(tm = tm))
  
  result <- create_traceability_matrix("mockPkg", "mock/path",
                                       func_covr = NULL, execute_coverage = FALSE)
  expect_equal(result$tm$documentation, "man/print.Rd")
})

# ── Plain-vector coercion tests (lines 176-181 of create_traceability_matrix.R) ──
#
# covr normally returns filecoverage as a 1-D named array.  Some callers pass a
# plain named or unnamed numeric / integer vector instead.  Lines 176-181 detect
# this and wrap the vector in a proper array so that as.data.frame.table() works.
#
# mockery::stub() must be called directly in each test_that() block; wrapping
# stubs in a helper causes them to be torn down on helper return (on.exit scoping).

test_that("plain named integer vector for filecoverage is coerced via as.numeric()", {
  # filecoverage supplied as an integer vector: c("R/fun1.R" = 42L, "R/fun2.R" = 85L).
  # is.integer() TRUE, !is.array() TRUE -> branch fires.
  # as.numeric() coerces integer values to double before building the array.
  mock_exports_df <- data.frame(
    exported_function = c("fun1", "fun2"),
    class = c(NA_character_, NA_character_),
    function_type = c(NA_character_, NA_character_),
    function_body = c(NA_character_, NA_character_),
    where = c("mockPkg", "mockPkg"),
    stringsAsFactors = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name = c("fun1", "fun2"),
      documentation_name = c("fun1", "fun2"),
      documentation_location = c("man/fun1.Rd", "man/fun2.Rd"),
      stringsAsFactors = FALSE
    ),
    has_docs_score = 1
  )
  mockery::stub(create_traceability_matrix, "contains_r_folder", function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports", function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions", function(pkg) list(fun1 = "desc1", fun2 = "desc2"))
  mockery::stub(create_traceability_matrix, "fine_grained_tms", function(tm, pkg) list(tm = tm))
  
  func_covr <- list(
    name = "mockPkg",
    coverage = list(
      filecoverage  = c("R/fun1.R" = 42L, "R/fun2.R" = 85L),
      totalcoverage = 0.635
    ),
    errors = NA, notes = NA
  )
  
  result <- create_traceability_matrix("mockPkg", "mock/path",
                                       func_covr = func_covr,
                                       execute_coverage = TRUE)
  
  expect_equal(result$tm$code_script,      c("R/fun1.R", "R/fun2.R"))
  # integer inputs coerced to double by as.numeric()
  expect_equal(result$tm$coverage_percent, c(42.0, 85.0))
})

test_that("create_traceability_matrix returns empty TM and emits 'unsuccessful' message when func_coverage has no Var1 column", {
  mock_exports_df <- data.frame(
    exported_function = c("fun1", "fun2"),
    class             = c(NA_character_, NA_character_),
    function_type     = c(NA_character_, NA_character_),
    function_body     = c(NA_character_, NA_character_),
    where             = c("mockPkg", "mockPkg"),
    stringsAsFactors  = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name          = c("fun1", "fun2"),
      documentation_name     = c("fun1", "fun2"),
      documentation_location = c("man/fun1.Rd", "man/fun2.Rd"),
      stringsAsFactors       = FALSE
    ),
    has_docs_score = 1
  )
  
  # A well-formed func_covr — the failure is forced via the stub below, not by
  # passing pathological coverage data. This isolates the test to the
  # cl_exists == FALSE branch only.
  func_covr <- list(
    name = "mockPkg",
    coverage = list(
      filecoverage = structure(
        c(42.5, 85.0), dim = 2L,
        dimnames = list(c("R/fun1.R", "R/fun2.R"))
      ),
      totalcoverage = 0.635
    ),
    errors = NA, notes = NA
  )
  
  mockery::stub(create_traceability_matrix, "contains_r_folder",             function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports",                    function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions",          function(pkg) list(fun1 = "desc1", fun2 = "desc2"))
  mockery::stub(create_traceability_matrix, "fine_grained_tms",               function(tm, pkg) list(tm = tm))
  
  # Force cl_exists == FALSE: return a data frame whose columns do not include
  # "Var1". Any column name other than "Var1" works; "other" is used to make
  # the test intent explicit.
  mockery::stub(
    create_traceability_matrix,
    "as.data.frame.table",
    function(...) data.frame(other = c("a", "b"), Freq = c(1, 2),
                             stringsAsFactors = FALSE)
  )
  
  msgs <- testthat::capture_messages(
    result <- create_traceability_matrix(
      "mockPkg", "mock/path",
      func_covr = func_covr,
      execute_coverage = TRUE
    )
  )
  
  # The "unsuccessful" message appears twice in this branch:
  #   1st emission: inside create_empty_tm()  (proves the assignment line ran)
  #   2nd emission: the message() right after (proves the message line ran)
  unsuccessful <- "traceability matrix for mockPkg unsuccessful"
  expect_gte(sum(grepl(unsuccessful, msgs, fixed = TRUE)), 2L)
  
  # The "successful" message must NOT appear — we did not take the happy path.
  expect_false(any(grepl("traceability matrices for mockPkg successful",
                         msgs, fixed = TRUE)))
  
  # tm_list is the create_empty_tm() return value: a 4-element list with the
  # documented schema (pkg_name / coverage / errors / notes). Crucially it does
  # NOT contain a "tm" element, which would only be present if fine_grained_tms()
  # had been reached on the success path.
  expect_type(result, "list")
  expect_named(result, c("pkg_name", "coverage", "errors", "notes"))
  expect_equal(result$pkg_name, "mockPkg")
  expect_equal(result$coverage, list(filecoverage = 0, totalcoverage = 0))
  expect_true(is.na(result$errors))
  expect_true(is.na(result$notes))
  expect_false("tm" %in% names(result))
})

test_that("create_traceability_matrix failure-branch message interpolates pkg_name correctly", {
  # Same failure trigger as the previous test, but with a different pkg_name —
  # one containing a dot, which was the exact pathology that motivated the
  # extract_short_path refactor. Confirms glue::glue() interpolation in the
  # "unsuccessful" message uses the argument rather than a hard-coded string.
  mock_exports_df <- data.frame(
    exported_function = "fun1",
    class             = NA_character_,
    function_type     = NA_character_,
    function_body     = NA_character_,
    where             = "data.table",
    stringsAsFactors  = FALSE
  )
  mock_docs_result <- list(
    data = data.frame(
      function_name          = "fun1",
      documentation_name     = "fun1",
      documentation_location = "man/fun1.Rd",
      stringsAsFactors       = FALSE
    ),
    has_docs_score = 1
  )
  
  func_covr <- list(
    name = "data.table",
    coverage = list(
      filecoverage  = structure(85.0, dim = 1L, dimnames = list("R/fun1.R")),
      totalcoverage = 0.85
    ),
    errors = NA, notes = NA
  )
  
  mockery::stub(create_traceability_matrix, "contains_r_folder",             function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports",                    function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "assess_exported_functions_docs", function(pkg, path) mock_docs_result)
  mockery::stub(create_traceability_matrix, "get_func_descriptions",          function(pkg) list(fun1 = "desc1"))
  mockery::stub(create_traceability_matrix, "fine_grained_tms",               function(tm, pkg) list(tm = tm))
  
  # Empty data frame -> no Var1 column -> cl_exists == FALSE.
  mockery::stub(
    create_traceability_matrix,
    "as.data.frame.table",
    function(...) data.frame()
  )
  
  msgs <- testthat::capture_messages(
    result <- create_traceability_matrix(
      "data.table", "mock/path",
      func_covr = func_covr,
      execute_coverage = TRUE
    )
  )
  
  # Interpolated pkg_name must appear in the failure-branch message — exactly
  # the "data.table" string, not "{pkg_name}" or any other placeholder.
  expect_true(any(grepl("traceability matrix for data.table unsuccessful",
                        msgs, fixed = TRUE)))
  
  # Sanity check on the returned empty TM: pkg_name propagates from the caller.
  expect_equal(result$pkg_name, "data.table")
})

