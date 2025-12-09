test_that("test doc_riskmetrics", {
  
  # set CRAN repo 
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  dp <- system.file("test-data", "stringr-1.5.1.tar.gz",
                    package = "risk.assessr")
  
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
    pkg_desc <- get_pkg_desc(pkg_source_path, 
                             fields = c("Package", 
                                        "Version"))
    
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)
    
    doc_riskmetric_test <- 
      doc_riskmetric(pkg_name, pkg_ver, pkg_source_path)
    
    expect_identical(length(doc_riskmetric_test), 10L)
    expect_true(checkmate::check_list(doc_riskmetric_test, all.missing = FALSE))
    expect_true(checkmate::check_list(doc_riskmetric_test, any.missing = TRUE))
  }
})


test_that("doc_riskmetric handles missing R folder", {
  
  # Stub fs::dir_exists to simulate missing R folder
  mockery::stub(doc_riskmetric, "fs::dir_exists", function(path) FALSE)
  
  # Stub fs::path to return a dummy path
  mockery::stub(doc_riskmetric, "fs::path", function(...) "mock/path/R")
  
  # Stub assess_description_file_elements to return expected structure
  mockery::stub(doc_riskmetric, "assess_description_file_elements", function(pkg_name, pkg_source_path) {
    list(
      has_bug_reports_url = TRUE,
      has_source_control = TRUE,
      has_maintainer = TRUE,
      has_website = TRUE
    )
  })
  
  # Stub other assess_* functions to return dummy values
  mockery::stub(doc_riskmetric, "assess_export_help", function(...) TRUE)
  mockery::stub(doc_riskmetric, "assess_vignettes", function(...) TRUE)
  mockery::stub(doc_riskmetric, "assess_examples", function(...) TRUE)
  mockery::stub(doc_riskmetric, "assess_news", function(...) TRUE)
  mockery::stub(doc_riskmetric, "assess_news_current", function(...) TRUE)
  
  pkg_name <- "mockpkg"
  pkg_ver <- "0.1.0"
  pkg_source_path <- "mock/path"
  
  expect_message(
    doc_scores <- doc_riskmetric(pkg_name, pkg_ver, pkg_source_path),
    glue::glue("{pkg_name} has no R folder to assess codebase size"),
    fixed = TRUE
  )
  
  expect_equal(doc_scores$size_codebase, 0)
})

test_that("get_pkg_author returns correct structure without funder", {
  # Mocked return values
  mock_creator <- list(list(email = "krlmlr+r@mailbox.org"))
  mock_authors <- list(
    list(email = "krlmlr+r@mailbox.org"),
    list(email = "jenny@rstudio.com")
  )
  
  # Create a fake description object with the required methods
  fake_desc <- list(
    has_fields = function(field) TRUE
  )
  class(fake_desc) <- "description"
  
  # Stub all necessary functions
  mockery::stub(get_pkg_author, "description$new", function(file) fake_desc)
  mockery::stub(get_pkg_author, "desc::desc_get_author", function(role, file) {
    if (role == "cre") return(mock_creator)
    if (role == "fnd") return(NULL)
  })
  mockery::stub(get_pkg_author, "desc::desc_get_authors", function(file) mock_authors)
  
  result <- get_pkg_author("test", "fake/path")
  
  expect_equal(result$maintainer[[1]]$email, "krlmlr+r@mailbox.org")
  expect_null(result$funder)
  expect_equal(length(result$authors), 2)
  expect_equal(result$authors[[1]]$email, "krlmlr+r@mailbox.org")
  expect_equal(result$authors[[2]]$email, "jenny@rstudio.com")
  
})


test_that("get_pkg_author returns correct structure with funder", {
  # Mocked return values
  mock_creator <- list(list(email = "hadley@posit.co"))
  mock_funder <- "Posit Software, PBC [cph, fnd]"
  mock_authors <- list(
    list(email = "hadley@posit.co"),
    list(email = "another@posit.co")
  )
  
  # Create a fake description object with the required methods
  fake_desc <- list(
    has_fields = function(field) TRUE
  )
  class(fake_desc) <- "description"
  
  # Stub all necessary functions
  mockery::stub(get_pkg_author, "description$new", function(file) fake_desc)
  mockery::stub(get_pkg_author, "desc::desc_get_author", function(role, file) {
    if (role == "cre") return(mock_creator)
    if (role == "fnd") return(mock_funder)
  })
  mockery::stub(get_pkg_author, "desc::desc_get_authors", function(file) mock_authors)
  
  result <- get_pkg_author("test", "fake/path")
  
  
  expect_equal(result$maintainer[[1]]$email, "hadley@posit.co")
  expect_equal(as.character(result$funder), mock_funder)
  expect_equal(length(result$authors), 2)
  expect_equal(result$authors[[1]]$email, "hadley@posit.co")
})


test_that("get_pkg_author handles missing creator and author", {
  
  # Stub description$new to return an object with has_fields method
  mock_desc_obj <- list(
    has_fields = function(field) FALSE
  )
  class(mock_desc_obj) <- "description"
  
  mockery::stub(get_pkg_author, "description$new", function(file) mock_desc_obj)
  
  # Stub desc_coerce_authors_at_r to do nothing
  mockery::stub(get_pkg_author, "desc_coerce_authors_at_r", function(file) NULL)
  
  # Stub desc::desc_get_author to return empty vector for both roles
  mockery::stub(get_pkg_author, "desc::desc_get_author", function(role, file) character(0))
  
  # Stub desc::desc_get_authors to return empty vector
  mockery::stub(get_pkg_author, "desc::desc_get_authors", function(file) character(0))
  
  pkg_name <- "mockpkg"
  pkg_source_path <- "mock/path"
  
  result <- get_pkg_author(pkg_name, pkg_source_path)
  
  expect_null(result$maintainer)
  expect_null(result$authors)
  expect_null(result$funder)
})



