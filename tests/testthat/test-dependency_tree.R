
# is_base

test_that("get_package_version returns correct version or Unknown", {
  expect_true(is_base("utils"))
  expect_true(is_base("methods"))
  expect_false(is_base("ggplot2"))
  expect_false(is_base("stringr"))
  expect_false(is_base("xxxxx"))
})


# parse_dcf_dependencies_version

test_that("parse_dcf_dependencies_version extracts dependencies correctly", {
  
  # Create a temporary DESCRIPTION file
  temp_dir <- tempdir()
  desc_path <- file.path(temp_dir, "DESCRIPTION")
  
  # Write sample dependencies
  writeLines(c(
    "Package: testpkg",
    "Version: 1.0.0",
    "Imports: ggplot2, dplyr, tidyr"
  ), desc_path)
  
  deps <- parse_dcf_dependencies_version(temp_dir)
  
  # Expected result
  expected <- data.frame(
    package = c("ggplot2", "dplyr", "tidyr"),
    type = rep("Imports", 3),
    stringsAsFactors = FALSE
  )
  
  expect_equal(deps, expected)
})


# ADD case with no depend package




# build_dependency_tree

# Mock
mock_parse_dcf_dependencies <- function(path) {
  data.frame(
    package = c("ggplot2", "dplyr"),
    type = c("Imports", "Imports"),
    stringsAsFactors = FALSE
  )
}

# download_and_parse_dependencies function

# Mock
mock_parse_dcf_dependencies <- function(path) {
  data.frame(
    package = c("ggplot2", "dplyr"),
    type = c("Imports", "Imports"),
    stringsAsFactors = FALSE
  )
}

test_that("download_and_parse_dependencies 2 Imports package", {
  
  # Create a temporary directory for testing
  temp_dir <- tempdir()
  package_name <- "testpkg"
  version <- "1.0.0"
  
  # Create a correctly structured package directory (inside temp_dir)
  package_root <- file.path(temp_dir, paste0(package_name, "_", version))  
  dir.create(package_root, recursive = TRUE)
  
  # Create DESCRIPTION file inside the correct package structure
  desc_path <- file.path(package_root, "DESCRIPTION")
  writeLines(c(
    "Package: testpkg",
    "Version: 1.0.0",
    "Imports: ggplot2, dplyr"
  ), desc_path)
  
  # Create a tarball with the correct structure
  tarball_path <- file.path(temp_dir, paste0(package_name, "_", version, ".tar.gz"))
  
  old_wd <- getwd()  # Save working directory
  setwd(temp_dir)  # Move to temp_dir for tar creation
  tar(tarball_path, files = basename(package_root), compression = "gzip", tar = "internal")
  setwd(old_wd)  # Restore working directory
  
  # Mock remotes::download_version to return the correct tarball path
  mock_download_version <- function(package, version, repos) {
    return(tarball_path)
  }
  
  # Use mockery to replace real functions with mocks
  mockery::stub(download_and_parse_dependencies, "remotes::download_version", mock_download_version)
  mockery::stub(download_and_parse_dependencies, "parse_dcf_dependencies_version", mock_parse_dcf_dependencies)
  
  # Run the function
  dependencies <- download_and_parse_dependencies(package_name, version)
  
  # Expected result
  expected <- data.frame(
    package = c("ggplot2", "dplyr"),
    type = c("Imports", "Imports"),
    parent_package = rep(package_name, 2),
    stringsAsFactors = FALSE
  )
  
  # Check that dependencies match expectations
  expect_equal(dependencies, expected)
  
  # Cleanup temporary files
  unlink(temp_dir, recursive = TRUE)
})



# Mock
mock_parse_dcf_dependencies <- function(path) {
  data.frame(
    package = c(""),
    type = c(""),
    stringsAsFactors = FALSE
  )
}

