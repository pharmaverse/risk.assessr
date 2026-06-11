test_that("test doc_riskmetric", {
  
  # set CRAN repo 
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
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
    pkg_desc <- get_pkg_desc(pkg_source_path, 
                             fields = c("Package", 
                                        "Version"))
    
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)
    
    doc_riskmetric_test <- 
      doc_riskmetric(pkg_name, pkg_ver, pkg_source_path)
    
    expect_identical(length(doc_riskmetric_test), 12L)
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
  
  
  # Stub assess_examples to avoid tools::Rd_db
  mockery::stub(doc_riskmetric, "assess_examples", function(...) {
    list(data = data.frame(function_name = "fun", example = "no example"), example_score = 50)
  })
  
  
  # Stub assess_exported_functions_docs to avoid tools::Rd_db
  mockery::stub(doc_riskmetric, "assess_exported_functions_docs", function(...) {
    list(data = data.frame(function_name = "fun", documentation_name = "topic", documentation_location = "man/topic.Rd"),
         documentation_score = 75)
  })
  
  
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
  skip_if_repo_unavailable()
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz",
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
    result <- extract_license_from_description(pkg_source_path)
    expect_equal(result, "MIT + file LICENSE")
  }
})


test_that("parse authors for tar file Apache License", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
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
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  if (package_installed == TRUE ) {	
    result <- extract_license_from_description(pkg_source_path)
    expect_equal(result, "Apache License (>= 2)")
  }
})


test_that("parse license not present", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  skip_if_repo_unavailable()
  
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0007_0.1.0.tar.gz",
                         package = "risk.assessr")
  skip_if_test_data_missing(dp_orig)
  
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
    suppressWarnings(result <- extract_license_from_description(pkg_source_path))
    expect_true(is.na(result))
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
      ),
      has_rforge = list(
        pkg_name = "pkg_has_rforge",
        desc_elements = list(URL = "https://r-forge.r-project.org/projects/surveillance/"),
        expected_message = "pkg_has_rforge has a source control",
        expected_has_source_control = 1
      ),
      has_codeberg = list(
        pkg_name = "pkg_has_codeberg",
        desc_elements = list(URL = "https://codeberg.org/episensr/episensr"),
        expected_message = "pkg_has_codeberg has a source control",
        expected_has_source_control = 1
      ),
      has_sourceforge = list(
        pkg_name = "pkg_has_sourceforge",
        desc_elements = list(URL = "https://sourceforge.net/projects/mcmc-jags/"),
        expected_message = "pkg_has_sourceforge has a source control",
        expected_has_source_control = 1
      ),
      has_sourcehut = list(
        pkg_name = "pkg_has_sourcehut",
        desc_elements = list(URL = "https://sr.ht/~enno/orgutils/"),
        expected_message = "pkg_has_sourcehut has a source control",
        expected_has_source_control = 1
      ),
      has_gitlab_selfhosted = list(
        pkg_name = "pkg_has_gitlab_selfhosted",
        desc_elements = list(URL = "https://gitlab.opencode.de/bmbf/datenlabor/barrierefrei-r"),
        expected_message = "pkg_has_gitlab_selfhosted has a source control",
        expected_has_source_control = 1
      )
    )
    
    # Patterns must stay in sync with documentation_metrics.R
    patterns <- paste(
      "github\\.com", "pages\\.github\\.io", "github\\.io",
      "gitlab\\.com", "gitlab\\.",
      "bitbucket\\.org",
      "r-forge\\.r-project\\.org",
      "codeberg\\.org",
      "sourceforge\\.net",
      "sr\\.ht",
      "bioconductor\\.org",
      "\\.ac\\.uk", "\\.edu\\.au",
      sep = "|"
    )
    
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

test_that("GitHub Pages URLs are detected as source control", {
  # Create a temporary package directory with DESCRIPTION file
  pkg_source_path <- tempfile(pattern = "testpkg")
  dir.create(pkg_source_path)
  on.exit(unlink(pkg_source_path, recursive = TRUE), add = TRUE)
  
  # Create DESCRIPTION with GitHub Pages URL
  desc_path <- file.path(pkg_source_path, "DESCRIPTION")
  description_text <- paste0(
    "Package: testpkg\n",
    "Title: Test Package\n",
    "Version: 1.0.0\n",
    "URL: https://probable-chainsaw-kgro2o7.pages.github.io/\n",
    "BugReports: https://github.com/Sanofi-GitHub/bp-art-risk.assessr/issues\n"
  )
  writeLines(description_text, desc_path)
  
  # Test that GitHub Pages URL is detected
  result <- assess_description_file_elements("testpkg", pkg_source_path)
  expect_false(is.null(result$has_source_control))
  expect_true(length(result$has_source_control) > 0)
  expect_true(grepl("pages\\.github\\.io", result$has_source_control))
})

test_that("BugReports URL is used as fallback when URL field doesn't match", {
  # Create a temporary package directory with DESCRIPTION file
  pkg_source_path <- tempfile(pattern = "testpkg")
  dir.create(pkg_source_path)
  on.exit(unlink(pkg_source_path, recursive = TRUE), add = TRUE)
  
  # Create DESCRIPTION with non-matching URL but GitHub BugReports
  desc_path <- file.path(pkg_source_path, "DESCRIPTION")
  description_text <- paste0(
    "Package: testpkg\n",
    "Title: Test Package\n",
    "Version: 1.0.0\n",
    "URL: https://example.com/package\n",
    "BugReports: https://github.com/user/repo/issues\n"
  )
  writeLines(description_text, desc_path)
  
  # Test that BugReports URL is used as fallback
  result <- assess_description_file_elements("testpkg", pkg_source_path)
  expect_false(is.null(result$has_source_control))
  expect_true(length(result$has_source_control) > 0)
  expect_true(grepl("github\\.com", result$has_source_control))
})

test_that("test assess_description_file_elements for all elements present", {
  
  library(risk.assessr)
  # set CRAN repo 
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
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
  skip_if_repo_unavailable()
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0007_0.1.0.tar.gz",
                         package = "risk.assessr")
  skip_if_test_data_missing(dp_orig)
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
  skip_if_repo_unavailable()
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0007_0.1.0.tar.gz",
                         package = "risk.assessr")
  skip_if_test_data_missing(dp_orig)
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
  skip_if_repo_unavailable()
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz",
                    package = "risk.assessr")
  skip_if_test_data_missing(dp)
  
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
  skip_if_repo_unavailable()
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0006_0.1.0.tar.gz",
                         package = "risk.assessr")
  skip_if_test_data_missing(dp_orig)
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
  skip_if_repo_unavailable()
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz",
                    package = "risk.assessr")
  skip_if_test_data_missing(dp)
  
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
      glue::glue("{(pkg_name)}: 75.00% of exported functions have examples"),
      fixed = TRUE
    )
    
    has_examples <- assess_examples(pkg_name, pkg_source_path)
    
    expect_identical(length(has_examples), 2L)
    
    expect_vector(has_examples)
    
    expect_true(checkmate::check_list(has_examples, 
                                      any.missing = TRUE)
    )
    
    testthat::expect_length(has_examples, 2L) 
  }
  
})