test_that("parse authors for mocked package folder works correctly", {
  mock_dir <- withr::local_tempdir()
  dir.create(file.path(mock_dir, "R"), showWarnings = FALSE)
  
  desc_text <- "Package: here
Title: A Simpler Way to Find Your Files
Version: 1.0.2.9000
Date: 2025-09-15
Authors@R:
    c(person(given = \"Kirill\",
             family = \"M\\u00fcller\",
             role = c(\"aut\", \"cre\"),
             email = \"kirill@cynkra.com\",
             comment = c(ORCID = \"0000-0002-1416-3412\")),
      person(given = \"Jennifer\",
             family = \"Bryan\",
             role = \"ctb\",
             email = \"jenny@rstudio.com\",
             comment = c(ORCID = \"0000-0002-6983-2759\")))
Description: Constructs paths to your project's files.
    Declare the relative path of a file within your project with 'i_am()'.
    Use the 'here()' function as a drop-in replacement for 'file.path()',
    it will always locate the files relative to your project root.
License: MIT + file LICENSE
URL: https://here.r-lib.org/, https://github.com/r-lib/here
BugReports: https://github.com/r-lib/here/issues
Imports:
    rprojroot (>= 2.1.0)
Suggests:
    conflicted,
    covr,
    fs,
    knitr,
    palmerpenguins,
    plyr,
    readr,
    rlang,
    rmarkdown,
    testthat,
    uuid,
    withr
VignetteBuilder:
    knitr
Encoding: UTF-8
Roxygen: list(markdown = TRUE)
RoxygenNote: 7.3.3.9000
Config/testthat/edition: 3
Config/Needs/website: tidyverse/tidytemplate
"
  
  writeLines(desc_text, file.path(mock_dir, "DESCRIPTION"), useBytes = TRUE)
  writeLines("exportPattern(\"^[[:alpha:]]+\")", file.path(mock_dir, "NAMESPACE"))
  
  result <- get_pkg_author("test", mock_dir)
  
  expect_equal(result$maintainer[[1]]$email, "kirill@cynkra.com")
  expect_null(result$funder)
  
  expect_true(!is.null(result$authors))
  expect_equal(length(result$authors), 2)
  expect_equal(result$authors[[1]]$email, "kirill@cynkra.com")
  expect_equal(result$authors[[2]]$email, "jenny@rstudio.com")
})



test_that("parse authors for mocked package folder works correctly 2", {
  mock_dir <- withr::local_tempdir()
  dir.create(file.path(mock_dir, "R"), showWarnings = FALSE)
  
  desc_text <- "Package: stringr
Title: Simple, Consistent Wrappers for Common String Operations
Version: 1.5.2.9000
Authors@R: c(
    person(\"Hadley\", \"Wickham\", , \"hadley@posit.co\", role = c(\"aut\", \"cre\", \"cph\")),
    person(\"Posit Software, PBC\", role = c(\"cph\", \"fnd\"))
  )
Description: A consistent, simple and easy to use set of wrappers around
    the fantastic 'stringi' package. All function and argument names (and
    positions) are consistent, all functions deal with \"NA\"'s and zero
    length vectors in the same way, and the output from one function is
    easy to feed into the input of another.
License: MIT + file LICENSE
URL: https://stringr.tidyverse.org, https://github.com/tidyverse/stringr
BugReports: https://github.com/tidyverse/stringr/issues
Depends:
    R (>= 3.6)
Imports:
    cli,
    glue (>= 1.6.1),
    lifecycle (>= 1.0.3),
    magrittr,
    rlang (>= 1.0.0),
    stringi (>= 1.5.3),
    vctrs (>= 0.4.0)
Suggests:
    covr,
    dplyr,
    gt,
    htmltools,
    htmlwidgets,
    knitr,
    rmarkdown,
    testthat (>= 3.0.0),
    tibble
VignetteBuilder:
    knitr
Config/Needs/website: tidyverse/tidytemplate
Config/potools/style: explicit
Config/testthat/edition: 3
Encoding: UTF-8
LazyData: true
Roxygen: list(markdown = TRUE)
RoxygenNote: 7.3.3
"
  
  writeLines(desc_text, file.path(mock_dir, "DESCRIPTION"), useBytes = TRUE)
  writeLines("exportPattern(\"^[[:alpha:]]+\")", file.path(mock_dir, "NAMESPACE"))
  
  result <- get_pkg_author("test", mock_dir)
  
  expect_equal(result$maintainer[[1]]$email, "hadley@posit.co")
  expect_equal(as.character(result$funder), "Posit Software, PBC [cph, fnd]")
  
  expect_equal(length(result$authors), 2)
  expect_equal(as.character(result$maintainer[[1]]$email), "hadley@posit.co")
})

test_that("parse license for tar file MIT", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz", 
                    package = "risk.assessr")
  
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
    result <- get_pkg_license("here", pkg_source_path)
    expect_equal(result, "MIT + file LICENSE")
  }
})


test_that("parse authors for tar file Apache License", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0001_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  if (package_installed == TRUE ) {	
    result <- get_pkg_license("test.package.0001", pkg_source_path)
    expect_equal(result, "Apache License (>= 2)")
  }
})


test_that("parse license not present", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0007_0.1.0.tar.gz", 
                         package = "risk.assessr")
  
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  if (package_installed == TRUE ) {	
    result <- get_pkg_license("test.package.0007", pkg_source_path)
    expect_null(result)
  }
})


# clean_license

test_that("clean_license splits and normalizes single license", {
  expect_equal(clean_license("MIT"), c("MIT"))
  expect_equal(clean_license("MIT + file LICENSE"), "MIT")
  expect_equal(clean_license("MIT file LICENSE"), "MIT")
  expect_equal(clean_license("Apache-2.0"), c("APACHE"))
  expect_equal(clean_license("NOT AVAILABLE"), c("NOTAVAILABLE"))
})

test_that("clean_license removes trailing file LICENSE", {
  expect_equal(clean_license("MIT file LICENSE"), c("MIT"))
  expect_equal(clean_license("Apache License"), c("APACHE"))
  expect_equal(clean_license("Apache file LICENSE and stuff"), c("APACHE"))
})

test_that("clean_license splits on commas, plus, and pipes", {
  expect_equal(clean_license("MIT, GPL"), c("MIT", "GPL"))
  expect_equal(clean_license("MIT + GPL"), c("MIT", "GPL"))
  expect_equal(clean_license("MIT | GPL"), c("MIT", "GPL"))
})

test_that("clean_license trims whitespace and normalizes to uppercase letters only", {
  expect_equal(clean_license(" mit "), c("MIT"))
  expect_equal(clean_license("Apache License 2.0"), c("APACHE"))
  expect_equal(clean_license("GPL-3.0"), c("GPL"))
})

test_that("clean_license ignores empty parts", {
  expect_equal(clean_license(", , MIT"), c("MIT"))
  expect_equal(clean_license("| | GPL |"), c("GPL"))
})

test_that("clean_license handles empty string input", {
  expect_equal(clean_license(""), NULL)
})

test_that("test assess_description_file_elements for all elements present", {
# check source control
  test_source_control_elements <- function() {
  # Define toy data for testing
    toy_data <- list(
      no_source_control = list(
        pkg_name = "pkg_no_source_control",
        desc_elements = list(URL = "http://example.com"),
        expected_message = "pkg_no_source_control does not have a source control",
        expected_has_source_control = 0
      ),
      has_github = list(
        pkg_name = "pkg_has_github",
        desc_elements = list(URL = "https://github.com/user/repo"),
        expected_message = "pkg_has_github has a source control",
        expected_has_source_control = 1
      ),
      has_ac_uk = list(
        pkg_name = "pkg_has_ac_uk",
        desc_elements = list(URL = "http://www.stats.ox.ac.uk/pub/MASS4/"),
        expected_message = "pkg_has_ac_uk has a source control",
        expected_has_source_control = 1
      ),
      has_bitbucket = list(
        pkg_name = "pkg_has_bitbucket",
        desc_elements = list(URL = "https://bitbucket.org/user/repo"),
        expected_message = "pkg_has_bitbucket has a source control",
        expected_has_source_control = 1
      ),
      has_gitlab = list(
        pkg_name = "pkg_has_gitlab",
        desc_elements = list(URL = "https://gitlab.com/user/repo"),
        expected_message = "pkg_has_gitlab has a source control",
        expected_has_source_control = 1
      ),
      has_cambridge_repo = list(
        pkg_name = "pkg_has_cambridge_repo",
        desc_elements = list(URL = "https://www.repository.cam.ac.uk/items/da5b9b21-ef5f-4ac8-80e4-553d99014aaf/full"),
        expected_message = "pkg_has_cambridge_repo has a source control",
        expected_has_source_control = 1
      ),
      has_wehi = list(
        pkg_name = "pkg_has_wehi",
        desc_elements = list(URL = "http://bioinf.wehi.edu.au/limma"),
        expected_message = "pkg_has_wehi has a source control",
        expected_has_source_control = 1
      ),
      has_bioconductor = list(
        pkg_name = "pkg_has_bioconductor",
        desc_elements = list(URL = "https://bioconductor.org/packages/IRanges"),
        expected_message = "pkg_has_bioconductor has a source control",
        expected_has_source_control = 1
      )
    )
    
    # Define the patterns
    patterns <- "github\\.com|bitbucket\\.org|gitlab\\.com|\\.ac\\.uk|\\.edu\\.au|bioconductor\\.org"
  
  # Test each scenario
    for (test_case in toy_data) {
      pkg_name <- test_case$pkg_name
      desc_elements <- test_case$desc_elements
      expected_message <- test_case$expected_message
      expected_has_source_control <- test_case$expected_has_source_control
      
      expect_message({
        if (is.null(desc_elements$URL) | (is.na(desc_elements$URL))) {
          message(glue::glue("{pkg_name} does not have a source control"))
          has_source_control <- 0
        } else {
          source_matches <- grep(patterns, desc_elements$URL, value = TRUE)
          if (length(source_matches) == 0) {
            message(glue::glue("{pkg_name} does not have a source control"))
            has_source_control <- 0
          } else {
            message(glue::glue("{pkg_name} has a source control"))
            has_source_control <- 1
          }
        }
      }, expected_message)
      
      expect_equal(has_source_control, expected_has_source_control)
    }
  }  

  test_source_control_elements()  
})

test_that("test assess_description_file_elements for all elements present", {
  
  library(risk.assessr)
  # set CRAN repo 
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  dp <- system.file("test-data", "stringr-1.5.1.tar.gz",
                    package = "risk.assessr")
  
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
  
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)
    
    testthat::expect_message(
      desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path),
      glue::glue("{pkg_name} has bug reports URL"),
      fixed = TRUE
    )
    
    testthat::expect_message(
      desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path),
      glue::glue("{pkg_name} has a source control"),
      fixed = TRUE
    )
    
    testthat::expect_message(
      desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path),
      glue::glue("{pkg_name} has a maintainer"),
      fixed = TRUE
    )
    
    testthat::expect_message(
      desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path),
      glue::glue("{pkg_name} has a website"),
      fixed = TRUE
    )
    desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path)
    expect_identical(length(desc_elements_test), 4L)
    expect_true(checkmate::check_list(desc_elements_test, all.missing = FALSE))
    expect_true(checkmate::check_list(desc_elements_test, any.missing = TRUE))
  }
})

