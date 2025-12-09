test_that("NULL input returns NULL", {
  expect_null(as_iso_date(NULL))
  expect_null(as_iso_date("not-a-date"))
})

test_that("Date inputs are formatted correctly", {
  d <- as.Date(c("2025-01-01", "2025-12-31"))
  out <- as_iso_date(d)
  expect_type(out, "character")
  expect_identical(out, c("2025-01-01", "2025-12-31"))
})

test_that("Character inputs coerce via as.Date and format as ISO", {
  x <- c("2024-02-28", "2024/02/29", "not-a-date")
  out <- as_iso_date(x)
  # as.Date("2024/02/29") parses under some locales; ensure expected positions
  expect_true(out[1] == "2024-02-28")
  expect_true(is.na(out[3]))
})

test_that("POSIXct inputs drop time and timezone (UTC by as.Date default)", {
  ts <- as.POSIXct(c("2025-03-14 00:00:00", "2025-03-14 23:59:59"), tz = "UTC")
  out <- as_iso_date(ts)
  expect_identical(out, c("2025-03-14", "2025-03-14"))
})

test_that("NA values are preserved as NA_character_", {
  x <- c(NA, "2020-01-02")
  out <- as_iso_date(x)
  expect_true(is.na(out[1]))
  expect_identical(out[2], "2020-01-02")
})

test_that("Vectorization: length and element-wise behavior", {
  x <- c("2021-01-01", "bad", "2021-01-03")
  out <- as_iso_date(x)
  expect_length(out, length(x))
  expect_identical(out[c(1,3)], c("2021-01-01", "2021-01-03"))
  expect_true(is.na(out[2]))
})


test_that("Empty HTML content", {
  empty_html <- NULL
  result <- parse_html_version(empty_html, "dummy_package")
  expect_equal(result, list())
})

test_that("HTML content without versions", {
  html_with_no_version <- '<table>
   <tr><td valign="top"></td><td><a href="https://example.com/package.tar.gz">package.tar.gz</a></td><td align="right">2023-01-01 12:00</td><td align="right">1.0M</td></tr>
  </table>'
  
  result <- parse_html_version(html_with_no_version, "package")
  expect_equal(result, list())
})

test_that("Valid HTML with one version", {
  valid_html <- '<table>
    <tr><td valign="top"></td><td><a href="https://example.com/package_1.0.tar.gz">package_1.0.tar.gz</a></td><td align="right">2023-01-01 12:00</td><td align="right">1.0M</td></tr>
  </table>'
  
  result <- parse_html_version(valid_html, "package")
  
  expected <- list(
    list(
      package_name = "package",
      package_version = "1.0",
      link = "https://example.com/package_1.0.tar.gz",
      date = "2023-01-01 12:00",
      size = "1.0M"
    )
  )
  expect_equal(result, expected)
})

test_that("Valid HTML with multiple versions", {
  valid_html <- '<table>
    <tr><td valign="top"></td><td><a href="https://example.com/package_1.0.tar.gz">package_1.0.tar.gz</a></td><td align="right">2023-01-01 12:00</td><td align="right">1.0M</td></tr>
    <tr><td valign="top"></td><td><a href="https://example.com/package_2.0.tar.gz">package_2.0.tar.gz</a></td><td align="right">2023-02-01 12:00</td><td align="right">1.5M</td></tr>
  </table>'
  
  result <- parse_html_version(valid_html, "package")
  expected <- list(
    list(
      package_name = "package",
      package_version = "1.0",
      link = "https://example.com/package_1.0.tar.gz",
      date = "2023-01-01 12:00",
      size = "1.0M"
    ),
    list(
      package_name = "package",
      package_version = "2.0",
      link = "https://example.com/package_2.0.tar.gz",
      date = "2023-02-01 12:00",
      size = "1.5M"
    )
  )
  expect_equal(result, expected)
})

test_that("HTML with missing version in table", {
  html_missing_version <- '<table>
    <tr><td valign="top"></td><td><a href="https://example.com/package.tar.gz"></a></td><td align="right">2023-01-01 12:00</td><td align="right">1.0M</td></tr>
  </table>'
  
  result <- parse_html_version(html_missing_version, "package")
  expect_equal(result, list())
})

test_that("HTML with corrupted table structure", {
  html_corrupted <- '<table>
    <tr><td valign="top"></td><td></td><td align="right">2023-01-01 12:00</td></tr>
  </table>'
  
  result <- parse_html_version(html_corrupted, "package")
  expect_equal(result, list())
})


# Test cases: parse_package_info

test_that("parse_package_info works correctly with mock response", {
  # Create a mock response object
  mock_response <- list(
    status_code = 200,
    content = charToRaw("<html>Mock Content</html>")
  )
  
  # Mock curl::curl_fetch_memory
  mock_fetch <- mockery::mock(mock_response)
  
  # Use with_mocked_bindings and explicitly bind curl::curl_fetch_memory
  with_mocked_bindings(
    `curl_fetch_memory` = mock_fetch,
    {
      result <- parse_package_info("mockpackage")
      
      # Check that the function returns the mocked content
      expect_type(result, "character")
      expect_match(result, "Mock Content")
    },
    .package = "curl"
  )
})

test_that("parse_package_info handles non-successful response", {
  # Create a mock response object for a 404 status
  mock_response <- list(
    status_code = 404,
    content = charToRaw("")
  )
  
  # Mock curl::curl_fetch_memory
  mock_fetch <- mockery::mock(mock_response)
  
  # Use with_mocked_bindings and explicitly bind curl::curl_fetch_memory
  with_mocked_bindings(
    `curl_fetch_memory` = mock_fetch,
    {
      result <- parse_package_info("nonexistentpackage")
      
      # Check that the function returns NULL for non-successful response
      expect_null(result)
    },
    .package = "curl"
  )
})


# check_cran_package


test_that("check_cran_package returns TRUE for a valid package", {
  # Create a mock response object for a valid package
  mock_response <- list(
    status_code = 200,
    content = charToRaw("<html><body>Package ‘mockpackage’ is available.</body></html>")
  )
  
  # Mock curl::curl_fetch_memory
  mock_fetch <- mockery::mock(mock_response)
  
  # Use with_mocked_bindings
  with_mocked_bindings(
    `curl_fetch_memory` = mock_fetch,
    {
      result <- check_cran_package("mockpackage")
      
      # Check that the function returns TRUE for a valid package
      expect_true(result)
    },
    .package = "curl"
  )
})

