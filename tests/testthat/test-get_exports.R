test_that("get_exports works correctly with regular functions", {
  skip_on_cran()
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0001_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # set up package
  install_list <- risk.assessr::set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  
  # install package locally to ensure test works
  package_installed <-
    install_package_local(pkg_source_path)
  package_installed <- TRUE

  if (package_installed == TRUE ) {
    
    rcmdcheck_args$path <- pkg_source_path


    # Test case: Normal scenario
    result <- get_exports(pkg_source_path)
    
    expect_equal(result$exported_function, 
                 c("myfunction"))
    expect_equal(result$class, NA_character_)
    expect_equal(result$function_type, 
                 c("regular function"))
  }
})

test_that("get_exports works correctly with no R functions", {
  skip_on_cran()
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0005_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # set up package
  install_list <- risk.assessr::set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  
  # install package locally to ensure test works
  package_installed <-
    install_package_local(pkg_source_path)
  package_installed <- TRUE
  
  if (package_installed == TRUE ) {
    
    rcmdcheck_args$path <- pkg_source_path
    
    
    # Test case: Normal scenario
    result <- get_exports(pkg_source_path)
    
    # Check it's a tibble
    expect_s3_class(result, "tbl_df")
    
    # Check number of columns
    expect_equal(ncol(result), 5)
    
    # Check column names
    expect_named(result, c("exported_function", "class", "function_type", "function_body", "where"))
    
    
    # Check number of rows
    expect_equal(nrow(result), 1)
    
  }
})


test_that("get_r6_methods_details extracts and formats R6 method bodies", {
  # Create a mock R6 class with public methods
  MockClass <- R6::R6Class("MockClass",
                           public = list(
                             method_one = function(x) {
                               x + 1
                             },
                             method_two = function(y) {
                               y * 2
                             }
                           )
  )
  
  # Call the function with the mock class
  result <- get_r6_methods_details(MockClass)
  
  # Check that the result is a character string
  expect_type(result, "list")
  
  # Check that method names and bodies are included
  # Check method one
  expect_equal(result[[1]]$name, "method_one")
  expect_true(any(grepl("x \\+ 1", result[[1]]$body)))
  
  # Check method two
  expect_equal(result[[2]]$name, "method_two")
  expect_true(any(grepl("y \\* 2", result[[2]]$body)))
  
})

test_that("get_exports works correctly with nonstandard NAMESPACE", {
  skip_on_cran()
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)

  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0012_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # set up package
  install_list <- risk.assessr::set_up_pkg(dp)

  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args


  # install package locally to ensure test works
  package_installed <-
    install_package_local(pkg_source_path)
  package_installed <- TRUE

  if (package_installed == TRUE ) {

    rcmdcheck_args$path <- pkg_source_path

    # Test case: Normal scenario
    suppressWarnings(result <- get_exports(pkg_source_path))

    expect_equal(result$exported_function,
                 c("fetch_ggproto", "as.list.AMap", "make_proto_method",
                   "length.AMap", "AMap", "$.ggproto", ".pt"))
    expect_equal(result$class,
                 c(NA_character_, NA_character_, NA_character_, NA_character_,  
                   NA_character_, NA_character_, NA_character_))
    expect_equal(result$function_type,
                 c("regular function", "S3 function, R6 class generator",
                   "regular function", "S3 function, R6 class generator",
                   "non-function or helper, R6 class", 
                   "S4 method, S4 generic", "numeric"
                   ))
    
    # Check dimensions
    expect_equal(nrow(result), 7)
    expect_equal(ncol(result), 5)
    
    # Check column names
    expect_named(result, c("exported_function", "class", "function_type", "function_body", "where"))
    
    # Check types
    expect_type(result$exported_function, "character")
    expect_type(result$class, "character")
    expect_type(result$function_type, "character")
    expect_type(result$function_body, "character")
    expect_type(result$where, "character")
    
    # Check specific values (example: first row)
    expect_equal(result$exported_function[1], "fetch_ggproto")
    expect_equal(result$function_type[1], "regular function")
    expect_equal(result$where[1], "test.package.0012")
    
    # Check for NA in class column
    expect_true(is.na(result$class[1]))
    
    # Check that function_body is not empty
    expect_true(nchar(result$function_body[1]) > 0)
    
  }
})