test_that("test assess_description_file_elements for all elements present", {
  
  library(risk.assessr)
  # set CRAN repo 
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0007_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  if (package_installed == TRUE ) {	
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)
    
    testthat::expect_message(
      desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path),
      glue::glue("{pkg_name} does not have bug reports URL"),
      fixed = TRUE
    )
    
    testthat::expect_message(
      desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path),
      glue::glue("{pkg_name} does not have a source control"),
      fixed = TRUE
    )
    
    testthat::expect_message(
      desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path),
      glue::glue("{pkg_name} has a maintainer"),
      fixed = TRUE
    )
    
    testthat::expect_message(
      desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path),
      glue::glue("{pkg_name} does not have a website"),
      fixed = TRUE
    )
    
    desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path)
    expect_identical(length(desc_elements_test), 4L)
    expect_true(checkmate::check_list(desc_elements_test, all.missing = FALSE))
    expect_true(checkmate::check_list(desc_elements_test, any.missing = TRUE))
  }
})


test_that("assess_description_file_elements handles missing maintainer", {
  
  
  # Stub desc_get_author to simulate no maintainer
  mockery::stub(assess_description_file_elements, "desc::desc_get_author", function(role, file) {
    character(0)
  })
  
  # Stub get_pkg_desc to return all required fields
  mockery::stub(assess_description_file_elements, "get_pkg_desc", function(path, fields) {
    list(
      Package = "mockpkg",
      BugReports = "https://example.com/bugs",
      Maintainer = NULL,
      URL = "https://example.com"
    )
  })
  
  pkg_name <- "mockpkg"
  pkg_source_path <- "mock/path"
  
  testthat::expect_message(
    desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path),
    glue::glue("{pkg_name} does not have a maintainer"),
    fixed = TRUE
  )
  
  # Optional: check output structure
  expect_true(checkmate::check_list(desc_elements_test, any.missing = TRUE))
})



