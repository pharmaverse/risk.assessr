# Mock function for file.choose
mock_file_choose <- function() {
  skip_on_cran()
  return(system.file("test-data", "test.package.0001_0.1.0.tar.gz", 
                     package = "risk.assessr"))
}

# Define the test
test_that("risk_assess_pkg works with mocked file.choose", {
  skip_on_cran()
  # Stub file.choose with the mock function
  mockery::stub(risk_assess_pkg, "file.choose", mock_file_choose)
  
  # Call the function
  risk_assess_package <- risk_assess_pkg()
  
  testthat::expect_identical(length(risk_assess_package), 5L)
  
  testthat::expect_true(checkmate::check_class(risk_assess_package, "list"))
  
  testthat::expect_identical(length(risk_assess_package$results), 30L)
  
  testthat::expect_true(!is.na(risk_assess_package$results$pkg_name))
  
  testthat::expect_true(!is.na(risk_assess_package$results$pkg_version))
  
  testthat::expect_true(!is.na(risk_assess_package$results$pkg_source_path))
  
  testthat::expect_true(!is.na(risk_assess_package$results$date_time))
  
  testthat::expect_true(!is.na(risk_assess_package$results$executor))
  
  testthat::expect_true(!is.na(risk_assess_package$results$sysname))
  
  testthat::expect_true(!is.na(risk_assess_package$results$version))
  
  testthat::expect_true(!is.na(risk_assess_package$results$release))
  
  testthat::expect_true(!is.na(risk_assess_package$results$machine))
  
  testthat::expect_true(!is.na(risk_assess_package$results$comments))
  
  testthat::expect_null(risk_assess_package$results$has_bug_reports_url)
    
  testthat::expect_true(!is.na(risk_assess_package$results$license))
  
  testthat::expect_true(!is.na(risk_assess_package$results$size_codebase))
  
  testthat::expect_true(checkmate::test_numeric(risk_assess_package$results$size_codebase))
  
  testthat::expect_true(checkmate::test_numeric(risk_assess_package$results$check))
  
  testthat::expect_gte(risk_assess_package$results$check, 0)
  
  testthat::expect_true(checkmate::test_numeric(risk_assess_package$results$covr))
  
  testthat::expect_gte(risk_assess_package$results$covr, 0.7)
  
  testthat::expect_identical(length(risk_assess_package$covr_list), 2L)
  
  testthat::expect_true(!is.na(risk_assess_package$covr_list$res_cov$name))
  
  testthat::expect_identical(length(risk_assess_package$covr_list$res_cov$coverage), 2L)
  
  testthat::expect_identical(length(risk_assess_package$tm), 3L)
  
  testthat::expect_identical(length(risk_assess_package$tm_list$tm), 9L)
  
  testthat::expect_true(!is.na(risk_assess_package$tm_list$tm$exported_function))
  
  testthat::expect_true(!is.na(risk_assess_package$tm_list$tm$code_script))
  
  testthat::expect_true(!is.na(risk_assess_package$tm_list$tm$documentation))
  
  testthat::expect_true(!is.na(risk_assess_package$tm_list$tm$coverage_percent))
  
  # high risk tm tests
  expect_true(is.list(risk_assess_package$tm_list$coverage$high_risk))
  expect_identical(risk_assess_package$tm_list$coverage$high_risk$pkg_name, "test.package.0001")
  expect_true(is.list(risk_assess_package$tm_list$coverage$high_risk$coverage))
  expect_identical(risk_assess_package$tm_list$coverage$high_risk$coverage$filecoverage, 0)
  expect_identical(risk_assess_package$tm_list$coverage$high_risk$coverage$totalcoverage, 0)
  expect_true(is.na(risk_assess_package$tm_list$coverage$high_risk$errors))
  expect_true(is.na(risk_assess_package$tm_list$coverage$high_risk$notes))
  
  # medium risk tm tests
  expect_true(is.list(risk_assess_package$tm_list$coverage$medium_risk))
  expect_identical(risk_assess_package$tm_list$coverage$medium_risk$pkg_name, "test.package.0001")
  expect_true(is.list(risk_assess_package$tm_list$coverage$medium_risk$coverage))
  expect_identical(risk_assess_package$tm_list$coverage$medium_risk$coverage$filecoverage, 0)
  expect_identical(risk_assess_package$tm_list$coverage$medium_risk$coverage$totalcoverage, 0)
  expect_true(is.na(risk_assess_package$tm_list$coverage$medium_risk$errors))
  expect_true(is.na(risk_assess_package$tm_list$coverage$medium_risk$notes))
  
  # low risk tm tests
  testthat::expect_equal(nrow(risk_assess_package$tm_list$coverage$low_risk), 1)
  testthat::expect_true(all(c("exported_function", "class", "function_type", "function_body",
                              "where", "code_script", "documentation", "description",
                              "coverage_percent") %in% names(risk_assess_package$tm_list$coverage$low_risk)))
  
  testthat::expect_identical(risk_assess_package$tm_list$coverage$low_risk$exported_function[1], "myfunction")
  testthat::expect_true(is.na(risk_assess_package$tm_list$coverage$low_risk$class[1]))
  testthat::expect_identical(risk_assess_package$tm_list$coverage$low_risk$function_type[1], "regular function")
  testthat::expect_true(!is.na(risk_assess_package$tm_list$coverage$low_risk$function_body[1]))
  testthat::expect_true(grepl("^test\\.package", risk_assess_package$tm_list$coverage$low_risk$where[1]))
  testthat::expect_true(grepl("^R/", risk_assess_package$tm_list$coverage$low_risk$code_script[1]))
  testthat::expect_identical(risk_assess_package$tm_list$coverage$low_risk$documentation[1], "myfunction.Rd")
  testthat::expect_type(risk_assess_package$tm_list$coverage$low_risk$coverage_percent[1], "double")

  testthat::expect_identical(length(risk_assess_package$check_list), 2L)
  
  testthat::expect_identical(length(risk_assess_package$check_list$res_check), 21L)
  
  testthat::expect_true(!is.na(risk_assess_package$check_list$res_check$platform))
  
  testthat::expect_true(!is.na(risk_assess_package$check_list$res_check$package))
  
  testthat::expect_identical(length(risk_assess_package$check_list$res_check$test_output), 1L)
  
  testthat::expect_true(!is.na(risk_assess_package$check_list$res_check$test_output$testthat))
  
  testthat::expect_true(all(sapply(risk_assess_package$check_list$res_check$session_info$platform,
                                   function(x) !is.null(x) && x != "")))
  
  
})


