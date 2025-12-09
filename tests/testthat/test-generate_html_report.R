toy_assessment_results <- list(
  results = list(
    pkg_name = "test.package.0001",
    pkg_version = "0.1.0",
    pkg_source_path = structure("/tmp/Rtmpnn3wNN/temp_file_7b003b884e49/test.package.0001", .Names = "/tmp/Rtmpnn3wNN/temp_file_7b003b884e49/test.package.0001"),
    date_time = "2025-01-02 09:15:18",
    executor = "u1004798",
    sysname = "Linux",
    version = "#1 SMP Tue Aug 18 14:50:17 EDT 2020",
    release = "3.10.0-1160.el7.x86_64",
    machine = "x86_64",
    comments = " ",
    has_bug_reports_url = 0,
    license = 1,
    has_examples = 0,
    has_maintainer = 1,
    size_codebase = 0.026,
    has_news = 0,
    has_source_control = 0,
    has_vignettes = 0,
    has_website = 0,
    news_current = 0,
    export_help = 1,
    export_calc = 0.731,
    check = 1,
    covr = 1,
    github_data = list(
      created_at = "2016-07-19T14:47:19Z",
      stars = 422,
      forks = 45,
      date = "2025-07-02",
      recent_commits_count = 0,
      open_issues = 29
    ),
    download = list(
      total_download = 11369237,
      last_month_download = 299354
    ),
    dependencies = list(
      imports = list(checkmate = "2.1.0"),
      suggests = list(testthat = "3.2.1.1")
    ),
    dep_score = 0.000203,
    rev_deps = logical(0),
    revdep_score = 0.0966,
    overall_risk_score = 0.577,
    risk_profile = "High",
    license_name = "MIT + file LICENSE"
  ),
  covr_list = list(
    total_cov = 1,
    res_cov = list(
      name = "test.package.0001",
      coverage = list(
        filecoverage = structure(50, .Dim = c(1L), .Dimnames = list("R/myscript.R")),
        totalcoverage = 50
      ),
      errors = NA,
      notes = NA
    )
  ),
  tm_list = list(
    tm = dplyr::tibble(
      exported_function = "myfunction",
      function_type = "regular",
      code_script = "R/myscript.R",
      documentation = "myfunction.Rd",
      description = "Adds 1 to x",
      coverage_percent = 50
    ),
    coverage = list(
      high_risk = dplyr::tibble(
        exported_function = "myfunction",
        class = NA,
        function_type = "regular",
        function_body = "{\n    check_string(encoding)\n    stri_conv(string, encoding, \"UTF-8\")\n}",
        where = "stringr",
        code_script = "R/myscript.R",
        documentation = "myfunction.Rd",
        description = "Adds 1 to x",
        coverage_percent = 50
      ),
      medium_risk = list(
        pkg_name = "test.package.0001",
        coverage = list(
          filecoverage = 0,
          totalcoverage =  0
        ),
        errors = NA,
        notes  = NA
      ),
      low_risk = list(
        pkg_name = "test.package.0001",
        coverage = list(
          filecoverage = 0,
          totalcoverage =  0
        ),
        errors = NA,
        notes  = NA
      )
    ),
    function_type = list(
      defunct = dplyr::tibble(
        pkg_name = "test.package.0001",
        coverage = list(
          filecoverage = 0,
          totalcoverage =  0
        ),
        errors = NA,
        notes  = NA
      ),
      imported = dplyr::tibble(
        pkg_name = "test.package.0001",
        coverage = list(
          filecoverage = 0,
          totalcoverage =  0
        ),
        errors = NA,
        notes  = NA
      ),
      rexported = dplyr::tibble(
        pkg_name = "test.package.0001",
        coverage = list(
          filecoverage = 0,
          totalcoverage =  0
        ),
        errors = NA,
        notes  = NA
      )
    )
  ),
  check_list = list(
    res_check = list(
      stdout = "* using log directory ‘/tmp/Rtmpnn3wNN/file7b001de03ced/test.package.0001.Rcheck’\n* using R version 4.2.1 (2022-06-23)\n* using platform: x86_64-pc-linux-gnu (64-bit)\n* using session charset: UTF-8\n* checking for file ‘test.package.0001/DESCRIPTION’ ... OK\n* this is package ‘test.package.0001’ version ‘0.1.0’\n* package encoding: UTF-8\n* checking package namespace information ... OK\n* checking package dependencies ... OK\n* checking if this is a source package ... OK\n* checking if there is a namespace ... OK\n* checking for executable files ... OK\n* checking for hidden files and directories ... OK\n* checking for portable file names ... OK\n* checking for sufficient/correct file permissions ... OK\n* checking whether package ‘test.package.0001’ can be installed ... OK\n* checking installed package size ... OK\n* checking package directory ... OK\n* checking DESCRIPTION meta-information ... OK\n* checking top-level files ... OK\n* checking for left-over files ... OK\n* checking index information ... OK\n* checking package subdirectories ... OK\n* checking R files for non-ASCII characters ... OK\n* checking R files for syntax errors ... OK\n* checking whether the package can be loaded ... OK\n* checking whether the package can be loaded with stated dependencies ... OK\n* checking whether the package can be unloaded cleanly ... OK\n* checking whether the namespace can be loaded with stated dependencies ... OK\n* checking whether the namespace can be unloaded cleanly ... OK\n* checking loading without being on the library search path ... OK\n* checking dependencies in R code ... OK\n* checking S3 generic/method consistency ... OK\n* checking replacement functions ... OK\n* checking foreign function calls ... OK\n* checking R code for possible problems ... OK\n* checking Rd files ... OK\n* checking Rd metadata ... OK\n* checking Rd cross-references ... OK\n* checking for missing documentation entries ... OK\n* checking for code/documentation mismatches ... OK\n* checking Rd \\\\usage sections ... OK\n* checking Rd contents ... OK\n* checking for unstated dependencies in examples ... OK\n* checking examples ... OK\n* checking for non-standard things in the check directory ... OK\n* checking for detritus in the temp directory ... OK\n* DONE\nStatus: OK\n",
      stderr = character(0),
      status = 0,
      duration = 40.2,
      timeout = FALSE,
      rversion = "4.2.1",
      platform = "x86_64-pc-linux-gnu",
      errors = character(0),
      warnings = character(0),
      notes = character(0),
      description = "Package: test.package.0001\nType: Package\nTitle: Test Package\nVersion: 0.1.0\nAuthors@R: \n    person(\"Jane\", \"Doe\", email = \"jane.doe@example.com\", role = c(\"aut\", \"cre\"))\nDescription: A test package.\nLicense: GPL-3\nEncoding: UTF-8\nLazyData: true\nImports: checkmate (>= 2.1.0)\nSuggests: testthat (>= 3.2.1.1)\n",
      package = "test.package.0001",
      version = "0.1.0",
      cran = FALSE,
      bioc = FALSE,
      checkdir = "/tmp/Rtmpnn3wNN/file7b001de03ced/test.package.0001.Rcheck",
      test_fail = list(),
      test_output = list(testthat = "> library(testthat)\n> library(test.package.0001)\n> \n> test_check(\"test.package.0001\")\n[ FAIL 0 | WARN 0 | SKIP 0 | PASS 1 ]\n"),
      install_out = "* installing *source* package ‘test.package.0001’ ...\n** using staged installation\n** R\n** byte-compile and prepare package for lazy loading\n** help\n*** installing help indices\n** building package indices\n** testing if installed package can be loaded from temporary location\n** testing if installed package can be loaded from final location\n** testing if installed package keeps a record of temporary installation path\n* DONE (test.package.0001)\n",
      session_info = list(
        platform = list(
          version = "R version 4.2.1 (2022-06-23)",
          os = "Red Hat Enterprise Linux Server 7.9 (Maipo)",
          system = "x86_64, linux-gnu",
          ui = "X11",
          language = "(EN)",
          collate = "C",
          ctype = "en_US.UTF-8",
          tz = "Europe/Paris",
          date = "2025-01-02",
          pandoc = "3.1.4 @ /cm/easybuild/software/Pandoc/3.1.4/bin/pandoc"
        ),
        packages = structure(list(
          package = c("backports", "checkmate", "test.package.0001"),
          ondiskversion = c("1.4.1", "2.1.0", "0.1.0"),
          loadedversion = c(NA, NA, NA),
          path = c("/cm/easybuild/software/R/4.2.1-foss-2020b-REL-001/lib64/R/library/backports", "/cm/easybuild/software/R/4.2.1-foss-2020b-REL-001/lib64/R/library/checkmate", "/tmp/Rtmpnn3wNN/file7b001de03ced/test.package.0001.Rcheck/test.package.0001"),
          loadedpath = c(NA, NA, NA),
          attached = c(FALSE, FALSE, FALSE),
          is_base = c(FALSE, FALSE, FALSE),
          date = c("2021-12-13", "2022-04-21", "2025-01-02"),
          source = c("CRAN (R 4.2.1)", "CRAN (R 4.2.1)", "local"),
          md5ok = c(NA, NA, NA),
          library = factor(c("/tmp/Rtmpnn3wNN/file7b001de03ced/test.package.0001.Rcheck", "/tmp/Rtmpnn3wNN/file7b001de03ced/test.package.0001.Rcheck", "/tmp/Rtmpnn3wNN/file7b001de03ced/test.package.0001.Rcheck"))
        ), class = c("packages_info", "data.frame"))
      ),
      cleaner = new.env()
    ),
    check_score = 1
  )
)