# Authors

test_that("get_pkg_author retrieves all authors correctly", {
  # Create a temporary directory to simulate the package folder
  temp_dir <- tempdir()
  pkg_source_path <- file.path(temp_dir, "limma")
  desc_path <- file.path(pkg_source_path, "DESCRIPTION")
  dir.create(pkg_source_path, recursive = TRUE, showWarnings = FALSE)
  
  # Provided DESCRIPTION text
  description_text <- "Package: here
Title: A Simpler Way to Find Your Files
Version: 1.0.1
Date: 2020-12-13
Authors@R: 
    c(person(given = 'Kirill',
             family = 'M\u00fcller',
             role = c('aut', 'cre'),
             email = 'krlmlr+r@mailbox.org',
             comment = c(ORCID = '0000-0002-1416-3412')),
      person(given = 'Jennifer',
             family = 'Bryan',
             role = 'ctb',
             email = 'jenny@rstudio.com',
             comment = c(ORCID = '0000-0002-6983-2759')))
Description: Constructs paths to your project's files.
    Declare the relative path of a file within your project with 'i_am()'.
    Use the 'here()' function as a drop-in replacement for 'file.path()',
    it will always locate the files relative to your project root.
License: MIT + file LICENSE
URL: https://here.r-lib.org/, https://github.com/r-lib/here
BugReports: https://github.com/r-lib/here/issues
Imports: rprojroot (>= 2.0.2)
Suggests: conflicted, covr, fs, knitr, palmerpenguins, plyr, readr,
        rlang, rmarkdown, testthat, uuid, withr
VignetteBuilder: knitr
Encoding: UTF-8
LazyData: true
RoxygenNote: 7.1.1.9000
Config/testthat/edition: 3
NeedsCompilation: no
Packaged: 2020-12-13 06:59:33 UTC; kirill
Author: Kirill Müller [aut, cre] (<https://orcid.org/0000-0002-1416-3412>),
  Jennifer Bryan [ctb] (<https://orcid.org/0000-0002-6983-2759>)
Maintainer: Kirill Müller <krlmlr+r@mailbox.org>
Repository: CRAN
Date/Publication: 2020-12-13 07:30:02 UTC
"
  
  # Write the DESCRIPTION text to a file
  writeLines(description_text, desc_path)
  
  # Run the function with the mocked package path
  result <- get_pkg_author("limma", pkg_source_path)
  
  # Assertions
  expect_type(result, "list")
  expect_true(!is.null(result$maintainer))
  expect_true(!is.null(result$authors))
  expect_equal(result$maintainer[[1]]$given, "Kirill")
  expect_equal(result$maintainer[[1]]$family, "Müller")
  
  # Clean up the temporary directory
  unlink(pkg_source_path, recursive = TRUE)
})

test_that("get_pkg_author retrieves all authors correctly without @Author", {
  # Create a temporary directory to simulate the package folder
  temp_dir <- tempdir()
  pkg_source_path <- file.path(temp_dir, "limma")
  desc_path <- file.path(pkg_source_path, "DESCRIPTION")
  dir.create(pkg_source_path, recursive = TRUE, showWarnings = FALSE)
  
  # Provided DESCRIPTION text
  description_text <- "Package: limma
Version: 2.10.7
Date: 2007/09/24
Title: Linear Models for Microarray Data
Author: Gordon Smyth with contributions from Matthew Ritchie, Jeremy Silver, James Wettenhall, Natalie Thorne, Mette Langaas, Egil Ferkingstad, Marcus Davy, Francois Pepin and Dongseok Choi.
Maintainer: Gordon Smyth <smyth@wehi.edu.au>
Depends: R (<= 2.5.1), methods
Suggests: affy, marray, MASS, splines, sma, statmod (>= 1.2.2), vsn
LazyLoad: yes
Description:  Data analysis, linear models and differential expression for microarray data.
License: LGPL
URL: http://bioinf.wehi.edu.au/limma
biocViews: Microarray, OneChannel, TwoChannel, DataImport, QualityControl, Preprocessing, Statistics, DifferentialExpression, MultipleComparisons, TimeCourse
Packaged: Mon Sep 24 13:01:39 2007; smyth
"
  
  # Write the DESCRIPTION text to a file
  writeLines(description_text, desc_path)
  
  # Run the function with the mocked package path
  result <- get_pkg_author("limma", pkg_source_path)
  
  # Assertions
  expect_type(result, "list")
  expect_true(!is.null(result$maintainer))
  expect_true(!is.null(result$authors))
  expect_equal(result$maintainer[[1]]$given, "Gordon")
  expect_equal(result$maintainer[[1]]$family, "Smyth")
  
  # Clean up the temporary directory
  unlink(pkg_source_path, recursive = TRUE)
})

test_that("test assess_description_file_elements for all elements present", {
  # check source control
  test_source_control_elements <- function() {
    # Define toy data for testing
    toy_data <- list(
      no_source_control = list(
        pkg_name = "pkg_no_source_control",
        desc_elements = list(URL = "http://example.com"),
        expected_message = "pkg_no_source_control does not have a source control",
        expected_has_source_control = 0
      ),
      has_github = list(
        pkg_name = "pkg_has_github",
        desc_elements = list(URL = "https://github.com/user/repo"),
        expected_message = "pkg_has_github has a source control",
        expected_has_source_control = 1
      ),
      has_ac_uk = list(
        pkg_name = "pkg_has_ac_uk",
        desc_elements = list(URL = "http://www.stats.ox.ac.uk/pub/MASS4/"),
        expected_message = "pkg_has_ac_uk has a source control",
        expected_has_source_control = 1
      ),
      has_bitbucket = list(
        pkg_name = "pkg_has_bitbucket",
        desc_elements = list(URL = "https://bitbucket.org/user/repo"),
        expected_message = "pkg_has_bitbucket has a source control",
        expected_has_source_control = 1
      ),
      has_gitlab = list(
        pkg_name = "pkg_has_gitlab",
        desc_elements = list(URL = "https://gitlab.com/user/repo"),
        expected_message = "pkg_has_gitlab has a source control",
        expected_has_source_control = 1
      ),
      has_cambridge_repo = list(
        pkg_name = "pkg_has_cambridge_repo",
        desc_elements = list(URL = "https://www.repository.cam.ac.uk/items/da5b9b21-ef5f-4ac8-80e4-553d99014aaf/full"),
        expected_message = "pkg_has_cambridge_repo has a source control",
        expected_has_source_control = 1
      ),
      has_wehi = list(
        pkg_name = "pkg_has_wehi",
        desc_elements = list(URL = "http://bioinf.wehi.edu.au/limma"),
        expected_message = "pkg_has_wehi has a source control",
        expected_has_source_control = 1
      ),
      has_bioconductor = list(
        pkg_name = "pkg_has_bioconductor",
        desc_elements = list(URL = "https://bioconductor.org/packages/IRanges"),
        expected_message = "pkg_has_bioconductor has a source control",
        expected_has_source_control = 1
      )
    )
    
    # Define the patterns
    patterns <- "github\\.com|bitbucket\\.org|gitlab\\.com|\\.ac\\.uk|\\.edu\\.au|bioconductor\\.org"
    
    # Test each scenario
    for (test_case in toy_data) {
      pkg_name <- test_case$pkg_name
      desc_elements <- test_case$desc_elements
      expected_message <- test_case$expected_message
      expected_has_source_control <- test_case$expected_has_source_control
      
      expect_message({
        if (is.null(desc_elements$URL) | (is.na(desc_elements$URL))) {
          message(glue::glue("{pkg_name} does not have a source control"))
          has_source_control <- 0
        } else {
          source_matches <- grep(patterns, desc_elements$URL, value = TRUE)
          if (length(source_matches) == 0) {
            message(glue::glue("{pkg_name} does not have a source control"))
            has_source_control <- 0
          } else {
            message(glue::glue("{pkg_name} has a source control"))
            has_source_control <- 1
          }
        }
      }, expected_message)
      
      expect_equal(has_source_control, expected_has_source_control)
    }
  }  
  
  test_source_control_elements()  
})

test_that("test assess_description_file_elements for all elements present", {
  
  library(risk.assessr)
  # set CRAN repo 
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  dp <- system.file("test-data", "stringr-1.5.1.tar.gz",
                    package = "risk.assessr")
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  withr::defer({
    unlink(pkg_source_path, recursive = TRUE, force = TRUE)
  })
  
  if (package_installed == TRUE ) {	
  
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)
    
    testthat::expect_message(
      desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path),
      glue::glue("{pkg_name} has bug reports URL"),
      fixed = TRUE
    )
    
    testthat::expect_message(
      desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path),
      glue::glue("{pkg_name} has a source control"),
      fixed = TRUE
    )
    
    testthat::expect_message(
      desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path),
      glue::glue("{pkg_name} has a maintainer"),
      fixed = TRUE
    )
    
    testthat::expect_message(
      desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path),
      glue::glue("{pkg_name} has a website"),
      fixed = TRUE
    )
    desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path)
    expect_identical(length(desc_elements_test), 4L)
    expect_true(checkmate::check_list(desc_elements_test, all.missing = FALSE))
    expect_true(checkmate::check_list(desc_elements_test, any.missing = TRUE))
  }
})