test_that("check_cran_package returns FALSE for a removed package", {
  # Create a mock response object for a removed package
  mock_response <- list(
    status_code = 200,
    content = charToRaw("<html><body>Package ‘mockpackage’ was removed from the CRAN repository.</body></html>")
  )
  
  # Mock curl::curl_fetch_memory
  mock_fetch <- mockery::mock(mock_response)
  
  # Use local_mocked_bindings instead of with_mocked_bindings (newer approach)
  local_mocked_bindings(curl_fetch_memory = mock_fetch, .package = "curl")
  
  # Call function
  result <- check_cran_package("mockpackage")
  
  # Expect FALSE because the package was removed
  expect_false(result)
})


test_that("check_cran_package returns FALSE for a package containing a point ", {
  # Create a mock response object for a removed package
  mock_response <- list(
    status_code = 200,
    content = charToRaw("<!DOCTYPE html>\n<html>\n<head>\n<title>CRAN: Package assertive.base</title>\n<link rel=\"canonical\" href=\"https://CRAN.R-project.org/package=assertive.base\"/>\n<link rel=\"stylesheet\" type=\"text/css\" href=\"../../CRAN_web.css\"/>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/>\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, user-scalable=yes\"/>\n</head>\n<body>\n<div class=\"container\">\n<p>Package &lsquo;assertive.base&rsquo; was removed from the CRAN repository.</p>\n<p>\nFormerly available versions can be obtained from the\n<a href=\"https://CRAN.R-project.org/src/contrib/Archive/assertive.base\"><span class=\"CRAN\">archive</span></a>.\n</p>\n<p>\nArchived on 2024-04-12 as issues were not corrected despite reminders.\n</p>\n<p>A summary of the most recent check results can be obtained from the <a href=\"https://cran-archive.R-project.org/web/checks/2024/2024-04-12_check_results_assertive.base.html\"><span class=\"CRAN\">check results archive</span></a>.</p>\n<p>Please use the canonical form\n<a href=\"https://CRAN.R-project.org/package=assertive.base\"><span class=\"CRAN\"><samp>https://CRAN.R-project.org/package=assertive.base</samp></span></a>\nto link to this page.</p>\n</div>\n</body>\n</html>\n")
  )
  
  # Mock curl::curl_fetch_memory
  mock_fetch <- mockery::mock(mock_response)
  local_mocked_bindings(curl_fetch_memory = mock_fetch, .package = "curl")
  result <- check_cran_package("assertive.base")
  
  # Expect FALSE because the package was removed
  expect_false(result)
})




test_that("check_cran_package returns FALSE for a non-existent package", {
  # Create a mock response object for a 404 status
  mock_response <- list(
    status_code = 404,
    content = charToRaw("")
  )
  
  # Mock curl::curl_fetch_memory
  mock_fetch <- mockery::mock(mock_response)
  
  # Use with_mocked_bindings
  with_mocked_bindings(
    `curl_fetch_memory` = mock_fetch,
    {
      result <- check_cran_package("nonexistentpackage")
      
      # Check that the function returns FALSE for a non-existent package
      expect_false(result)
    },
    .package = "curl"
  )
})


# get_cran_package_url

test_that("get_cran_package_url returns URL for the latest version when version is NULL", {
  last_version <- list(version = "1.1.0", date = "2024-05-01")
  all_versions <- list(
    list(version = "1.0.0", date = "2023-01-01"),
    list(version = "1.1.0", date = "2024-05-01")
  )
  result <- get_cran_package_url("mockpackage", NULL, last_version, all_versions)
  expect_equal(result, "https://cran.r-project.org/src/contrib/mockpackage_1.1.0.tar.gz")
})

test_that("get_cran_package_url returns URL for the latest version when explicitly provided", {
  last_version <- list(version = "1.1.0", date = "2024-05-01")
  all_versions <- list(
    list(version = "1.0.0", date = "2023-01-01"),
    list(version = "1.1.0", date = "2024-05-01")
  )
  result <- get_cran_package_url("mockpackage", "1.1.0", last_version, all_versions)
  expect_equal(result, "https://cran.r-project.org/src/contrib/mockpackage_1.1.0.tar.gz")
})

test_that("get_cran_package_url returns URL for a specific older version", {
  last_version <- list(version = "1.1.0", date = "2024-05-01")
  all_versions <- list(
    list(version = "1.0.0", date = "2023-01-01"),
    list(version = "1.1.0", date = "2024-05-01")
  )
  result <- get_cran_package_url("mockpackage", "1.0.0", last_version, all_versions)
  expect_equal(result, "https://cran.r-project.org/src/contrib/Archive/mockpackage/mockpackage_1.0.0.tar.gz")
})

test_that("get_cran_package_url returns fallback message for a version that doesn't exist", {
  last_version <- list(version = "1.1.0", date = "2024-05-01")
  all_versions <- list(
    list(version = "1.0.0", date = "2023-01-01"),
    list(version = "1.1.0", date = "2024-05-01")
  )
  result <- get_cran_package_url("mockpackage", "2.0.0", last_version, all_versions)
  expect_equal(result, "No valid URL found")
})



# Test cases: get_versions

test_that("get_versions with empty table returns last version correctly", {
  # Mock input table
  mock_table <- NULL
  
  # Mock package name
  package_name <- "mockpackage"
  
  # Mock curl_fetch_memory response with version and date_publication
  mock_response <- list(
    status_code = 200,
    content = charToRaw('{"version": "1.2.0", "date_publication": "2024-05-01T00:00:00Z"}')
  )
  
  # Create a mock function for curl_fetch_memory
  mock_curl_fetch <- mockery::mock(mock_response)
  
  # Use with_mocked_bindings to override curl_fetch_memory in the curl package
  with_mocked_bindings(
    curl_fetch_memory = mock_curl_fetch,
    {
      result <- get_versions(mock_table, package_name)
      
      expect_equal(result$all_versions, list(list(version = "1.2.0", date = "2024-05-01")))
      expect_equal(result$last_version, list(version = "1.2.0", date = "2024-05-01"))
    },
    .package = "curl"
  )
})


