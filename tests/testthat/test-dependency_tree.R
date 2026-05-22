
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
  result <- download_and_parse_dependencies(package_name, version)
  
  # Expected result - function now always returns a list
  expected_deps <- data.frame(
    package = c("ggplot2", "dplyr"),
    type = c("Imports", "Imports"),
    parent_package = rep(package_name, 2),
    stringsAsFactors = FALSE
  )
  
  # Check that result is a list with dependencies and license
  expect_type(result, "list")
  expect_true("dependencies" %in% names(result))
  expect_true("license" %in% names(result))
  expect_equal(result$dependencies, expected_deps)
  expect_equal(result$license, NA_character_)
  
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
  
  result <- download_and_parse_dependencies(package_name, version)
  
  # Should return error structure (list with empty dependencies and NA license)
  expect_type(result, "list")
  expect_true("dependencies" %in% names(result))
  expect_true("license" %in% names(result))
  expect_equal(nrow(result$dependencies), 0)
  expect_equal(result$license, NA_character_)
  
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
  
  result <- download_and_parse_dependencies(package_name, version)
  
  # Should return error structure (list with empty dependencies and NA license)
  expect_type(result, "list")
  expect_true("dependencies" %in% names(result))
  expect_true("license" %in% names(result))
  expect_equal(nrow(result$dependencies), 0)
  expect_equal(result$license, NA_character_)
  
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
# Now always returns a list with dependencies and license
mock_download_and_parse_dependencies <- function(package_name, get_license = FALSE, repos) {
  deps <- switch(package_name,
         "pkgA" = data.frame(package = c("pkgB", "pkgC"), type = "Imports", stringsAsFactors = FALSE),
         "pkgB" = data.frame(package = "pkgD", type = "Imports", stringsAsFactors = FALSE),
         "pkgC" = data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE), 
         "pkgD" = data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE), 
         data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE)
  )
  # Always return list format with dependencies and license
  return(list(dependencies = deps, license = NA_character_))
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

test_that("build_dependency_tree respects max_level parameter", {
  with_mocked_bindings(
    download_and_parse_dependencies = mock_download_and_parse_dependencies,
    extract_package_version = mock_package_description,
    is_base = mock_is_base,
    {
      # Test with max_level = 2 (should stop at level 2)
      result_tree_level2 <- build_dependency_tree("pkgA", max_level = 2)
      
      # pkgA (level 1) -> pkgB, pkgC (level 2) -> should stop, no pkgD
      expect_true("pkgB" %in% names(result_tree_level2))
      expect_true("pkgC" %in% names(result_tree_level2))
      # pkgD should not be present (would be level 3)
      expect_false("pkgD" %in% names(result_tree_level2$pkgB))
      
      # Test with max_level = 1 (should only have root)
      result_tree_level1 <- build_dependency_tree("pkgA", max_level = 1)
      expect_true("version" %in% names(result_tree_level1))
      expect_false("pkgB" %in% names(result_tree_level1))
      expect_false("pkgC" %in% names(result_tree_level1))
      
      # Test with max_level = 5 (should go deeper than default)
      result_tree_level5 <- build_dependency_tree("pkgA", max_level = 5)
      # Should have same structure as default (no deeper dependencies in mock)
      expect_true("pkgB" %in% names(result_tree_level5))
      expect_true("pkgC" %in% names(result_tree_level5))
    }
  )
})