test_that("test assess_description_file_elements for all elements present", {
  
  library(risk.assessr)
  # set CRAN repo 
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0007_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  if (package_installed == TRUE ) {	
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)
    
    testthat::expect_message(
      desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path),
      glue::glue("{pkg_name} does not have bug reports URL"),
      fixed = TRUE
    )
    
    testthat::expect_message(
      desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path),
      glue::glue("{pkg_name} does not have a source control"),
      fixed = TRUE
    )
    
    testthat::expect_message(
      desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path),
      glue::glue("{pkg_name} has a maintainer"),
      fixed = TRUE
    )
    
    testthat::expect_message(
      desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path),
      glue::glue("{pkg_name} does not have a website"),
      fixed = TRUE
    )
    
    desc_elements_test <- assess_description_file_elements(pkg_name, pkg_source_path)
    expect_identical(length(desc_elements_test), 4L)
    expect_true(checkmate::check_list(desc_elements_test, all.missing = FALSE))
    expect_true(checkmate::check_list(desc_elements_test, any.missing = TRUE))
  }
})

# Authors

test_that("get_pkg_author retrieves all authors correctly", {
  # Create a temporary directory to simulate the package folder
  temp_dir <- tempdir()
  pkg_source_path <- file.path(temp_dir, "limma")
  desc_path <- file.path(pkg_source_path, "DESCRIPTION")
  dir.create(pkg_source_path, recursive = TRUE, showWarnings = FALSE)
  
  # Provided DESCRIPTION text
  description_text <- "Package: here
Title: A Simpler Way to Find Your Files
Version: 1.0.1
Date: 2020-12-13
Authors@R: 
    c(person(given = 'Kirill',
             family = 'M\u00fcller',
             role = c('aut', 'cre'),
             email = 'krlmlr+r@mailbox.org',
             comment = c(ORCID = '0000-0002-1416-3412')),
      person(given = 'Jennifer',
             family = 'Bryan',
             role = 'ctb',
             email = 'jenny@rstudio.com',
             comment = c(ORCID = '0000-0002-6983-2759')))
Description: Constructs paths to your project's files.
    Declare the relative path of a file within your project with 'i_am()'.
    Use the 'here()' function as a drop-in replacement for 'file.path()',
    it will always locate the files relative to your project root.
License: MIT + file LICENSE
URL: https://here.r-lib.org/, https://github.com/r-lib/here
BugReports: https://github.com/r-lib/here/issues
Imports: rprojroot (>= 2.0.2)
Suggests: conflicted, covr, fs, knitr, palmerpenguins, plyr, readr,
        rlang, rmarkdown, testthat, uuid, withr
VignetteBuilder: knitr
Encoding: UTF-8
LazyData: true
RoxygenNote: 7.1.1.9000
Config/testthat/edition: 3
NeedsCompilation: no
Packaged: 2020-12-13 06:59:33 UTC; kirill
Author: Kirill Müller [aut, cre] (<https://orcid.org/0000-0002-1416-3412>),
  Jennifer Bryan [ctb] (<https://orcid.org/0000-0002-6983-2759>)
Maintainer: Kirill Müller <krlmlr+r@mailbox.org>
Repository: CRAN
Date/Publication: 2020-12-13 07:30:02 UTC
"
  
  # Write the DESCRIPTION text to a file
  writeLines(description_text, desc_path)
  
  # Run the function with the mocked package path
  result <- get_pkg_author("limma", pkg_source_path)
  
  # Assertions
  expect_type(result, "list")
  expect_true(!is.null(result$maintainer))
  expect_true(!is.null(result$authors))
  expect_equal(result$maintainer[[1]]$given, "Kirill")
  expect_equal(result$maintainer[[1]]$family, "Müller")
  
  # Clean up the temporary directory
  unlink(pkg_source_path, recursive = TRUE)
})

test_that("get_pkg_author retrieves all authors correctly without @Author", {
  # Create a temporary directory to simulate the package folder
  temp_dir <- tempdir()
  pkg_source_path <- file.path(temp_dir, "limma")
  desc_path <- file.path(pkg_source_path, "DESCRIPTION")
  dir.create(pkg_source_path, recursive = TRUE, showWarnings = FALSE)
  
  # Provided DESCRIPTION text
  description_text <- "Package: limma
Version: 2.10.7
Date: 2007/09/24
Title: Linear Models for Microarray Data
Author: Gordon Smyth with contributions from Matthew Ritchie, Jeremy Silver, James Wettenhall, Natalie Thorne, Mette Langaas, Egil Ferkingstad, Marcus Davy, Francois Pepin and Dongseok Choi.
Maintainer: Gordon Smyth <smyth@wehi.edu.au>
Depends: R (<= 2.5.1), methods
Suggests: affy, marray, MASS, splines, sma, statmod (>= 1.2.2), vsn
LazyLoad: yes
Description:  Data analysis, linear models and differential expression for microarray data.
License: LGPL
URL: http://bioinf.wehi.edu.au/limma
biocViews: Microarray, OneChannel, TwoChannel, DataImport, QualityControl, Preprocessing, Statistics, DifferentialExpression, MultipleComparisons, TimeCourse
Packaged: Mon Sep 24 13:01:39 2007; smyth
"
  
  # Write the DESCRIPTION text to a file
  writeLines(description_text, desc_path)
  
  # Run the function with the mocked package path
  result <- get_pkg_author("limma", pkg_source_path)
  
  # Assertions
  expect_type(result, "list")
  expect_true(!is.null(result$maintainer))
  expect_true(!is.null(result$authors))
  expect_equal(result$maintainer[[1]]$given, "Gordon")
  expect_equal(result$maintainer[[1]]$family, "Smyth")
  
  # Clean up the temporary directory
  unlink(pkg_source_path, recursive = TRUE)
})

test_that("assess exports for tar file works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz", 
                    package = "risk.assessr")
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  withr::defer({
    unlink(pkg_source_path, recursive = TRUE, force = TRUE)
  })
  
  if (package_installed == TRUE ) {	
    export_calc <- assess_exports(pkg_source_path)
    
    expect_identical(length(export_calc), 1L)
    
    expect_vector(export_calc)
    
    expect_true(checkmate::check_numeric(export_calc, 
                                         any.missing = FALSE)
    )
    testthat::expect_equal(export_calc, 1)
  }
})