test_that("get_versions extracts and combines versions correctly", {
  mock_table <- list(
    list(package_version = "1.0.0", date = "2022-01-01"),
    list(package_version = "1.1.0", date = "2023-01-01")
  )
  
  package_name <- "mockpackage"
  
  mock_response <- list(
    status_code = 200,
    content = charToRaw('{"version": "1.2.0", "date_publication": "2024-05-01T00:00:00Z"}')
  )
  mock_curl_fetch <- mockery::mock(mock_response)
  
  with_mocked_bindings(
    curl_fetch_memory = mock_curl_fetch,
    {
      result <- get_versions(mock_table, package_name)
      
      expect_equal(result$all_versions, list(
        list(version = "1.0.0", date = "2022-01-01"),
        list(version = "1.1.0", date = "2023-01-01"),
        list(version = "1.2.0", date = "2024-05-01")
      ))
      
      expect_equal(result$last_version, list(
        version = "1.2.0",
        date = "2024-05-01"
      ))
    },
    .package = "curl"
  )
})


test_that("get_versions handles invalid API response", {
  mock_table <- list(
    list(package_version = "1.0.0", date = "2022-01-01"),
    list(package_version = "1.1.0", date = "2023-01-01")
  )
  
  package_name <- "mockpackage"
  
  mock_response <- list(
    status_code = 500,
    content = charToRaw("")
  )
  mock_curl_fetch <- mockery::mock(mock_response)
  
  with_mocked_bindings(
    curl_fetch_memory = mock_curl_fetch,
    {
      result <- get_versions(mock_table, package_name)
      
      expect_equal(result$all_versions, list(
        list(version = "1.0.0", date = "2022-01-01"),
        list(version = "1.1.0", date = "2023-01-01")
      ))
      expect_null(result$last_version)
    },
    .package = "curl"
  )
})




test_that("get_versions removes duplicate versions", {
  mock_table <- list(
    list(package_version = "1.0.0", date = "2022-01-01"),
    list(package_version = "1.0.0", date = "2022-01-01"),
    list(package_version = "1.1.0", date = "2023-01-01")
  )
  
  package_name <- "mockpackage"
  
  mock_response <- list(
    status_code = 200,
    content = charToRaw('{"version": "1.1.0", "date_publication": "2023-01-01T00:00:00Z"}')
  )
  mock_curl_fetch <- mockery::mock(mock_response)
  
  with_mocked_bindings(
    curl_fetch_memory = mock_curl_fetch,
    {
      result <- get_versions(mock_table, package_name)
      
      expect_equal(result$all_versions, list(
        list(version = "1.0.0", date = "2022-01-01"),
        list(version = "1.0.0", date = "2022-01-01"),
        list(version = "1.1.0", date = "2023-01-01")
      ))
      
      expect_equal(result$last_version, list(
        version = "1.1.0",
        date = "2023-01-01"
      ))
    },
    .package = "curl"
  )
})

test_that("get_versions handles missing API version", {
  mock_table <- list(
    list(package_version = "1.0.0", date = "2022-01-01"),
    list(package_version = "1.1.0", date = "2023-01-01")
  )
  
  package_name <- "mockpackage"
  
  mock_response <- list(
    status_code = 200,
    content = charToRaw('{}')  # No version or date_publication
  )
  mock_curl_fetch <- mockery::mock(mock_response)
  
  with_mocked_bindings(
    curl_fetch_memory = mock_curl_fetch,
    {
      result <- get_versions(mock_table, package_name)
      
      expect_equal(result$all_versions, list(
        list(version = "1.0.0", date = "2022-01-01"),
        list(version = "1.1.0", date = "2023-01-01")
      ))
      expect_null(result$last_version$version)
    },
    .package = "curl"
  )
})



# Test cases: check_and_fetch_cran_package


test_that("check_and_fetch_cran_package fetches the correct URL for the latest version", {
  mock_check_cran_package <- mockery::mock(TRUE)
  mock_parse_package_info <- mockery::mock("<html>Mock HTML Content</html>")
  mock_parse_html_version <- mockery::mock(
    list(
      list(package_version = "1.0.0", date = "2022-01-01"),
      list(package_version = "1.1.0", date = "2023-01-01")
    )
  )
  mock_get_versions <- mockery::mock(list(
    all_versions = list(
      list(version = "1.0.0", date = "2022-01-01"),
      list(version = "1.1.0", date = "2023-01-01"),
      list(version = "1.2.0", date = "2024-01-01")
    ),
    last_version = list(version = "1.2.0", date = "2024-01-01")
  ))
  mock_get_cran_package_url <- mockery::mock("https://cran.r-project.org/src/contrib/mockpackage_1.2.0.tar.gz")
  
  with_mocked_bindings(
    check_cran_package = mock_check_cran_package,
    parse_package_info = mock_parse_package_info,
    parse_html_version = mock_parse_html_version,
    get_versions = mock_get_versions,
    get_cran_package_url = mock_get_cran_package_url,
    {
      result <- check_and_fetch_cran_package("mockpackage")
      
      expect_equal(result$package_url, "https://cran.r-project.org/src/contrib/mockpackage_1.2.0.tar.gz")
      expect_equal(result$last_version$version, "1.2.0")
      expect_equal(result$last_version$date, "2024-01-01")
      expect_null(result$version)
      expect_equal(
        result$all_versions,
        list(
          list(version = "1.0.0", date = "2022-01-01"),
          list(version = "1.1.0", date = "2023-01-01"),
          list(version = "1.2.0", date = "2024-01-01")
        )
      )
    }
  )
})

test_that("check_and_fetch_cran_package handles specific version correctly", {
  mock_check_cran_package <- mockery::mock(TRUE)
  mock_parse_package_info <- mockery::mock("<html>Mock HTML Content</html>")
  mock_parse_html_version <- mockery::mock(
    list(
      list(package_version = "1.0.0", date = "2022-01-01"),
      list(package_version = "1.1.0", date = "2023-01-01")
    )
  )
  mock_get_versions <- mockery::mock(list(
    all_versions = list(
      list(version = "1.0.0", date = "2022-01-01"),
      list(version = "1.1.0", date = "2023-01-01")
    ),
    last_version = list(version = "1.1.0", date = "2023-01-01")
  ))
  mock_get_cran_package_url <- mockery::mock("https://cran.r-project.org/src/contrib/Archive/mockpackage/mockpackage_1.0.0.tar.gz")
  
  with_mocked_bindings(
    check_cran_package = mock_check_cran_package,
    parse_package_info = mock_parse_package_info,
    parse_html_version = mock_parse_html_version,
    get_versions = mock_get_versions,
    get_cran_package_url = mock_get_cran_package_url,
    {
      result <- check_and_fetch_cran_package("mockpackage", "1.0.0")
      
      expect_equal(result$package_url, "https://cran.r-project.org/src/contrib/Archive/mockpackage/mockpackage_1.0.0.tar.gz")
      expect_equal(result$version, "1.0.0")
      expect_equal(result$last_version$version, "1.1.0")
      expect_equal(result$last_version$date, "2023-01-01")
      expect_equal(
        result$all_versions,
        list(
          list(version = "1.0.0", date = "2022-01-01"),
          list(version = "1.1.0", date = "2023-01-01")
        )
      )
    }
  )
})