# ---------------------------------------------------------------------------
# Tests for find_rd_for_fun() - branch 3 (topic-name fallback) and NULL return
#
# These tests cover the rare-fallback branch of find_rd_for_fun() where a
# function is resolved only because a topic in `idx$topic_by_file` matches
# its name. Branches 1 (`<fun>.Rd` exists in `db`) and 2 (`alias_index`
# hit) are deliberately defeated by the synthetic `db` / `idx` so that
# only branch 3 (or the final NULL fallthrough) can produce the result.
#
# build_rd_index() is stubbed with mockery to make the test for the
# `idx = NULL` code path deterministic. No installed package, no internet
# access, and no filesystem access are required, keeping these tests
# CRAN-safe.
# ---------------------------------------------------------------------------

test_that("find_rd_for_fun returns the Rd via topic-name fallback when neither file nor alias match", {
  fun_name <- "myfun"
  rd_object <- list(name = "myfun", tag = "rd-1")
  
  # Conventional filename ("myfun.Rd") and alias index both *miss* on
  # purpose: only the topic-name fallback can return a hit.
  db <- list(
    "weird_topic.Rd" = rd_object,
    "unrelated.Rd"   = list(name = "unrelated")
  )
  idx <- list(
    alias_index   = new.env(parent = emptyenv()),
    topic_by_file = c(
      "weird_topic.Rd" = "myfun",
      "unrelated.Rd"   = "unrelated"
    )
  )
  
  res <- find_rd_for_fun(fun_name, db, idx)
  
  expect_type(res, "list")
  expect_named(res, c("rd", "filename"))
  expect_identical(res$filename, "weird_topic.Rd")
  expect_identical(res$rd, rd_object)
})

test_that("find_rd_for_fun topic-name fallback returns the first match when multiple topics equal fun", {
  fun_name <- "shared_topic"
  rd_first  <- list(name = "shared_topic", id = 1L)
  rd_second <- list(name = "shared_topic", id = 2L)
  
  db <- list(
    "first.Rd"  = rd_first,
    "second.Rd" = rd_second
  )
  idx <- list(
    alias_index   = new.env(parent = emptyenv()),
    topic_by_file = c(
      "first.Rd"  = "shared_topic",
      "second.Rd" = "shared_topic"
    )
  )
  
  res <- find_rd_for_fun(fun_name, db, idx)
  
  # Implementation uses topic_match[[1]] - i.e. first index wins.
  expect_identical(res$filename, "first.Rd")
  expect_identical(res$rd, rd_first)
})

test_that("find_rd_for_fun returns NULL when no branch (direct, alias, or topic) resolves", {
  fun_name <- "absent"
  
  db <- list(
    "exists.Rd" = list(name = "exists")
  )
  idx <- list(
    alias_index   = new.env(parent = emptyenv()),
    topic_by_file = c("exists.Rd" = "exists")
  )
  
  # The conventional file "absent.Rd" is not in db, no alias entry
  # maps to "absent", and no topic in topic_by_file equals "absent".
  expect_null(find_rd_for_fun(fun_name, db, idx))
})

test_that("find_rd_for_fun builds the index on demand when idx is NULL and reaches the topic-name fallback", {
  fun_name <- "myfun"
  rd_real  <- list(name = "myfun", tag = "via-stub")
  
  db <- list("weird.Rd" = rd_real)
  
  built_idx <- list(
    alias_index   = new.env(parent = emptyenv()),
    topic_by_file = c("weird.Rd" = "myfun")
  )
  
  build_mock <- mockery::mock(built_idx)
  mockery::stub(find_rd_for_fun, "build_rd_index", build_mock)
  
  res <- find_rd_for_fun(fun_name, db)  # idx defaults to NULL
  
  mockery::expect_called(build_mock, 1)
  build_args <- mockery::mock_args(build_mock)[[1]]
  expect_identical(build_args[[1]], db)
  
  expect_identical(res$filename, "weird.Rd")
  expect_identical(res$rd, rd_real)
})

test_that("assess_examples returns 'No documentation found' and 'no Rd file' when find_rd_for_fun() returns NULL", {
  # Bind the function object
  fn <- assess_examples
  
  # Stub tools::Rd_db to return an empty Rd database (or minimal)
  mockery::stub(fn, "tools::Rd_db", function(dir) list())
  
  # Stub build_rd_index to return a dummy index
  mockery::stub(fn, "build_rd_index", function(db) list(alias_index = new.env(), topic_by_file = character(0)))
  
  # Stub find_rd_for_fun to always return NULL (simulate missing Rd doc)
  mockery::stub(fn, "find_rd_for_fun", function(fun, db, idx) NULL)
  
  # Stub extract_examples_text (won't be called because hit is NULL)
  mockery::stub(fn, "extract_examples_text", function(rd_doc) stop("Should not be called"))
  
  # Stub rd_name (won't be called because hit is NULL)
  mockery::stub(fn, "rd_name", function(rd) stop("Should not be called"))
  
  # Stub the exports helper to simulate two exported functions.
  # (This replaces the previous asNamespace/getNamespaceExports/getExportedValue
  # stubs - assess_examples() now delegates that work to get_exported_function_names().)
  mockery::stub(fn, "get_exported_function_names",
                function(pkg_name, pkg_source_path) c("funA", "funB"))
  
  # Run the function
  result <- fn(pkg_name = "mockpkg", pkg_source_path = "mock/path")
  
  # Assertions
  expect_s3_class(result$data, "data.frame")
  expect_equal(nrow(result$data), 2) # two exported functions
  expect_true(all(result$data$documentation_name == "No documentation found"))
  expect_true(all(result$data$example == "no Rd file"))
  expect_true(all(is.na(result$data$documentation_location)))
  expect_equal(result$example_score, 0) # no examples found
})


test_that("assess_exported_functions_docs returns empty data frame when no exported functions", {
  fn <- assess_exported_functions_docs
  
  # Stub tools::Rd_db to return an empty Rd database
  mockery::stub(fn, "tools::Rd_db", function(dir) list())
  
  # Stub the exports helper to simulate a package with no exports.
  # (Replaces the previous asNamespace/getNamespaceExports stubs -
  # assess_exported_functions_docs() now delegates that work to
  # get_exported_function_names().)
  mockery::stub(fn, "get_exported_function_names",
                function(pkg_name, pkg_source_path) character(0))
  
  # Run the function
  expect_message(
    result <- fn(pkg_name = "mockpkg", pkg_source_path = "mock/path"),
    regexp = "mockpkg: no exported functions found; documentation score = 0.00%"
  )
  
  # Assertions
  expect_s3_class(result$data, "data.frame")
  expect_equal(nrow(result$data), 0)
  expect_equal(result$has_docs_score, 0)
})