test_that("assess exports for tar file works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0006_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  if (package_installed == TRUE ) {	
    export_calc <- assess_exports(pkg_source_path)
    
    expect_identical(length(export_calc), 1L)
    
    expect_vector(export_calc)
    
    expect_true(checkmate::check_numeric(export_calc, 
                                         any.missing = FALSE)
    )
    
    testthat::expect_equal(export_calc, 0) 
  }
  
})

test_that("assess exports for examples works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz", 
                    package = "risk.assessr")
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  withr::defer({
    unlink(pkg_source_path, recursive = TRUE, force = TRUE)
  })
  
  if (package_installed == TRUE ) {	
    
    # Get package name and version
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    
    testthat::expect_message(
      has_examples <- assess_examples(pkg_name, pkg_source_path),
      glue::glue("{(pkg_name)} has examples"),
      fixed = TRUE
    )
    
    has_examples <- assess_examples(pkg_name, pkg_source_path)
    
    expect_identical(length(has_examples), 1L)
    
    expect_vector(has_examples)
    
    expect_true(checkmate::check_numeric(has_examples, 
                                         any.missing = FALSE)
    )
    
    testthat::expect_equal(has_examples, 1L) 
  }
  
})

test_that("assess exports for missing examples works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0001_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  if (package_installed == TRUE ) {	
    
    # Get package name and version
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    
    testthat::expect_message(
      has_examples <- assess_examples(pkg_name, pkg_source_path),
      glue::glue("{(pkg_name)} has no examples"),
      fixed = TRUE
    )
    
    has_examples <- assess_examples(pkg_name, pkg_source_path)
    
    expect_identical(length(has_examples), 1L)
    
    expect_vector(has_examples)
    
    expect_true(checkmate::check_numeric(has_examples, 
                                         any.missing = FALSE)
    )
    
    testthat::expect_equal(has_examples, 0L) 
  }
  
})

