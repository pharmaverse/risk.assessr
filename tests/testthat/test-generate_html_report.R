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
    has_examples = list(
      data = data.frame(
        function_name = c("here", "i_am", "dr_here", "set_here"),
        documentation_name = c("here", "i_am", "dr_here", "set_here"),
        documentation_location = c(
          "man/here.Rd",
          "man/i_am.Rd",
          "man/dr_here.Rd",
          "man/set_here.Rd"
        ),
        example = c(
          "here()\n\nhere(\"some\", \"path\", \"below\", \"your\", \"project\", \"root.txt\")\nhere(\"some/path/below/your",
          "here::i_am(\"prepare/penguins.R\")\nhere::i_am(\"analysis/report.Rmd\", uuid = \"f9e884084b84794d762a535f3facec85\")",
          "dr_here()",
          "no example"
        ),
        stringsAsFactors = FALSE
      ),
      example_score = .75
    ),
    has_docs = list(
      data = data.frame(
        function_name = c("here", "i_am", "dr_here", "set_here"),
        documentation_name = c("here", "i_am", "dr_here", "set_here"),
        documentation_location = c(
          "man/here.Rd",
          "man/i_am.Rd",
          "man/dr_here.Rd",
          "man/set_here.Rd"
        ),
        stringsAsFactors = FALSE
      ),
      has_docs_score = 1
    ),
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
  expect_equal(handle_null(123), "123")
  expect_equal(handle_null("text"), "text")
})