test_that("get_exports works correctly with S3 functions", {
  skip_on_cran()
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0009_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # set up package
  install_list <- risk.assessr::set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  
  # install package locally to ensure test works
  package_installed <-
    install_package_local(pkg_source_path)
  package_installed <- TRUE
  
  if (package_installed == TRUE ) {
    
    rcmdcheck_args$path <- pkg_source_path
    
    
    # Test case: Normal scenario
    result <- get_exports(pkg_source_path)
    
    expect_equal(result$exported_function, 
                 c("filter_first_two_rows_y", "myfunction",
                   "filter_first_three_rows", "filter_first_three_rows"))
    expect_equal(result$class, 
                 c(NA, NA, "dataframe_with_y", "list"))
    expect_equal(result$function_type, 
                 c("regular function", "regular function",
                   "S3 method", "S3 method"))
  }
})

test_that("get_exports works correctly with S4 functions", {
  skip_on_cran()
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0010_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # set up package
  install_list <- risk.assessr::set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  
  # install package locally to ensure test works
  package_installed <-
    install_package_local(pkg_source_path)
  package_installed <- TRUE
  
  if (package_installed == TRUE ) {
    
    rcmdcheck_args$path <- pkg_source_path
    
    
    # Test case: Normal scenario
    result <- get_exports(pkg_source_path)
    
    expect_equal(result$exported_function, 
                 c("addOne"))
    expect_equal(result$class, 
                 c(NA_character_))
    expect_equal(result$function_type, 
                 c("S4 method, S4 generic"))
  }
})

test_that("get_exports works correctly with R6 functions", {
  skip_on_cran()
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0011_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # set up package
  install_list <- risk.assessr::set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  
  # install package locally to ensure test works
  package_installed <-
    install_package_local(pkg_source_path)
  package_installed <- TRUE
  
  if (package_installed == TRUE ) {
    
    rcmdcheck_args$path <- pkg_source_path
    
    # Test case: Normal scenario
    result <- get_exports(pkg_source_path)
    
    expect_equal(result$exported_function, 
                 c(".pt", "\"$\"",
                   "as.list", "length", "$"))
    expect_equal(result$class, 
                 c(NA, "ggproto", "AMap", "AMap", "ggproto"))
    expect_equal(result$function_type, 
                 c("numeric", "S3 method", "S3 function", 
                   "S3 method", "S4 method, S4 generic"))
  }
})

test_that("S4 generics are correctly processed from exportMethods", {
  nsInfo <- list(
    exports = character(),
    S3methods = NULL,
    exportMethods = c("foo", "bar", "baz") # S4 generics
  )
  
  func_method <- character()
  class <- character()
  function_types <- character()
  
  s4_methods_raw <- nsInfo$exportMethods
  
  if (is.character(s4_methods_raw)) {
    s4_generics <- unique(s4_methods_raw)
    func_method <- c(func_method, s4_generics)
    class <- c(class, rep(NA, length(s4_generics)))
    function_types <- c(function_types, rep("S4 generic", length(s4_generics)))
  }
  
  expect_equal(func_method, c("foo", "bar", "baz"))
  expect_equal(class, rep(NA_character_, 3))
  expect_equal(function_types, rep("S4 generic", 3))
})

test_that("S4 methods are correctly processed from exportMethods", {
  nsInfo <- list(
    exports = character(),
    S3methods = NULL,
    exportMethods = list(
      c("foo", "MyClass"),
      c("bar", "YourClass"),
      c("baz", NA), # Should be filtered out
      c("qux") # Invalid (length < 2)
    )
  )
  
  func_method <- character()
  class <- character()
  function_types <- character()
  
  s4_methods_raw <- nsInfo$exportMethods
  
  if (is.list(s4_methods_raw)) {
    valid_s4_methods <- Filter(function(x) is.character(x) && length(x) >= 2 && !is.na(x[[2]]), s4_methods_raw)
    
    if (length(valid_s4_methods) > 0) {
      s4_func_names <- sapply(valid_s4_methods, `[[`, 1)
      s4_classes <- sapply(valid_s4_methods, `[[`, 2)
      
      s4_df <- unique(data.frame(func = s4_func_names, class = s4_classes, stringsAsFactors = FALSE))
      
      func_method <- c(func_method, s4_df$func)
      class <- c(class, s4_df$class)
      function_types <- c(function_types, rep("S4 function", nrow(s4_df)))
    }
  }
  
  expect_equal(func_method, c("foo", "bar"))
  expect_equal(class, c("MyClass", "YourClass"))
  expect_equal(function_types, rep("S4 function", 2))
})



