# CRAN

test_that("get_package_download_cran works with mocked API response", {
  # Mocked API JSON response as character vector (like from readLines)
  mock_json <- jsonlite::toJSON(list(
    downloads = list(
      list(day = "2024-04-22", downloads = 5000),
      list(day = "2024-04-21", downloads = 6000),
      list(day = "2024-04-20", downloads = 7000)
    )
  ), auto_unbox = TRUE)
  
  
  # Mock readLines to return fake API response
  mock_read_lines <- function(...) unlist(strsplit(mock_json, "\n"))
  
  # Mock Sys.Date to freeze the date
  mock_sys_date <- function() as.Date("2024-04-23")
  
  # Mock curl connection object (not used but needs to exist)
  mock_curl <- function(...) "fake_con"
  
  # Stub dependencies
  mockery::stub(get_package_download_cran, "readLines", mock_read_lines)
  mockery::stub(get_package_download_cran, "Sys.Date", mock_sys_date)
  mockery::stub(get_package_download_cran, "curl::curl", mock_curl)
  mockery::stub(get_package_download_cran, "close", function(x) NULL)
  
  # Run function
  result <- get_package_download_cran("ggplot2")
  
  # Check structure and content
  expect_type(result, "list")
  expect_s3_class(result, "data.frame")
  expect_named(result, c("date", "count", "cumulative_downloads"))
  expect_equal(nrow(result), 3)
  expect_equal(result$count, c(5000, 6000, 7000))
  expect_equal(result$cumulative_downloads, cumsum(c(5000, 6000, 7000)))
})

test_that("get_package_download_cran handles empty API response", {
  # Mock response with empty downloads
  mock_json <- jsonlite::toJSON(list(downloads = list()), auto_unbox = TRUE)
  mock_read_lines <- function(...) unlist(strsplit(mock_json, "\n"))
  mock_sys_date <- function() as.Date("2024-04-23")
  mock_curl <- function(...) "fake_con"
  
  mockery::stub(get_package_download_cran, "readLines", mock_read_lines)
  mockery::stub(get_package_download_cran, "Sys.Date", mock_sys_date)
  mockery::stub(get_package_download_cran, "curl::curl", mock_curl)
  mockery::stub(get_package_download_cran, "close", function(x) NULL)
  
  result <- get_package_download_cran("ggplot2")
  expect_null(result)
})

test_that("get_package_download_cran handles API error gracefully", {
  # Mock readLines to simulate an error
  mock_read_lines <- function(...) stop("Simulated API error")
  mock_sys_date <- function() as.Date("2024-04-23")
  mock_curl <- function(...) "fake_con"
  
  mockery::stub(get_package_download_cran, "readLines", mock_read_lines)
  mockery::stub(get_package_download_cran, "Sys.Date", mock_sys_date)
  mockery::stub(get_package_download_cran, "curl::curl", mock_curl)
  mockery::stub(get_package_download_cran, "close", function(x) NULL)
  
  result <- get_package_download_cran("ggplot2")
  expect_null(result)
})

test_that("get_package_download_cran fails when no package name is given", {
  expect_error(get_package_download_cran(), "Please provide a package name.")
})

test_that("Returns null when no downloads exist", {

  mock_json <- jsonlite::toJSON(list(
    downloads = list(
      list(downloads = NA, start = "2025-03-01", end = "2025-03-31", package = "nonexistent8package")
    )
  ), auto_unbox = TRUE)
  
  # Mock functions
  mock_read_lines <- function(...) unlist(strsplit(mock_json, "\n"))
  mock_sys_date <- function() as.Date("2025-03-31")
  mock_curl <- function(...) tempfile() 
  
  mockery::stub(get_package_download_cran, "readLines", mock_read_lines)
  mockery::stub(get_package_download_cran, "Sys.Date", mock_sys_date)
  mockery::stub(get_package_download_cran, "curl::curl", mock_curl)
  
  # Run the function and test the result
  result <- get_package_download_cran("nonexistent8package", years = 1)
  expect_null(result)
})