test_that("download_and_parse_dependencies correctly - No DESCRIPTION file", {
  
  temp_dir <- tempdir()
  package_name <- "testpkg"
  version <- "1.0.0"
  
  package_root <- file.path(temp_dir, paste0(package_name, "_", version))  # Package root folder in tarball
  dir.create(package_root, recursive = TRUE)
  
  # Create DESCRIPTION file 
  desc_path <- file.path(package_root, "DESCRIPxxxTION")
  writeLines(c(
    "Package: testpkg",
    "Version: 1.0.0"
  ), desc_path)
  
  mock_download_version <- function(package, version, repos) {
    return(tarball_path)
  }
  
  # Create a tarball with the correct structure
  tarball_path <- file.path(temp_dir, paste0(package_name, "_", version, ".tar.gz"))
  
  old_wd <- getwd()
  setwd(temp_dir)
  tar(tarball_path, files = basename(package_root), compression = "gzip", tar = "internal")
  setwd(old_wd)
  
  # Use mockery 
  mockery::stub(download_and_parse_dependencies, "remotes::download_version", mock_download_version)
  mockery::stub(download_and_parse_dependencies, "parse_dcf_dependencies_version", mock_parse_dcf_dependencies)
  expect_message(download_and_parse_dependencies(package_name, version), "Failed to download or parse testpkg - DESCRIPTION file not found for testpkg")
  
  unlink(temp_dir, recursive = TRUE)
})


test_that("download_and_parse_dependencies error in remotes::download_version", {
  
  temp_dir <- tempdir()
  package_name <- "testpkg"
  version <- "1.0.0"
  
  package_root <- file.path(temp_dir, paste0(package_name, "_", version))
  dir.create(package_root, recursive = TRUE)
  
  # Create DESCRIPTION file 
  desc_path <- file.path(package_root, "DESCRIPTION")
  writeLines(c(
    "Package: testpkg",
    "Version: 1.0.0"
  ), desc_path)
  
  tarball_path <- file.path(temp_dir, paste0(package_name, "_", version, ".tar.gz"))
  
  old_wd <- getwd()
  setwd(temp_dir)
  tar(tarball_path, files = basename(package_root), compression = "gzip", tar = "internal")
  setwd(old_wd)
  
  mock_download_version <- function(package, version, repos) {
    stop()
  }
  
  mockery::stub(download_and_parse_dependencies, "remotes::download_version", mock_download_version)
  mockery::stub(download_and_parse_dependencies, "parse_dcf_dependencies_version", mock_parse_dcf_dependencies)
  expect_message(download_and_parse_dependencies(package_name, version))
  
  # Cleanup temporary files
  unlink(temp_dir, recursive = TRUE)
})


# extract_package_version

test_that("extract_package_version works correctly", {
  with_mocked_bindings(
    packageDescription = function(...) { "1.2.3" }, 
    {
      expect_equal(extract_package_version("testpkg"), "1.2.3")
    }
  )
})


test_that("extract_package_versionwith error in packageDescription", {
  with_mocked_bindings(
    packageDescription = function(...) stop(), 
    {
      expect_equal(extract_package_version("testpkg"), NA)
    }
  )
})

test_that("extract_package_version handles errors correctly", {
  with_mocked_bindings(
    packageDescription = function(...) { stop("mocked error") },
    {
      expect_message(
        result <- extract_package_version("fakepkg"),
        "mocked error"
      )
      expect_true(is.na(result))
    }
  )
})



# build_dependency_tree

# Mock `download_and_parse_dependencies`
mock_download_and_parse_dependencies <- function(package_name, repos) {
  switch(package_name,
         "pkgA" = data.frame(package = c("pkgB", "pkgC"), type = "Imports", stringsAsFactors = FALSE),
         "pkgB" = data.frame(package = "pkgD", type = "Imports", stringsAsFactors = FALSE),
         "pkgC" = data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE), 
         "pkgD" = data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE), 
         data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE)
  )
}

# Mock `extract_package_version`
mock_package_description <- function(package_name) {
  version <- switch(package_name,
                    "pkgA" = "1.0.0",
                    "pkgB" = "1.1.0",
                    "pkgC" = "1.2.0",
                    "pkgD" = "1.3.0",
                    "Unknown")  
  
  return(ifelse(is.null(version), "Unknown", version))
}

# Mock `is_base`
mock_is_base <- function(package_name) {
  return(FALSE) 
}

test_that("build_dependency_tree constructs correct tree recursively", {
  with_mocked_bindings(
    download_and_parse_dependencies = mock_download_and_parse_dependencies,
    extract_package_version = mock_package_description,
    is_base = mock_is_base, 
    
    {
      # Run the function
      result_tree <- build_dependency_tree("pkgA")
      
      # Expected Dependency Tree
      expected_tree <- list(
        version = "1.0.0",
        pkgB = list(
          version = "1.1.0",
          pkgD = list(
            version = "1.3.0"
          )
        ),
        pkgC = list(
          version = "1.2.0"
        )
      )
      
      # Validate the tree
      expect_equal(result_tree, expected_tree)
    }
  )
})