test_that("build_dependency_tree outputs progress messages", {
  with_mocked_bindings(
    download_and_parse_dependencies = function(package_name, get_license = FALSE) {
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
mock_download_and_parse_dependencies <- function(package_name, get_license = FALSE, repos) {
  deps <- switch(package_name,
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
  if (get_license) {
    return(list(dependencies = deps, license = NA))
  } else {
    return(deps)
  }
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
  mock_build_dependency_tree <- function(package_name, get_license = FALSE, max_level = 3) {
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

test_that("fetch_all_dependencies passes max_level parameter correctly", {
  # Mocked return value for build_dependency_tree
  mock_build_dependency_tree <- function(package_name, get_license = FALSE, max_level = 3) {
    # Return a list with max_level info for verification
    return(list(max_level_used = max_level, package = package_name))
  }
  
  # Stub the build_dependency_tree function
  mockery::stub(fetch_all_dependencies, "build_dependency_tree", mock_build_dependency_tree)
  
  # Test with default max_level
  result_default <- fetch_all_dependencies("testpkg")
  expect_equal(result_default$testpkg$max_level_used, 3)
  
  # Test with custom max_level
  result_custom <- fetch_all_dependencies("testpkg", max_level = 5)
  expect_equal(result_custom$testpkg$max_level_used, 5)
  
  # Test with max_level = 1
  result_level1 <- fetch_all_dependencies("testpkg", max_level = 1)
  expect_equal(result_level1$testpkg$max_level_used, 1)
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


# extract_license_from_description

test_that("extract_license_from_description extracts license correctly", {
  # Create a temporary directory with DESCRIPTION file
  temp_dir <- tempdir()
  desc_path <- file.path(temp_dir, "DESCRIPTION")
  
  # Write sample DESCRIPTION with license
  writeLines(c(
    "Package: testpkg",
    "Version: 1.0.0",
    "License: MIT + file LICENSE"
  ), desc_path)
  
  license <- extract_license_from_description(temp_dir)
  
  expect_equal(license, "MIT + file LICENSE")
  
  # Cleanup
  unlink(temp_dir, recursive = TRUE)
})

test_that("extract_license_from_description returns NA when no license field", {
  # Create a temporary directory with DESCRIPTION file
  temp_dir <- tempdir()
  desc_path <- file.path(temp_dir, "DESCRIPTION")
  
  # Write sample DESCRIPTION without license
  writeLines(c(
    "Package: testpkg",
    "Version: 1.0.0"
  ), desc_path)
  
  # Should warn about missing License field
  expect_warning(
    license <- extract_license_from_description(temp_dir),
    "No License field in DESCRIPTION"
  )
  
  expect_true(is.na(license))
  
  # Cleanup
  unlink(temp_dir, recursive = TRUE)
})

test_that("extract_license_from_description handles missing DESCRIPTION file", {
  # Create a temporary directory without DESCRIPTION file
  temp_dir <- tempfile()
  dir.create(temp_dir)
  
  # Should warn about missing DESCRIPTION file
  expect_warning(
    license <- extract_license_from_description(temp_dir),
    "DESCRIPTION file not found"
  )
  
  expect_true(is.na(license))
  
  # Cleanup
  unlink(temp_dir, recursive = TRUE)
})

test_that("extract_license_from_description handles various license formats", {
  # Create a temporary directory with DESCRIPTION file
  temp_dir <- tempdir()
  desc_path <- file.path(temp_dir, "DESCRIPTION")
  
  # Test GPL-3 license
  writeLines(c(
    "Package: testpkg",
    "Version: 1.0.0",
    "License: GPL-3"
  ), desc_path)
  
  license <- extract_license_from_description(temp_dir)
  expect_equal(license, "GPL-3")
  
  # Test AGPL-3.0 license
  writeLines(c(
    "Package: testpkg",
    "Version: 1.0.0",
    "License: AGPL-3.0"
  ), desc_path)
  
  license <- extract_license_from_description(temp_dir)
  expect_equal(license, "AGPL-3.0")
  
  # Cleanup
  unlink(temp_dir, recursive = TRUE)
})


# build_dependency_tree with get_license parameter

test_that("build_dependency_tree includes license when get_license = TRUE", {
  # Mock download_and_parse_dependencies to return list with dependencies and license
  # Note: download_and_parse_dependencies now ALWAYS returns list(dependencies, license)
  # Version is extracted separately via extract_package_version
  mock_download_and_parse_dependencies <- function(package_name, get_license = FALSE) {
    # Always return list format with dependencies and license
    return(list(
      dependencies = data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE),
      license = if (get_license) "MIT + file LICENSE" else NA_character_
    ))
  }
  
  mock_extract_package_version <- function(package_name) {
    return("1.0.0")
  }
  
  with_mocked_bindings(
    download_and_parse_dependencies = mock_download_and_parse_dependencies,
    extract_package_version = mock_extract_package_version,
    is_base = function(pkg) FALSE,
    {
      result_tree <- build_dependency_tree("testpkg", get_license = TRUE)
      
      # Should have version and license
      expect_true("version" %in% names(result_tree))
      expect_true("license" %in% names(result_tree))
      expect_equal(result_tree$version, "1.0.0")
      expect_equal(result_tree$license, "MIT + file LICENSE")
    }
  )
})

test_that("build_dependency_tree excludes license when get_license = FALSE", {
  # Mock download_and_parse_dependencies to return data.frame (old format)
  mock_download_and_parse_dependencies <- function(package_name, get_license = FALSE) {
    return(data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE))
  }
  
  mock_extract_package_version <- function(package_name) {
    return("1.0.0")
  }
  
  with_mocked_bindings(
    download_and_parse_dependencies = mock_download_and_parse_dependencies,
    extract_package_version = mock_extract_package_version,
    is_base = function(pkg) FALSE,
    {
      result_tree <- build_dependency_tree("testpkg", get_license = FALSE)
      
      # Should have version but NOT license
      expect_true("version" %in% names(result_tree))
      expect_false("license" %in% names(result_tree))
      expect_equal(result_tree$version, "1.0.0")
    }
  )
})

test_that("build_dependency_tree includes licenses for nested dependencies", {
  # Mock download_and_parse_dependencies to return dependencies with licenses
  # Note: download_and_parse_dependencies returns list(dependencies, license) when get_license=TRUE
  mock_download_and_parse_dependencies <- function(package_name, get_license = FALSE) {
    if (package_name == "pkgA") {
      if (get_license) {
        return(list(
          dependencies = data.frame(package = "pkgB", type = "Imports", stringsAsFactors = FALSE),
          license = "MIT"
        ))
      } else {
        return(data.frame(package = "pkgB", type = "Imports", stringsAsFactors = FALSE))
      }
    } else if (package_name == "pkgB") {
      if (get_license) {
        return(list(
          dependencies = data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE),
          license = "GPL-3"
        ))
      } else {
        return(data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE))
      }
    }
    return(data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE))
  }
  
  mock_extract_package_version <- function(package_name) {
    switch(package_name,
           "pkgA" = "1.0.0",
           "pkgB" = "1.1.0",
           "Unknown")
  }
  
  with_mocked_bindings(
    download_and_parse_dependencies = mock_download_and_parse_dependencies,
    extract_package_version = mock_extract_package_version,
    is_base = function(pkg) FALSE,
    {
      result_tree <- build_dependency_tree("pkgA", get_license = TRUE)
      
      # Root should have license
      expect_equal(result_tree$license, "MIT")
      
      # Nested dependency should have license
      expect_true("license" %in% names(result_tree$pkgB))
      expect_equal(result_tree$pkgB$license, "GPL-3")
    }
  )
})


# fetch_all_dependencies with get_license parameter

test_that("fetch_all_dependencies includes license when get_license = TRUE", {
  # Mock build_dependency_tree to return tree with license
  mock_build_dependency_tree <- function(package_name, get_license = FALSE, max_level = 3) {
    if (get_license) {
      return(list(
        version = "1.0.0",
        license = "MIT + file LICENSE"
      ))
    } else {
      return(list(
        version = "1.0.0"
      ))
    }
  }
  
  mockery::stub(fetch_all_dependencies, "build_dependency_tree", mock_build_dependency_tree)
  
  result <- fetch_all_dependencies("testpkg", get_license = TRUE)
  
  expect_type(result, "list")
  expect_named(result, "testpkg")
  expect_true("license" %in% names(result$testpkg))
  expect_equal(result$testpkg$license, "MIT + file LICENSE")
})

test_that("fetch_all_dependencies excludes license when get_license = FALSE", {
  # Mock build_dependency_tree to return tree without license
  mock_build_dependency_tree <- function(package_name, get_license = FALSE, max_level = 3) {
    return(list(
      version = "1.0.0"
    ))
  }
  
  mockery::stub(fetch_all_dependencies, "build_dependency_tree", mock_build_dependency_tree)
  
  result <- fetch_all_dependencies("testpkg", get_license = FALSE)
  
  expect_type(result, "list")
  expect_named(result, "testpkg")
  expect_false("license" %in% names(result$testpkg))
})


# print_tree with licenses

test_that("print_tree does not show version and license as separate packages", {
  # Create a tree with version and license at root level
  test_tree <- list(
    version = "1.0.0",
    license = "MIT + file LICENSE",
    cli = list(
      version = "3.6.2"
    )
  )
  
  # Capture output
  output <- capture.output(print_tree(test_tree))
  
  # Should NOT contain "├── version" or "├── license" as separate entries
  expect_false(any(grepl("├── version", output)))
  expect_false(any(grepl("├── license", output)))
  expect_false(any(grepl("└── version", output)))
  expect_false(any(grepl("└── license", output)))
  
  # Should show cli with version
  expect_true(any(grepl("cli", output)))
})

test_that("print_tree displays license with root package", {
  # Create a tree wrapped by fetch_all_dependencies
  test_tree <- list(
    testpkg = list(
      version = "1.0.0",
      license = "MIT + file LICENSE",
      cli = list(
        version = "3.6.2"
      )
    )
  )
  
  # Capture output
  output <- capture.output(print_tree(test_tree))
  
  # Should show license with the package name
  # The output should be something like: "└── testpkg (v1.0.0) MIT + file LICENSE license"
  # Escape the + sign properly in regex
  expect_true(any(grepl("MIT.*file LICENSE license", output)) || any(grepl("MIT \\+ file LICENSE license", output)))
  expect_true(any(grepl("testpkg", output)))
})

test_that("print_tree displays licenses for nested dependencies", {
  # Create a tree with licenses at multiple levels
  test_tree <- list(
    testpkg = list(
      version = "1.0.0",
      license = "MIT",
      dep1 = list(
        version = "2.0.0",
        license = "GPL-3"
      )
    )
  )
  
  # Capture output
  output <- capture.output(print_tree(test_tree))
  
  # Should show license for root package (with "license" word at root level)
  expect_true(any(grepl("MIT license", output)))
  
  # Should show license for nested dependency (without "license" word, just the value)
  expect_true(any(grepl("GPL-3", output)))
  # Make sure it's not showing "GPL-3 license" for nested dependency
  expect_false(any(grepl("dep1.*GPL-3 license", output)))
})

test_that("print_tree handles tree with only metadata (no packages)", {
  # Edge case: tree with only version and license, no dependencies
  edge_tree <- list(
    version = "1.0.0",
    license = "MIT"
  )
  
  # Should not crash and should return NULL or print nothing
  expect_silent(print_tree(edge_tree))
  
  # Capture output
  output <- capture.output(print_tree(edge_tree))
  
  # Should not print version/license as packages
  expect_false(any(grepl("version", output)))
  expect_false(any(grepl("license", output)))
})

test_that("print_tree with licenses matches snapshot", {
  # Create a test tree with licenses
  test_tree <- list(
    stringr = list(
      version = "1.5.1",
      license = "MIT + file LICENSE",
      cli = list(
        version = "3.6.2",
        license = "MIT + file LICENSE",
        utils = "base"
      )
    )
  )
  
  expect_snapshot(print_tree(test_tree, show_version = TRUE))
})


# Comprehensive test coverage for all combinations

# Test all combinations: get_license (TRUE/FALSE) x show_version (TRUE/FALSE)

test_that("print_tree: get_license=TRUE, show_version=TRUE", {
  test_tree <- list(
    pkg = list(
      version = "1.0.0",
      license = "MIT",
      dep = list(
        version = "2.0.0",
        license = "GPL-3"
      )
    )
  )
  
  output <- capture.output(print_tree(test_tree, show_version = TRUE))
  
  # Should show versions
  expect_true(any(grepl("v1.0.0", output)))
  expect_true(any(grepl("v2.0.0", output)))
  
  # Should show licenses
  expect_true(any(grepl("MIT license", output)))
  expect_true(any(grepl("GPL-3", output)))
  
  # Should NOT show version/license as separate packages
  expect_false(any(grepl("├── version", output)))
  expect_false(any(grepl("├── license", output)))
})

test_that("print_tree: get_license=TRUE, show_version=FALSE", {
  test_tree <- list(
    pkg = list(
      version = "1.0.0",
      license = "MIT",
      dep = list(
        version = "2.0.0",
        license = "GPL-3"
      )
    )
  )
  
  output <- capture.output(print_tree(test_tree, show_version = FALSE))
  
  # Should NOT show versions
  expect_false(any(grepl("v1.0.0", output)))
  expect_false(any(grepl("v2.0.0", output)))
  
  # Should show licenses
  expect_true(any(grepl("MIT license", output)))
  expect_true(any(grepl("GPL-3", output)))
  
  # Should NOT show version/license as separate packages
  expect_false(any(grepl("├── version", output)))
  expect_false(any(grepl("├── license", output)))
})

test_that("print_tree: get_license=FALSE, show_version=TRUE", {
  test_tree <- list(
    pkg = list(
      version = "1.0.0",
      dep = list(
        version = "2.0.0"
      )
    )
  )
  
  output <- capture.output(print_tree(test_tree, show_version = TRUE))
  
  # Should show versions
  expect_true(any(grepl("v1.0.0", output)))
  expect_true(any(grepl("v2.0.0", output)))
  
  # Should NOT show licenses (none in tree)
  expect_false(any(grepl("license", output)))
  
  # Should NOT show version/license as separate packages
  expect_false(any(grepl("├── version", output)))
})

test_that("print_tree: get_license=FALSE, show_version=FALSE", {
  test_tree <- list(
    pkg = list(
      version = "1.0.0",
      dep = list(
        version = "2.0.0"
      )
    )
  )
  
  output <- capture.output(print_tree(test_tree, show_version = FALSE))
  
  # Should NOT show versions
  expect_false(any(grepl("v1.0.0", output)))
  expect_false(any(grepl("v2.0.0", output)))
  
  # Should NOT show licenses
  expect_false(any(grepl("license", output)))
  
  # Should show package names
  expect_true(any(grepl("pkg", output)))
  expect_true(any(grepl("dep", output)))
})


# Error scenarios and edge cases

test_that("build_dependency_tree handles license extraction failure (NA)", {
  mock_download_and_parse_dependencies <- function(package_name, get_license = FALSE) {
    if (get_license) {
      return(list(
        dependencies = data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE),
        license = NA  # License extraction failed
      ))
    } else {
      return(data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE))
    }
  }
  
  mock_extract_package_version <- function(package_name) {
    return("1.0.0")
  }
  
  with_mocked_bindings(
    download_and_parse_dependencies = mock_download_and_parse_dependencies,
    extract_package_version = mock_extract_package_version,
    is_base = function(pkg) FALSE,
    {
      result_tree <- build_dependency_tree("testpkg", get_license = TRUE)
      
      # Should have version
      expect_true("version" %in% names(result_tree))
      
      # License should be NA or NULL (not included if NA)
      if ("license" %in% names(result_tree)) {
        expect_true(is.na(result_tree$license))
      }
    }
  )
})

test_that("build_dependency_tree handles empty license string", {
  mock_download_and_parse_dependencies <- function(package_name, get_license = FALSE) {
    if (get_license) {
      return(list(
        dependencies = data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE),
        license = ""  # Empty license string
      ))
    } else {
      return(data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE))
    }
  }
  
  mock_extract_package_version <- function(package_name) {
    return("1.0.0")
  }
  
  with_mocked_bindings(
    download_and_parse_dependencies = mock_download_and_parse_dependencies,
    extract_package_version = mock_extract_package_version,
    is_base = function(pkg) FALSE,
    {
      result_tree <- build_dependency_tree("testpkg", get_license = TRUE)
      
      # Should have version
      expect_true("version" %in% names(result_tree))
      
      # License might be empty string or not included
      if ("license" %in% names(result_tree)) {
        expect_true(result_tree$license == "" || is.na(result_tree$license))
      }
    }
  )
})