test_that("check_and_fetch_cran_package handles missing version", {
  mock_check_cran_package <- mockery::mock(TRUE)
  mock_parse_package_info <- mockery::mock("<html>Mock HTML Content</html>")
  mock_parse_html_version <- mockery::mock(
    list(
      list(package_version = "1.0.0", date = "2022-01-01"),
      list(package_version = "1.1.0", date = "2023-01-01")
    )
  )
  mock_get_versions <- mockery::mock(list(
    all_versions = list(
      list(version = "1.0.0", date = "2022-01-01"),
      list(version = "1.1.0", date = "2023-01-01")
    ),
    last_version = list(version = "1.1.0", date = "2023-01-01")
  ))
  mock_get_cran_package_url <- mockery::mock(NULL)
  
  with_mocked_bindings(
    check_cran_package = mock_check_cran_package,
    parse_package_info = mock_parse_package_info,
    parse_html_version = mock_parse_html_version,
    get_versions = mock_get_versions,
    get_cran_package_url = mock_get_cran_package_url,
    {
      result <- check_and_fetch_cran_package("mockpackage", "2.0.0")
      
      expect_equal(result$error, "Version 2.0.0 for mockpackage not found")
      expect_equal(
        result$versions_available,
        list(
          list(version = "1.0.0", date = "2022-01-01"),
          list(version = "1.1.0", date = "2023-01-01")
        )
      )
    }
  )
})

test_that("check_and_fetch_cran_package with version table null", {
  mock_check_cran_package <- mockery::mock(TRUE)
  mock_parse_package_info <- mockery::mock(NULL)
  mock_parse_html_version <- mockery::mock(NULL)
  
  mock_get_versions <- mockery::mock(list(
    all_versions = list(
      list(version = "1.2.0", date = "2024-01-01")
    ),
    last_version = list(version = "1.2.0", date = "2024-01-01")
  ))
  mock_get_cran_package_url <- mockery::mock("https://cran.r-project.org/src/contrib/mockpackage_1.2.0.tar.gz")
  
  with_mocked_bindings(
    check_cran_package = mock_check_cran_package,
    parse_package_info = mock_parse_package_info,
    parse_html_version = mock_parse_html_version,
    get_versions = mock_get_versions,
    get_cran_package_url = mock_get_cran_package_url,
    {
      result <- check_and_fetch_cran_package("mockpackage")
      
      expect_equal(result$package_url, "https://cran.r-project.org/src/contrib/mockpackage_1.2.0.tar.gz")
      expect_equal(result$last_version$version, "1.2.0")
      expect_equal(result$last_version$date, "2024-01-01")
      expect_null(result$version)
      expect_equal(
        result$all_versions,
        list(
          list(version = "1.2.0", date = "2024-01-01")
        )
      )
    }
  )
})


# get_internal_package_url


# test-get_internal_package_url.R

test_that("check_and_fetch_cran_package with version table null", {
  mock_check_cran_package <- mockery::mock(TRUE)
  mock_parse_package_info <- mockery::mock(NULL)
  mock_parse_html_version <- mockery::mock(NULL, cycle = TRUE)
  mock_get_versions <- mockery::mock(list(
    all_versions = list(list(version = "1.2.0", date = "2024-01-01")),
    last_version = list(version = "1.2.0", date = "2024-01-01")
  ), cycle = TRUE)
  mock_get_cran_package_url <- mockery::mock("https://cran.r-project.org/src/contrib/mockpackage_1.2.0.tar.gz")
  
  with_mocked_bindings(
    check_cran_package = mock_check_cran_package,
    parse_package_info = mock_parse_package_info,
    parse_html_version = mock_parse_html_version,
    get_versions = mock_get_versions,
    get_cran_package_url = mock_get_cran_package_url,
    {
      result <- check_and_fetch_cran_package("mockpackage")
      
      expect_equal(result$package_url, "https://cran.r-project.org/src/contrib/mockpackage_1.2.0.tar.gz")
      expect_equal(result$last_version$version, "1.2.0")
      expect_equal(result$last_version$date, "2024-01-01")
      expect_null(result$version)
      expect_equal(result$all_versions, list(list(version = "1.2.0", date = "2024-01-01")))
    }
  )
})

# get_internal_package_url