test_that("classify_function_body handles regular function", {
  # Mock input row
  row <- list(
    exported_function = "my_func",
    class = NA,
    function_type = NA,
    function_body = NA,
    where = "test.package"
  )
  package_name <- "test.package"
  
  # Stub dependencies
  mockery::stub(classify_function_body, "get", function(name, envir) {
    function(x) x + 1  # mock function
  })
  mockery::stub(classify_function_body, "methods::isGeneric", function(name) FALSE)
  mockery::stub(classify_function_body, "get_s3_method", function(generic, class, package) NULL)
  mockery::stub(classify_function_body, "check_ggproto", function(value) FALSE)
  mockery::stub(classify_function_body, "function_is_ggproto", function(value) FALSE)
  
  result <- classify_function_body(row, package_name)
  
  expect_equal(result$function_type, "regular")
  expect_equal(result$function_body, "x + 1")
})


test_that("classify_function_body handles S3 method with R6 class generator", {
  row <- list(
    exported_function = "my_s3_func",
    class = "MyClass",
    function_type = "S3 function",
    function_body = NA,
    where = "test.package"
  )
  package_name <- "test.package"
  
  # Mock S3 method return
  mock_func <- function(x) x
  mock_s3 <- list(
    func = mock_func,
    has_r6_class = FALSE,
    has_r6_generator = TRUE
  )
  
  mockery::stub(classify_function_body, "get_s3_method", function(generic, class, package) mock_s3)
  mockery::stub(classify_function_body, "methods::isGeneric", function(name) FALSE)
  
  result <- classify_function_body(row, package_name)
  
  expect_equal(result$class, "MyClass")
  expect_equal(result$function_type, "S3 function, R6 class generator")
  expect_true(grepl("function", result$function_body))
})


test_that("classify_function_body handles S7 generic with methods", {
  row <- list(
    exported_function = "my_s7_generic",
    class = NA,
    function_type = "S7 generic",
    function_body = NA,
    where = "test.package"
  )
  package_name <- "test.package"
  
  # Mock S7 generic object
  mock_s7_generic <- structure(list(), class = "S7_generic")
  
  # Mock S7 methods
  mock_method1 <- function(x) { x }
  mock_method2 <- function(x) { x * 2 }
  
  # Stub get to return the S7 generic object
  mockery::stub(classify_function_body, "get", function(name, envir) mock_s7_generic)
  
  # Stub S7::methods to return a list of mock methods
  mockery::stub(classify_function_body, "get", function(name, envir) {
    if (name == "methods" && identical(envir, asNamespace("S7"))) {
      function(obj) list(mock_method1, mock_method2)
    } else {
      mock_s7_generic
    }
  })
  
  result <- classify_function_body(row, package_name)
  
  expect_equal(result$class, NA)
  expect_equal(result$function_type, "S7 generic")
  expect_true(grepl("x \\* 2", result$function_body))
})


test_that("classify_function_body handles S7 constructor", {
  row <- list(
    exported_function = "new_s7",
    class = NA,
    function_type = NA,
    function_body = NA,
    where = "test.package"
  )
  package_name <- "test.package"
  
  mock_constructor <- function() {
    S7::new("MyClass")
  }
  
  mockery::stub(classify_function_body, "get", function(name, envir) mock_constructor)
  mockery::stub(classify_function_body, "methods::isGeneric", function(name) FALSE)
  mockery::stub(classify_function_body, "get_s3_method", function(generic, class, package) NULL)
  
  result <- classify_function_body(row, package_name)
  
  expect_equal(result$class, NA)
  expect_equal(result$function_type, "S7 constructor")
  expect_true(grepl("S7::new", result$function_body))
})