test_that("assess exports for help files works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz", 
                    package = "risk.assessr")
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  if (package_installed == TRUE ) {	
    
    # Get package name and version
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)
    
    testthat::expect_message(
      export_help <- assess_export_help(pkg_name, pkg_source_path),
      glue::glue("All exported functions have corresponding help files in {(pkg_name)}"),
      fixed = TRUE
    )
    
    export_help <- assess_export_help(pkg_name, pkg_source_path)
    
    expect_identical(length(export_help), 1L)
    expect_vector(export_help)
    expect_true(checkmate::check_numeric(export_help, 
                                         any.missing = FALSE)
    )
    
    testthat::expect_equal(export_help, 1L) 
  }
  
})

test_that("assess exports for missing help files works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  dp <- system.file("test-data", "stringr-1.5.1.tar.gz", 
                    package = "risk.assessr")
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  withr::defer({
    unlink(pkg_source_path, recursive = TRUE, force = TRUE)
  })
  
  if (package_installed == TRUE ) {	
    
    # Get package name and version
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)
    
    testthat::expect_message(
      export_help <- assess_export_help(pkg_name, pkg_source_path),
      glue::glue("Some exported functions are missing help files in {(pkg_name)}"),
      fixed = TRUE
    )
    
    export_help <- assess_export_help(pkg_name, pkg_source_path)
    
    expect_identical(length(export_help), 1L)
    expect_vector(export_help)
    expect_true(checkmate::check_numeric(export_help, 
                                         any.missing = FALSE)
    )
    
    testthat::expect_equal(export_help, 0L) 
  }
  
})

test_that("assess exports for no help files works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0006_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  # install package locally to ensure test works
  package_installed <- 
    install_package_local(pkg_source_path)
  package_installed <- TRUE
  
  if (package_installed == TRUE ) {	
    
    # ensure path is set to package source path
    rcmdcheck_args$path <- pkg_source_path
    
    # Get package name and version
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)
    
    testthat::expect_message(
      export_help <- assess_export_help(pkg_name, pkg_source_path),
      glue::glue("No exported functions in {(pkg_name)}"),
      fixed = TRUE
    )
    
    export_help <- assess_export_help(pkg_name, pkg_source_path)
    
    expect_identical(length(export_help), 1L)
    expect_vector(export_help)
    expect_true(checkmate::check_numeric(export_help, 
                                         any.missing = FALSE)
    )
    
    testthat::expect_equal(export_help, 0L) 
  }
  
})