test_that("assess_exported_functions_docs returns 'No documentation found' when find_rd_for_fun returns NULL", {
  fn <- assess_exported_functions_docs
  
  # Stub tools::Rd_db to return a dummy Rd database
  mockery::stub(fn, "tools::Rd_db", function(dir) list())
  
  # Stub build_rd_index to return a dummy index
  mockery::stub(fn, "build_rd_index", function(db) list(alias_index = new.env(), topic_by_file = character(0)))
  
  # Stub find_rd_for_fun to always return NULL
  mockery::stub(fn, "find_rd_for_fun", function(fun, db, idx) NULL)
  
  # Stub the exports helper to simulate two exported functions.
  # (Replaces the previous asNamespace/getNamespaceExports/getExportedValue
  # stubs - assess_exported_functions_docs() now delegates that work to
  # get_exported_function_names().)
  mockery::stub(fn, "get_exported_function_names",
                function(pkg_name, pkg_source_path) c("funA", "funB"))
  
  # Run the function
  expect_message(
    result <- fn(pkg_name = "mockpkg", pkg_source_path = "mock/path"),
    regexp = "mockpkg: 0.00% of exported functions have documentation"
  )
  
  # Assertions
  expect_s3_class(result$data, "data.frame")
  expect_equal(nrow(result$data), 2)
  expect_true(all(result$data$documentation_name == "No documentation found"))
  expect_true(all(is.na(result$data$documentation_location)))
  expect_equal(result$has_docs_score, 0)
})


test_that("assess exports for missing examples works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  skip_if_repo_unavailable()
  
  
  # Ensure installs during this test go to a temp lib that stays on .libPaths()
  temp_lib <- file.path(tempdir(), "testthat-lib")
  dir.create(temp_lib, recursive = TRUE, showWarnings = FALSE)
  withr::local_libpaths(new = temp_lib, action = "prefix")
  
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0001_0.1.0.tar.gz", 
                         package = "risk.assessr")
  testthat::skip_if(identical(dp_orig, ""), "Bundled test tarball not found")
  
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
    
    
    # First attempt: should be found on .libPaths() because we prefixed temp_lib
    available <- requireNamespace(pkg_name, quietly = TRUE)
    
    # Fallback: load from source if not found (use pkgload if available)
    if (!available && dir.exists(pkg_source_path)) {
      testthat::skip_if_not_installed("pkgload")
      pkgload::load_all(pkg_source_path, quiet = TRUE, helpers = FALSE)
      available <- requireNamespace(pkg_name, quietly = TRUE)
    }
    
    testthat::skip_if_not(
      available,
      message = paste("Package", pkg_name, "not available in .libPaths() in CI")
    )
    
    
    testthat::expect_message(
      has_examples <- assess_examples(pkg_name, pkg_source_path),
      glue::glue("{(pkg_name)}: 0.00% of exported functions have examples"),
      fixed = TRUE
    )
    
    has_examples <- assess_examples(pkg_name, pkg_source_path)
    
    expect_identical(length(has_examples), 2L)
    
    expect_vector(has_examples)
    
    expect_true(checkmate::check_list(has_examples, 
                                      any.missing = TRUE)
    )
    
    testthat::expect_length(has_examples, 2L) 
  }
  
})

test_that("assess exports for packages - no exported functions works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  skip_if_repo_unavailable()
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0005_0.1.0.tar.gz",
                         package = "risk.assessr")
  skip_if_test_data_missing(dp_orig)
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
      glue::glue("{(pkg_name)}: no exported functions found; example score = 0.00%"),
      fixed = TRUE
    )
    
    has_examples <- assess_examples(pkg_name, pkg_source_path)
    
    expect_identical(length(has_examples), 2L)
    
    expect_vector(has_examples)
    
    expect_true(checkmate::check_list(has_examples, 
                                      any.missing = TRUE)
    )
    
    testthat::expect_length(has_examples, 2L) 
  }
  
})

test_that("assess exports for help files works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  skip_if_repo_unavailable()
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz",
                    package = "risk.assessr")
  skip_if_test_data_missing(dp)
  
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
  skip_if_repo_unavailable()
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0006_0.1.0.tar.gz",
                         package = "risk.assessr")
  skip_if_test_data_missing(dp_orig)
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

# ---------------------------------------------------------------------------
# Tests for get_exports_from_source()
#
# These tests cover every branch of get_exports_from_source() without
# relying on any installed package, internet access, or files outside of
# session tempdir(), so they are safe to run under CRAN checks.
# parseNamespaceFile() is stubbed with mockery so the tests do not
# depend on R version-specific behaviour of the base parser.
# ---------------------------------------------------------------------------

test_that("get_exports_from_source returns character(0) for NULL path", {
  expect_identical(get_exports_from_source(NULL), character(0))
})

test_that("get_exports_from_source returns character(0) for empty string path", {
  expect_identical(get_exports_from_source(""), character(0))
})

test_that("get_exports_from_source returns character(0) when path does not exist", {
  tmp <- withr::local_tempdir()
  missing_path <- file.path(tmp, "this_directory_does_not_exist")
  expect_false(dir.exists(missing_path))
  expect_identical(get_exports_from_source(missing_path), character(0))
})

test_that("get_exports_from_source returns character(0) when NAMESPACE is missing", {
  pkg_root <- withr::local_tempdir()
  # Intentionally do not create a NAMESPACE file.
  expect_false(file.exists(file.path(pkg_root, "NAMESPACE")))
  expect_identical(get_exports_from_source(pkg_root), character(0))
})

test_that("get_exports_from_source returns character(0) when parseNamespaceFile errors", {
  pkg_root <- withr::local_tempdir()
  writeLines("export(foo)", file.path(pkg_root, "NAMESPACE"))
  
  mockery::stub(
    get_exports_from_source,
    "parseNamespaceFile",
    function(...) stop("simulated parse failure")
  )
  
  expect_identical(get_exports_from_source(pkg_root), character(0))
})

test_that("get_exports_from_source returns character(0) when there are no exports or patterns", {
  pkg_root <- withr::local_tempdir()
  writeLines("# empty NAMESPACE", file.path(pkg_root, "NAMESPACE"))
  
  mockery::stub(
    get_exports_from_source,
    "parseNamespaceFile",
    function(...) list(
      exports = character(0),
      exportPatterns = character(0)
    )
  )
  
  expect_identical(get_exports_from_source(pkg_root), character(0))
})

test_that("get_exports_from_source returns explicit exports when no patterns are defined", {
  pkg_root <- withr::local_tempdir()
  writeLines("export(foo)", file.path(pkg_root, "NAMESPACE"))
  
  mockery::stub(
    get_exports_from_source,
    "parseNamespaceFile",
    function(...) list(
      exports = c("foo", "bar"),
      exportPatterns = character(0)
    )
  )
  
  out <- get_exports_from_source(pkg_root)
  expect_type(out, "character")
  expect_setequal(out, c("foo", "bar"))
})

test_that("get_exports_from_source skips pattern expansion when man/ is missing", {
  pkg_root <- withr::local_tempdir()
  writeLines('exportPattern("^my_")', file.path(pkg_root, "NAMESPACE"))
  # Intentionally do not create a man/ directory.
  expect_false(dir.exists(file.path(pkg_root, "man")))
  
  mockery::stub(
    get_exports_from_source,
    "parseNamespaceFile",
    function(...) list(
      exports = "explicit_export",
      exportPatterns = "^my_"
    )
  )
  
  expect_identical(get_exports_from_source(pkg_root), "explicit_export")
})