test_that("classify_function_body handles S4 generic and method", {
  row <- list(
    exported_function = "my_s4_func",
    class = NA,
    function_type = NA,
    function_body = NA,
    where = "test.package"
  )
  package_name <- "test.package"
  
  mockery::stub(classify_function_body, "methods::isGeneric", function(name) TRUE)
  mockery::stub(classify_function_body, "get_all_s4_methods", function(name) {
    list(
      is_generic = TRUE,
      has_methods = TRUE,
      bodies = c("method1_body", "method2_body")
    )
  })
  
  result <- classify_function_body(row, package_name)
  
  expect_equal(result$class, NA)
  expect_equal(result$function_type, "S4 method, S4 generic")
  expect_true(grepl("method1_body", result$function_body))
})


test_that("classify_function_body handles ggproto object", {
  row <- list(
    exported_function = "my_ggproto",
    class = NA,
    function_type = NA,
    function_body = NA,
    where = "test.package"
  )
  package_name <- "test.package"
  
  mockery::stub(classify_function_body, "get", function(name, envir) "ggproto_object")
  mockery::stub(classify_function_body, "check_ggproto", function(value) TRUE)
  mockery::stub(classify_function_body, "function_is_ggproto", function(value) TRUE)
  mockery::stub(classify_function_body, "extract_ggproto_methods", function(value) {
    quote({ print("ggproto method") })
  })
  
  result <- classify_function_body(row, package_name)
  
  expect_equal(result$class, NA)
  expect_equal(result$function_type, "ggproto")
  expect_true(grepl("ggproto method", result$function_body))
})


test_that("classify_function_body handles R6 class generator", {
  row <- list(
    exported_function = "my_r6_class",
    class = NA,
    function_type = NA,
    function_body = NA,
    where = "test.package"
  )
  package_name <- "test.package"
  
  mock_r6 <- structure(list(), class = "R6ClassGenerator")
  
  mockery::stub(classify_function_body, "get", function(name, envir) mock_r6)
  mockery::stub(classify_function_body, "check_ggproto", function(value) FALSE)
  mockery::stub(classify_function_body, "get_r6_methods_details", function(value) "R6 method details")
  
  result <- classify_function_body(row, package_name)
  
  expect_equal(result$class, NA)
  expect_equal(result$function_type, "R6 Class Generator")
  expect_equal(result$function_body, "R6 method details")
})

# Define a mock ggproto object
mock_ggproto <- list(
  method1 = function() { print("Method 1") },
  method2 = function() { print("Method 2") },
  non_function = "Not a function"
)

# Test the extract_ggproto_methods function
test_that("extract_ggproto_methods extracts methods correctly", {
  # Mock the ggproto object
  mock_obj <- mock_ggproto
  
  # Call the function with the mock object
  result <- extract_ggproto_methods(mock_obj)
  
  # Expected result
  expected_result <- paste(
    paste(deparse(body(mock_obj$method1)), collapse = "\n"),
    paste(deparse(body(mock_obj$method2)), collapse = "\n"),
    sep = "\n\n"
  )
  
  # Check if the result matches the expected result
  expect_equal(result, expected_result)
})

test_that("preprocess_func_full_name works for usual S3 functions", {
  func_full_name <- "dplyr::filter_.tbl_df"
  result <- preprocess_func_full_name(func_full_name)
  expect_equal(result$package, "dplyr")
  expect_equal(result$generic, "filter_")
  expect_equal(result$class, "tbl_df")
})

test_that("preprocess_func_full_name works for specific S3 functions with :::", {
  result <- preprocess_func_full_name("dplyr::filter_bullets.dplyr:::filter_incompatible_size")
  expect_equal(result$package, "dplyr")
  expect_equal(result$generic, "filter_bullets")
  expect_equal(result$class, "dplyr:::filter_incompatible_size")
})

test_that("preprocess_func_full_name works for specific S3 functions with multiple :::", {
  result <- preprocess_func_full_name("dplyr::mutate_bullets.dplyr:::mutate_constant_recycle_error")
  expect_equal(result$package, "dplyr")
  expect_equal(result$generic, "mutate_bullets")
  expect_equal(result$class, "dplyr:::mutate_constant_recycle_error")
})

