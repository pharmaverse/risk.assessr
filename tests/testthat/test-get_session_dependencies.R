test_that("get_session_dependencies correctly processes both Imports and Suggests", {
  mock_session_info <- function() {
    list(
      otherPkgs = list(
        "callr" = list(Version = "3.5.1"),
        "checkmate" = list(Version = "2.0.0"),
        "covr" = list(Version = "3.6.1"),
        "testthat" = list(Version = "3.0.0")
      ),
      loadedOnly = list(
        "knitr" = list(Version = "1.31")
      )
    )
  }
  
  deps_list <- data.frame(
    package = c("callr", "checkmate", "covr", "testthat", "knitr"),
    type = c("Imports", "Imports", "Imports", "Suggests", "Suggests"),
    stringsAsFactors = FALSE
  )
  
  with_mocked_bindings(
    sessionInfo = mock_session_info,
    {
      result <- get_session_dependencies(deps_list)
      expect_equal(result$imports, list(callr = "3.5.1", checkmate = "2.0.0", covr = "3.6.1"))
      expect_equal(result$suggests, list(testthat = "3.0.0", knitr = "1.31"))
    }
  )
})

test_that("get_session_dependencies works when only Imports are provided", {
  mock_session_info <- function() {
    list(
      otherPkgs = list(
        "callr" = list(Version = "3.5.1"),
        "checkmate" = list(Version = "2.0.0"),
        "covr" = list(Version = "3.6.1")
      ),
      loadedOnly = list()
    )
  }
  
  deps_list <- data.frame(
    package = c("callr", "checkmate", "covr"),
    type = c("Imports", "Imports", "Imports"),
    stringsAsFactors = FALSE
  )
  
  with_mocked_bindings(
    sessionInfo = mock_session_info,
    {
      result <- get_session_dependencies(deps_list)
      
      expect_equal(result$imports, list(callr = "3.5.1", checkmate = "2.0.0", covr = "3.6.1"))
      expect_length(result$suggests, 0) 
    }
  )
})

test_that("get_session_dependencies works when only Suggests are provided", {
  mock_session_info <- function() {
    list(
      otherPkgs = list(
        "testthat" = list(Version = "3.0.0"),
        "knitr" = list(Version = "1.31")
      ),
      loadedOnly = list()
    )
  }
  
  deps_list <- data.frame(
    package = c("testthat", "knitr"),
    type = c("Suggests", "Suggests"),
    stringsAsFactors = FALSE
  )
  
  with_mocked_bindings(
    sessionInfo = mock_session_info,
    {
      result <- get_session_dependencies(deps_list)
      
      expect_length(result$imports, 0) 
      expect_equal(result$suggests, list(testthat = "3.0.0", knitr = "1.31"))
    }
  )
})


test_that("get_session_dependencies handles empty deps_list gracefully", {
  mock_session_info <- function() {
    list(
      otherPkgs = list(
        "callr" = list(Version = "3.5.1")
      ),
      loadedOnly = list()
    )
  }
  
  deps_list <- data.frame(
    package = character(0),
    type = character(0),
    stringsAsFactors = FALSE
  )
  
  with_mocked_bindings(
    sessionInfo = mock_session_info,
    {
      result <- get_session_dependencies(deps_list)
      expect_length(result$imports, 0) 
      expect_length(result$suggests, 0)
    }
  )
})

test_that("get_session_dependencies handles missing package from session info with descriptive 'None'", {
  mock_session_info <- function() {
    list(
      otherPkgs = list(
        "callr" = list(Version = "3.5.1")
      ),
      loadedOnly = list()
    )
  }
  
  deps_list <- data.frame(
    package = c("callr", "nonexistentPkg"),
    type = c("Imports", "Imports"),
    stringsAsFactors = FALSE
  )
  
  with_mocked_bindings(
    sessionInfo = mock_session_info,
    {
      result <- get_session_dependencies(deps_list)
      
      expect_equal(result$imports, list(callr = "3.5.1", nonexistentPkg = "No package version found"))
    }
  )
})