test_that("print_tree handles NULL license gracefully", {
  test_tree <- list(
    pkg = list(
      version = "1.0.0",
      license = NULL,
      dep = list(
        version = "2.0.0"
      )
    )
  )
  
  # Should not crash or error
  expect_error(print_tree(test_tree), NA)
  
  output <- capture.output(print_tree(test_tree))
  
  # Should show package names
  expect_true(any(grepl("pkg", output)))
  expect_true(any(grepl("dep", output)))
})

test_that("print_tree handles NA license gracefully", {
  test_tree <- list(
    pkg = list(
      version = "1.0.0",
      license = NA,
      dep = list(
        version = "2.0.0"
      )
    )
  )
  
  # Should not crash or error
  expect_error(print_tree(test_tree), NA)
  
  output <- capture.output(print_tree(test_tree))
  
  # Should show package names
  expect_true(any(grepl("pkg", output)))
  expect_true(any(grepl("dep", output)))
  
  # Should not show "NA license"
  expect_false(any(grepl("NA license", output)))
})

test_that("print_tree handles empty license string", {
  test_tree <- list(
    pkg = list(
      version = "1.0.0",
      license = "",
      dep = list(
        version = "2.0.0"
      )
    )
  )
  
  # Should not crash or error
  expect_error(print_tree(test_tree), NA)
  
  output <- capture.output(print_tree(test_tree))
  
  # Should show package names
  expect_true(any(grepl("pkg", output)))
})