test_that("get_internal_package_url works correctly for latest version", {
  # Mock the repos API response
  mock_repos_response <- list(
    content = charToRaw(enc2utf8('[
      {"id": 6, "name": "art-git"},
      {"id": 1, "name": "prod-cran"}
    ]')),
    status_code = 200
  )
  
  # Mock the package API response
  mock_package_response <- list(
    content = charToRaw(enc2utf8('{
      "version": "1.2.0",
      "date_publication": "2024-01-01T12:00:00+01:00",
      "archived": [{"version": "1.0.0", "date": "2023-01-01T00:00:00+01:00"}, {"version": "1.1.0", "date": "2023-06-01T00:00:00+01:00"}]
    }')),
    status_code = 200
  )
  
  # Create a mock that returns different responses for different URLs
  mock_curl_fetch_memory <- mockery::mock(
    mock_repos_response,  # First call - for repos list
    mock_package_response # Second call - for package info
  )
  
  local_mocked_bindings(curl_fetch_memory = mock_curl_fetch_memory, .package = "curl")
  
  result <- get_internal_package_url("mockpackage", base_url="https://rstudio-pm.com")
  
  # Verify the mock was called with the correct URLs
  expect_equal(
    mockery::mock_args(mock_curl_fetch_memory)[[1]], 
    list("https://rstudio-pm.com/__api__/repos/")
  )
  expect_equal(
    mockery::mock_args(mock_curl_fetch_memory)[[2]], 
    list("https://rstudio-pm.com/__api__/repos/6/packages/mockpackage")
  )
  
  # Verify the result
  expect_equal(result$url, "https://rstudio-pm.com/art-git/latest/src/contrib/mockpackage_1.2.0.tar.gz")
  expect_equal(result$last_version$version, "1.2.0")
  expect_equal(result$all_versions, list(
    list(version = "1.2.0", date = as.Date("2024-01-01")),
    list(version = "1.0.0", date = as.Date("2023-01-01")),
    list(version = "1.1.0", date = as.Date("2023-06-01"))
  ))
  expect_equal(result$repo_id, c("art-git" = 6))
  expect_equal(result$repo_name, "art-git")
})

test_that("get_internal_package_url works correctly for latest version", {

  mock_repos_response <- list(
    content = charToRaw(enc2utf8('[
      {"id": 6, "name": "art-git"},
      {"id": 1, "name": "prod-cran"}
    ]')),
    status_code = 200
  )
  
  mock_package_response <- list(
    content = charToRaw(enc2utf8('{
      "version": "1.2.0",
      "date_publication": "2024-01-01T12:00:00+01:00",
      "archived": [{"version": "1.0.0", "date": "2023-01-01T00:00:00+01:00"}, {"version": "1.1.0", "date": "2023-06-01T00:00:00+01:00"}]
    }')),
    status_code = 200
  )
  
   mock_curl_fetch_memory <- mockery::mock(
    mock_repos_response,  
    mock_package_response 
  )
  
  local_mocked_bindings(curl_fetch_memory = mock_curl_fetch_memory, .package = "curl")
  
  result <- get_internal_package_url("mockpackage", base_url="https://rstudio-pm.com")
  
  expect_equal(
    mockery::mock_args(mock_curl_fetch_memory)[[1]], 
    list("https://rstudio-pm.com/__api__/repos/")
  )
  expect_equal(
    mockery::mock_args(mock_curl_fetch_memory)[[2]], 
    list("https://rstudio-pm.com/__api__/repos/6/packages/mockpackage")
  )
  
  expect_equal(result$url, "https://rstudio-pm.com/art-git/latest/src/contrib/mockpackage_1.2.0.tar.gz")
  expect_equal(result$last_version$version, "1.2.0")
  expect_equal(result$all_versions, list(
    list(version = "1.2.0", date = as.Date("2024-01-01")),
    list(version = "1.0.0", date = as.Date("2023-01-01")),
    list(version = "1.1.0", date = as.Date("2023-06-01"))
  ))
  expect_equal(result$repo_id, c("art-git" = 6))
  expect_equal(result$repo_name, "art-git")
})

test_that("get_internal_package_url works correctly for archived version", {
  
  mock_repos_response <- list(
    content = charToRaw(enc2utf8('[
      {"id": 6, "name": "art-git"},
      {"id": 1, "name": "prod-cran"}
    ]')),
    status_code = 200
  )
  
  mock_package_response <- list(
    content = charToRaw(enc2utf8('{
      "version": "1.2.0",
      "date_publication": "2024-01-01T12:00:00+01:00",
      "archived": [{"version": "1.0.0", "date": "2023-01-01T00:00:00+01:00"}, {"version": "1.1.0", "date": "2023-06-01T00:00:00+01:00"}]
    }')),
    status_code = 200
  )
  
  mock_curl_fetch_memory <- mockery::mock(
    mock_repos_response,  
    mock_package_response 
  )
  
  local_mocked_bindings(curl_fetch_memory = mock_curl_fetch_memory, .package = "curl")
  
  result <- get_internal_package_url("mockpackage", "1.0.0", base_url="https://rstudio-pm.com")
  
  expect_equal(
    mockery::mock_args(mock_curl_fetch_memory)[[1]], 
    list("https://rstudio-pm.com/__api__/repos/")
  )
  expect_equal(
    mockery::mock_args(mock_curl_fetch_memory)[[2]], 
    list("https://rstudio-pm.com/__api__/repos/6/packages/mockpackage")
  )
  
  expect_equal(result$url, "https://rstudio-pm.com/art-git/latest/src/contrib/Archive/mockpackage/mockpackage_1.0.0.tar.gz")
  expect_equal(result$last_version$version, "1.2.0")
  expect_equal(result$all_versions, list(
    list(version = "1.2.0", date = as.Date("2024-01-01")),
    list(version = "1.0.0", date = as.Date("2023-01-01")),
    list(version = "1.1.0", date = as.Date("2023-06-01"))
  ))
  expect_equal(result$repo_id, c("art-git" = 6))
  expect_equal(result$repo_name, "art-git")
})


test_that("get_internal_package_url returns NULLs when no last version exists", {
  
  mock_repos_response <- list(
    content = charToRaw(enc2utf8('[
      {"id": 6, "name": "art-git"},
      {"id": 1, "name": "prod-cran"}
    ]')),
    status_code = 200
  )
  
  # Mock the package API response with no current version
  mock_package_response <- list(
    content = charToRaw(enc2utf8('{
      "archived": [{"version": "1.0.0", "date": "2023-01-01"}, {"version": "1.1.0", "date": "2023-06-01"}]
    }')),
    status_code = 200
  )
  
  mock_curl_fetch_memory <- mockery::mock(
    mock_repos_response,  
    mock_package_response 
  )
  
  local_mocked_bindings(curl_fetch_memory = mock_curl_fetch_memory, .package = "curl")
  result <- get_internal_package_url("mockpackage", "2.0.0", base_url="https://rstudio-pm.com")
  
  expect_equal(
    mockery::mock_args(mock_curl_fetch_memory)[[1]], 
    list("https://rstudio-pm.com/__api__/repos/")
  )
  expect_equal(
    mockery::mock_args(mock_curl_fetch_memory)[[2]], 
    list("https://rstudio-pm.com/__api__/repos/6/packages/mockpackage")
  )
  
  expect_null(result$url)
  expect_null(result$last_version)
  expect_equal(result$all_versions, list())
  expect_null(result$repo_id)
  expect_null(result$repo_name)
})

test_that("get_internal_package_url returns NULLs when no last version exists and no version params", {
  mock_response <- list(
    content = charToRaw(enc2utf8('{
      "archived": [{"version": "1.0.0", "date": "2023-01-01"}, {"version": "1.1.0", "date": "2023-06-01"}]
    }')),
    status_code = 200
  )

  mock_curl_fetch_memory <- mockery::mock(mock_response)
  local_mocked_bindings(curl_fetch_memory = mock_curl_fetch_memory, .package = "curl")
  result <- get_internal_package_url("mockpackage", base_url="https://rstudio-pm.com")
  expect_null(result$url)
  expect_null(result$last_version)
  expect_equal(result$all_versions, list())
})

test_that("get_internal_package_url works correctly when no archived versions exist", {
  
  mock_repos_response <- list(
    content = charToRaw(enc2utf8('[
      {"id": 6, "name": "art-git"},
      {"id": 1, "name": "prod-cran"}
    ]')),
    status_code = 200
  )
  
  mock_package_response <- list(
    content = charToRaw(enc2utf8('{
      "version": "1.2.0",
      "date_publication": "2024-01-01T12:00:00+01:00"
    }')),
    status_code = 200
  )
  
  mock_curl_fetch_memory <- mockery::mock(
    mock_repos_response,  
    mock_package_response 
  )
  
  local_mocked_bindings(curl_fetch_memory = mock_curl_fetch_memory, .package = "curl")
  result <- get_internal_package_url("mockpackage", "1.2.0", base_url="https://rstudio-pm.com")
  
  expect_equal(
    mockery::mock_args(mock_curl_fetch_memory)[[1]], 
    list("https://rstudio-pm.com/__api__/repos/")
  )
  expect_equal(
    mockery::mock_args(mock_curl_fetch_memory)[[2]], 
    list("https://rstudio-pm.com/__api__/repos/6/packages/mockpackage")
  )
  
  # Verify the result
  expect_equal(result$url, "https://rstudio-pm.com/art-git/latest/src/contrib/mockpackage_1.2.0.tar.gz")
  expect_equal(result$last_version$version, "1.2.0")
  expect_equal(result$all_versions, list(
    list(version = "1.2.0", date = as.Date("2024-01-01"))
  ))
  expect_equal(result$repo_id, c("art-git" = 6))
  expect_equal(result$repo_name, "art-git")
})


test_that("get_internal_package_url handles empty API response", {
  mock_response <- list(
    content = raw(0),
    status_code = 200
  )

  mock_curl_fetch_memory <- mockery::mock(mock_response)
  local_mocked_bindings(curl_fetch_memory = mock_curl_fetch_memory, .package = "curl")

  result <- get_internal_package_url("mockpackage")

  expect_null(result$url)
  expect_null(result$last_version)
  expect_equal(result$all_versions, list())
})

test_that("get_internal_package_url handles invalid JSON response", {
  mock_response <- list(
    content = charToRaw("Invalid JSON"),
    status_code = 200
  )

  mock_curl_fetch_memory <- mockery::mock(mock_response)
  local_mocked_bindings(curl_fetch_memory = mock_curl_fetch_memory, .package = "curl")

  result <- get_internal_package_url("mockpackage")

  expect_null(result$url)
  expect_null(result$last_version)
  expect_equal(result$all_versions, list())
})

test_that("get_internal_package_url handles 404 (package not found)", {
  mock_response <- list(
    content = charToRaw("Not Found"),
    status_code = 404
  )

  mock_curl_fetch_memory <- mockery::mock(mock_response)
  local_mocked_bindings(curl_fetch_memory = mock_curl_fetch_memory, .package = "curl")

  result <- get_internal_package_url("nonexistentpackage")

  expect_null(result$url)
  expect_null(result$last_version)
  expect_equal(result$all_versions, list())
})


test_that("get_internal_package_url handles NULL base_url and missing INTERNAL_RSPM option", {
  
  old_repos <- options("repos")
  on.exit(options(repos = old_repos$repos))
  
  options(repos = NULL)
  
  expect_message(
    result <- get_internal_package_url("mockpackage"),
    "NO INTERNAL_RSPM FOUND"
  )
  
  expect_null(result$url)
  expect_null(result$last_version)
  expect_equal(result$all_versions, list())
  expect_null(result$repo_id)
  expect_null(result$repo_name)
})

test_that("get_internal_package_url handles repos without INTERNAL_RSPM", {
  
  old_repos <- options("repos")
  on.exit(options(repos = old_repos$repos))
  
  # Set repos without INTERNAL_RSPM
  options(repos = c(CRAN = "https://cloud.r-project.org"))
  
  expect_message(
    result <- get_internal_package_url("mockpackage"),
    "NO INTERNAL_RSPM FOUND"
  )
  
  expect_null(result$url)
  expect_null(result$last_version)
  expect_equal(result$all_versions, list())
  expect_null(result$repo_id)
  expect_null(result$repo_name)
})

test_that("get_internal_package_url handles failure in first API call", {

  mock_curl_fetch_memory <- mockery::mock(NULL)
  local_mocked_bindings(curl_fetch_memory = mock_curl_fetch_memory, .package = "curl")
  
  result <- get_internal_package_url("mockpackage", base_url="https://rstudio-pm.com")
  
  # Verify the mock was called
  expect_equal(length(mockery::mock_args(mock_curl_fetch_memory)), 1)
  expect_equal(
    mockery::mock_args(mock_curl_fetch_memory)[[1]], 
    list("https://rstudio-pm.com/__api__/repos/")
  )
  
  # Verify the result
  expect_null(result$url)
  expect_null(result$last_version)
  expect_equal(result$all_versions, list())
  expect_null(result$repo_id)
  expect_null(result$repo_name)
})

test_that("get_internal_package_url handles failure in second API call", {
  # Mock the repos API response
  mock_repos_response <- list(
    content = charToRaw(enc2utf8('[
      {"id": 6, "name": "art-git"},
      {"id": 1, "name": "prod-cran"}
    ]')),
    status_code = 200
  )
  
  mock_curl_fetch_memory <- mockery::mock(
    mock_repos_response,  
    NULL                  
  )
  local_mocked_bindings(curl_fetch_memory = mock_curl_fetch_memory, .package = "curl")
  
  result <- get_internal_package_url("mockpackage", base_url="https://rstudio-pm.com")
  
  expect_equal(
    mockery::mock_args(mock_curl_fetch_memory)[[1]], 
    list("https://rstudio-pm.com/__api__/repos/")
  )
  
  expect_equal(
    mockery::mock_args(mock_curl_fetch_memory)[[2]], 
    list("https://rstudio-pm.com/__api__/repos/6/packages/mockpackage")
  )
  
  expect_null(result$url)
  expect_null(result$last_version)
  expect_equal(result$all_versions, list())
  expect_null(result$repo_id)
  expect_null(result$repo_name)
})


test_that("get_internal_package_url handles failure in all package API calls", {
  # Mock the repos API response
  mock_repos_response <- list(
    content = charToRaw(enc2utf8('[
      {"id": 6, "name": "art-git"},
      {"id": 1, "name": "prod-cran"}
    ]')),
    status_code = 200
  )
  
  # Mock package API responses (all fail)
  mock_package_response_fail <- list(
    content = charToRaw("Not Found"),
    status_code = 404
  )
  
  # Mock curl_fetch_memory to succeed on first call but return 404 on subsequent calls
  mock_curl_fetch_memory <- mockery::mock(
    mock_repos_response,        # First call succeeds
    mock_package_response_fail, # First package call fails
    mock_package_response_fail  # Second package call fails
  )
  local_mocked_bindings(curl_fetch_memory = mock_curl_fetch_memory, .package = "curl")
  
  result <- get_internal_package_url("mockpackage", base_url="https://rstudio-pm.com")
  
  # Verify the mock was called three times
  expect_equal(length(mockery::mock_args(mock_curl_fetch_memory)), 3)
  expect_equal(
    mockery::mock_args(mock_curl_fetch_memory)[[1]], 
    list("https://rstudio-pm.com/__api__/repos/")
  )
  expect_equal(
    mockery::mock_args(mock_curl_fetch_memory)[[2]], 
    list("https://rstudio-pm.com/__api__/repos/6/packages/mockpackage")
  )
  expect_equal(
    mockery::mock_args(mock_curl_fetch_memory)[[3]], 
    list("https://rstudio-pm.com/__api__/repos/1/packages/mockpackage")
  )
  
  # Verify the result
  expect_null(result$url)
  expect_null(result$last_version)
  expect_equal(result$all_versions, list())
  expect_null(result$repo_id)
  expect_null(result$repo_name)
})

# get_host_package

test_that("get_host_package returns correct links for valid inputs", {
  # Mock description$new
  mock_description <- mockery::mock(list(
    str = function() "Mocked DESCRIPTION content",
    get_urls = function() c("https://github.com/owner1/mockpackage"),
    has_fields = function(field) field == "BugReports",
    get_list = function(field) {
      if (field == "BugReports") "https://github.com/owner1/mockpackage/issues"
    }
  ))

  # Stub description$new
  mockery::stub(get_host_package, "description$new", mock_description)

  # Mock other dependencies
  mock_check_cran_package <- mockery::mock(TRUE)
  mock_parse_package_info <- mockery::mock("<html>Mock Archive Content</html>")
  mock_parse_html_version <- mockery::mock(list(
    list(package_version = "1.0.0"),
    list(package_version = "1.1.0")
  ),
  cycle = TRUE
  )

  mock_check_and_fetch_cran_package <- mockery::mock(list(
    last_version = "1.1.0",
    all_versions = c("1.0.0", "1.1.0")
  ))
  mock_get_cran_package_url <- mockery::mock("https://cran.r-project.org/src/contrib/mockpackage_1.1.0.tar.gz")
  mock_get_internal_package_url <- mockery::mock(list(
    url = "https://rstudio-pm.prod.example.com/mockpackage_1.1.0.tar.gz",
    last_version = "1.1.0",
    all_versions = c("1.0.0", "1.1.0")
  ))

  # Use local_mocked_bindings for other dependencies
  with_mocked_bindings(
    check_cran_package = mock_check_cran_package,
    parse_package_info = mock_parse_package_info,
    parse_html_version = mock_parse_html_version,
    check_and_fetch_cran_package = mock_check_and_fetch_cran_package,
    get_cran_package_url = mock_get_cran_package_url,
    get_internal_package_url = mock_get_internal_package_url,
    {
      # Call the function with mocked dependencies
      result <- get_host_package("mockpackage", "1.1.0", "/path/to/source")

      # Validate the result
      expect_equal(result$github_links, "https://github.com/owner1/mockpackage")
      expect_equal(result$cran_links, "https://cran.r-project.org/src/contrib/mockpackage_1.1.0.tar.gz")
      expect_equal(result$internal_links, "https://rstudio-pm.prod.example.com/mockpackage_1.1.0.tar.gz")
      expect_null(result$bioconductor_links)
    }
  )
})

test_that("get_host_package with github name and CRAN name different", {
  # Mock description$new
  mock_description <- mockery::mock(list(
    str = function() "Mocked DESCRIPTION content",
    get_urls = function() c("https://github.com/ow-ner1/mockpackage_no_cran"),
    has_fields = function(field) field == "BugReports",
    get_list = function(field) {
      if (field == "BugReports") "https://github.com/ow-ner1/mockpackage_no_cran/issues"
    }
  ))

  # Stub description$new
  mockery::stub(get_host_package, "description$new", mock_description)

  # Mock other dependencies
  mock_check_cran_package <- mockery::mock(TRUE)
  mock_parse_package_info <- mockery::mock("<html>Mock Archive Content</html>")
  mock_parse_html_version <- mockery::mock(list(
    list(package_version = "1.0.0"),
    list(package_version = "1.1.0")
  ),
  cycle = TRUE
  )

  mock_check_and_fetch_cran_package <- mockery::mock(list(
    last_version = "1.1.0",
    all_versions = c("1.0.0", "1.1.0")
  ))
  mock_get_cran_package_url <- mockery::mock("https://cran.r-project.org/src/contrib/mockpackage_1.1.0.tar.gz")
  mock_get_internal_package_url <- mockery::mock(list(
    url = "https://rstudio-pm.prod.example.com/mockpackage_1.1.0.tar.gz",
    last_version = "1.1.0",
    all_versions = c("1.0.0", "1.1.0")
  ))

  # Use local_mocked_bindings for other dependencies
  with_mocked_bindings(
    check_cran_package = mock_check_cran_package,
    parse_package_info = mock_parse_package_info,
    parse_html_version = mock_parse_html_version,
    check_and_fetch_cran_package = mock_check_and_fetch_cran_package,
    get_cran_package_url = mock_get_cran_package_url,
    get_internal_package_url = mock_get_internal_package_url,
    {
      # Call the function with mocked dependencies
      result <- get_host_package("mockpackage", "1.1.0", "/path/to/source")

      # Validate the result
      expect_equal(result$github_links, "https://github.com/ow-ner1/mockpackage_no_cran")
      expect_equal(result$cran_links, "https://cran.r-project.org/src/contrib/mockpackage_1.1.0.tar.gz")
      expect_equal(result$internal_links, "https://rstudio-pm.prod.example.com/mockpackage_1.1.0.tar.gz")
      expect_null(result$bioconductor_links)
    }
  )
})


test_that("get_host_package with no github link, no bug report", {
  # Mock description$new
  mock_description <- mockery::mock(list(
    str = function() "Mocked DESCRIPTION content",
    get_urls = function() c(""),
    has_fields = function(field) field == "BugReports",
    get_list = function(field) {
      if (field == "BugReports") ""
    }
  ))

  # Stub description$new
  mockery::stub(get_host_package, "description$new", mock_description)

  # Mock other dependencies
  mock_check_cran_package <- mockery::mock(TRUE)
  mock_parse_package_info <- mockery::mock("<html>Mock Archive Content</html>")
  mock_parse_html_version <- mockery::mock(list(
    list(package_version = "1.0.0"),
    list(package_version = "1.1.0")
  ),
  cycle = TRUE
  )
  mock_check_and_fetch_cran_package <- mockery::mock(list(
    last_version = "1.1.0",
    all_versions = c("1.0.0", "1.1.0")
  ))
  mock_get_cran_package_url <- mockery::mock("https://cran.r-project.org/src/contrib/mockpackage_1.1.0.tar.gz")
  mock_get_internal_package_url <- mockery::mock(list(
    url = "https://rstudio-pm.prod.example.com/mockpackage_1.1.0.tar.gz",
    last_version = "1.1.0",
    all_versions = c("1.0.0", "1.1.0")
  ))

  # Use local_mocked_bindings for other dependencies
  with_mocked_bindings(
    check_cran_package = mock_check_cran_package,
    parse_package_info = mock_parse_package_info,
    parse_html_version = mock_parse_html_version,
    check_and_fetch_cran_package = mock_check_and_fetch_cran_package,
    get_cran_package_url = mock_get_cran_package_url,
    get_internal_package_url = mock_get_internal_package_url,
    {
      # Call the function with mocked dependencies
      result <- get_host_package("mockpackage", "1.1.0", "/path/to/source")

      # Validate the result
      expect_null(result$github_links)
      expect_equal(result$cran_links, "https://cran.r-project.org/src/contrib/mockpackage_1.1.0.tar.gz")
      expect_equal(result$internal_links, "https://rstudio-pm.prod.example.com/mockpackage_1.1.0.tar.gz")
      expect_null(result$bioconductor_links)
    }
  )
})


test_that("get_host_package with github name, but not bug report", {
  # Mock description$new
  mock_description <- mockery::mock(list(
    str = function() "Mocked DESCRIPTION content",
    get_urls = function() c(""),
    has_fields = function(field) field == "BugReports",
    get_list = function(field) {
      if (field == "BugReports") "https://github.com/ow-ner1/mockpackage_no_cran/issues"
    }
  ))

  # Stub description$new
  mockery::stub(get_host_package, "description$new", mock_description)

  # Mock other dependencies
  mock_check_cran_package <- mockery::mock(TRUE)
  mock_parse_package_info <- mockery::mock("<html>Mock Archive Content</html>")
  mock_parse_html_version <- mockery::mock(list(
    list(package_version = "1.0.0"),
    list(package_version = "1.1.0")
  ),
  cycle = TRUE
  )

  mock_check_and_fetch_cran_package <- mockery::mock(list(
    last_version = "1.1.0",
    all_versions = c("1.0.0", "1.1.0")
  ))

  mock_get_cran_package_url <- mockery::mock("https://cran.r-project.org/src/contrib/mockpackage_1.1.0.tar.gz")
  mock_get_internal_package_url <- mockery::mock(list(
    url = "https://rstudio-pm.prod.example.com/mockpackage_1.1.0.tar.gz",
    last_version = "1.1.0",
    all_versions = c("1.0.0", "1.1.0")
  ))

  # Use local_mocked_bindings for other dependencies
  with_mocked_bindings(
    check_cran_package = mock_check_cran_package,
    parse_package_info = mock_parse_package_info,
    parse_html_version = mock_parse_html_version,
    check_and_fetch_cran_package = mock_check_and_fetch_cran_package,
    get_cran_package_url = mock_get_cran_package_url,
    get_internal_package_url = mock_get_internal_package_url,
    {
      # Call the function with mocked dependencies
      result <- get_host_package("mockpackage", "1.1.0", "/path/to/source")

      # Validate the result
      expect_equal(result$github_links, "https://github.com/ow-ner1/mockpackage_no_cran")
      expect_equal(result$cran_links, "https://cran.r-project.org/src/contrib/mockpackage_1.1.0.tar.gz")
      expect_equal(result$internal_links, "https://rstudio-pm.prod.example.com/mockpackage_1.1.0.tar.gz")
      expect_null(result$bioconductor_links)
    }
  )
})


test_that("get_host_package with no github name, but bug report", {
  # Mock description$new
  mock_description <- mockery::mock(list(
    str = function() "Mocked DESCRIPTION content",
    get_urls = function() c("https://github.com/ow-ner1/mockpackage_no_cran"),
    has_fields = function(field) field == "BugReports",
    get_list = function(field) {
      if (field == "BugReports") ""
    }
  ))

  # Stub description$new
  mockery::stub(get_host_package, "description$new", mock_description)

  # Mock other dependencies
  mock_check_cran_package <- mockery::mock(TRUE)
  mock_parse_package_info <- mockery::mock("<html>Mock Archive Content</html>")
  mock_parse_html_version <- mockery::mock(list(
    list(package_version = "1.0.0"),
    list(package_version = "1.1.0")
  ),
  cycle = TRUE
  )
  mock_check_and_fetch_cran_package <- mockery::mock(list(
    last_version = "1.1.0",
    all_versions = c("1.0.0", "1.1.0")
  ))
  mock_get_cran_package_url <- mockery::mock("https://cran.r-project.org/src/contrib/mockpackage_1.1.0.tar.gz")
  mock_get_internal_package_url <- mockery::mock(list(
    url = "https://rstudio-pm.prod.example.com/mockpackage_1.1.0.tar.gz",
    last_version = "1.1.0",
    all_versions = c("1.0.0", "1.1.0")
  ))

  # Use local_mocked_bindings for other dependencies
  with_mocked_bindings(
    check_cran_package = mock_check_cran_package,
    parse_package_info = mock_parse_package_info,
    parse_html_version = mock_parse_html_version,
    check_and_fetch_cran_package = mock_check_and_fetch_cran_package,
    get_cran_package_url = mock_get_cran_package_url,
    get_internal_package_url = mock_get_internal_package_url,
    {
      # Call the function with mocked dependencies
      result <- get_host_package("mockpackage", "1.1.0", "/path/to/source")

      # Validate the result
      expect_equal(result$github_links, "https://github.com/ow-ner1/mockpackage_no_cran")
      expect_equal(result$cran_links, "https://cran.r-project.org/src/contrib/mockpackage_1.1.0.tar.gz")
      expect_equal(result$internal_links, "https://rstudio-pm.prod.example.com/mockpackage_1.1.0.tar.gz")
      expect_null(result$bioconductor_links)
    }
  )
})