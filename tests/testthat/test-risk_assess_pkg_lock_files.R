test_that("running risk_assess_pkg_lock_files with tar file", {
  
  lock_file <- system.file("test-data", "here-1.0.1.tar.gz",
                           package = "risk.assessr")
  
  expect_error(
    pak_results <-
      risk.assessr::risk_assess_pkg_lock_files(lock_file),
    regexp = "Assertion on 'input_data' failed.*\\.lock"
  )
  
})

# Mock the assess_pkg_r_package function
mock_assess_pkg_r_package <- function(pkg_name, pkg_version) {
  list(
    pkg_name = pkg_name,
    pkg_version = pkg_version,
    overall_risk_score = 0.3,
    risk_profile = "Medium"
  )
}

test_that("risk_assess_pkg_lock_files processes renv.lock correctly", {
  # Mock the risk.assessr::assess_pkg_r_package function
  mockery::stub(risk_assess_pkg_lock_files, "risk.assessr::assess_pkg_r_package", mock_assess_pkg_r_package)
  
  # Create a temporary .lock file
  temp_lock_file <- tempfile(fileext = ".lock")
  writeLines('{
    "R": {
      "Version": "4.0.2",
      "Repositories": [
        {
          "Name": "CRAN",
          "URL": "https://cloud.r-project.org"
        }
      ]
    },
    "Packages": {
      "askpass": {
        "Package": "markdown",
        "Version": "1.0",
        "Source": "Repository",
        "Repository": "CRAN",
        "Hash": "4584a57f565dd7987d59dda3a02cfb41"
      },
      "mime": {
        "Package": "mime",
        "Version": "0.12",
        "Source": "GitHub",
        "RemoteType": "github",
        "RemoteHost": "api.github.com",
        "RemoteUsername": "yihui",
        "RemoteRepo": "mime",
        "RemoteRef": "main",
        "RemoteSha": "1763e0dcb72fb58d97bab97bb834fc71f1e012bc",
        "Requirements": ["tools"],
        "Hash": "c2772b6269924dad6784aaa1d99dbb86"
      }
    }
  }', temp_lock_file)
  
  result <- risk_assess_pkg_lock_files(temp_lock_file)
  
  testthat::expect_true("markdown_1.0" %in% names(result))
  testthat::expect_true("mime_0.12" %in% names(result))
  testthat::expect_identical(length(result), 2L)
  testthat::expect_true(checkmate::check_class(result, "list"))
})

test_that("risk_assess_pkg_lock_files processes pak.lock correctly", {
  # Mock the risk.assessr::assess_pkg_r_package function
  mockery::stub(risk_assess_pkg_lock_files, "risk.assessr::assess_pkg_r_package", mock_assess_pkg_r_package)
  
  # Create a temporary .lock file with pak.lock format
  temp_lock_file <- tempfile(fileext = ".lock")
  writeLines('{
    "pak_version": "0.1.0",
    "r_version": "4.0.2",
    "repos": [
      {
        "name": "CRAN",
        "url": "https://cloud.r-project.org"
      }
    ],
    "packages": [
      {
        "package": "markdown",
        "version": "1.0",
        "source": "Repository",
        "repository": "CRAN",
        "hash": "4584a57f565dd7987d59dda3a02cfb41"
      }
    ]
  }', temp_lock_file)

  result <- risk_assess_pkg_lock_files(temp_lock_file)
  
  testthat::expect_true("markdown_1.0" %in% names(result))
  testthat::expect_identical(length(result), 1L)
  testthat::expect_true(checkmate::check_class(result, "list"))
})