test_that("print_tree handles base packages with license metadata (should ignore)", {
  test_tree <- list(
    pkg = list(
      version = "1.0.0",
      license = "MIT",
      utils = "base"  # Base package
    )
  )
  
  output <- capture.output(print_tree(test_tree))
  
  # Should show base package
  expect_true(any(grepl("utils.*base", output)))
  
  # Should NOT show license for base package
  expect_false(any(grepl("utils.*MIT", output)))
})

test_that("build_dependency_tree with get_license=TRUE handles base packages correctly", {
  mock_download_and_parse_dependencies <- function(package_name, get_license = FALSE) {
    if (get_license) {
      return(list(
        dependencies = data.frame(package = "utils", type = "Imports", stringsAsFactors = FALSE),
        license = "MIT"
      ))
    } else {
      return(data.frame(package = "utils", type = "Imports", stringsAsFactors = FALSE))
    }
  }
  
  mock_extract_package_version <- function(package_name) {
    return("1.0.0")
  }
  
  with_mocked_bindings(
    download_and_parse_dependencies = mock_download_and_parse_dependencies,
    extract_package_version = mock_extract_package_version,
    is_base = function(pkg) pkg == "utils",
    {
      result_tree <- build_dependency_tree("testpkg", get_license = TRUE)
      
      # Root should have license
      expect_equal(result_tree$license, "MIT")
      
      # Base package should be marked as "base", not have license
      expect_equal(result_tree$utils, "base")
    }
  )
})

