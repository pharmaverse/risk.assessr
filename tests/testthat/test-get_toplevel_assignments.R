test_that("get_toplevel_assignments works correctly", {
  # Mock the tools::list_files_with_type function
  mock_list_files_with_type <- function(path, type) {
    if (path == "dummy_path/R") {
      return(c("file1.R", "file2.R"))
    }
    return(character(0))
  }
  
  # Mock the parse function
  mock_parse <- function(file) {
    if (file == "file1.R") {
      return(parse(text = "func1 <- function() {}"))
    } else if (file == "file2.R") {
      return(parse(text = "func2 <- function() {}"))
    }
    stop("Unexpected file")
  }
  
  # Mock the fs::path_rel function
  mock_path_rel <- function(path, start) {
    return(basename(path))
  }
  
  pkg_name <- "dummy_path"
  
  # Use mockery to stub the functions
  mockery::stub(get_toplevel_assignments, "tools::list_files_with_type", mock_list_files_with_type)
  mockery::stub(get_toplevel_assignments, "parse", mock_parse)
  mockery::stub(get_toplevel_assignments, "fs::path_rel", mock_path_rel)
  
  # Test case: Normal scenario
  result <- get_toplevel_assignments(pkg_name)
  expect_equal(result$func, c("func1", "func2"))
  expect_equal(result$code_script, c("file1.R", "file2.R"))
  
  # Test case: No R files found
  mock_list_files_with_type_empty <- function(path, type) {
    return(character(0))
  }
  
  mockery::stub(get_toplevel_assignments, "tools::list_files_with_type", mock_list_files_with_type_empty)
  
  messages <- capture_messages(result <- get_toplevel_assignments(pkg_name))
  expect_true(any(grepl(glue::glue("No sourceable R scripts were found in the R/ directory for package {pkg_name}. Make sure this was expected."), messages)))
  expect_equal(nrow(result), 0)
})



