# Test cases
test_that("check_suggested_exp_funcs returns matches correctly", {
  result <- risk.assessr::get_suggested_exp_funcs(deps_df)
  
  testthat::expect_true(checkmate::check_class(result, "data.frame"))
  
  testthat::expect_identical(length(result), 3L)

  expect_gte(nrow(result), 0L)

  expect_true(checkmate::check_character(result$package, 
                                       any.missing = TRUE)
  )
  
  expect_true(checkmate::check_character(result$functions, 
                                         any.missing = TRUE)
  )
  
  expect_true(checkmate::check_character(result$descriptions, 
                                         any.missing = TRUE)
  )
  
})

# test data for get_suggested_exp_funcs handles no suggested packages
test_that("handles no suggested packages", {
  no_suggests_df <- deps_df[deps_df$type != "Suggests", ]
  result <- risk.assessr::get_suggested_exp_funcs(no_suggests_df)
  expect_equal(nrow(result), 0)
  # Function to test if each column has no values
  test_no_values <- function(df) {
    sapply(df, function(column) all(is.na(column)))
  }
  
  no_values_test <- test_no_values(result)
  
  expect_true(all(no_values_test))
})

# Test cases
test_that("Function works with valid dataset", {
  result <- get_suggested_exp_funcs(deps_df)
  expect_true(nrow(result) > 0)
})

test_that("Function handles empty dataset", {
  empty_df <- data.frame(package = character(), type = character())
  expect_error(
    get_suggested_exp_funcs(empty_df),
    "Assertion on 'data' failed: Must have at least 1 rows, but has 0 rows."
  )
})

# Mock function to simulate getNamespaceExports
mock_getNamespaceExports <- function(pkg) {
  if (pkg == "pkgA") {
    return(character(0))  # Simulate no exported functions
  } else if (pkg == "pkgB") {
    return(c("func1", "func2"))  # Simulate exported functions
  } 
}

# Replace getNamespaceExports with the mock function
mockery::stub(get_suggested_exp_funcs, "getNamespaceExports", mock_getNamespaceExports)


# Mock function to simulate getNamespaceExports
mock_getNamespaceExports <- function(pkg) {
  if (pkg == "pkgC") {
    stop("Error in getting exports")  # Simulate an error
  }
}

# Replace getNamespaceExports with the mock function
mockery::stub(get_suggested_exp_funcs, "getNamespaceExports", mock_getNamespaceExports)

# Test case for no exported functions
test_that("get_suggested_exp_funcs handles no exported functions correctly", {
  data <- data.frame(
    package = c("pkgC"),
    type = c("Suggests"),
    stringsAsFactors = FALSE
  )
  
  result <- get_suggested_exp_funcs(data)
  
  # Define the expected messages
  expected_pkg_messages <- c(
    "pkgC"
  )
  
  expect_true(any(grepl("Error in getting exports", result$functions)))
})


# Mock function to simulate getNamespaceExports
mock_getNamespaceExports <- function(pkg) {
  if (pkg == "pkgB") {
    return(c("func1", "func2"))  # Simulate exported functions
  }
  stop("Unexpected package")
}

# Replace getNamespaceExports with the mock function
mockery::stub(get_suggested_exp_funcs, "getNamespaceExports", mock_getNamespaceExports)


# Test case for exported functions
test_that("get_suggested_exp_funcs handles exported functions correctly", {
  data <- data.frame(
    package = c("pkgB"),
    type = c("Suggests")
  )
  
  result <- get_suggested_exp_funcs(data)
  
  # Define the expected package messages
  expected_pkg_messages <- c(
    "pkgB",
    "pkgB",
    NA
  )
  
  # Loop through result$exported_functions and check for package messages
  for (i in seq_along(result$package)) {
    if (is.na(expected_pkg_messages[i])) {
      expect_true(is.na(result$package[[i]]))
    } else {
      expect_true(any(grepl(expected_pkg_messages[i], result$package[[i]])))
    }
  }
  
  # Define the expected function messages
  expected_func_messages <- c(
    "func1",
    "func2",
    NA
  )
  
  # Loop through result$exported_functions and check for function messages
  for (i in seq_along(result$exported_functions)) {
    if (is.na(expected_func_messages[i])) {
      expect_true(is.na(result$functions[[i]]))
    } else {
      expect_true(any(grepl(expected_func_messages[i], result$functions[[i]])))
    }
  }
})

test_that("get_suggested_exp_funcs handles empty input data frame", {
  # Mock data for empty input data frame
  data <- data.frame(package = character(), type = character(), stringsAsFactors = FALSE)
  
  # Mock the checkmate::assert_data_frame function to pass the check
  mock_assert_data_frame <- mockery::mock(TRUE, cycle = TRUE)
  mockery::stub(get_suggested_exp_funcs, "checkmate::assert_data_frame", mock_assert_data_frame)
  
  # Call the actual function
  result_df <- get_suggested_exp_funcs(data)
  
  # Construct the expected result
  expected <- data.frame(
    package = character(),
    functions = character(),
    descriptions = character(),
    stringsAsFactors = FALSE
  )
  
  # Check the results
  expect_equal(result_df, expected)
})  