test_that("build_dependency_tree outputs progress messages", {
  with_mocked_bindings(
    download_and_parse_dependencies = function(pkg) {
      data.frame(package = character(0), stringsAsFactors = FALSE)  # No dependencies
    },
    extract_package_version = function(pkg) {
      "1.0.0"
    },
    is_base = function(pkg) {
      FALSE
    },
    {
      expect_message(
        result <- build_dependency_tree("testpkg"),
        "Dependency tree in progress for testpkg package",
        all = TRUE
      )
      
      expect_message(
        result <- build_dependency_tree("testpkg"),
        "Finished building for testpkg",
        all = TRUE
      )
      expect_equal(result, list(version = "1.0.0"))
    }
  )
})



# download_and_parse_dependencies

# Mock 
mock_download_and_parse_dependencies <- function(package_name, repos) {
  switch(package_name,
         "pkgA" = data.frame(package = c("pkgB", "pkgC"), type = "Imports", stringsAsFactors = FALSE),
         "pkgB" = data.frame(package = "pkgD", type = "Imports", stringsAsFactors = FALSE),
         "pkgC" = data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE), # No dependencies
         "pkgD" = data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE), # No dependencies
         "pkgE" = data.frame(package = "pkgF", type = "Imports", stringsAsFactors = FALSE), # Deep Dependency
         "pkgF" = data.frame(package = "pkgG", type = "Imports", stringsAsFactors = FALSE), # Deep Dependency
         "pkgG" = data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE), # Deep Leaf
         "unknownPkg" = data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE), # Unknown
         "basePkg" = data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE), # Base package
         data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE) # Default empty
  )
}

# Mock `extract_package_version`
mock_package_description <- function(package_name) {
  version <- switch(package_name,
                    "pkgA" = "1.0.0",
                    "pkgB" = "1.1.0",
                    "pkgC" = "1.2.0",
                    "pkgD" = "1.3.0",
                    "pkgE" = "2.0.0",
                    "pkgF" = "2.1.0",
                    "pkgG" = "2.2.0",
                    "unknownPkg" = "Unknown",
                    "basePkg" = "base", 
                    "Unknown")  
  
  return(ifelse(is.null(version), "Unknown", version))
}

# Mock
mock_is_base <- function(package_name) {
  return(package_name == "basePkg")  
}

test_that("build_dependency_tree constructs correct tree with various cases", {
  with_mocked_bindings(
    download_and_parse_dependencies = mock_download_and_parse_dependencies,
    extract_package_version = mock_package_description,
    is_base = mock_is_base,
    
    {
      # basic Tree Test (Already covered)
      result_tree <- build_dependency_tree("pkgA")
      expected_tree <- list(
        version = "1.0.0",
        pkgB = list(
          version = "1.1.0",
          pkgD = list(
            version = "1.3.0"
          )
        ),
        pkgC = list(
          version = "1.2.0"
        )
      )
      expect_equal(result_tree, expected_tree)
      
      # empty Dependency Test
      result_tree_c <- build_dependency_tree("pkgC")
      expect_equal(result_tree_c, list(version = "1.2.0"))
      
      # deep Dependency Chain Test
      result_tree_e <- build_dependency_tree("pkgE")
      expected_tree_e <- list(
        version = "2.0.0",
        pkgF = list(
          version = "2.1.0",
          pkgG = list(
            version = "2.2.0"
          )
        )
      )
      expect_equal(result_tree_e, expected_tree_e)
      
      # handling Unknown 
      result_tree_unknown <- build_dependency_tree("unknownPkg")
      expect_equal(result_tree_unknown, list(version = "Unknown"))
      
      # Base Package
      result_tree_base <- build_dependency_tree("basePkg")
      expect_equal(result_tree_base, list(version = "base"))
    }
  )
})


# fetch_all_dependencies


test_that("fetch_all_dependencies returns correct dependency tree", {
  
  # Mocked return value for build_dependency_tree
  mock_build_dependency_tree <- function(package_name) {
    if (package_name == "ggplot2") {
      return(c("scales", "rlang", "tibble"))
    } else if (package_name == "scales") {
      return(c("R6", "digest"))
    }
    return(character(0))
  }
  
  # Stub the build_dependency_tree function
  mockery::stub(fetch_all_dependencies, "build_dependency_tree", mock_build_dependency_tree)
  
  # Run the function with the test package
  result <- fetch_all_dependencies("ggplot2")
  
  # Assertions
  expect_type(result, "list")
  expect_named(result, "ggplot2")
  expect_equal(result$ggplot2, c("scales", "rlang", "tibble"))
})