test_that("print_tree handles tree with dependencies but no version/license metadata", {
  test_tree <- list(
    pkg = list(
      dep1 = list(),
      dep2 = "base"
    )
  )
  
  # Should not crash or error
  expect_error(print_tree(test_tree), NA)
  
  output <- capture.output(print_tree(test_tree))
  
  # Should show package names
  expect_true(any(grepl("pkg", output)))
  expect_true(any(grepl("dep1", output)))
  expect_true(any(grepl("dep2.*base", output)))
})

test_that("print_tree handles invalid tree structure (not a list)", {
  # Should handle gracefully
  expect_silent(print_tree("not a list"))
  expect_silent(print_tree(NULL))
  expect_silent(print_tree(123))
  
  # Should return NULL or print nothing
  output <- capture.output(print_tree("not a list"))
  expect_length(output, 0)
})

test_that("extract_license_from_description handles corrupted DESCRIPTION file", {
  temp_dir <- tempdir()
  desc_path <- file.path(temp_dir, "DESCRIPTION")
  
  # Write corrupted DESCRIPTION (invalid DCF format)
  writeLines(c(
    "Package: testpkg",
    "Version: 1.0.0",
    "License: MIT + file LICENSE",
    "Invalid line without colon"
  ), desc_path)
  
  # Should handle gracefully (might return NA or the license)
  suppressWarnings(license <- extract_license_from_description(temp_dir))
  
  # Should either return the license or NA
  expect_true(is.character(license) || is.na(license))
  
  # Cleanup
  unlink(temp_dir, recursive = TRUE)
})

