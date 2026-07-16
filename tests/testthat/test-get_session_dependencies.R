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

test_that("handles NULL attached_pkgs (lines 33-34)", {
  # Test lines 33-34: if (is.null(attached_pkgs)) { attached_pkgs <- list() }
  mock_session_info <- function() {
    list(
      otherPkgs = NULL,
      loadedOnly = list(
        "dplyr" = list(Version = "1.0.7")
      )
    )
  }
  
  deps_list <- data.frame(
    package = c("dplyr"),
    type = c("Imports"),
    stringsAsFactors = FALSE
  )
  
  mockery::stub(get_session_dependencies, "sessionInfo", mock_session_info)
  result <- get_session_dependencies(deps_list)
  
  # dplyr is in loadedOnly, so it should be found
  expect_equal(result$imports, list(dplyr = "1.0.7"))
  expect_length(result$suggests, 0)
})


test_that("handles NULL loaded_pkgs (lines 37-38)", {
  # Test lines 37-38: if (is.null(loaded_pkgs)) { loaded_pkgs <- list() }
  mock_session_info <- function() {
    list(
      otherPkgs = list(
        "ggplot2" = list(Version = "3.3.5")
      ),
      loadedOnly = NULL
    )
  }
  
  deps_list <- data.frame(
    package = c("ggplot2"),
    type = c("Suggests"),
    stringsAsFactors = FALSE
  )
  
  mockery::stub(get_session_dependencies, "sessionInfo", mock_session_info)
  result <- get_session_dependencies(deps_list)
  
  # ggplot2 is in otherPkgs, so it should be found
  expect_equal(result$suggests, list(ggplot2 = "3.3.5"))
  expect_length(result$imports, 0)
})


test_that("handles both NULL attached_pkgs and loaded_pkgs (lines 33-34, 37-38)", {
  # Test both NULL conditions together
  mock_session_info <- function() {
    list(
      otherPkgs = NULL,
      loadedOnly = NULL
    )
  }
  
  deps_list <- data.frame(
    package = c("any_package"),
    type = c("Imports"),
    stringsAsFactors = FALSE
  )
  
  mockery::stub(get_session_dependencies, "sessionInfo", mock_session_info)
  result <- get_session_dependencies(deps_list)
  
  # No packages in session, should return "No package version found"
  expect_equal(result$imports, list(any_package = "No package version found"))
  expect_length(result$suggests, 0)
})


test_that("handles package with missing Version field (lines 45-46)", {
  # Test lines 45-46: else { return("No package version found") }
  # when package is a list but doesn't have $Version
  mock_session_info <- function() {
    list(
      otherPkgs = list(
        "badpkg" = list(Title = "Bad Package"),  # has Title but no Version
        "goodpkg" = list(Version = "1.0.0")
      ),
      loadedOnly = list()
    )
  }
  
  deps_list <- data.frame(
    package = c("badpkg", "goodpkg"),
    type = c("Imports", "Imports"),
    stringsAsFactors = FALSE
  )
  
  mockery::stub(get_session_dependencies, "sessionInfo", mock_session_info)
  result <- get_session_dependencies(deps_list)
  
  expect_equal(result$imports$badpkg, "No package version found")
  expect_equal(result$imports$goodpkg, "1.0.0")
})


test_that("handles non-list package entry in sapply (lines 45-46)", {
  # Test lines 45-46 when package is not a list
  mock_session_info <- function() {
    list(
      otherPkgs = list(
        "stringpkg" = "1.2.3",  # This is a string, not a list
        "listpkg" = list(Version = "2.0.0")
      ),
      loadedOnly = list()
    )
  }
  
  deps_list <- data.frame(
    package = c("stringpkg", "listpkg"),
    type = c("Suggests", "Suggests"),
    stringsAsFactors = FALSE
  )
  
  mockery::stub(get_session_dependencies, "sessionInfo", mock_session_info)
  result <- get_session_dependencies(deps_list)
  
  # stringpkg is not a list, so should return "No package version found"
  expect_equal(result$suggests$stringpkg, "No package version found")
  expect_equal(result$suggests$listpkg, "2.0.0")
})


test_that("handles NULL package Version field in sapply (lines 45-46)", {
  # Test lines 45-46 when package$Version is explicitly NULL
  mock_session_info <- function() {
    list(
      otherPkgs = list(
        "nullverpkg" = list(Version = NULL),
        "validpkg" = list(Version = "3.1.0")
      ),
      loadedOnly = list()
    )
  }
  
  deps_list <- data.frame(
    package = c("nullverpkg", "validpkg"),
    type = c("Imports", "Imports"),
    stringsAsFactors = FALSE
  )
  
  mockery::stub(get_session_dependencies, "sessionInfo", mock_session_info)
  result <- get_session_dependencies(deps_list)
  
  # nullverpkg has Version = NULL, condition !is.null(pkg$Version) is FALSE
  expect_equal(result$imports$nullverpkg, "No package version found")
  expect_equal(result$imports$validpkg, "3.1.0")
})


test_that("handles all packages from loadedOnly when attached_pkgs is NULL (lines 33-34, 37-38)", {
  # Integration test: NULL attached_pkgs combines with loadedOnly packages
  mock_session_info <- function() {
    list(
      otherPkgs = NULL,
      loadedOnly = list(
        "data.table" = list(Version = "1.14.0"),
        "tidyr" = list(Version = "1.1.3")
      )
    )
  }
  
  deps_list <- data.frame(
    package = c("data.table", "tidyr"),
    type = c("Imports", "Suggests"),
    stringsAsFactors = FALSE
  )
  
  mockery::stub(get_session_dependencies, "sessionInfo", mock_session_info)
  result <- get_session_dependencies(deps_list)
  
  expect_equal(result$imports, list("data.table" = "1.14.0"))
  expect_equal(result$suggests, list("tidyr" = "1.1.3"))
})


test_that("handles mixed valid and invalid packages in sapply (lines 45-46)", {
  # Complex scenario with multiple package states
  mock_session_info <- function() {
    list(
      otherPkgs = list(
        "valid1" = list(Version = "1.0.0"),
        "noversion" = list(Title = "No Version"),
        "nonlist" = "2.0.0",
        "nullversion" = list(Version = NULL),
        "valid2" = list(Version = "3.0.0")
      ),
      loadedOnly = list()
    )
  }
  
  deps_list <- data.frame(
    package = c("valid1", "noversion", "nonlist", "nullversion", "valid2"),
    type = c("Imports", "Imports", "Imports", "Imports", "Suggests"),
    stringsAsFactors = FALSE
  )
  
  mockery::stub(get_session_dependencies, "sessionInfo", mock_session_info)
  result <- get_session_dependencies(deps_list)
  
  expect_equal(result$imports$valid1, "1.0.0")
  expect_equal(result$imports$noversion, "No package version found")
  expect_equal(result$imports$nonlist, "No package version found")
  expect_equal(result$imports$nullversion, "No package version found")
  expect_equal(result$suggests$valid2, "3.0.0")
})