test_that("handle_null returns 'N/A' for NULL", {
  expect_equal(handle_null(NULL), "N/A")
})

test_that("handle_null returns original value for non-NULL", {
  expect_equal(handle_null(123), 123)
  expect_equal(handle_null("text"), "text")
})

test_that("convert_number_to_abbreviation handles millions", {
  expect_equal(convert_number_to_abbreviation(1500000), "1.5M")
  expect_equal(convert_number_to_abbreviation(-2500000), "-2.5M")
})

test_that("convert_number_to_abbreviation handles thousands", {
  expect_equal(convert_number_to_abbreviation(1200), "1.2K")
  expect_equal(convert_number_to_abbreviation(-9999), "-10K")
})

test_that("convert_number_to_abbreviation handles small numbers", {
  expect_equal(convert_number_to_abbreviation(999), "999")
  expect_equal(convert_number_to_abbreviation(0), "0")
})

test_that("convert_number_to_abbreviation handles NA and non-numeric", {
  expect_true(is.na(convert_number_to_abbreviation(NA)))
  expect_true(is.na(convert_number_to_abbreviation("text")))
})

test_that("generate_rcmd_check_rmd_section works correctly", {
  result <- generate_rcmd_check_section(toy_assessment_results)
  expect_equal(result$Message, "RCMD Check score")
  expect_equal(result$Score, "100%")
  expect_equal(result$Errors, "No errors")
  expect_equal(result$Warnings, "No warnings")
  expect_equal(result$Notes, "No notes")
})