test_that("extract_license_from_description handles empty DESCRIPTION file", {
  temp_dir <- tempdir()
  desc_path <- file.path(temp_dir, "DESCRIPTION")
  
  # Write empty DESCRIPTION
  writeLines("", desc_path)
  
  # Should warn about missing License field
  expect_warning(
    license <- extract_license_from_description(temp_dir),
    "No License field in DESCRIPTION"
  )
  
  expect_true(is.na(license))
  
  # Cleanup
  unlink(temp_dir, recursive = TRUE)
})

test_that("build_dependency_tree handles download_and_parse_dependencies returning NULL with get_license=TRUE", {
  mock_download_and_parse_dependencies <- function(package_name, get_license = FALSE) {
    return(NULL)  # Download failed
  }
  
  mock_extract_package_version <- function(package_name) {
    return("1.0.0")
  }
  
  with_mocked_bindings(
    download_and_parse_dependencies = mock_download_and_parse_dependencies,
    extract_package_version = mock_extract_package_version,
    is_base = function(pkg) FALSE,
    {
      result_tree <- build_dependency_tree("testpkg", get_license = TRUE)
      
      # Should have version
      expect_true("version" %in% names(result_tree))
      
      # Should not have license (NULL result means no license extracted)
      expect_false("license" %in% names(result_tree))
    }
  )
})

test_that("print_tree handles complex license strings with special characters", {
  test_tree <- list(
    pkg = list(
      version = "1.0.0",
      license = "MIT + file LICENSE | GPL-2",
      dep = list(
        version = "2.0.0",
        license = "AGPL-3.0 + file LICENSE"
      )
    )
  )
  
  output <- capture.output(print_tree(test_tree))
  
  # Should handle special characters in license
  expect_true(any(grepl("MIT.*file LICENSE", output)) || any(grepl("GPL-2", output)))
  expect_true(any(grepl("AGPL-3.0", output)))
})

test_that("fetch_all_dependencies with get_license=TRUE handles build_dependency_tree returning NULL", {
  mock_build_dependency_tree <- function(package_name, get_license = FALSE, max_level = 3) {
    return(NULL)  # Build failed
  }
  
  mockery::stub(fetch_all_dependencies, "build_dependency_tree", mock_build_dependency_tree)
  
  result <- fetch_all_dependencies("testpkg", get_license = TRUE)
  
  expect_type(result, "list")
  # Note: In R, assigning NULL to a list element removes it, so when build_dependency_tree
  # returns NULL, the result will be an empty list (the element is not added)
  expect_length(result, 0)
})


# Validation tests for build_dependency_tree - now uses warnings instead of errors

test_that("build_dependency_tree warns on negative max_level", {
  expect_warning(
    build_dependency_tree("testpkg", max_level = -1),
    "max_level must be a non-negative integer"
  )
})

test_that("build_dependency_tree warns on fractional max_level", {
  # Mock extract_package_version to avoid "package not found" warnings
  mock_extract_package_version <- function(package_name) {
    return("1.0.0")
  }
  
  with_mocked_bindings(
    extract_package_version = mock_extract_package_version,
    {
      expect_warning(
        result <- build_dependency_tree("testpkg", max_level = 3.5),
        "max_level must be a non-negative integer"
      )
      expect_null(result)  # Should return NULL after warning
    }
  )
})

test_that("build_dependency_tree warns on NULL max_level", {
  expect_warning(
    build_dependency_tree("testpkg", max_level = NULL),
    "max_level must be a non-negative integer"
  )
})

test_that("build_dependency_tree warns on character max_level", {
  # Mock extract_package_version to avoid "package not found" warnings
  mock_extract_package_version <- function(package_name) {
    return("1.0.0")
  }
  
  with_mocked_bindings(
    extract_package_version = mock_extract_package_version,
    {
      expect_warning(
        result <- build_dependency_tree("testpkg", max_level = "3"),
        "max_level must be a non-negative integer"
      )
      expect_null(result)  # Should return NULL after warning
    }
  )
})