test_that("risk_assess_pkg works with mocked file.choose and get_host_package", {
  skip_on_cran()
  # Stub file.choose with the mock function (already handled)
  mockery::stub(risk_assess_pkg, "file.choose", mock_file_choose)

  # Define the mock function for get_host_package
  mock_get_host_package <- function(pkg_name, pkg_ver, pkg_source_path) {
    return(list(cran = TRUE, host = "CRAN", url = "https://cran.r-project.org"))
  }

  # Apply mocked binding for risk.assessr::get_host_package
  local_mocked_bindings(
    get_host_package = mock_get_host_package,
    .package = "risk.assessr"
  )

  # Call the function
  risk_assess_package <- risk_assess_pkg()

  # Expect the function to return a valid assessment result
  testthat::expect_true(checkmate::check_class(risk_assess_package, "list"))
})


test_that("risk_assess_pkg works with path params", {
  skip_on_cran()
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)

  dp <- system.file("test-data/test.package.0001_0.1.0.tar.gz",
                    package = "risk.assessr")

  # Define the mock function for get_host_package
  mock_get_host_package <- function(pkg_name, pkg_ver, pkg_source_path) {
    return(list(cran = TRUE, host = "CRAN", url = "https://cran.r-project.org"))
  }

  # Apply mocked binding for risk.assessr::get_host_package
  local_mocked_bindings(
    get_host_package = mock_get_host_package,
    .package = "risk.assessr"
  )

  # Call the function
  risk_assess_package <- risk_assess_pkg(path = dp)

  # Expect the function to return a valid assessment result
  testthat::expect_true(checkmate::check_class(risk_assess_package, "list"))
})

test_that("risk_assess_pkg works with invalid path params", {

  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)

  dp <- "invaled_path/"

  # Define the mock function for get_host_package
  mock_get_host_package <- function(pkg_name, pkg_ver, pkg_source_path) {
    return(list(cran = TRUE, host = "CRAN", url = "https://cran.r-project.org"))
  }

  # Apply mocked binding for risk.assessr::get_host_package
  local_mocked_bindings(
    get_host_package = mock_get_host_package,
    .package = "risk.assessr"
  )

  expect_warning(risk_assess_package <- risk_assess_pkg(path = dp))
  testthat::expect_null(risk_assess_package)
})