test_that("get_exports_from_source expands exportPatterns against Rd files in man/", {
  pkg_root <- withr::local_tempdir()
  writeLines('exportPattern("^my_")', file.path(pkg_root, "NAMESPACE"))
  dir.create(file.path(pkg_root, "man"))
  file.create(file.path(
    pkg_root, "man",
    c("my_fun.Rd", "my_helper.Rd", "other.Rd", "notes.txt")
  ))
  
  mockery::stub(
    get_exports_from_source,
    "parseNamespaceFile",
    function(...) list(
      exports = character(0),
      exportPatterns = "^my_"
    )
  )
  
  out <- get_exports_from_source(pkg_root)
  expect_setequal(out, c("my_fun", "my_helper"))
  expect_false("other" %in% out)
  expect_false("notes" %in% out)
})

test_that("get_exports_from_source returns the unique union of exports and pattern matches", {
  pkg_root <- withr::local_tempdir()
  writeLines(c('export(my_fun)', 'exportPattern("^my_")'),
             file.path(pkg_root, "NAMESPACE"))
  dir.create(file.path(pkg_root, "man"))
  file.create(file.path(pkg_root, "man",
                        c("my_fun.Rd", "my_helper.Rd")))
  
  mockery::stub(
    get_exports_from_source,
    "parseNamespaceFile",
    function(...) list(
      exports = "my_fun",
      exportPatterns = "^my_"
    )
  )
  
  out <- get_exports_from_source(pkg_root)
  expect_setequal(out, c("my_fun", "my_helper"))
  # my_fun appears in both `exports` and as a pattern match, but the
  # final result must be de-duplicated.
  expect_equal(length(out), length(unique(out)))
})

# ---------------------------------------------------------------------------
# Tests for get_exported_function_names()
#
# get_exported_function_names() is the shared helper used by
# assess_examples() and assess_exported_functions_docs() to obtain the
# list of exported function names. The happy path reads from the
# installed namespace; the fallback parses NAMESPACE from source so
# `R CMD INSTALL` failures (e.g. no R/ folder on stricter R versions)
# do not abort the documentation metrics. Tests use mockery::stub() to
# pin both branches deterministically without requiring any installed
# package, internet access, or filesystem access beyond tempdir().
# ---------------------------------------------------------------------------

test_that("get_exported_function_names: returns only function exports when namespace is loadable", {
  fake_ns <- new.env(parent = emptyenv())
  
  mockery::stub(
    get_exported_function_names,
    "asNamespace",
    function(pkg) fake_ns
  )
  mockery::stub(
    get_exported_function_names,
    "getNamespaceExports",
    function(ns) c("fun_a", "data_b", "fun_c")
  )
  mockery::stub(
    get_exported_function_names,
    "getExportedValue",
    function(ns, name) {
      # Only fun_a and fun_c are functions; data_b is a non-function export.
      if (name %in% c("fun_a", "fun_c")) function() NULL else 42L
    }
  )
  
  out <- get_exported_function_names("mockpkg", "mock/path")
  
  expect_type(out, "character")
  expect_setequal(out, c("fun_a", "fun_c"))
  expect_false("data_b" %in% out)
})

test_that("get_exported_function_names: returns character(0) when namespace exports nothing", {
  fake_ns <- new.env(parent = emptyenv())
  
  mockery::stub(get_exported_function_names, "asNamespace",
                function(pkg) fake_ns)
  mockery::stub(get_exported_function_names, "getNamespaceExports",
                function(ns) character(0))
  
  out <- get_exported_function_names("mockpkg", "mock/path")
  expect_identical(out, character(0))
})

test_that("get_exported_function_names: falls back to get_exports_from_source when namespace is missing", {
  fallback_mock <- mockery::mock(c("foo", "bar"))
  
  mockery::stub(
    get_exported_function_names,
    "asNamespace",
    function(pkg) stop(sprintf("there is no package called '%s'", pkg))
  )
  mockery::stub(
    get_exported_function_names,
    "get_exports_from_source",
    fallback_mock
  )
  
  out <- get_exported_function_names("missing.pkg", "mock/path")
  
  expect_setequal(out, c("foo", "bar"))
  mockery::expect_called(fallback_mock, 1)
  fb_args <- mockery::mock_args(fallback_mock)[[1]]
  expect_equal(fb_args[[1]], "mock/path")
})

test_that("get_exported_function_names: fallback returns character(0) when NAMESPACE has no exports", {
  mockery::stub(
    get_exported_function_names,
    "asNamespace",
    function(pkg) stop("packageNotFoundError")
  )
  mockery::stub(
    get_exported_function_names,
    "get_exports_from_source",
    function(...) character(0)
  )
  
  expect_identical(
    get_exported_function_names("missing.pkg", "mock/path"),
    character(0)
  )
})

# ---------------------------------------------------------------------------
# Tests for assess_examples() / assess_exported_functions_docs() fallback path
#
# These tests reproduce the Ubuntu R-release / R-devel failure where
# the package namespace cannot be loaded (e.g. R CMD INSTALL failed
# because the package has no R/ folder). With the fix in place,
# assess_examples() and assess_exported_functions_docs() delegate to
# get_exported_function_names(), which silently falls back to
# get_exports_from_source() and lets the metrics complete instead of
# bubbling up a packageNotFoundError.
# ---------------------------------------------------------------------------

test_that("assess_examples: completes via fallback when namespace is not loadable (no exports)", {
  fn <- assess_examples
  
  mockery::stub(fn, "tools::Rd_db", function(dir) list())
  # Simulate the package failing to load AND having no declared exports.
  mockery::stub(fn, "get_exported_function_names",
                function(pkg_name, pkg_source_path) character(0))
  
  expect_message(
    result <- fn(pkg_name = "mockpkg", pkg_source_path = "mock/path"),
    regexp = "mockpkg: no exported functions found; example score = 0.00%"
  )
  
  expect_s3_class(result$data, "data.frame")
  expect_equal(nrow(result$data), 0)
  expect_equal(result$example_score, 0)
})

test_that("assess_examples: completes via fallback when namespace is not loadable (some exports)", {
  fn <- assess_examples
  
  mockery::stub(fn, "tools::Rd_db", function(dir) list())
  mockery::stub(fn, "build_rd_index",
                function(db) list(alias_index = new.env(parent = emptyenv()),
                                  topic_by_file = character(0)))
  # Names produced by the source-NAMESPACE fallback.
  mockery::stub(fn, "get_exported_function_names",
                function(pkg_name, pkg_source_path) c("alpha", "beta"))
  # No Rd page for either: simulates a package whose R/ folder is missing.
  mockery::stub(fn, "find_rd_for_fun", function(fun, db, idx) NULL)
  
  result <- suppressMessages(
    fn(pkg_name = "mockpkg", pkg_source_path = "mock/path")
  )
  
  expect_s3_class(result$data, "data.frame")
  expect_equal(nrow(result$data), 2)
  expect_setequal(result$data$function_name, c("alpha", "beta"))
  expect_true(all(result$data$documentation_name == "No documentation found"))
  expect_true(all(result$data$example == "no Rd file"))
  expect_equal(result$example_score, 0)
})