test_that("build_dependency_tree warns on vector max_level", {
  # Mock extract_package_version to avoid "package not found" warnings
  mock_extract_package_version <- function(package_name) {
    return("1.0.0")
  }
  
  with_mocked_bindings(
    extract_package_version = mock_extract_package_version,
    {
      expect_warning(
        result <- build_dependency_tree("testpkg", max_level = c(1, 2, 3)),
        "max_level must be a non-negative integer"
      )
      expect_null(result)  # Should return NULL after warning
    }
  )
})

test_that("build_dependency_tree warns on empty package_name", {
  expect_warning(
    build_dependency_tree(""),
    "package_name must be a non-empty character string"
  )
})

test_that("build_dependency_tree warns on NA package_name", {
  expect_warning(
    build_dependency_tree(NA_character_),
    "package_name must be a non-empty character string"
  )
})

test_that("build_dependency_tree warns on NULL package_name", {
  expect_warning(
    build_dependency_tree(NULL),
    "package_name must be a non-empty character string"
  )
})

test_that("build_dependency_tree warns on numeric package_name", {
  # Mock extract_package_version to avoid "package not found" warnings
  mock_extract_package_version <- function(package_name) {
    return("1.0.0")
  }
  
  with_mocked_bindings(
    extract_package_version = mock_extract_package_version,
    {
      expect_warning(
        result <- build_dependency_tree(123),
        "package_name must be a non-empty character string"
      )
      expect_null(result)  # Should return NULL after warning
    }
  )
})

test_that("build_dependency_tree warns on vector package_name", {
  # Mock download_and_parse_dependencies to avoid actual download attempts
  mock_download_and_parse_dependencies <- function(package_name, get_license = FALSE) {
    return(list(
      dependencies = data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE),
      license = NA_character_
    ))
  }
  
  with_mocked_bindings(
    download_and_parse_dependencies = mock_download_and_parse_dependencies,
    {
      expect_warning(
        result <- build_dependency_tree(c("pkg1", "pkg2")),
        "package_name must be a non-empty character string"
      )
      expect_null(result)  # Should return NULL after warning
    }
  )
})

# Validation tests for fetch_all_dependencies - still uses errors

test_that("fetch_all_dependencies rejects negative max_level", {
  expect_error(
    fetch_all_dependencies("testpkg", max_level = -1),
    "max_level must be a non-negative integer"
  )
})

test_that("fetch_all_dependencies rejects fractional max_level", {
  expect_error(
    fetch_all_dependencies("testpkg", max_level = 3.5),
    "max_level must be a non-negative integer"
  )
})

test_that("fetch_all_dependencies rejects NULL max_level", {
  expect_error(
    fetch_all_dependencies("testpkg", max_level = NULL),
    "max_level must be a non-negative integer"
  )
})

test_that("fetch_all_dependencies rejects character max_level", {
  expect_error(
    fetch_all_dependencies("testpkg", max_level = "3"),
    "max_level must be a non-negative integer"
  )
})

test_that("fetch_all_dependencies rejects vector max_level", {
  expect_error(
    fetch_all_dependencies("testpkg", max_level = c(1, 2, 3)),
    "max_level must be a non-negative integer"
  )
})

test_that("fetch_all_dependencies accepts zero max_level", {
  # Mock build_dependency_tree to avoid actual download
  mock_build_dependency_tree <- function(package_name, get_license = FALSE, max_level = 3, visited = character()) {
    return(list(version = "1.0.0"))
  }
  
  mockery::stub(fetch_all_dependencies, "build_dependency_tree", mock_build_dependency_tree)
  
  result <- fetch_all_dependencies("testpkg", max_level = 0)
  expect_type(result, "list")
})

test_that("fetch_all_dependencies rejects empty package_name", {
  expect_error(
    fetch_all_dependencies(""),
    "package_name must be a non-empty character string"
  )
})

test_that("fetch_all_dependencies rejects NA package_name", {
  expect_error(
    fetch_all_dependencies(NA_character_),
    "package_name must be a non-empty character string"
  )
})

test_that("fetch_all_dependencies rejects NULL package_name", {
  expect_error(
    fetch_all_dependencies(NULL),
    "package_name must be a non-empty character string"
  )
})

test_that("fetch_all_dependencies rejects numeric package_name", {
  expect_error(
    fetch_all_dependencies(123),
    "package_name must be a non-empty character string"
  )
})

test_that("fetch_all_dependencies rejects vector package_name", {
  expect_error(
    fetch_all_dependencies(c("pkg1", "pkg2")),
    "package_name must be a non-empty character string"
  )
})

