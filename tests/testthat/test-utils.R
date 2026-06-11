test_that("get package description works correctly", {
  
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  withr::local_options(list(repos = r))
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz", 
                    package = "risk.assessr")
 
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  if (package_installed == TRUE ) {	
    pkg_desc <- get_pkg_desc(pkg_source_path)
    
    expect_identical(length(pkg_desc), 17L)
    
    expect_true(checkmate::check_list(pkg_desc, 
                                            any.missing = FALSE)
    )
    
    expect_true(checkmate::check_list(pkg_desc, 
                                      types = "character")
    )
    
  }
  
})


test_that("get_risk_metadata returns correct metadata with executor", {
  # Mocked values
  fake_time <- "2025-09-30 12:00:00"
  fake_sysinfo <- list(
    sysname = "Linux",
    version = "#1 SMP Debian",
    release = "5.10.0-8-amd64",
    machine = "x86_64"
  )
  
  # Stub system functions
  mockery::stub(get_risk_metadata, "Sys.time", function() fake_time)
  mockery::stub(get_risk_metadata, "Sys.info", function() fake_sysinfo)
  
  result <- get_risk_metadata(executor = "edward")
  
  expect_equal(result$datetime, fake_time)
  expect_equal(result$executor, "edward")
  expect_equal(result$info$sys, fake_sysinfo)
})

test_that("get_risk_metadata returns correct metadata without executor", {
  # Mocked values
  fake_time <- "2025-09-30 12:00:00"
  fake_user <- "mock_user"
  fake_sysinfo <- list(
    sysname = "Darwin",
    version = "22.6.0",
    release = "macOS",
    machine = "arm64"
  )
  
  # Stub system functions
  mockery::stub(get_risk_metadata, "Sys.time", function() fake_time)
  mockery::stub(get_risk_metadata, "Sys.getenv", function(var) {
    if (var == "USER") return(fake_user)
  })
  mockery::stub(get_risk_metadata, "Sys.info", function() fake_sysinfo)
  
  result <- get_risk_metadata()
  
  expect_equal(result$datetime, fake_time)
  expect_equal(result$executor, fake_user)
  expect_equal(result$info$sys, fake_sysinfo)
})


test_that("get_result_path returns correct path for check.rds", {
  # Stub basename and file.path
  mockery::stub(get_result_path, "basename", function(path) "mockpkg")
  mockery::stub(get_result_path, "file.path", function(out_dir, filename) {
    paste0(out_dir, "/", filename)
  })
  
  result <- get_result_path("some/fake/path", ext = "check.rds")
  expect_equal(result, "some/fake/path/mockpkg.check.rds")
})

test_that("get_result_path returns correct path for covr.rds", {
  mockery::stub(get_result_path, "basename", function(path) "mockpkg")
  mockery::stub(get_result_path, "file.path", function(out_dir, filename) {
    paste0(out_dir, "/", filename)
  })
  
  result <- get_result_path("another/path", ext = "covr.rds")
  expect_equal(result, "another/path/mockpkg.covr.rds")
})

test_that("get_result_path defaults to check.rds when ext is not specified", {
  mockery::stub(get_result_path, "basename", function(path) "mockpkg")
  mockery::stub(get_result_path, "file.path", function(out_dir, filename) {
    paste0(out_dir, "/", filename)
  })
  
  result <- get_result_path("default/path")
  expect_equal(result, "default/path/mockpkg.check.rds")
})

test_that("extract_short_path handles forward slashes", {
  p <- "C:/Users/yyy/AppData/Local/Temp/RtmpXXXX/MASS/R/add.R"
  expect_equal(extract_short_path(p), "R/add.R")
})

test_that("extract_short_path handles backslashes", {
  p <- "C:\\Users\\yyy\\AppData\\Local\\Temp\\RtmpXXXX\\MASS\\R\\add.R"
  expect_equal(extract_short_path(p), "R/add.R")
})

test_that("extract_short_path handles mixed separators", {
  p <- "C:/Users\\yyy/AppData\\Local/Temp/RtmpXXXX/MASS/R/add.R"
  expect_equal(extract_short_path(p), "R/add.R")
})

test_that("extract_short_path returns last two components for general paths", {
  p <- "/opt/projects/pkgname/src/module/file.ext"
  expect_equal(extract_short_path(p), "module/file.ext")
})

test_that("extract_short_path handles single-component paths", {
  p <- "file.ext"
  expect_equal(extract_short_path(p), "file.ext")
})

test_that("extract_short_path handles empty string", {
  p <- ""
  # strsplit("", "[/\\\\]") returns character(0), function returns ""
  expect_equal(extract_short_path(p), "")
})

test_that("extract_short_path handles trailing separator", {
  # Trailing separator creates an empty last component
  p1 <- "dir/subdir/"
  expect_equal(extract_short_path(p1), "subdir/")  # last component is ""
  
  p2 <- "dir\\subdir\\"
  expect_equal(extract_short_path(p2), "subdir/")  # unified separator in output
})

test_that("extract_short_path works over a vector via vapply", {
  paths <- c(
    "C:/A/B/C/D.R",
    "C:\\A\\B\\C\\E.R",
    "/A/B/C/F.R",
    "file.ext"
  )
  out <- vapply(paths, extract_short_path, FUN.VALUE = character(1))
  expect_equal(unname(out), c("C/D.R", "C/E.R", "C/F.R", "file.ext"))
})

test_that("extract_short_path behavior for NA (optional policy)", {
  # If you want NA-in -> NA-out, you can wrap it:
  safe_extract <- function(x) if (is.na(x)) NA_character_ else extract_short_path(x)
  expect_true(is.na(safe_extract(NA_character_)))
})

test_that("normalize_code_script_key ignores hyphen, underscore, and case", {
  expect_equal(
    normalize_code_script_key(c("R/geom_alluvium.R", "R/geom-alluvium.r")),
    c("geomalluvium", "geomalluvium")
  )
  expect_true(is.na(normalize_code_script_key(NA_character_)))
})

test_that("camel_to_kebab converts ggproto-style names", {
  expect_equal(camel_to_kebab("GeomAlluvium"), "geom-alluvium")
  expect_equal(camel_to_kebab("StatFlow"), "stat-flow")
})

test_that("build_r_script_lookup maps normalized keys to actual R paths", {
  mockery::stub(build_r_script_lookup, "dir.exists", function(path) TRUE)
  mockery::stub(build_r_script_lookup, "list.files", function(path, pattern, full.names) {
    "geom-alluvium.r"
  })
  
  lookup <- build_r_script_lookup("mock/path")
  expect_equal(unname(lookup["geomalluvium"]), "R/geom-alluvium.r")
})