test_that("assess_exported_functions_docs: completes via fallback when namespace is not loadable (no exports)", {
  fn <- assess_exported_functions_docs
  
  mockery::stub(fn, "tools::Rd_db", function(dir) list())
  mockery::stub(fn, "get_exported_function_names",
                function(pkg_name, pkg_source_path) character(0))
  
  expect_message(
    result <- fn(pkg_name = "mockpkg", pkg_source_path = "mock/path"),
    regexp = "mockpkg: no exported functions found; documentation score = 0.00%"
  )
  
  expect_s3_class(result$data, "data.frame")
  expect_equal(nrow(result$data), 0)
  expect_equal(result$has_docs_score, 0)
})

test_that("assess_exported_functions_docs: completes via fallback when namespace is not loadable (some exports)", {
  fn <- assess_exported_functions_docs
  
  mockery::stub(fn, "tools::Rd_db", function(dir) list())
  mockery::stub(fn, "build_rd_index",
                function(db) list(alias_index = new.env(parent = emptyenv()),
                                  topic_by_file = character(0)))
  mockery::stub(fn, "get_exported_function_names",
                function(pkg_name, pkg_source_path) c("alpha", "beta"))
  mockery::stub(fn, "find_rd_for_fun", function(fun, db, idx) NULL)
  
  result <- suppressMessages(
    fn(pkg_name = "mockpkg", pkg_source_path = "mock/path")
  )
  
  expect_s3_class(result$data, "data.frame")
  expect_equal(nrow(result$data), 2)
  expect_setequal(result$data$function_name, c("alpha", "beta"))
  expect_true(all(result$data$documentation_name == "No documentation found"))
  expect_true(all(is.na(result$data$documentation_location)))
  expect_equal(result$has_docs_score, 0)
})

# ---------------------------------------------------------------------------
# Tests for assess_export_help() error-fallback branch
#
# These tests target the `error = function(e) get_exports_from_source(...)`
# handler inside assess_export_help(). getNamespaceExports() is stubbed to
# raise a packageNotFoundError-style error so the tryCatch handler is
# always exercised, independently of what is (or is not) installed.
# All collaborators are mocked, so no installed package, no filesystem
# access beyond session tempdir(), and no internet access are required.
# ---------------------------------------------------------------------------

test_that("assess_export_help falls back to get_exports_from_source when namespace is missing (no exports)", {
  pkg_name <- "fake.pkg.no.exports"
  pkg_source_path <- withr::local_tempdir()
  
  # Simulate the failure seen on Ubuntu R-release / R-devel when
  # R CMD INSTALL has not produced a loadable namespace.
  mockery::stub(
    assess_export_help,
    "getNamespaceExports",
    function(...) stop(sprintf("there is no package called '%s'", pkg_name))
  )
  
  # Fallback resolves to no declared exports.
  mockery::stub(
    assess_export_help,
    "get_exports_from_source",
    function(...) character(0)
  )
  
  testthat::expect_message(
    out <- assess_export_help(pkg_name, pkg_source_path),
    glue::glue("No exported functions in {pkg_name}"),
    fixed = TRUE
  )
  expect_identical(length(out), 1L)
  expect_true(checkmate::check_numeric(out, any.missing = FALSE))
  expect_equal(out, 0)
})

test_that("assess_export_help fallback path returns 1 when every parsed export is documented", {
  pkg_name <- "fake.pkg.all.docs"
  pkg_source_path <- withr::local_tempdir()
  
  mockery::stub(
    assess_export_help,
    "getNamespaceExports",
    function(...) stop("packageNotFoundError")
  )
  mockery::stub(
    assess_export_help,
    "get_exports_from_source",
    function(...) c("foo", "bar")
  )
  mockery::stub(
    assess_export_help,
    "get_func_descriptions",
    function(...) c(foo = "desc-foo", bar = "desc-bar")
  )
  
  testthat::expect_message(
    out <- assess_export_help(pkg_name, pkg_source_path),
    glue::glue("All exported functions have corresponding help files in {pkg_name}"),
    fixed = TRUE
  )
  expect_equal(out, 1)
})

test_that("assess_export_help fallback path returns 0 when some parsed exports lack documentation", {
  pkg_name <- "fake.pkg.partial.docs"
  pkg_source_path <- withr::local_tempdir()
  
  mockery::stub(
    assess_export_help,
    "getNamespaceExports",
    function(...) stop("packageNotFoundError")
  )
  mockery::stub(
    assess_export_help,
    "get_exports_from_source",
    function(...) c("foo", "bar", "baz")
  )
  mockery::stub(
    assess_export_help,
    "get_func_descriptions",
    function(...) c(foo = "desc-foo")  # bar and baz are undocumented
  )
  
  testthat::expect_message(
    out <- assess_export_help(pkg_name, pkg_source_path),
    glue::glue("Some exported functions are missing help files in {pkg_name}"),
    fixed = TRUE
  )
  expect_equal(out, 0)
})

test_that("assess_export_help passes pkg_source_path to the fallback exactly once on namespace error", {
  pkg_name <- "fake.pkg.args"
  pkg_source_path <- withr::local_tempdir()
  
  mockery::stub(
    assess_export_help,
    "getNamespaceExports",
    function(...) stop("packageNotFoundError")
  )
  
  fallback_mock <- mockery::mock(character(0))
  mockery::stub(
    assess_export_help,
    "get_exports_from_source",
    fallback_mock
  )
  
  suppressMessages(assess_export_help(pkg_name, pkg_source_path))
  
  mockery::expect_called(fallback_mock, 1)
  fb_args <- mockery::mock_args(fallback_mock)[[1]]
  expect_equal(fb_args[[1]], pkg_source_path)
})

test_that("assess_export_help does NOT invoke the fallback when getNamespaceExports succeeds", {
  pkg_name <- "fake.pkg.loaded"
  pkg_source_path <- withr::local_tempdir()
  
  mockery::stub(
    assess_export_help,
    "getNamespaceExports",
    function(...) c("foo")
  )
  
  fallback_mock <- mockery::mock(character(0))
  mockery::stub(
    assess_export_help,
    "get_exports_from_source",
    fallback_mock
  )
  mockery::stub(
    assess_export_help,
    "get_func_descriptions",
    function(...) c(foo = "desc-foo")
  )
  
  suppressMessages(out <- assess_export_help(pkg_name, pkg_source_path))
  
  # The error handler must not run on the happy path.
  mockery::expect_called(fallback_mock, 0)
  expect_equal(out, 1)
})


test_that("assess exports for news works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  skip_if_repo_unavailable()
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz",
                    package = "risk.assessr")
  skip_if_test_data_missing(dp)
  
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
  skip_if_repo_unavailable()
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz",
                    package = "risk.assessr")
  skip_if_test_data_missing(dp)
  
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
    
    news_current <- assess_news_current(pkg_name, pkg_ver, pkg_source_path)
    
    expect_identical(length(news_current), 1L)
    
    expect_vector(news_current)
    
    expect_true(checkmate::check_numeric(news_current, 
                                         any.missing = FALSE)
    )
    
    testthat::expect_equal(news_current, 0L) 
  }
})