testthat::test_that("handle_null returns comma-separated string for logical inputs", {
  # Mocked logical inputs
  x1 <- TRUE
  x2 <- c(TRUE, FALSE)
  x3 <- c(TRUE, NA, FALSE)
  
  out1 <- handle_null(x1)
  out2 <- handle_null(x2)
  out3 <- handle_null(x3)
  
  # Each should hit: else if (is.logical(x)) return(paste(as.character(x), collapse = ", "))
  testthat::expect_identical(out1, "TRUE")
  testthat::expect_identical(out2, "TRUE, FALSE")
  testthat::expect_identical(out3, "TRUE, NA, FALSE")
  
  # Sanity: each result is a length-1 character scalar
  testthat::expect_type(out1, "character"); testthat::expect_equal(length(out1), 1L)
  testthat::expect_type(out2, "character"); testthat::expect_equal(length(out2), 1L)
  testthat::expect_type(out3, "character"); testthat::expect_equal(length(out3), 1L)
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


testthat::test_that("collapses multi-part given names into a single string", {
  person_obj <- list(
    list(
      given  = c("Jane", "Ann"),
      family = "Doe",
      email  = "jane@example.com"
    )
  )
  
  out <- extract_maintainer_info(person_obj)
  
  # Accept both literal angle brackets and HTML-escaped ones.
  expected_plain <- "Jane Ann Doe < jane@example.com >"
  expected_html  <- "Jane Ann Doe &lt; jane@example.com &gt;"
  
  testthat::expect_true(
    out %in% c(expected_plain, expected_html),
    info = paste("Got:", out)
  )
})

testthat::test_that("single-part given name is unchanged", {
  person_obj <- list(
    list(
      given  = "Jane",
      family = "Doe",
      email  = "jane@example.com"
    )
  )
  
  out <- extract_maintainer_info(person_obj)
  
  expected_plain <- "Jane Doe < jane@example.com >"
  expected_html  <- "Jane Doe &lt; jane@example.com &gt;"
  
  testthat::expect_true(
    out %in% c(expected_plain, expected_html),
    info = paste("Got:", out)
  )
})

testthat::test_that("uses the first person in the list", {
  person_obj <- list(
    list(
      given  = c("First", "Person"),
      family = "One",
      email  = "first.one@example.com"
    ),
    list(
      given  = c("Second", "Person"),
      family = "Two",
      email  = "second.two@example.com"
    )
  )
  
  out <- extract_maintainer_info(person_obj)
  
  expected_plain_first <- "First Person One < first.one@example.com >"
  expected_html_first  <- "First Person One &lt; first.one@example.com &gt;"
  
  # Ensure the output corresponds to the FIRST entry, not the second
  testthat::expect_true(
    out %in% c(expected_plain_first, expected_html_first),
    info = paste("Got:", out)
  )
  
  # And it should not match the second entry
  unexpected_plain_second <- "Second Person Two < second.two@example.com >"
  unexpected_html_second  <- "Second Person Two &lt; second.two@example.com &gt;"
  
  testthat::expect_false(
    out %in% c(unexpected_plain_second, unexpected_html_second),
    info = paste("Unexpectedly got:", out)
  )
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
  pkg_name <- "test.package.0001"
  result <- generate_coverage_section(toy_assessment_results, pkg_name)
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


testthat::test_that("generate_coverage_section returns NA-row when file_names is NULL", {
  # Build file_coverage with NULL dimnames so attr(..., "dimnames")[[1]] == NULL
  # grepl(pattern, NULL) returns logical(0) -> any(logical(0)) == FALSE, so the
  # extract_short_path branch is never entered; no stub needed.
  file_coverage_mat <- matrix(
    numeric(0),
    nrow = 0, ncol = 0,
    dimnames = list(NULL, NULL)
  )
  
  assessment_results <- list(
    covr_list = list(
      res_cov = list(
        coverage = list(
          totalcoverage = 85.1,
          filecoverage  = file_coverage_mat
        ),
        errors = NA,
        notes  = NA
      )
    )
  )
  
  out <- generate_coverage_section(assessment_results, pkg_name = "mypkg")
  
  # Validate the NA-row data.frame
  testthat::expect_s3_class(out, "data.frame")
  testthat::expect_identical(colnames(out), c("Function", "Coverage", "Errors", "Notes"))
  testthat::expect_equal(nrow(out), 1L)
  
  # Column-wise checks match the code block: NA_character_, NA_real_, NA, NA
  testthat::expect_true(is.na(out$Function))
  testthat::expect_identical(typeof(out$Function), "character")
  
  testthat::expect_true(is.na(out$Coverage))
  testthat::expect_identical(typeof(out$Coverage), "double")  # NA_real_
  
  testthat::expect_true(is.na(out$Errors))
  testthat::expect_identical(typeof(out$Errors), "logical")   # plain NA
  
  testthat::expect_true(is.na(out$Notes))
  testthat::expect_identical(typeof(out$Notes), "logical")    # plain NA
})

testthat::test_that("generate_coverage_section shortens full Linux paths via extract_short_path", {
  # File names are absolute Linux paths; extract_short_path should reduce each
  # to its last two components, e.g. "/tmp/.../R/myscript.R" -> "R/myscript.R"
  assessment_results_full_path <- list(
    covr_list = list(
      res_cov = list(
        coverage = list(
          filecoverage = structure(
            75,
            .Dim    = c(1L),
            .Dimnames = list("/tmp/RtmpXXXXXX/test.package.0001/R/myscript.R")
          ),
          totalcoverage = 75
        ),
        errors = NA,
        notes  = NA
      )
    )
  )
  
  result <- generate_coverage_section(assessment_results_full_path, pkg_name = "test.package.0001")
  
  testthat::expect_s3_class(result, "data.frame")
  testthat::expect_equal(result$Function[1], "R/myscript.R")
  testthat::expect_equal(result$Coverage[1], 75)
  testthat::expect_equal(result$Errors[1],   "No test coverage errors")
  testthat::expect_equal(result$Notes[1],    "No test coverage notes")
})

testthat::test_that("multi_framework: returns named list with one entry per framework", {
  # Stub extract_coverage_df so the test is independent of its internals.
  # Each call returns a distinct sentinel data.frame identified by a marker column.
  df_testthat <- data.frame(fw = "testthat", stringsAsFactors = FALSE)
  df_tinytest <- data.frame(fw = "tinytest", stringsAsFactors = FALSE)
  
  call_log <- character(0)
  
  fn <- generate_coverage_section
  mockery::stub(fn, "extract_coverage_df", function(res_cov, pkg_name) {
    # Identify which framework is being processed by a field we embed in res_cov
    call_log <<- c(call_log, res_cov$.fw_id)
    if (res_cov$.fw_id == "testthat") df_testthat else df_tinytest
  })
  
  ar <- list(
    covr_list = list(
      multi_framework = TRUE,
      frameworks      = list("testthat", "tinytest"),
      results         = list(
        testthat = list(res_cov = list(.fw_id = "testthat",
                                       coverage = list(filecoverage = numeric(0),
                                                       totalcoverage = 80),
                                       errors = NA, notes = NA)),
        tinytest = list(res_cov = list(.fw_id = "tinytest",
                                       coverage = list(filecoverage = numeric(0),
                                                       totalcoverage = 90),
                                       errors = NA, notes = NA))
      )
    )
  )
  
  out <- fn(ar, pkg_name = "mypkg")
  
  # Result must be a named list, not a data.frame
  testthat::expect_true(is.list(out) && !is.data.frame(out))
  testthat::expect_identical(names(out), c("testthat", "tinytest"))
  testthat::expect_equal(length(out), 2L)
})

testthat::test_that("multi_framework: each list element is the data.frame from extract_coverage_df", {
  df_fw1 <- data.frame(Function = "R/a.R", Coverage = 80, Errors = "none", Notes = "none",
                       stringsAsFactors = FALSE)
  df_fw2 <- data.frame(Function = "R/b.R", Coverage = 90, Errors = "none", Notes = "none",
                       stringsAsFactors = FALSE)
  
  fn <- generate_coverage_section
  mockery::stub(fn, "extract_coverage_df", function(res_cov, pkg_name) {
    if (res_cov$.fw_id == "fw1") df_fw1 else df_fw2
  })
  
  ar <- list(
    covr_list = list(
      multi_framework = TRUE,
      frameworks      = list("fw1", "fw2"),
      results         = list(
        fw1 = list(res_cov = list(.fw_id = "fw1",
                                  coverage = list(filecoverage = numeric(0), totalcoverage = 80),
                                  errors = NA, notes = NA)),
        fw2 = list(res_cov = list(.fw_id = "fw2",
                                  coverage = list(filecoverage = numeric(0), totalcoverage = 90),
                                  errors = NA, notes = NA))
      )
    )
  )
  
  out <- fn(ar, pkg_name = "mypkg")
  
  # fw1 slot must be exactly df_fw1, fw2 slot exactly df_fw2
  testthat::expect_identical(out[["fw1"]], df_fw1)
  testthat::expect_identical(out[["fw2"]], df_fw2)
})

testthat::test_that("multi_framework: extract_coverage_df is called once per framework with correct res_cov", {
  received_res_covs <- list()
  
  fn <- generate_coverage_section
  mockery::stub(fn, "extract_coverage_df", function(res_cov, pkg_name) {
    received_res_covs[[length(received_res_covs) + 1]] <<- res_cov
    data.frame()
  })
  
  res_cov_a <- list(.fw_id = "alpha", coverage = list(filecoverage = numeric(0), totalcoverage = 70),
                    errors = NA, notes = NA)
  res_cov_b <- list(.fw_id = "beta",  coverage = list(filecoverage = numeric(0), totalcoverage = 30),
                    errors = NA, notes = NA)
  
  ar <- list(
    covr_list = list(
      multi_framework = TRUE,
      frameworks      = list("alpha", "beta"),
      results         = list(
        alpha = list(res_cov = res_cov_a),
        beta  = list(res_cov = res_cov_b)
      )
    )
  )
  
  fn(ar, pkg_name = "mypkg")
  
  # extract_coverage_df must have been called exactly twice
  testthat::expect_equal(length(received_res_covs), 2L)
  
  # First call received alpha's res_cov, second received beta's
  testthat::expect_identical(received_res_covs[[1]], res_cov_a)
  testthat::expect_identical(received_res_covs[[2]], res_cov_b)
})


test_that("generate_doc_metrics_section works correctly", {
  result <- generate_doc_metrics_section(toy_assessment_results)
  
  expect_true(is.data.frame(result$has_examples))
    
  # Correct columns
  expect_identical(
    names(result$has_examples),
    c("function_name", "documentation_name", "documentation_location", "example")
  )
    
  # Score attribute exists
  expect_true(!is.null(attr(result$has_examples, "score")))
    
  # Score is numeric, NA allowed
  expect_true(is.numeric(attr(result$has_examples, "score")))
  
  # use match because string truncated in your display
  
  
  expect_true(is.data.frame(result$has_docs))
  
  expect_identical(
    names(result$has_docs),
    c("function_name", "documentation_name", "documentation_location")
  )
  
  # Score attribute exists
  expect_true(!is.null(attr(result$has_docs, "score")))
  
  # Score is numeric
  expect_true(is.numeric(attr(result$has_docs, "score")))
  
  
  expect_true(is.data.frame(result$doc_metrics))
  
  expect_identical(names(result$doc_metrics), c("Metric", "Value"))
  
  # Metric must be character
  expect_true(is.character(result$doc_metrics$Metric))
  
  # Value must be character (your example shows strings)
  expect_true(is.character(result$doc_metrics$Value))
  
  # high level structure test
  expect_true(is.list(result))
  expect_named(result, c("has_examples", "has_docs", "doc_metrics"))
  
})


# ---- Helpers ---------------------------------------------------------------

# Build a minimal assessment_results with pluggable 'has_examples'
make_base_assessment_for_examples <- function(hex_obj) {
  list(
    results = list(
      author = list(
        # Structure not actually used because we'll stub extract_maintainer_info()
        maintainer = list(name = "Any", email = "any@example.com")
      ),
      # Target under test:
      has_examples = hex_obj,
      
      # Provide a simple valid has_docs to avoid interference with our focus
      has_docs = data.frame(doc = "README", present = TRUE, stringsAsFactors = FALSE),
      
      # Other metrics (simple scalars) — will be passed through handle_null (stubbed)
      has_bug_reports_url = 1,
      license             = 1,
      has_news            = 0,
      has_source_control  = 1,
      has_vignettes       = 0,
      has_website         = 1,
      news_current        = 1,
      export_help         = 0
    )
  )
}

# Create a stubbed copy of the function so external helpers don't leak into tests
make_stubbed_fun <- function() {
  fn <- generate_doc_metrics_section
  # Stub external helpers referenced by the function
  mockery::stub(fn, "extract_maintainer_info", function(x) "Mock Maintainer <mock@example.com>")
  mockery::stub(fn, "handle_null", function(x) x)  # identity to keep values as-is
  fn
}

# ---- Tests -----------------------------------------------------------------

testthat::test_that("'has_examples' as data.frame is used directly and score attr set to NA_real_", {
  # This should exercise:
  # } else if (is.data.frame(hex)) {
  #   has_examples_df <- hex
  #   attr(has_examples_df, "score") <- NA_real_
  # }
  hex_df <- data.frame(
    name    = c("f1", "f2", "f3"),
    example = c("Has example", "No Example", "no example "),
    stringsAsFactors = FALSE
  )
  
  assessment_results <- make_base_assessment_for_examples(hex_df)
  fn <- make_stubbed_fun()
  
  out <- fn(assessment_results)
  
  # Validate structure
  testthat::expect_true(is.list(out))
  testthat::expect_true("has_examples" %in% names(out))
  has_examples_df <- out$has_examples
  testthat::expect_s3_class(has_examples_df, "data.frame")
  
  # Because the function filters to rows where example == "no example" (case/space-insensitive),
  # we should only keep rows 2 and 3 from the original data.
  testthat::expect_equal(nrow(has_examples_df), 2L)
  testthat::expect_true(all(tolower(trimws(has_examples_df$example)) == "no example"))
  
  # Attribute must be NA_real_
  sc <- attr(has_examples_df, "score")
  testthat::expect_true(is.na(sc))
  testthat::expect_identical(typeof(sc), "double")
})

testthat::test_that("'has_examples' missing (NULL/other) yields empty data.frame and score NA_real_", {
  
  hex <- NULL
  
  assessment_results <- make_base_assessment_for_examples(hex)
  fn <- make_stubbed_fun()
  
  out <- fn(assessment_results)
  
  has_examples_df <- out$has_examples
  testthat::expect_s3_class(has_examples_df, "data.frame")
  testthat::expect_equal(nrow(has_examples_df), 0L)
  testthat::expect_equal(ncol(has_examples_df), 0L)
  
  sc <- attr(has_examples_df, "score")
  testthat::expect_true(is.na(sc))
  testthat::expect_identical(typeof(sc), "double")
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


# Helper to build a minimal assessment_results with pluggable 'has_docs'
make_base_assessment <- function(has_docs_obj) {
  list(
    results = list(
      author = list(
        maintainer = list(name = "Any Name", email = "any@example.com")
      ),
      # has_examples is exercised but not the focus; we keep it minimal and valid
      has_examples = list(
        data = data.frame(
          `function` = c("f1", "f2"),
          example  = c("Has example", "No Example"),
          stringsAsFactors = FALSE
        ),
        example_score = 0.75
      ),
      # The branch under test:
      has_docs = has_docs_obj,
      
      # The remaining metrics used by the function — provide simple 0/1 values
      has_bug_reports_url = 1,
      license             = 1,
      has_news            = 0,
      has_source_control  = 1,
      has_vignettes       = 0,
      has_website         = 1,
      news_current        = 1,
      export_help         = 0
    )
  )
}

# Utility to create a stubbed copy of the function under test
make_stubbed_fun <- function() {
  # Local copy so stub works on a closure we can call in tests
  fn <- generate_doc_metrics_section
  
  # Stub external helpers referenced by the function
  mockery::stub(fn, "extract_maintainer_info", function(x) "Mock Maintainer <mock@example.com>")
  mockery::stub(fn, "handle_null", function(x) x)  # identity to keep values as-is
  
  fn
}

# ---------------------------------------------------------------------------
# Shared helpers for generate_html_report multi_framework branch tests
# ---------------------------------------------------------------------------

# Minimal assessment_results for generate_html_report that satisfies
# checkmate assertions and provides all tm_list fields accessed after the
# multi_framework if/else block.
make_mf_assessment <- function(covr_list_override) {
  list(
    results  = list(pkg_name = "mypkg", pkg_version = "1.0.0"),
    covr_list = covr_list_override,
    tm_list = list(
      tm = dplyr::tibble(),
      coverage = list(
        high_risk   = dplyr::tibble(),
        medium_risk = dplyr::tibble(),
        low_risk    = dplyr::tibble()
      ),
      function_type = list(
        defunct      = dplyr::tibble(),
        imported     = dplyr::tibble(),
        rexported    = dplyr::tibble(),
        experimental = dplyr::tibble()
      )
    ),
    check_list = list(check_score = 1)
  )
}

# Stub all heavy helpers on a copy of generate_html_report so the test only
# exercises the multi_framework if/else lines (67-74).  Returns the stubbed
# function AND a mutable `captured` environment for inspecting call args.
make_stubbed_html_report <- function() {
  dummy_df      <- data.frame()
  dummy_thresh  <- list(high_max = 0.9, medium_max = 0.7, low_max = 0.5)
  dummy_lic     <- list(high = character(0), medium = character(0), low = character(0))
  dummy_deps    <- list(deps_df = data.frame(), dep_score = 0,
                        import_count = 0L, suggest_count = 0L)
  dummy_revdeps <- list(
    rev_deps_df      = data.frame(Reverse_dependencies = character(0)),
    rev_deps_summary = list(rev_deps_no = 0L, rev_deps_score = 0)
  )
  dummy_docs <- list(
    has_examples = data.frame(),
    has_docs     = data.frame(),
    doc_metrics  = data.frame(Metric = character(0), Value = character(0))
  )
  
  captured <- new.env(parent = emptyenv())
  
  fn <- generate_html_report
  mockery::stub(fn, "generate_risk_summary",            function(...) dummy_df)
  mockery::stub(fn, "generate_risk_details",            function(...) dummy_df)
  mockery::stub(fn, "generate_rcmd_check_section",      function(...) dummy_df)
  mockery::stub(fn, "generate_coverage_section",        function(...) dummy_df)
  mockery::stub(fn, "generate_doc_metrics_section",     function(...) dummy_docs)
  mockery::stub(fn, "generate_pop_metrics_section",     function(...) dummy_df)
  mockery::stub(fn, "generate_deps_section",            function(...) dummy_deps)
  mockery::stub(fn, "generate_rev_deps_section",        function(...) dummy_revdeps)
  mockery::stub(fn, "generate_trace_matrix_section",    function(total_coverage, file_coverage, tm_df) {
    captured$total_coverage <- total_coverage
    captured$file_coverage  <- file_coverage
    dummy_df
  })
  mockery::stub(fn, "generate_fg_trace_matrix_section", function(...) dummy_df)
  mockery::stub(fn, "get_risk_definition",              function(...) list())
  mockery::stub(fn, "extract_thresholds_by_id",         function(...) list())
  mockery::stub(fn, "get_max_thresholds",               function(...) dummy_thresh)
  mockery::stub(fn, "extract_thresholds_by_key",        function(...) list())
  mockery::stub(fn, "get_license_thresholds",           function(...) dummy_lic)
  mockery::stub(fn, "dir_exists",                       function(...) TRUE)
  mockery::stub(fn, "path_abs",                         function(...) "/tmp/report.html")
  mockery::stub(fn, "system.file",                      function(...) "")
  mockery::stub(fn, "render",                           function(...) invisible(NULL))
  
  list(fn = fn, captured = captured)
}

testthat::test_that("multi_framework TRUE: total_coverage = total_cov * 100", {
  fw1_file_cov <- structure(
    c(80, 60),
    .Dim      = c(2L),
    .Dimnames = list(c("R/foo.R", "R/bar.R"))
  )
  
  ar <- make_mf_assessment(list(
    multi_framework = TRUE,
    total_cov       = 0.75,
    frameworks      = list("testthat", "tinytest"),
    results         = list(
      testthat = list(res_cov = list(
        coverage = list(filecoverage = fw1_file_cov, totalcoverage = 75),
        errors = NA, notes = NA
      )),
      tinytest = list(res_cov = list(
        coverage = list(
          filecoverage = structure(90, .Dim = c(1L), .Dimnames = list("R/baz.R")),
          totalcoverage = 90
        ),
        errors = NA, notes = NA
      ))
    )
  ))
  
  h <- make_stubbed_html_report()
  withr::with_envvar(c(NOT_CRAN = "true"), h$fn(ar, output_dir = tempdir()))
  
  # Line 68: total_cov * 100
  testthat::expect_equal(h$captured$total_coverage, 75)
})

testthat::test_that("multi_framework TRUE: file_coverage taken from first framework, not second", {
  fw1_file_cov <- structure(
    c(80, 60),
    .Dim      = c(2L),
    .Dimnames = list(c("R/foo.R", "R/bar.R"))
  )
  fw2_file_cov <- structure(
    90,
    .Dim      = c(1L),
    .Dimnames = list("R/baz.R")
  )
  
  ar <- make_mf_assessment(list(
    multi_framework = TRUE,
    total_cov       = 0.75,
    frameworks      = list("testthat", "tinytest"),
    results         = list(
      testthat = list(res_cov = list(
        coverage = list(filecoverage = fw1_file_cov, totalcoverage = 75),
        errors = NA, notes = NA
      )),
      tinytest = list(res_cov = list(
        coverage = list(filecoverage = fw2_file_cov, totalcoverage = 90),
        errors = NA, notes = NA
      ))
    )
  ))
  
  h <- make_stubbed_html_report()
  withr::with_envvar(c(NOT_CRAN = "true"), h$fn(ar, output_dir = tempdir()))
  
  # Lines 69-70: first framework ("testthat") filecoverage, NOT "tinytest"
  testthat::expect_identical(h$captured$file_coverage, fw1_file_cov)
  testthat::expect_false(identical(h$captured$file_coverage, fw2_file_cov))
})

testthat::test_that("multi_framework FALSE: falls back to top-level res_cov fields", {
  file_cov <- structure(
    55,
    .Dim      = c(1L),
    .Dimnames = list("R/single.R")
  )
  
  ar <- make_mf_assessment(list(
    multi_framework = FALSE,
    res_cov = list(
      coverage = list(filecoverage = file_cov, totalcoverage = 55),
      errors = NA, notes = NA
    )
  ))
  
  h <- make_stubbed_html_report()
  withr::with_envvar(c(NOT_CRAN = "true"), h$fn(ar, output_dir = tempdir()))
  
  # Line 72-73: else branch
  testthat::expect_equal(h$captured$total_coverage, 55)
  testthat::expect_identical(h$captured$file_coverage, file_cov)
})

testthat::test_that("has_docs list with data + has_docs_score sets data.frame and score attr", {
  hdoc <- list(
    data = data.frame(doc = c("README", "NEWS"), present = c(TRUE, TRUE), stringsAsFactors = FALSE),
    has_docs_score = 0.9
  )
  assessment_results <- make_base_assessment(hdoc)
  fn <- make_stubbed_fun()
  
  out <- fn(assessment_results)
  
  testthat::expect_true(is.list(out))
  testthat::expect_true("has_docs" %in% names(out))
  
  has_docs_df <- out$has_docs
  testthat::expect_s3_class(has_docs_df, "data.frame")
  testthat::expect_equal(nrow(has_docs_df), 2L)
  testthat::expect_equal(attr(has_docs_df, "score"), 0.9, tolerance = 1e-12)
})

testthat::test_that("has_docs list with data + NULL has_docs_score falls back to NA_real_", {
  hdoc <- list(
    data = data.frame(doc = "README", present = TRUE, stringsAsFactors = FALSE),
    has_docs_score = NULL
  )
  assessment_results <- make_base_assessment(hdoc)
  fn <- make_stubbed_fun()
  
  out <- fn(assessment_results)
  
  has_docs_df <- out$has_docs
  testthat::expect_s3_class(has_docs_df, "data.frame")
  testthat::expect_equal(nrow(has_docs_df), 1L)
  
  sc <- attr(has_docs_df, "score")
  testthat::expect_true(is.na(sc))
  # Confirm numeric NA (NA_real_) — typeof should be "double"
  testthat::expect_identical(typeof(sc), "double")
})

testthat::test_that("has_docs data.frame path returns input data.frame and score attr NA_real_", {
  hdoc <- data.frame(
    doc = c("README", "VIGNETTE"),
    present = c(TRUE, FALSE),
    stringsAsFactors = FALSE
  )
  assessment_results <- make_base_assessment(hdoc)
  fn <- make_stubbed_fun()
  
  out <- fn(assessment_results)
  
  has_docs_df <- out$has_docs
  testthat::expect_s3_class(has_docs_df, "data.frame")
  testthat::expect_equal(nrow(has_docs_df), 2L)
  # Score attribute must be NA_real_
  sc <- attr(has_docs_df, "score")
  testthat::expect_true(is.na(sc))
  testthat::expect_identical(typeof(sc), "double")
})

testthat::test_that("has_docs fallback path (NULL/other) yields empty data.frame and score attr NA_real_", {
  hdoc <- NULL  # could also be an atomic or list without $data; either triggers the else branch
  assessment_results <- make_base_assessment(hdoc)
  fn <- make_stubbed_fun()
  
  out <- fn(assessment_results)
  
  has_docs_df <- out$has_docs
  testthat::expect_s3_class(has_docs_df, "data.frame")
  testthat::expect_equal(nrow(has_docs_df), 0L)
  testthat::expect_equal(ncol(has_docs_df), 0L)
  
  sc <- attr(has_docs_df, "score")
  testthat::expect_true(is.na(sc))
  testthat::expect_identical(typeof(sc), "double")
})