test_that("safe_value returns 'N/A' for NULL", {
  expect_equal(safe_value(NULL), "N/A")
})

test_that("safe_value abbreviates numeric values", {
  expect_equal(safe_value(1000), "1K")
  expect_equal(safe_value(1000000), "1M")
})

test_that("safe_value returns character for small numbers", {
  expect_equal(safe_value(42), "42")
})

# Define the toy assessment_results object
toy_assessment_results_1_1 <- list(
  results = list(
    pkg_name = "test.package.0001",
    pkg_version = "1.0.0",
    license_name = "MIT + file LICENSE",
    cran_link = "https://cran.r-project.org/src/contrib/stringr_1.5.1.tar.gz",
    github_link = "https://github.com/tidyverse/stringr",
    bioc_link = NULL,
    internal_link = NULL
  )
)

# Test the generate_risk_summary function
test_that("generate_risk_summary works correctly", {
  result <- generate_risk_summary(toy_assessment_results_1_1)
  
  expect_equal(result$Metric[1], "Package")
  expect_equal(result$Value[1], "test.package.0001")
  expect_equal(result$Metric[2], "Version")
  expect_equal(result$Value[2], "1.0.0")
  expect_equal(result$Metric[3], "License")
  expect_equal(result$Value[3], "MIT + file LICENSE")
  expect_equal(result$Metric[4], "CRAN link")
  expect_equal(result$Value[4], "No CRAN link found")
  expect_equal(result$Metric[5], "GitHub repository")
  expect_equal(result$Value[5], "No GitHub link found")
  expect_equal(result$Metric[6], "Bioconductor Link")
  expect_equal(result$Value[6], "No Bioconductor link found")
  expect_equal(result$Metric[7], "Internal Repository")
  expect_equal(result$Value[7], "No Internal link found")
})

