# get_pubmed_count

test_that("get_pubmed_count returns mocked value correctly", {
  fake_json_text <- '{"esearchresult":{"count":"1234"}}'
  mockery::stub(get_pubmed_count, "readLines", function(...) fake_json_text)

  count <- get_pubmed_count("mocked_package")
  expect_equal(count, 1234)
})

test_that("get_pubmed_count handles nonexistent package (returns 0)", {
  fake_json_text <- '{"esearchresult":{"count":"0"}}'
  mockery::stub(get_pubmed_count, "readLines", function(...) fake_json_text)

  count <- get_pubmed_count("nonsensepackagename123456")
  expect_equal(count, 0)
})

test_that("get_pubmed_count handles API failure (returns NA)", {
  mockery::stub(get_pubmed_count, "curl", function(...) stop("Network error"))
  
  count <- get_pubmed_count("ggplot2")
  expect_true(is.na(count))
})

test_that("get_pubmed_count returns NA on network failure", {
  mockery::stub(get_pubmed_count, "readLines", function(...) stop("Network error"))
  
  result <- get_pubmed_count("ggplot2")
  expect_true(is.na(result))
})

test_that("get_pubmed_count returns 0 when no articles are found", {
  json_zero <- '{"esearchresult":{"count":"0"}}'
  mockery::stub(get_pubmed_count, "readLines", function(...) json_zero)
  
  result <- get_pubmed_count("nonsensepackagename")
  expect_equal(result, 0)
})

test_that("get_pubmed_count returns NA and shows message when JSON parsing fails", {
  # Mock readLines to return invalid JSON
  mockery::stub(get_pubmed_count, "readLines", function(...) "invalid_json")
  
  # Mock curl and close to suppress side effects
  mockery::stub(get_pubmed_count, "curl", function(...) "fake_con")
  mockery::stub(get_pubmed_count, "close", function(...) NULL)
  mockery::stub(get_pubmed_count, "new_handle", function(...) NULL)
  
  expect_message(
    count <- get_pubmed_count("fakepkg"),
    "No articles found on pubmed for fakepkg"
  )
  expect_true(is.na(count))
})





# get_pubmed_by_year

test_that("get_pubmed_by_year returns mocked counts by year", {
  fake_xml <- xml2::read_xml('<?xml version="1.0"?><eSearchResult><Count>42</Count></eSearchResult>')
  
  mockery::stub(get_pubmed_by_year, "xml2::read_xml", function(...) fake_xml)
  df <- get_pubmed_by_year("mocked_package", years_back = 2)
  
  expect_s3_class(df, "data.frame")
  expect_named(df, c("Year", "Count"))
  expect_equal(nrow(df), 3)  # current year and 2 previous
  expect_true(all(df$Count == 42))
})

test_that("get_pubmed_by_year returns zero counts when no articles found", {
  fake_xml <- xml2::read_xml('<?xml version="1.0"?><eSearchResult><Count>0</Count></eSearchResult>')
  
  mockery::stub(get_pubmed_by_year, "xml2::read_xml", function(...) fake_xml)
  df <- get_pubmed_by_year("nonsensepackagename123456", years_back = 1)
  
  expect_s3_class(df, "data.frame")
  expect_named(df, c("Year", "Count"))
  expect_equal(nrow(df), 2)
  expect_true(all(df$Count == 0))
})

test_that("get_pubmed_by_year handles API failure safely", {
  mockery::stub(get_pubmed_by_year, "xml2::read_xml", function(...) stop("Simulated API failure"))
  
  df <- get_pubmed_by_year("ggplot2", years_back = 2)
  
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 0)
  expect_named(df, c("Year", "Count"))
})