test_that("preprocess_func_full_name works for usual S3 functions without :::", {
  result <- preprocess_func_full_name("dplyr::inner_join::data.frame")
  expect_equal(result$package, "dplyr")
  expect_equal(result$generic, "inner_join")
  expect_equal(result$class, "")
})

test_that("preprocess_func_full_name works for usual S3 functions with single dot", {
  result <- preprocess_func_full_name("dplyr::mutate_::tbl_df")
  expect_equal(result$package, "dplyr")
  expect_equal(result$generic, "mutate_")
  expect_equal(result$class, "")
})


test_that("preprocess_func_full_name works for functions without namespace qualifier", {
  func_full_name <- "mean.default"
  result <- preprocess_func_full_name(func_full_name)
  expect_null(result$package)
  expect_null(result$generic) # Because generic is not set in this branch
  expect_equal(result$generic_clean, "") # generic is NULL, so clean should be ""
  expect_null(result$class) # class is not set in this branch
})


test_that("preprocess_func_full_name wraps infix operators in backticks if not already wrapped", {
  func_full_name <- "%/%"
  result <- preprocess_func_full_name(func_full_name)
  expect_null(result$package)
  expect_equal(result$generic, "`%/%`")
  expect_equal(result$generic_clean, "%/%")
  expect_equal(result$class, "")
})

test_that("preprocess_func_full_name keeps already backtick-wrapped infix operators unchanged", {
  func_full_name <- "`%in%`"
  result <- preprocess_func_full_name(func_full_name)
  expect_null(result$package)
  expect_equal(result$generic, "`%in%`")
  expect_equal(result$generic_clean, "%in%")
  expect_equal(result$class, "")
})


test_that("preprocess_func_full_name handles double-dot forms like ..1", {
  func_full_name <- "..1"
  result <- preprocess_func_full_name(func_full_name)
  expect_null(result$package)
  expect_equal(result$generic, "..1")
  expect_equal(result$generic_clean, "..1")
  expect_equal(result$class, "..1")
})

test_that("preprocess_func_full_name handles exactly ..", {
  func_full_name <- ".."
  result <- preprocess_func_full_name(func_full_name)
  expect_null(result$package)
  expect_equal(result$generic, "..")
  expect_equal(result$generic_clean, "..")
  expect_equal(result$class, "..")
})

test_that("generic is adjusted correctly if it contains '::'", {
  result <- preprocess_func_full_name("dplyr::filter_bullets.dplyr:::filter_incompatible_size")
  expect_equal(result$package, "dplyr")
  expect_equal(result$generic, "filter_bullets")  # Test for adjusted generic
  expect_equal(result$class, "dplyr:::filter_incompatible_size")
})


test_that("get_exports returns fallback tibble when R folder is missing", {
  # Mock package path
  pkg_source_path <- "/fake/path/to/package"
  package_name <- "testpkg"
  
  # Stub contains_r_folder to return FALSE
  mockery::stub(get_exports, "contains_r_folder", function(path) FALSE)
  
  # Stub extract_package_name to return mocked package name
  mockery::stub(get_exports, "extract_package_name", function(path) package_name)
  
  # Run the function
  result <- get_exports(pkg_source_path)
  
  # Expected package name from path
  expected_pkg_name <- basename(pkg_source_path)
  
  # Check structure and values
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_equal(result$exported_function, NA)
  expect_equal(result$class, NA)
  expect_equal(result$function_type, NA)
  expect_equal(result$function_body, "No R folder found in the package source path")
 
})