# Define the toy assessment_results object
toy_assessment_results_1_2 <- list(
  results = list(
    check = 1L,
    covr = 1L,
    date_time = "2025-01-13 17:01:49",
    executor = "test.executor",
    sysname = "Linux",
    release = "5.4.0-42-generic",
    machine = "x86_64",
    check_list = list(res_check = list(rversion = "4.0.2"))
  )
)

# Define the expected output
expected_risk_details <- list(
  Metric = c(
    'R CMD Check Score', 'Test Coverage Score', 'Date Time', 'Executor', 
    'OS Name', 'OS Release', 'OS Machine', 'R version'
  ),
  Value = c(
    toy_assessment_results_1_2$results$check,
    toy_assessment_results_1_2$results$covr,
    toy_assessment_results_1_2$results$date_time,
    toy_assessment_results_1_2$results$executor,
    toy_assessment_results_1_2$results$sysname,
    toy_assessment_results_1_2$results$release,
    toy_assessment_results_1_2$results$machine,
    toy_assessment_results_1_2$results$check_list$res_check$rversion
  )
)

# Test the generate_risk_details function
test_that("generate_risk_details works correctly", {
  result <- generate_risk_details(toy_assessment_results_1_2)
  
  expect_equal(result$Metric, expected_risk_details$Metric)
})

test_that("generate_coverage_section works correctly", {
  result <- generate_coverage_section(toy_assessment_results)
  expect_equal(result$Function[1], "R/myscript.R")
  expect_equal(result$Coverage[1], 50)
  expect_equal(result$Errors, "No test coverage errors")
  expect_equal(result$Notes, "No test coverage notes")
})

test_that("create_file_coverage_df works correctly with toy dataset", {
  # Toy dataset
  file_names <- c("file1.R", "file2.R")
  file_coverage <- c(85.0, 90.0)
  notes <- c("Note1", "Note2")
  errors <- list(
    message = "in callr subprocess.",
    status = 0
  )
  
  # Expected output
  expected_output <- data.frame(
    File = c("file1.R", "file2.R"),
    Coverage = c(85.0, 90.0),
    Errors = rep("in callr subprocess.; 0", 2),
    Notes = c("Note1", "Note2"),
    stringsAsFactors = FALSE
  )
  
  # Run the function
  result <- create_file_coverage_df(file_names, file_coverage, errors, notes)
  
  # Check if the result matches the expected output
  expect_equal(result, expected_output)
})

test_that("generate_doc_metrics_section works correctly", {
  result <- generate_doc_metrics_section(toy_assessment_results)
  expect_equal(result$Metric[1], "Has Bug Reports URL")
  expect_equal(result$Value[1], "Not Included")
})

test_that("generate_pop_metrics_section works correctly", {
  result <- generate_pop_metrics_section(toy_assessment_results)
  expect_equal(result$Metric[1], "Date created")
  expect_equal(result$Value[1], "2016-07-19T14:47:19Z")
  expect_equal(result$Metric[2], "Stars")
  expect_equal(result$Value[2], "422")
  expect_equal(result$Metric[3], "Forks")
  expect_equal(result$Value[3], "45")
  expect_equal(result$Metric[4], "Data Extract Date")
  expect_equal(result$Value[4], "2025-07-02")
  expect_equal(result$Metric[5], "Recent Commits")
  expect_equal(result$Value[5], "0")
  expect_equal(result$Metric[6], "Open Issues")
  expect_equal(result$Value[6], "29")
  expect_equal(result$Metric[7], "Downloads Total")
  expect_equal(result$Value[7], "11.4M")
  expect_equal(result$Metric[8], "Downloads Last Month")
  expect_equal(result$Value[8], "299.4K")
})