build_mock_response <- function(days, counts) {
  list(
    downloads = list(
      data.frame(
        day = days,
        downloads = counts,
        stringsAsFactors = FALSE
      )
    ),
    start = if (length(days) > 0) min(days) else NA_character_,
    end   = if (length(days) > 0) max(days) else NA_character_,
    package = "package"
  )
}

test_that("get_cran_total_downloads returns correct total for last 6 full months", {
  mock_data <- build_mock_response(
    days = c("2024-01-01", "2024-02-01", "2024-03-01", "2024-04-01", "2024-05-01", "2024-06-01"),
    counts = c(1000, 2000, 3000, 4000, 5000, 6000)
  )
  
  mock_json <- jsonlite::toJSON(mock_data, auto_unbox = TRUE)
  mock_read_lines <- function(...) mock_json
  mock_sys_date <- function() as.Date("2024-07-15")
  mock_curl <- function(...) "fake_con"
  
  mockery::stub(get_cran_total_downloads, "readLines", mock_read_lines)
  mockery::stub(get_cran_total_downloads, "Sys.Date", mock_sys_date)
  mockery::stub(get_cran_total_downloads, "curl::curl", mock_curl)
  mockery::stub(get_cran_total_downloads, "close", function(x) NULL)
  
  total <- get_cran_total_downloads("package", months = 6)
  expect_equal(total, 21000)
})


test_that("get_cran_total_downloads handles fewer than 6 months of data", {
  mock_data <- build_mock_response(
    days = c("2024-04-01", "2024-05-01"),
    counts = c(4000, 5000)
  )
  
  mock_json <- jsonlite::toJSON(mock_data, auto_unbox = TRUE)
  mock_read_lines <- function(...) mock_json
  mock_sys_date <- function() as.Date("2024-07-15")
  mock_curl <- function(...) "fake_con"
  
  mockery::stub(get_cran_total_downloads, "readLines", mock_read_lines)
  mockery::stub(get_cran_total_downloads, "Sys.Date", mock_sys_date)
  mockery::stub(get_cran_total_downloads, "curl::curl", mock_curl)
  mockery::stub(get_cran_total_downloads, "close", function(x) NULL)
  
  total <- get_cran_total_downloads("package", months = 6)
  expect_equal(total, 9000)
})


test_that("get_cran_total_downloads handles empty API response", {
  mock_data <- build_mock_response(
    days = character(0),
    counts = integer(0)
  )
  
  mock_json <- jsonlite::toJSON(mock_data, auto_unbox = TRUE)
  mock_read_lines <- function(...) mock_json
  mock_sys_date <- function() as.Date("2024-07-15")
  mock_curl <- function(...) "fake_con"
  
  mockery::stub(get_cran_total_downloads, "readLines", mock_read_lines)
  mockery::stub(get_cran_total_downloads, "Sys.Date", mock_sys_date)
  mockery::stub(get_cran_total_downloads, "curl::curl", mock_curl)
  mockery::stub(get_cran_total_downloads, "close", function(x) NULL)
  
  total <- get_cran_total_downloads("package", months = 6)
  expect_equal(total, 0)
})

test_that("get_cran_total_downloads handles API error gracefully", {
  mock_read_lines <- function(...) stop("Simulated API error")
  mock_sys_date <- function() as.Date("2024-07-15")
  mock_curl <- function(...) "fake_con"

  mockery::stub(get_cran_total_downloads, "readLines", mock_read_lines)
  mockery::stub(get_cran_total_downloads, "Sys.Date", mock_sys_date)
  mockery::stub(get_cran_total_downloads, "curl::curl", mock_curl)
  mockery::stub(get_cran_total_downloads, "close", function(x) NULL)

  expect_message(get_cran_total_downloads("package", months = 6), "URL not available")
})