test_that("assess_news and assess_news_current find NEWS under inst/", {
  pkg_root <- tempfile("news_inst")
  withr::defer(unlink(pkg_root, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  dir.create(pkg_root)
  dir.create(file.path(pkg_root, "inst"))
  news_body <- c(
    "------------------------------------------------------------------------",
    "VERSIONS mynewsinst 2.1.0 | 2026-04-01 | Last: mynewsinst 2.1.0-5",
    "FIXED * example"
  )
  writeLines(news_body, file.path(pkg_root, "inst", "NEWS"))
  
  testthat::expect_message(
    out <- assess_news("mynewsinst", pkg_root),
    "mynewsinst has news",
    fixed = TRUE
  )
  testthat::expect_equal(out, 1L)
  
  testthat::expect_message(
    cur <- assess_news_current("mynewsinst", "2.1.0-5", pkg_root),
    "mynewsinst has current news",
    fixed = TRUE
  )
  testthat::expect_equal(cur, 1L)
})

test_that("assess_news finds plain NEWS at package root", {
  pkg_root <- tempfile("news_plain")
  withr::defer(unlink(pkg_root, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  dir.create(pkg_root)
  writeLines("Changes in version 0.0.1\n", file.path(pkg_root, "NEWS"))
  
  testthat::expect_message(
    out <- assess_news("plainpkg", pkg_root),
    "plainpkg has news",
    fixed = TRUE
  )
  testthat::expect_equal(out, 1L)
})

test_that("assess_news_current matches Changes in version in plain NEWS", {
  pkg_root <- tempfile("news_changes")
  withr::defer(unlink(pkg_root, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  dir.create(pkg_root)
  writeLines(
    c("Changes in version 9.8.7", "  * note"),
    file.path(pkg_root, "NEWS")
  )
  
  testthat::expect_message(
    cur <- assess_news_current("chgpkg", "9.8.7", pkg_root),
    "chgpkg has current news",
    fixed = TRUE
  )
  testthat::expect_equal(cur, 1L)
})

test_that("assess_news_current requires exact version (no prefix match to longer)", {
  pkg_root <- tempfile("news_ver_prefix")
  withr::defer(unlink(pkg_root, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  dir.create(pkg_root)
  writeLines(
    c("# shortpkg 1.2.3", "more"),
    file.path(pkg_root, "NEWS.md")
  )
  
  testthat::expect_message(
    cur <- assess_news_current("shortpkg", "1.2", pkg_root),
    "shortpkg has no current news",
    fixed = TRUE
  )
  testthat::expect_equal(cur, 0L)
  
  testthat::expect_message(
    cur_ok <- assess_news_current("shortpkg", "1.2.3", pkg_root),
    "shortpkg has current news",
    fixed = TRUE
  )
  testthat::expect_equal(cur_ok, 1L)
})

test_that("assess_news finds NEWS.md under doc/", {
  pkg_root <- tempfile("news_doc")
  withr::defer(unlink(pkg_root, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  dir.create(pkg_root)
  dir.create(file.path(pkg_root, "doc"))
  writeLines(
    c("# docnews 1.0.0", "initial"),
    file.path(pkg_root, "doc", "NEWS.md")
  )
  
  testthat::expect_message(
    out <- assess_news("docnews", pkg_root),
    "docnews has news",
    fixed = TRUE
  )
  testthat::expect_equal(out, 1L)
  
  testthat::expect_message(
    cur <- assess_news_current("docnews", "1.0.0", pkg_root),
    "docnews has current news",
    fixed = TRUE
  )
  testthat::expect_equal(cur, 1L)
})

test_that("assess_news does not search tests/ (not a utils::news layout path)", {
  pkg_root <- tempfile("news_tests_skip")
  withr::defer(unlink(pkg_root, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  dir.create(pkg_root)
  dir.create(file.path(pkg_root, "tests", "fixtures"), recursive = TRUE)
  writeLines("noise", file.path(pkg_root, "tests", "fixtures", "NEWS"))
  
  testthat::expect_message(
    out <- assess_news("notestnews", pkg_root),
    "notestnews has no news",
    fixed = TRUE
  )
  testthat::expect_equal(out, 0L)
})

test_that("find_news_files picks NEWS under nested inst/ and vignettes/", {
  pkg_root <- tempfile("news_nested")
  withr::defer(unlink(pkg_root, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  dir.create(pkg_root)
  dir.create(file.path(pkg_root, "inst", "ext", "notes"), recursive = TRUE)
  dir.create(file.path(pkg_root, "vignettes"))
  writeLines(
    "Changes in version 4.3.2",
    file.path(pkg_root, "inst", "ext", "notes", "NEWS")
  )
  writeLines(
    c("\\name{NEWS}", "vignews 0.0.9"),
    file.path(pkg_root, "vignettes", "NEWS.Rd")
  )
  
  paths <- risk.assessr:::find_news_files(pkg_root)
  testthat::expect_true(length(paths) >= 2L)
  testthat::expect_true(any(grepl("inst/ext/notes/NEWS$", paths, perl = TRUE)))
  testthat::expect_true(any(grepl("vignettes/NEWS\\.Rd$", paths, perl = TRUE)))
  
  testthat::expect_message(
    out <- assess_news("nested", pkg_root),
    "nested has news",
    fixed = TRUE
  )
  testthat::expect_equal(out, 1L)
  
  testthat::expect_message(
    cur <- assess_news_current("vignews", "0.0.9", pkg_root),
    "vignews has current news",
    fixed = TRUE
  )
  testthat::expect_equal(cur, 1L)
  
  testthat::expect_message(
    cur2 <- assess_news_current("any", "4.3.2", pkg_root),
    "any has current news",
    fixed = TRUE
  )
  testthat::expect_equal(cur2, 1L)
})

test_that("assess_news does not match non-utils NEWS filenames", {
  pkg_root <- tempfile("news_wrong_name")
  withr::defer(unlink(pkg_root, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  dir.create(pkg_root)
  writeLines("Changes in version 1", file.path(pkg_root, "NEWS.txt"))
  
  testthat::expect_message(
    out <- assess_news("wrongname", pkg_root),
    "wrongname has no news",
    fixed = TRUE
  )
  testthat::expect_equal(out, 0L)
})


test_that("assess vignettes for tar file with vignettes works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  skip_if_repo_unavailable()
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz",
                    package = "risk.assessr")
  skip_if_test_data_missing(dp)
  
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

test_that("assess_size_codebase returns 0 when R/ has no source files (stubbed list.files)", {
  # Use a real temp dir with an empty R/ subfolder so contains_r_folder()
  # returns TRUE and the code reaches the list.files branch.
  pkg_root <- withr::local_tempdir()
  dir.create(file.path(pkg_root, "R"))
  
  mock_list_files <- mockery::mock(character(0))
  mockery::stub(assess_size_codebase, "list.files", mock_list_files)
  
  out <- assess_size_codebase(pkg_root)
  expect_equal(out, 0)
  
  lf_args <- mockery::mock_args(mock_list_files)[[1]]
  expect_identical(lf_args$path, file.path(pkg_root, "R"))
  expect_true(isTRUE(lf_args$full.names))
  expect_true(isTRUE(lf_args$recursive))
  expect_false(isTRUE(lf_args$include.dirs))
})


test_that("returns NA when both inputs are NA", {
  expect_true(is.na(create_has_ex_docs_score(NA_real_, NA_real_)))
})

test_that("returns the non-NA input when the other is NA", {
  expect_equal(create_has_ex_docs_score(0.75, NA_real_), 0.75)
  expect_equal(create_has_ex_docs_score(NA_real_, 1), 1)
})

test_that("computes the mean for numeric scalars", {
  expect_equal(create_has_ex_docs_score(0, 0), 0)
  expect_equal(create_has_ex_docs_score(1, 1), 1)
  expect_equal(create_has_ex_docs_score(0, 1), 0.5)
  expect_equal(create_has_ex_docs_score(0.75, 1), 0.875)
})

test_that("works with integer inputs", {
  expect_equal(create_has_ex_docs_score(0L, 1L), 0.5)
  expect_type(create_has_ex_docs_score(0L, 1L), "double")  # result should be double
})

test_that("vector inputs are concatenated and averaged (not elementwise)", {
  e <- c(0.2, 0.8)
  d <- c(0.4, 0.6)
  expected <- mean(c(e, d), na.rm = TRUE)  # = 0.5
  expect_equal(create_has_ex_docs_score(e, d), expected)
})

test_that("handles NA within vectors using na.rm=TRUE", {
  e <- c(0.2, NA_real_)
  d <- c(NA_real_, 0.8)
  # concatenated -> c(0.2, NA, NA, 0.8) -> mean of c(0.2, 0.8) = 0.5
  expect_equal(create_has_ex_docs_score(e, d), 0.5)
})

test_that("treats NaN like NA (removed when na.rm=TRUE)", {
  e <- c(0.2, NaN)
  d <- c(NA_real_, 0.8)
  expected <- mean(c(0.2, NaN, NA_real_, 0.8), na.rm = TRUE)  # = 0.5
  expect_equal(create_has_ex_docs_score(e, d), expected)
})

test_that("mixed vector + scalar works (scalar just joins the pool)", {
  e <- c(0.2, 0.8)
  d <- 0.5
  expected <- mean(c(e, d), na.rm = TRUE)  # = 0.5
  expect_equal(create_has_ex_docs_score(e, d), expected)
})

test_that("symmetry: order of arguments does not change the result", {
  e <- c(0.1, 0.5, 0.9)
  d <- c(0.3, NA_real_)
  expect_equal(create_has_ex_docs_score(e, d),
               create_has_ex_docs_score(d, e))
})

test_that("always returns a length-1 double", {
  res <- create_has_ex_docs_score(c(0.2, 0.3), c(0.4, 0.5))
  expect_equal(length(res), 1L)
  expect_type(res, "double")
})

# ---- get_func_descriptions() ------------------------------------------------
#
# get_func_descriptions() reads exported function descriptions from an Rd
# database. The function has three exit paths we want to exercise:
#
#   * happy path: tools::Rd_db() succeeds and returns a populated database.
#   * fallback path: tools::Rd_db() throws, the function emits a message
#     (line 14), then resorts to find.package() + list.files() + parse_Rd()
#     to assemble a database manually.
#   * per-file resilience: an individual parse_Rd() failure emits a message
#     (line 29) and is dropped from the manual database.
#
# All external dependencies (tools::Rd_db, find.package, list.files,
# tools::parse_Rd) are mocked with mockery::stub() so the tests are
# deterministic, offline, and CRAN-compliant.

# Helper: build a minimal Rd "document" with the structure get_func_descriptions
# inspects. Each top-level element is a "block" carrying an Rd_tag attribute,
# matching what tools::parse_Rd() / tools::Rd_db() return in practice.
make_fake_rd <- function(name, description = NULL) {
  blocks <- list(structure(list(name), Rd_tag = "\\name"))
  if (!is.null(description)) {
    blocks <- c(
      blocks,
      list(structure(list(description), Rd_tag = "\\description"))
    )
  }
  blocks
}

test_that("get_func_descriptions() returns a named list of descriptions when tools::Rd_db() succeeds", {
  fake_db <- list(
    "topicA.Rd" = make_fake_rd("topicA", "Description of topicA."),
    "topicB.Rd" = make_fake_rd("topicB", "Description of topicB.")
  )
  
  mockery::stub(
    get_func_descriptions,
    "tools::Rd_db",
    function(pkg_name) fake_db
  )
  # Defensive guard: the fallback path must not run when Rd_db() succeeds.
  mockery::stub(
    get_func_descriptions,
    "find.package",
    function(pkg, quiet) stop("find.package() should not be called on the happy path")
  )
  
  out <- get_func_descriptions("mockpkg")
  
  expect_type(out, "list")
  expect_named(out, c("topicA", "topicB"))
  expect_identical(out$topicA, "Description of topicA.")
  expect_identical(out$topicB, "Description of topicB.")
})

test_that("get_func_descriptions() drops Rd topics that have no \\description tag", {
  fake_db <- list(
    "withDesc.Rd" = make_fake_rd("withDesc", "I have a description."),
    # No description block on purpose - this topic should be filtered out.
    "noDesc.Rd"   = make_fake_rd("noDesc",   description = NULL)
  )
  
  mockery::stub(
    get_func_descriptions,
    "tools::Rd_db",
    function(pkg_name) fake_db
  )
  
  out <- get_func_descriptions("mockpkg")
  
  expect_named(out, "withDesc")
  expect_identical(out$withDesc, "I have a description.")
})

test_that("get_func_descriptions() falls back to manual parse_Rd() when tools::Rd_db() fails", {
  parsed_rd <- make_fake_rd("topicX", "Manually parsed description.")
  
  mockery::stub(
    get_func_descriptions,
    "tools::Rd_db",
    function(pkg_name) stop("simulated Rd_db failure")
  )
  mockery::stub(
    get_func_descriptions,
    "find.package",
    function(pkg, quiet) "mock/pkg/path"
  )
  mockery::stub(
    get_func_descriptions,
    "list.files",
    function(path, pattern, full.names) c("mock/pkg/path/man/topicX.Rd")
  )
  mockery::stub(
    get_func_descriptions,
    "tools::parse_Rd",
    function(f) parsed_rd
  )
  
  msgs <- testthat::capture_messages(
    out <- get_func_descriptions("mockpkg")
  )
  
  # The line-14 message records why we entered the fallback path.
  expect_true(any(grepl(
    "tools::Rd_db\\(\\) failed for 'mockpkg': simulated Rd_db failure",
    msgs
  )))
  expect_named(out, "topicX")
  expect_identical(out$topicX, "Manually parsed description.")
})

test_that("get_func_descriptions() emits a message and drops Rd files that fail parse_Rd()", {
  good_rd <- make_fake_rd("topicGood", "Description from the good Rd file.")
  
  mockery::stub(
    get_func_descriptions,
    "tools::Rd_db",
    function(pkg_name) stop("force fallback")
  )
  mockery::stub(
    get_func_descriptions,
    "find.package",
    function(pkg, quiet) "mock/pkg/path"
  )
  mockery::stub(
    get_func_descriptions,
    "list.files",
    function(path, pattern, full.names) c(
      "mock/pkg/path/man/bad.Rd",
      "mock/pkg/path/man/good.Rd"
    )
  )
  mockery::stub(
    get_func_descriptions,
    "tools::parse_Rd",
    function(f) {
      if (basename(f) == "bad.Rd") {
        stop("simulated parse_Rd failure")
      }
      good_rd
    }
  )
  
  msgs <- testthat::capture_messages(
    out <- get_func_descriptions("mockpkg")
  )
  
  # Both messages should fire: the line-14 Rd_db failure and the line-29
  # parse_Rd failure for the bad file.
  expect_true(any(grepl("tools::Rd_db\\(\\) failed for 'mockpkg'", msgs)))
  expect_true(any(grepl(
    "Failed to parse bad\\.Rd: simulated parse_Rd failure",
    msgs
  )))
  
  # Only the successfully-parsed Rd survives into the final result.
  expect_named(out, "topicGood")
  expect_identical(out$topicGood, "Description from the good Rd file.")
})

# ---- find_rd_for_fun() ------------------------------------------------------
#
# find_rd_for_fun() resolves a function name to its Rd document by trying,
# in priority order:
#   1. on-demand build_rd_index() when idx is NULL (line 229),
#   2. the conventional filename "fun.Rd" (lines 231-234),
#   3. an alias-based lookup via idx$alias_index (lines 235-239),
#   4. a topic-name fallback via idx$topic_by_file (lines 240-245),
#   5. NULL when nothing matches (line 246).
#
# Each branch gets its own test driven by minimal synthetic db / idx objects.
# build_rd_index() is mocked with mockery::stub() so we can prove the
# on-demand index build only fires when idx is missing, and so the tests
# don't depend on the production index-building code. All tests are offline,
# deterministic, and CRAN-friendly.

# Helper: build a minimal idx of the shape build_rd_index() returns.
# `alias_map` is a named list mapping alias -> filename.
# `topic_by_file` is a named character vector mapping filename -> topic name.
make_rd_idx <- function(alias_map = list(),
                        topic_by_file = character()) {
  alias_index <- new.env(parent = emptyenv())
  for (alias in names(alias_map)) {
    alias_index[[alias]] <- alias_map[[alias]]
  }
  list(alias_index = alias_index, topic_by_file = topic_by_file)
}

test_that("find_rd_for_fun() returns the direct fun.Rd match (lines 231-234) and never touches the alias/topic paths", {
  db <- list(
    "foo.Rd" = list(content = "rd for foo"),
    "bar.Rd" = list(content = "rd for bar")
  )
  # Empty idx: alias_index is empty and topic_by_file has no entries, so the
  # function MUST resolve via the direct filename match.
  idx <- make_rd_idx()
  
  hit <- find_rd_for_fun("foo", db, idx)
  
  expect_type(hit, "list")
  expect_named(hit, c("rd", "filename"))
  expect_identical(hit$filename, "foo.Rd")
  expect_identical(hit$rd, db[["foo.Rd"]])
})

test_that("find_rd_for_fun() builds the index on demand when idx is NULL (line 229)", {
  db <- list("foo.Rd" = list(content = "rd for foo"))
  
  # Stub build_rd_index() so we can prove it was called exactly once on the
  # supplied db, without depending on the production index-building code.
  built_idx <- make_rd_idx()
  build_calls <- 0L
  captured_db <- NULL
  mockery::stub(
    find_rd_for_fun,
    "build_rd_index",
    function(db_arg) {
      build_calls <<- build_calls + 1L
      captured_db <<- db_arg
      built_idx
    }
  )
  
  hit <- find_rd_for_fun("foo", db)
  
  expect_equal(build_calls, 1L)
  expect_identical(captured_db, db)
  # Direct filename match still wins after the index is built.
  expect_identical(hit$filename, "foo.Rd")
  expect_identical(hit$rd, db[["foo.Rd"]])
})

test_that("find_rd_for_fun() does NOT call build_rd_index() when idx is supplied", {
  db <- list("foo.Rd" = list(content = "rd for foo"))
  idx <- make_rd_idx()
  
  mockery::stub(
    find_rd_for_fun,
    "build_rd_index",
    function(db_arg) stop("build_rd_index() should not be called when idx is supplied")
  )
  
  expect_no_error(find_rd_for_fun("foo", db, idx))
})

test_that("find_rd_for_fun() resolves via alias_index when there is no direct filename match (lines 235-239)", {
  db <- list(
    "actual_topic.Rd" = list(content = "rd for actual_topic"),
    "other.Rd"        = list(content = "rd for other")
  )
  # "foo" is not a filename in db, but it is aliased to actual_topic.Rd.
  idx <- make_rd_idx(
    alias_map = list(foo = "actual_topic.Rd")
  )
  
  hit <- find_rd_for_fun("foo", db, idx)
  
  expect_identical(hit$filename, "actual_topic.Rd")
  expect_identical(hit$rd, db[["actual_topic.Rd"]])
})

test_that("find_rd_for_fun() falls back to topic_by_file when no alias matches (lines 240-245)", {
  db <- list(
    "weird_filename.Rd" = list(content = "rd for foo (via topic name)"),
    "other.Rd"          = list(content = "rd for other")
  )
  # alias_index has no "foo" entry, but topic_by_file says weird_filename.Rd
  # has \name == "foo".
  idx <- make_rd_idx(
    topic_by_file = c(
      "weird_filename.Rd" = "foo",
      "other.Rd"          = "other_topic"
    )
  )
  
  hit <- find_rd_for_fun("foo", db, idx)
  
  expect_identical(hit$filename, "weird_filename.Rd")
  expect_identical(hit$rd, db[["weird_filename.Rd"]])
})

test_that("find_rd_for_fun() uses the first match when topic_by_file has duplicates (lines 242-244)", {
  db <- list(
    "first.Rd"  = list(content = "first rd"),
    "second.Rd" = list(content = "second rd")
  )
  # Both filenames advertise the same topic name "foo"; the function should
  # pick the first one via `topic_match[[1]]`.
  idx <- make_rd_idx(
    topic_by_file = c("first.Rd" = "foo", "second.Rd" = "foo")
  )
  
  hit <- find_rd_for_fun("foo", db, idx)
  
  expect_identical(hit$filename, "first.Rd")
  expect_identical(hit$rd, db[["first.Rd"]])
})

test_that("find_rd_for_fun() returns NULL when no path matches (line 246)", {
  db <- list(
    "alpha.Rd" = list(content = "rd for alpha"),
    "beta.Rd"  = list(content = "rd for beta")
  )
  idx <- make_rd_idx(
    alias_map     = list(other_alias = "alpha.Rd"),
    topic_by_file = c("alpha.Rd" = "alpha_topic", "beta.Rd" = "beta_topic")
  )
  
  expect_null(find_rd_for_fun("not_there", db, idx))
})