# Test for generate_deps_section function
# Define the expected output
expected_deps_df <- data.frame(
  Package = c("checkmate", "testthat"),
  Version = c("2.1.0", "3.2.1.1"),
  Type = c("Imports", "Suggests"),
  stringsAsFactors = FALSE
)

expected_import_count <- 1
expected_suggest_count <- 1

# Test the generate_deps_section function
test_that("generate_deps_section works correctly", {
  result <- generate_deps_section(toy_assessment_results)
  
  expect_equal(result$deps_df, expected_deps_df)
  expect_equal(result$import_count, expected_import_count)
  expect_equal(result$suggest_count, expected_suggest_count)
})

# Define the toy assessment_results object
toy_assessment_results_2 <- list(
  results = list(
    rev_deps = c("abcrf", "abjutils", "accessrmd", "accucor", "ace2fastq")
  )
)

# Define the expected output
expected_rev_deps <- c("abcrf", "abjutils", "accessrmd", "accucor", "ace2fastq")

expected_rev_deps_no <- 5

# Test the generate_rev_deps_section function
test_that("generate_rev_deps_section works correctly", {
  result <- generate_rev_deps_section(toy_assessment_results_2)
  
  expect_equal(result$rev_deps_df$Reverse_dependencies, expected_rev_deps)
  expect_equal(result$rev_deps_summary$rev_deps_no, expected_rev_deps_no)
})

test_that("generate_trace_matrix_section works correctly with empty trace matrix", {
  # Toy dataset with empty trace matrix
  assessment_results <- list(
    covr_list = list(
      res_cov = list(
        coverage = list(
          totalcoverage = NA,
          filecoverage = NA
        )
      )
    )
  )
  
  file_coverage <- assessment_results$covr_list$res_cov$coverage$filecoverage
  total_coverage <- assessment_results$covr_list$res_cov$coverage$totalcoverage
  
  # Expected output
  expected_output <- data.frame(
    Exported_function = " ",
    Function_type = " ",
    Code_script = " ",
    Documentation = " ",
    Description = "Traceability matrix unsuccessful",
    Test_Coverage = " ",
    stringsAsFactors = FALSE
  )
  
  # Run the function
  result <- 
    generate_trace_matrix_section(total_coverage, file_coverage, assessment_results)
  
  # Check if the result matches the expected output
  expect_equal(result, expected_output)
})

test_that("generate_html_report returns message when directory does not exist", {
  # Mock the fs::dir_exists function to return FALSE
  mockery::stub(generate_html_report, "fs::dir_exists", FALSE)
  
  # Define the output directory
  output_dir <- "mock_output_dir"
  
  # Capture the message output
  expect_message(output_file <- generate_html_report(toy_assessment_results, output_dir), "The output directory does not exist.")
  
  # Check that the output file is NULL
  expect_null(output_file)
})


test_that("generate_html_report creates an HTML report", {
  skip_on_cran()
  # Create a temporary directory for output
  tmp_dir <- withr::local_tempdir()
  
  # Ensure cleanup of all files in tmp_dir
  withr::defer(unlink(tmp_dir, recursive = TRUE), envir = parent.frame())
  
  # Force rendering in CRAN/win-builder
  withr::local_envvar(NOT_CRAN = "true")
  
  # Run the function
  generate_html_report(toy_assessment_results, tmp_dir)
  
  # Find any .html file in tmp_dir
  html_files <- list.files(tmp_dir, pattern = "\\.html$", full.names = TRUE)
  
  # Check that at least one HTML file exists and is non-empty
  expect_true(length(html_files) > 0, info = "No HTML report was generated")
  expect_true(file.info(html_files[1])$size > 0, info = "HTML report is empty")
  
})

