# Mock function to simulate get_toplevel_assignments
mock_get_toplevel_assignments <- function(pkg_source_path) {
  data.frame(
    func = c("func1", "func2"),
    code_script = c("script1.R", NA),
    stringsAsFactors = FALSE
  )
}

test_that("map_functions_to_scripts handles missing code_script correctly", {
  # Mock the get_toplevel_assignments function
  with_mocked_bindings(
    get_toplevel_assignments = mock_get_toplevel_assignments,
    {
      # Create a sample exports_df
      exports_df <- data.frame(
        exported_function = c("func1", "func2"),
        class = c(NA, NA),
        stringsAsFactors = FALSE
      )
      
      # Capture the messages
      messages <- capture_messages(
        result <- map_functions_to_scripts(exports_df, "dummy_path", verbose = TRUE)
      )
      
      # Check that the expected message is present
      expect_true(any(grepl("The following exports were not found in R/ for dummy_path", messages)))
      
      # Check that the result has NA in code_script for func2
      expect_true(any(is.na(result$code_script)))
    }
  )
})