# print_tree

here <- list(
  version = "1.0.1",
  rprojroot = list(
    version = "2.0.4"
  )
)

test_that("here package", {
  expect_snapshot(print_tree(here, show_version = TRUE))
})

test_that("here package - no versions", {
  expect_snapshot(print_tree(here, show_version = FALSE))
})



stringr <- list(
  version = "1.5.1",
  cli = list(
    version = "3.6.2",
    utils = "base"
  ),
  glue = list(
    version = "1.7.0",
    methods = "base"
  ),
  lifecycle = list(
    version = "1.0.4",
    cli = list(
      version = "3.6.2",
      utils = "base"
    ),
    glue = list(
      version = "1.7.0",
      methods = "base"
    ),
    rlang = list(
      version = "1.1.3",
      utils = "base"
    )
  ),
  magrittr = list(
    version = "2.0.3"
  ),
  rlang = list(
    version = "1.1.3",
    utils = "base"
  ),
  stringi = list(
    version = "1.8.3",
    tools = "base",
    utils = "base",
    stats = "base"
  ),
  vctrs = list(
    version = "0.6.5",
    cli = list(
      version = "3.6.2",
      utils = "base"
    ),
    glue = list(
      version = "1.7.0",
      methods = "base"
    ),
    lifecycle = list(
      version = "1.0.4"
    ),
    rlang = list(
      version = "1.1.3",
      utils = "base"
    )
  )
)

test_that("stringr package", {
  expect_snapshot(print_tree(stringr, show_version = TRUE))
})

test_that("stringr package - no versions", {
  expect_snapshot(print_tree(stringr, show_version = FALSE))
})


test_that("stringr package - no versions", {
  expect_null(print_tree("stringr", show_version = FALSE))
})


# detect_version_conflicts

test_that("detect_version_conflicts detects a version conflict (cli)", {
  pkg_list <- list(
    ggplot2 = list(
      version = "3.5.1",
      cli = list(
        version = "3.6.2"
      ),
      gtable = list(
        version = "0.3.4",
        cli = list(version = "3.6.1")  # Conflict here!
      )
    )
  )
  
  result <- detect_version_conflicts(pkg_list)
  
  # Expect a conflict in cli
  expect_type(result, "list")
  expect_length(result, 1)
  expect_match(result[[1]], "Conflict in package cli: versions found - 3.6.2, 3.6.1")
})

test_that("detect_version_conflicts returns NULL when no conflict", {
  pkg_list <- list(
    ggplot2 = list(
      version = "3.5.1",
      cli = list(
        version = "3.6.2"
      ),
      gtable = list(
        version = "0.3.4",
        cli = list(version = "3.6.2")  # Same version, no conflict
      )
    )
  )
  
  result <- detect_version_conflicts(pkg_list)
  
  # Expect NULL since there are no conflicts
  expect_null(result)
})

test_that("detect_version_conflicts detects multiple version conflicts (glue, cli)", {
  pkg_list <- list(
    ggplot2 = list(
      version = "3.5.1",
      cli = list(version = "3.6.2"),
      gtable = list(
        version = "0.3.4",
        cli = list(version = "3.6.1"),  
        glue = list(version = "1.6.0")  
      ),
      glue = list(version = "1.7.0")  
    )
  )
  
  result <- detect_version_conflicts(pkg_list)
  
  expect_type(result, "list")
  expect_length(result, 2)
  expect_match(result[[1]], "Conflict in package cli: versions found - 3.6.2, 3.6.1")
  expect_match(result[[2]], "Conflict in package glue: versions found - 1.6.0, 1.7.0")
})

test_that("detect_version_conflicts works with deeply nested lists (cli)", {
  pkg_list <- list(
    ggplot2 = list(
      version = "3.5.1",
      cli = list(
        version = "3.6.2",
        deep_nested = list(
          cli = list(version = "3.6.1") 
        )
      )
    )
  )
  
  result <- detect_version_conflicts(pkg_list)
  expect_type(result, "list")
  expect_length(result, 1)
  expect_match(result[[1]], "Conflict in package cli: versions found - 3.6.2, 3.6.1")
})

test_that("detect_version_conflicts handles an empty list", {
  pkg_list <- list()
  
  result <- detect_version_conflicts(pkg_list)
  
  # Expect NULL for an empty list
  expect_null(result)
})