test_that("extract_exported_function_info builds initial result tibble with mocked namespace info", {
  pkg_source_path <- "/fake/path/testpkg"
  package_name <- "testpkg"
  
  # Mock namespace info
  nsInfo <- list(
    exports = c("fun1", "fun2"),
    S3methods = matrix(c("print", "summary", "MyClass", "MyClass"), ncol = 2),
    exportMethods = list(c("show", "MyClass"), c("plot", "MyClass"))
  )
  
  # Stub parseNamespaceFile to return mocked nsInfo
  mockery::stub(extract_exported_function_info, "parseNamespaceFile", function(pkg, lib, mustExist) nsInfo)
  
  # Stub getExportedValue to return mock objects
  mockery::stub(extract_exported_function_info, "getExportedValue", function(pkg, name) {
    if (name == "fun1") {
      structure(list(), class = "S7_generic")
    } else if (name == "fun2") {
      function(x) x  # regular function
    } else {
      NULL
    }
  })
  
  # Stub getNamespaceExports to return fallback exports (not used here)
  mockery::stub(extract_exported_function_info, "getNamespaceExports", function(pkg) character(0))
  
  result <- extract_exported_function_info(pkg_source_path, package_name)
  
  expect_s3_class(result, "tbl_df")
  expect_true(all(c("exported_function", "class", "function_type", "function_body", "where") %in% names(result)))
  expect_equal(result$where, rep(package_name, nrow(result)))
  expect_true("fun1" %in% result$exported_function)
  expect_true("fun2" %in% result$exported_function)
  expect_true("print" %in% result$exported_function)
  expect_true("show" %in% result$exported_function)
  expect_true("S7 generic" %in% result$function_type)
  expect_true("S3 method" %in% result$function_type)
  expect_true("S4 function" %in% result$function_type)
  expect_true("regular function" %in% result$function_type)
})


test_that("returns NULL when getExportedValue returns NULL", {
  pkg_source_path <- "/fake/path/testpkg"
  package_name <- "testpkg"
  
  nsInfo <- list(exports = c("fun1"))
  
  mockery::stub(extract_exported_function_info, "parseNamespaceFile", function(...) nsInfo)
  mockery::stub(extract_exported_function_info, "getExportedValue", function(...) NULL)
  mockery::stub(extract_exported_function_info, "getNamespaceExports", function(...) character(0))
  
  result <- extract_exported_function_info(pkg_source_path, package_name)
  
  expect_equal(nrow(result), 1)
})


test_that("detects S7 class", {
  pkg_source_path <- "/fake/path/testpkg"
  package_name <- "testpkg"
  
  nsInfo <- list(exports = c("fun1"))
  
  mockery::stub(extract_exported_function_info, "parseNamespaceFile", function(...) nsInfo)
  mockery::stub(extract_exported_function_info, "getExportedValue", function(...) structure(list(), class = "S7_class"))
  mockery::stub(extract_exported_function_info, "getNamespaceExports", function(...) character(0))
  
  result <- extract_exported_function_info(pkg_source_path, package_name)
  
  expect_equal(result$function_type, "S7 class")
})


test_that("detects S7 constructor from function body", {
  pkg_source_path <- "/fake/path/testpkg"
  package_name <- "testpkg"
  
  nsInfo <- list(exports = c("fun1"))
  
  mock_fun <- function(x) {
    S7::new("MyClass")
  }
  
  mockery::stub(extract_exported_function_info, "parseNamespaceFile", function(...) nsInfo)
  mockery::stub(extract_exported_function_info, "getExportedValue", function(...) mock_fun)
  mockery::stub(extract_exported_function_info, "getNamespaceExports", function(...) character(0))
  
  result <- extract_exported_function_info(pkg_source_path, package_name)
  
  expect_equal(result$function_type, "S7 constructor")
})


test_that("handles NA in class column", {
  pkg_source_path <- "/fake/path/testpkg"
  package_name <- "testpkg"
  
  nsInfo <- list(exports = c("fun1"))
  
  mockery::stub(extract_exported_function_info, "parseNamespaceFile", function(...) nsInfo)
  mockery::stub(extract_exported_function_info, "getExportedValue", function(...) structure(list(), class = "S7_generic"))
  mockery::stub(extract_exported_function_info, "getNamespaceExports", function(...) character(0))
  
  result <- extract_exported_function_info(pkg_source_path, package_name)
  
  expect_true(is.na(result$class[1]))
})


test_that("detects S4 generics from exportMethods", {
  pkg_source_path <- "/fake/path/testpkg"
  package_name <- "testpkg"
  
  nsInfo <- list(
    exports = character(0),
    exportMethods = c("show", "plot")
  )
  
  mockery::stub(extract_exported_function_info, "parseNamespaceFile", function(...) nsInfo)
  mockery::stub(extract_exported_function_info, "getNamespaceExports", function(...) character(0))
  
  result <- extract_exported_function_info(pkg_source_path, package_name)
  
  expect_equal(sort(result$function_type), c("S4 generic", "S4 generic"))
  expect_true(all(is.na(result$class)))
})