test_that("get_cran_total_downloads handles URL unavailability", {

  mock_read_lines <- function(...) stop("Simulated connection error")
  mock_sys_date <- function() as.Date("2024-07-15")
  mock_curl <- function(...) "fake_con"
  mock_close <- function(x) NULL

  # Stub dependencies
  mockery::stub(get_cran_total_downloads, "readLines", mock_read_lines)
  mockery::stub(get_cran_total_downloads, "Sys.Date", mock_sys_date)
  mockery::stub(get_cran_total_downloads, "curl::curl", mock_curl)
  mockery::stub(get_cran_total_downloads, "close", mock_close)

  expect_message(
    result <- get_cran_total_downloads("fake245", months = 3),
    "URL not available"
  )
  expect_null(result)
})

test_that("get_cran_total_downloads throws on invalid months param", {
  expect_message(get_cran_total_downloads("package", months = -1), "months must be a positive integer")
  expect_message(get_cran_total_downloads("package", months = "six"), "months must be a positive integer")
})

# Bioconductor

test_that("get_package_download_bioconductor works with mocked read.table and date", {
  # Mock data frame with predictable months
  mock_data <- data.frame(
    Year = c(2023, 2023, 2023, 2024, 2024, 2024),
    Month = c("Oct", "Nov", "Dec", "Jan", "Feb", "Mar"),
    Nb_of_distinct_IPs = c(100, 200, 300, 400, 500, 600),
    Nb_of_downloads = c(1000, 2000, 3000, 4000, 5000, 6000) # sum 21 000
  )
  
  # Mock read.table() to return mock_data
  mock_read_table <- function(...) mock_data
  
  # Mock Sys.Date() to return a fixed date (e.g., 2024-04-15)
  mock_sys_date <- function() as.Date("2024-04-15")
  
  # Stub both functions inside get_package_download_bioconductor
  
  mockery::stub(get_package_download_bioconductor, "read.table", mock_read_table)
  mockery::stub(get_package_download_bioconductor, "Sys.Date", mock_sys_date)
  
  # Run the function
  result <- get_package_download_bioconductor("bio_package")
  
  # Check result
  expect_type(result, "list")
  expect_s3_class(result$all_data, "data.frame")
  expect_equal(nrow(result$all_data), 6)
  expected_months <- c("Oct", "Nov", "Dec", "Jan", "Feb", "Mar")
  expect_equal(format(result$all_data$Date, "%b"), expected_months)
  expect_equal(result$total_download, 21000)
  # Only the last 6 full months before April 2024: Oct 2023 to Mar 2024
  expect_equal(result$total_6_months, 21000)
})

test_that("get_package_download_bioconductor handles read.table error gracefully", {
  
  # Mock read.table to throw an error
  mock_read_table_error <- function(...) stop("Simulated download error")
  
  mockery::stub(get_package_download_bioconductor, "read.table", mock_read_table_error)
  result <- get_package_download_bioconductor("FakePackage123")

  expect_message(get_package_download_bioconductor("FakePackage123"), "could not fetch download data for package: FakePackage123")
  expect_message(get_package_download_bioconductor("FakePackage123"), "No download data found for package: FakePackage123")
  
  expect_null(result$all_data)
  expect_null(result$total_6_months)
  expect_null(result$total_download)
})

test_that("get_package_download_bioconductor handles empty download table", {
  # Mock read.table to return empty data
  mock_read_table_empty <- function(...) {
    data.frame(Year = numeric(0), Month = character(0), 
               Nb_of_distinct_IPs = numeric(0), Nb_of_downloads = numeric(0))
  }
  
  mockery::stub(get_package_download_bioconductor, "read.table", mock_read_table_empty)
  result <- get_package_download_bioconductor("EmptyDataPkg")
  expect_message(get_package_download_bioconductor("EmptyDataPkg"), "No download data found for package: EmptyDataPkg")
  
  expect_null(result$all_data)
  expect_null(result$total_download)
  expect_null(result$total_6_months)
})