test_that("assess exports for news works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz", 
                    package = "risk.assessr")
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  withr::defer({
    unlink(pkg_source_path, recursive = TRUE, force = TRUE)
  })
  
  if (package_installed == TRUE ) {	
    
    # Get package name and version
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    
    testthat::expect_message(
      has_news <- assess_news(pkg_name, pkg_source_path),
      glue::glue("{(pkg_name)} has news"),
      fixed = TRUE
    )
    
    has_news <- assess_news(pkg_name, pkg_source_path)
    
    expect_identical(length(has_news), 1L)
    
    expect_vector(has_news)
    
    expect_true(checkmate::check_numeric(has_news, 
                                         any.missing = FALSE)
    )
    
    testthat::expect_equal(has_news, 1L) 
  }
  
})

test_that("assess exports for missing news works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0001_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  if (package_installed == TRUE ) {	
    
    # Get package name and version
    pkg_desc <- get_pkg_desc(pkg_source_path, 
                             fields = c("Package", 
                                        "Version"))
    pkg_name <- pkg_desc$Package
    
    testthat::expect_message(
      has_news <- assess_news(pkg_name, pkg_source_path),
      glue::glue("{(pkg_name)} has no news"),
      fixed = TRUE
    )
    
    has_news <- assess_news(pkg_name, pkg_source_path)
    
    expect_identical(length(has_news), 1L)
    
    expect_vector(has_news)
    
    expect_true(checkmate::check_numeric(has_news, 
                                         any.missing = FALSE)
    )
    
    testthat::expect_equal(has_news, 0L) 
  }
  
})

test_that("assess exports for current news works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz", 
                    package = "risk.assessr")
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  withr::defer({
    unlink(pkg_source_path, recursive = TRUE, force = TRUE)
  })
  
  if (package_installed == TRUE ) {	
    
    # Get package name and version
    pkg_desc <-get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    
    testthat::expect_message(
      news_current <- assess_news_current(pkg_name, pkg_ver,pkg_source_path),
      glue::glue("{(pkg_name)} has current news"),
      fixed = TRUE
    )
    
    news_current <- assess_news_current(pkg_name, pkg_ver, pkg_source_path)
    
    expect_identical(length(news_current), 1L)
    
    expect_vector(news_current)
    
    expect_true(checkmate::check_numeric(news_current, 
                                         any.missing = FALSE)
    )
    
    testthat::expect_equal(news_current, 1L) 
  }
  
})

test_that("assess exports for missing news works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
 
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0001_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  if (package_installed == TRUE ) {	
    
    # Get package name and version
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    
    testthat::expect_message(
      news_current <- assess_news_current(pkg_name, pkg_ver, pkg_source_path),
      glue::glue("{(pkg_name)} has no current news"),
      fixed = TRUE
    )
    
    testthat::expect_message(
      news_current <- assess_news_current(pkg_name, pkg_ver, pkg_source_path),
      glue::glue("{(pkg_name)} has no news"),
      fixed = TRUE
    )
    
    news_current <- assess_news_current(pkg_name, pkg_ver, pkg_source_path)
    
    expect_identical(length(news_current), 1L)
    
    expect_vector(news_current)
    
    expect_true(checkmate::check_numeric(news_current, 
                                         any.missing = FALSE)
    )
    
    testthat::expect_equal(news_current, 0L) 
  }
})

test_that("assess vignettes for tar file with vignettes works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz", 
                    package = "risk.assessr")
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  withr::defer({
    unlink(pkg_source_path, recursive = TRUE, force = TRUE)
  })
  
  if (package_installed == TRUE ) {	
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)
    
    has_vignettes <- assess_vignettes(pkg_name, pkg_source_path)
    
    expect_identical(length(has_vignettes), 1L)
    
    expect_vector(has_vignettes)
    
    expect_true(checkmate::check_numeric(has_vignettes, 
                                         any.missing = FALSE)
    )
    
    testthat::expect_equal(has_vignettes, 1L) 
  }
  
})

test_that("assess vignettes for tar file with no vignettes works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0001_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  
  if (package_installed == TRUE ) {	
    
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)
    
    has_vignettes <- assess_vignettes(pkg_name, pkg_source_path)
    
    expect_identical(length(has_vignettes), 1L)
    
    expect_vector(has_vignettes)
    
    expect_true(checkmate::check_numeric(has_vignettes, 
                                         any.missing = FALSE)
    )
    
    testthat::expect_equal(has_vignettes, 0L) 
  }
  
})

test_that("assess code base size for small package works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0001_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  if (package_installed == TRUE ) {	
    size_codebase <- assess_size_codebase(pkg_source_path)
    
    expect_identical(length(size_codebase), 1L)
    
    expect_vector(size_codebase)
    
    expect_true(checkmate::check_numeric(size_codebase, 
                                         any.missing = FALSE)
    )
    
    testthat::expect_gt(size_codebase, 0.010) 
  }
  
})

test_that("assess code base size for large package works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  dp <- system.file("test-data", "stringr-1.5.1.tar.gz", 
                    package = "risk.assessr")
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  withr::defer({
    unlink(pkg_source_path, recursive = TRUE, force = TRUE)
  })
  
  if (package_installed == TRUE ) {	
    size_codebase <- assess_size_codebase(pkg_source_path)
    
    expect_identical(length(size_codebase), 1L)
    
    expect_vector(size_codebase)
    
    expect_true(checkmate::check_numeric(size_codebase, 
                                         any.missing = FALSE)
    )
    
    testthat::expect_gt(size_codebase, 0.85) 
  }
  
})