test_that("fetch_all_dependencies accepts package_name with whitespace (trimmed)", {
  # Mock build_dependency_tree to avoid actual download
  mock_build_dependency_tree <- function(package_name, get_license = FALSE, max_level = 3, visited = character()) {
    return(list(version = "1.0.0"))
  }
  
  mockery::stub(fetch_all_dependencies, "build_dependency_tree", mock_build_dependency_tree)
  
  # Should work with whitespace (will be trimmed)
  result <- fetch_all_dependencies("  testpkg  ", max_level = 1)
  expect_type(result, "list")
})


# Validation tests for build_dependency_tree - now uses warnings instead of errors

test_that("build_dependency_tree warns on negative max_level", {
  expect_warning(
    build_dependency_tree("testpkg", max_level = -1),
    "max_level must be a non-negative integer"
  )
})

test_that("build_dependency_tree warns on fractional max_level", {
  # Mock extract_package_version to avoid "package not found" warnings
  mock_extract_package_version <- function(package_name) {
    return("1.0.0")
  }
  
  with_mocked_bindings(
    extract_package_version = mock_extract_package_version,
    {
      expect_warning(
        result <- build_dependency_tree("testpkg", max_level = 2.7),
        "max_level must be a non-negative integer"
      )
      expect_null(result)  # Should return NULL after warning
    }
  )
})

test_that("build_dependency_tree warns on NULL max_level", {
  expect_warning(
    build_dependency_tree("testpkg", max_level = NULL),
    "max_level must be a non-negative integer"
  )
})

test_that("build_dependency_tree accepts zero max_level", {
  # Mock download_and_parse_dependencies to avoid actual download
  # Now always returns a list with dependencies and license
  mock_download_and_parse_dependencies <- function(package_name, get_license = FALSE) {
    return(list(
      dependencies = data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE),
      license = NA_character_
    ))
  }
  
  mock_extract_package_version <- function(package_name) {
    return("1.0.0")
  }
  
  with_mocked_bindings(
    download_and_parse_dependencies = mock_download_and_parse_dependencies,
    extract_package_version = mock_extract_package_version,
    is_base = function(pkg) FALSE,
    {
      result <- build_dependency_tree("testpkg", max_level = 0)
      # Should return NULL because level (1) > max_level (0)
      expect_null(result)
    }
  )
})

test_that("build_dependency_tree warns on empty package_name", {
  expect_warning(
    build_dependency_tree(""),
    "package_name must be a non-empty character string"
  )
})

test_that("build_dependency_tree warns on NA package_name", {
  expect_warning(
    build_dependency_tree(NA_character_),
    "package_name must be a non-empty character string"
  )
})

test_that("build_dependency_tree warns on NULL package_name", {
  expect_warning(
    build_dependency_tree(NULL),
    "package_name must be a non-empty character string"
  )
})

test_that("build_dependency_tree accepts package_name with whitespace (trimmed)", {
  # Mock download_and_parse_dependencies to avoid actual download
  mock_download_and_parse_dependencies <- function(package_name, get_license = FALSE) {
    return(data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE))
  }
  
  mock_extract_package_version <- function(package_name) {
    return("1.0.0")
  }
  
  with_mocked_bindings(
    download_and_parse_dependencies = mock_download_and_parse_dependencies,
    extract_package_version = mock_extract_package_version,
    is_base = function(pkg) FALSE,
    {
      # Should work with whitespace (will be trimmed)
      result <- build_dependency_tree("  testpkg  ", max_level = 1)
      expect_type(result, "list")
      expect_true("version" %in% names(result))
    }
  )
})


# Cycle detection tests

test_that("build_dependency_tree handles circular dependencies (no infinite loop)", {
  # Mock a circular dependency: pkgA -> pkgB -> pkgA
  mock_download_and_parse_dependencies <- function(package_name, get_license = FALSE) {
    deps <- switch(package_name,
      "pkgA" = data.frame(package = "pkgB", type = "Imports", stringsAsFactors = FALSE),
      "pkgB" = data.frame(package = "pkgA", type = "Imports", stringsAsFactors = FALSE),
      data.frame(package = character(0), type = character(0), stringsAsFactors = FALSE)
    )
    return(deps)
  }
  
  mock_extract_package_version <- function(package_name) {
    return("1.0.0")
  }
  
  with_mocked_bindings(
    download_and_parse_dependencies = mock_download_and_parse_dependencies,
    extract_package_version = mock_extract_package_version,
    is_base = function(pkg) FALSE,
    {
      # With max_level = 2, pkgA (level 1) -> pkgB (level 2) -> pkgA (level 3, stopped)
      # Should not cause infinite loop due to max_level limit
      result <- build_dependency_tree("pkgA", max_level = 2)
      
      # Should have pkgB but pkgB should not have pkgA (stopped at max_level)
      expect_true("pkgB" %in% names(result))
      expect_true(is.list(result$pkgB))
      # pkgB should not have pkgA as a dependency (stopped at max_level)
      expect_false("pkgA" %in% names(result$pkgB))
    }
  )
})