test_that("get_package_download_bioconductor handles <6 months", {
  # Mock a small data frame (only 3 full months before April 2024)
  mock_data <- data.frame(
    Year = c(2024, 2024, 2024),
    Month = c("Jan", "Feb", "Mar"),
    Nb_of_distinct_IPs = c(100, 200, 300),
    Nb_of_downloads = c(1000, 2000, 3000) # sum 6000
  )
  
  # Mock read.table to return this partial data
  mock_read_table <- function(...) mock_data
  
  # Mock Sys.Date to simulate it's currently April 2024
  mock_sys_date <- function() as.Date("2024-04-15")
  
  # Patch both inside the function
  mockery::stub(get_package_download_bioconductor, "read.table", mock_read_table)
  mockery::stub(get_package_download_bioconductor, "Sys.Date", mock_sys_date)
  
  # Run function
  result <- get_package_download_bioconductor("NewPkg")
  
  # Expect all 3 rows returned
  expect_equal(nrow(result$all_data), 3)
  expect_equal(result$total_download, 6000)
  expect_equal(result$total_6_months, 6000)

  # Dates are correctly parsed
  expect_false(any(is.na(result$all_data$Date)))
})

test_that("get_package_download_bioconductor works with mocked read.table and date and excluded cuttent month", {
  # Mock data frame with predictable months
  mock_data <- data.frame(
    Year = c(2023, 2023, 2023, 2024, 2024, 2024, 2024, 2024, 2024),
    Month = c("Oct", "Nov", "Dec", "Jan", "Feb", "Mar", "Apr", "May", "Jun"),
    Nb_of_distinct_IPs = c(100, 200, 300, 400, 500, 600, 650, 700, 0),
    Nb_of_downloads = c(1000, 2000, 3000, 4000, 5000, 6111, 6500, 7000, 0) # sum 42111
  )
  
  # Mock read.table() to return mock_data
  mock_read_table <- function(...) mock_data
  
  # Mock Sys.Date() to return a fixed date (e.g., 2024-04-15)
  mock_sys_date <- function() as.Date("2024-06-15") # Jun
  
  # Stub both functions inside get_package_download_bioconductor
  
  mockery::stub(get_package_download_bioconductor, "read.table", mock_read_table)
  mockery::stub(get_package_download_bioconductor, "Sys.Date", mock_sys_date)
  
  # Run the function
  result <- get_package_download_bioconductor("bio_package")
  
  # Check result
  expect_type(result, "list")
  expect_s3_class(result$all_data, "data.frame")
  expect_equal(nrow(result$all_data), 8)
  expect_equal(result$total_download, 34611)
  
  # Only the last 6 full months before April 2024: Oct 2023 to Mar 2024
  expect_equal(result$total_6_months, 31611)
})

test_that("get_package_download_bioconductor works with excluded future months", {
  # Mock data frame with predictable months
  mock_data <- data.frame(
    Year = c(2023, 2023, 2023, 2024, 2024, 2024, 2024, 2024, 2024),
    Month = c("Oct", "Nov", "Dec", "Jan", "Feb", "Mar", "Apr", "May", "Jun"),
    Nb_of_distinct_IPs = c(100, 200, 0, 0, 0, 0, 0, 0, 0),
    Nb_of_downloads = c(101, 200, 0, 0, 0, 0, 0, 0, 0)
  )

  # Mock read.table() to return mock_data
  mock_read_table <- function(...) mock_data

  # Mock Sys.Date() to return a fixed date (e.g., 2024-04-15)
  mock_sys_date <- function() as.Date("2023-12-15")

  # Stub both functions inside get_package_download_bioconductor

  mockery::stub(get_package_download_bioconductor, "read.table", mock_read_table)
  mockery::stub(get_package_download_bioconductor, "Sys.Date", mock_sys_date)

  # Run the function
  result <- get_package_download_bioconductor("bio_package")

  # Check result
  expect_type(result, "list")
  expect_s3_class(result$all_data, "data.frame")
  expect_equal(nrow(result$all_data), 2)
  expect_equal(result$total_download, 301)

  # Only the last 6 full months before April 2024: Oct 2023 to Mar 2024
  expect_equal(result$total_6_months, 301)
})

test_that("get_package_download_cran fails when no package name is given", {
  expect_error(get_package_download_bioconductor(), "Please provide a bioconductor package name.")
})






