# normalize_data

mock_data <- list(
  pkg_name = "mockpkg",
  pkg_version = "1.0.0",
  dependencies = list(
    imports = list(rprojroot = "2.0.4")
  ),
  author = list(
    maintainer = "Mock Maintainer",
    funder = "No package foundation found",
    authors = c("Mock Maintainer")
  ),
  license_name = "MIT + file LICENSE",
  rev_deps = list("pkg1", "pkg2", "pkg3"),
  has_bug_reports_url = 1,
  has_examples = 1,
  has_maintainer = 1,
  has_source_control = 1,
  has_vignettes = 1,
  has_news = 1,
  has_website = 1,
  check = 0,   
  version_info = list(
    all_versions = list(  
      list(version = "0.1", date = 17314),
      list(version = "0.9.0", date = 18581),
      list(version = "1.0.0", date = 18609)
    ),
    last_version = list(version = "1.0.0", date = 18609)
  ),
  download = list(
    total_download = 10000,
    last_month_download = 50000
  ),
  sysname = "Windows",
  machine = "x86-64",
  release = "10 x64",
  date_time = "2025-06-04 11:00:26",
  host = list(
    github_links = "https://github.com/mock/mockpkg",
    cran_links = "https://cran.r-project.org/src/contrib/mockpkg_1.0.0.tar.gz",
    bioconductor_links = NULL,
    internal_links = NULL
  ),
  github_data = list(
    created_at = "2016-07-19T14:47:19Z",
    stars = 100,
    forks = 10,
    recent_commits_count = 5
  ),
  covr = 0.9
)

# normalize_data

test_that("normalize_data works correctly", {
  normalized <- normalize_data(mock_data)
  expect_equal(normalized$name, "mockpkg")
  expect_equal(normalized$version, "1.0.0")
  expect_equal(normalized$dependencies_count, 1)
  expect_equal(normalized$license, "MIT")
  expect_equal(normalized$reverse_dependencies_count, 3)
  expect_equal(normalized$code_coverage, 0.9)
  expect_equal(normalized$last_month_download, 50000)
})

test_that("documentation_score = 7 when all flags are 1 with non null key value", {
  results <- list(
    pkg_name = "mockpkg",
    pkg_version = "1.0.0",
    license_name = "MIT + file LICENSE",
    rev_deps = list("pkg1"),
    has_bug_reports_url = "https",
    has_examples = 1,
    has_maintainer = 'john doe',
    has_source_control = 1,
    has_vignettes = 1,
    has_website = "https",
    has_news = 1,
    version_info = list(
      all_versions = list(
        list(version = "0.9.0"),
        list(version = "1.0.0")
      ),
      last_version = "1.0.0"
    )
  )
  flat <- normalize_data(results)
  out <- extract_risk_inputs(flat)
  expect_equal(out$documentation_score, 7)
})

test_that("documentation_score = 7 when all flags are 1", {
  results <- list(
    pkg_name = "mockpkg",
    pkg_version = "1.0.0",
    license_name = "MIT + file LICENSE",
    rev_deps = list("pkg1"),
    has_bug_reports_url = 1,
    has_examples = 1,
    has_maintainer = 1,
    has_source_control = 1,
    has_vignettes = 1,
    has_website = 1,
    has_news = 1,
    version_info = list(
      all_versions = list(
        list(version = "0.9.0"),
        list(version = "1.0.0")
      ),
      last_version = "1.0.0"
    )
  )
  flat <- normalize_data(results)
  out <- extract_risk_inputs(flat)
  expect_equal(out$documentation_score, 7)
})

test_that("documentation_score sums only the 1s when some flags are 0", {
  results <- list(
    pkg_name = "mockpkg",
    pkg_version = "1.0.0",
    has_bug_reports_url = 1,
    has_examples = 0,
    has_maintainer = 1,
    has_source_control = 0,
    has_vignettes = 1,
    has_website = 0,
    has_news = 1
  )
  flat <- normalize_data(results)
  out <- extract_risk_inputs(flat)
  expect_equal(out$documentation_score, 4)
})

test_that("missing flags are treated as 0 by normalize_data defaults", {
  results <- list(
    pkg_name = "mockpkg",
    pkg_version = "1.0.0",
    has_bug_reports_url = 1,
    has_maintainer = 1,
    has_source_control = 1,
    has_vignettes = 1,
    has_news = 1
  )
  flat <- normalize_data(results)
  out <- extract_risk_inputs(flat)
  expect_equal(out$documentation_score, 5)
})

test_that("NA flags are ignored by sum(..., na.rm = TRUE)", {
  results <- list(
    pkg_name = "mockpkg",
    pkg_version = "1.0.0",
    has_bug_reports_url = 1,
    has_examples = NA,  
    has_maintainer = 1,
    has_source_control = NA,  
    has_vignettes = 1,
    has_website = 1,
    has_news = 1
  )
  flat <- normalize_data(results)
  out <- extract_risk_inputs(flat)
  expect_equal(out$documentation_score, 5)
})

test_that("later_version counts versions strictly after current when present", {
  results <- list(
    pkg_name = "mockpkg",
    pkg_version = "1.0.0",
    version_info = list(
      all_versions = list(
        list(version = "0.8.0"),
        list(version = "1.0.0"),
        list(version = "1.2.0"),
        list(version = "2.0.0")
      ),
      last_version = "2.0.0"
    )
  )
  flat <- normalize_data(results)
  out <- extract_risk_inputs(flat)
  expect_equal(out$later_version, 2)
})

test_that("later_version = 0 when current version not in all_versions", {
  results <- list(
    pkg_name = "mockpkg",
    pkg_version = "9.9.9",  # not present
    version_info = list(
      all_versions = list(
        list(version = "0.8.0"),
        list(version = "1.0.0")
      ),
      last_version = "1.0.0"
    )
  )
  flat <- normalize_data(results)
  out <- extract_risk_inputs(flat)
  expect_equal(out$later_version, 0)
})

test_that("later_version is NA when all_versions is NULL", {
  results <- list(
    pkg_name = "mockpkg",
    pkg_version = "1.0.0",
    version_info = list(
      all_versions = NULL,
      last_version = "1.0.0"
    )
  )
  flat <- normalize_data(results)
  out <- extract_risk_inputs(flat)
  expect_true(is.na(out$later_version))
})

test_that("extract_risk_inputs preserves original normalized fields", {
  results <- list(
    pkg_name = "mockpkg",
    pkg_version = "1.0.0",
    has_bug_reports_url = 1
  )
  flat <- normalize_data(results)
  out <- extract_risk_inputs(flat)
  expect_equal(out$name, "mockpkg")
  expect_equal(out$version, "1.0.0")
  expect_true(all(c("documentation_score", "later_version") %in% names(out)))
})


# extract_risk_inputs

test_that("extract_risk_inputs works correctly", {
  normalized <- normalize_data(mock_data)
  extracted <- extract_risk_inputs(normalized)
  
  expect_equal(extracted$dependencies_count, 1)
  expect_equal(extracted$reverse_dependencies_count, 3)
  expect_equal(extracted$documentation_score, 7)
  expect_equal(extracted$license, "MIT")
  expect_equal(extracted$cmd_check, 0)
})

mock_data <- list(
  pkg_name = "mockpkg",
  pkg_version = "1.0.0",
  dependencies = list(
    imports = list(rprojroot = "2.0.4")
  ),
  author = list(
    maintainer = "Mock Maintainer",
    funder = "No package foundation found",
    authors = c("Mock Maintainer")
  ),
  license_name = "MIT + file LICENSE",
  rev_deps = list("pkg1", "pkg2", "pkg3"),
  has_bug_reports_url = 1,
  has_examples = 1,
  has_maintainer = 1,
  has_source_control = 1,
  has_vignettes = 1,
  has_news = 1,
  has_website = 1,
  check = 0,   
  version_info = list(
    all_versions = list(  
      list(version = "0.1", date = 17314),
      list(version = "0.9.0", date = 18581),
      list(version = "1.0.0", date = 18609)
    ),
    last_version = list(version = "1.0.0", date = 18609)
  ),
  download = list(
    total_download = 10000,
    last_month_download = 50000
  ),
  sysname = "Windows",
  machine = "x86-64",
  release = "10 x64",
  date_time = "2025-06-04 11:00:26",
  host = list(
    github_links = "https://github.com/mock/mockpkg",
    cran_links = "https://cran.r-project.org/src/contrib/mockpkg_1.0.0.tar.gz",
    bioconductor_links = NULL,
    internal_links = NULL
  ),
  github_data = list(
    created_at = "2016-07-19T14:47:19Z",
    stars = 100,
    forks = 10,
    recent_commits_count = 5
  ),
  covr = 0.9
)


test_that("extract_risk_inputs works correctly", {
  normalized <- normalize_data(mock_data)
  extracted <- extract_risk_inputs(normalized)
  
  expect_equal(extracted$dependencies_count, 1)
  expect_equal(extracted$reverse_dependencies_count, 3)
  expect_equal(extracted$documentation_score, 7)
  expect_equal(extracted$license, "MIT")
  expect_equal(extracted$cmd_check, 0)
})



# get_risk_definition

mock_risk_config <- list(
  list(
    label = "mock test",
    id = "mock_id",
    key = "mock_key",
    thresholds = list(list(level = "low", max = 10))
  )
)

test_that("returns R object when option is a valid list", {

  withr::local_options(list(risk.assessr.risk_definition = mock_risk_config))
  result <- get_risk_definition()
  expect_equal(result, mock_risk_config)
})

test_that("returns parsed list from valid JSON file path", {
  tmpfile <- tempfile(fileext = ".json")
  json_txt <- jsonlite::toJSON(mock_risk_config, auto_unbox = TRUE, pretty = TRUE)
  writeLines(json_txt, tmpfile)
  withr::local_options(list(risk.assessr.risk_definition = tmpfile))

  result <- get_risk_definition()

  expect_equal(
    jsonlite::fromJSON(jsonlite::toJSON(result, auto_unbox = TRUE)),
    jsonlite::fromJSON(jsonlite::toJSON(mock_risk_config, auto_unbox = TRUE))
  )
  unlink(tmpfile)
})


test_that("warns and falls back when JSON path is invalid or file doesn't exist", {
  withr::local_options(list(risk.assessr.risk_definition = "non_existent_file.json"))

  result <- get_risk_definition()
  expect_true(is.list(result))
})

test_that("falls back when JSON is valid but not a list", {
  tmpfile <- tempfile(fileext = ".json")
  writeLines('{"this": "is not a list of configs"}', tmpfile)
  withr::local_options(list(risk.assessr.risk_definition = tmpfile))

  result <- get_risk_definition()
  expect_true(is.list(result))
  unlink(tmpfile)
})


test_that("uses bundled JSON if no option is set", {
  withr::local_options(list(risk.assessr.risk_definition = NULL))
  result <- get_risk_definition()
  expect_true(is.list(result))
})

test_that("errors if bundled JSON is missing or malformed", {

  withr::local_options(list(risk.assessr.risk_definition = NULL))
  mockery::stub(get_risk_definition, "system.file", function(...) tempfile())
  expect_error(
    get_risk_definition(),
    "No valid risk definition found in options or package."
  )
})


# Compute_risk

test_that("compute_risk works for numeric thresholds", {

  risk_def <- list(
    thresholds = list(
      list(level = "low", max = 10),
      list(level = "medium", max = 20),
      list(level = "high", max = NULL)
    )
  )

  expect_equal(compute_risk(5, risk_def), "low")
  expect_equal(compute_risk(15, risk_def), "medium")
  expect_equal(compute_risk(30, risk_def), "high")
})

test_that("compute_risk works for categorical thresholds", {
  risk_def <- list(
    thresholds = list(
      list(level = "high", values = c("AGPL", "GPL")),
      list(level = "low", values = c("MIT", "APACHE"))
    ),
    default = "high"
  )

  expect_equal(compute_risk("MIT", risk_def), "low")
  expect_equal(compute_risk("GPL", risk_def), "high")
  expect_equal(compute_risk("UNKNOWN", risk_def), "high")
})

test_that("compute_risk handles NULL value with no default", {
  risk_def <- list(
    thresholds = list(
      list(level = "low", max = 10)
    )
  )
  expect_equal(compute_risk(NULL, risk_def), "unknown")
})

test_that("compute_risk is case-insensitive for categorical values", {
  risk_def <- list(
    thresholds = list(
      list(level = "low", values = c("MIT", "APACHE"))
    )
  )
  expect_equal(compute_risk("mit", risk_def), "low")
  expect_equal(compute_risk("Apache", risk_def), "low")
})


test_that("compute_risk handles vector inputs with highest risk wins by level rank", {
  
  risk_def <- list(
    thresholds = list(
      list(level = "low", values = c("MIT", "APACHE")),
      list(level = "high", values = c("AGPL", "GPL"))
    ))

  expect_equal(compute_risk(c("GPL"), risk_def), "high")
  expect_equal(compute_risk(c("MIT"), risk_def), "low")
  expect_equal(compute_risk(c("BSD"), risk_def), "unknown")
})


test_that("compute_risk works correctly for all configured metrics", {
  withr::local_options(list(risk.assessr.risk_definition = NULL))
  
  # Helper
  get_risk <- function(key) {
    config <- get_risk_definition()
    idx <- which(sapply(config, function(x) x$key == key))
    config[[idx]]
  }

  expect_equal(compute_risk(10, get_risk("dependencies_count")), "low")
  expect_equal(compute_risk(5, get_risk("dependencies_count")), "low")
  expect_equal(compute_risk(30, get_risk("dependencies_count")), "medium")
  expect_equal(compute_risk(100, get_risk("dependencies_count")), "high")

  expect_equal(compute_risk(1, get_risk("later_version")), "low")
  expect_equal(compute_risk(5, get_risk("later_version")), "high")

  expect_equal(compute_risk(0.5, get_risk("code_coverage")), "high")
  expect_equal(compute_risk(0.7, get_risk("code_coverage")), "medium")
  expect_equal(compute_risk(0.95, get_risk("code_coverage")), "low")

  expect_equal(compute_risk(30000, get_risk("total_download")), "high")
  expect_equal(compute_risk(3500001, get_risk("total_download")), "medium")
  expect_equal(compute_risk(50000001, get_risk("total_download")), "low")

  expect_equal(compute_risk("MIT", get_risk("license")), "low")
  expect_equal(compute_risk("GPL", get_risk("license")), "medium")
  expect_equal(compute_risk("SSPL", get_risk("license")), "high")
  expect_equal(compute_risk(NULL, get_risk("license")), "unknown")

  expect_equal(compute_risk(2, get_risk("reverse_dependencies_count")), "high")
  expect_equal(compute_risk(10, get_risk("reverse_dependencies_count")), "medium")
  expect_equal(compute_risk(100, get_risk("reverse_dependencies_count")), "low")
  
  expect_equal(compute_risk(7, get_risk("documentation_score")), "low")
  expect_equal(compute_risk(1, get_risk("documentation_score")), "high")
  expect_equal(compute_risk(2, get_risk("documentation_score")), "high")
  expect_equal(compute_risk(5, get_risk("documentation_score")), "medium")
  expect_equal(compute_risk(6, get_risk("documentation_score")), "medium")
  expect_equal(compute_risk(4, get_risk("documentation_score")), "medium")
  
  expect_equal(compute_risk(0, get_risk("cmd_check")), "high")
  expect_equal(compute_risk(1, get_risk("cmd_check")), "low")
})


# get_risk_analysis

test_that("get_risk_analysis returns expected risk levels", {
  withr::local_options(list(risk.assessr.risk_definition = NULL))

  risks <- get_risk_analysis(mock_data)
  expect_equal(risks$dependencies_count, "low")
  expect_equal(risks$code_coverage, "low")
  expect_equal(risks$license, "low")
  expect_equal(risks$reverse_dependencies_count, "high")
  expect_equal(risks$cmd_check, "high")
  expect_equal(risks$total_download, "high")
  expect_equal(risks$later_version, "low")
})

test_that("get_risk_analysis works end-to-end", {
  withr::local_options(list(risk.assessr.risk_definition = NULL))
  
  risks <- get_risk_analysis(mock_data)
  expect_true("dependencies_count" %in% names(risks))
  expect_true("license" %in% names(risks))
  expect_true("reverse_dependencies_count" %in% names(risks))
  expect_true("documentation_score" %in% names(risks))
  expect_true("cmd_check" %in% names(risks))
})


test_that("get_risk_analysis assigns default when value is missing", {
  withr::local_options(list(risk.assessr.risk_definition = NULL))
  
  partial_data <- mock_data
  partial_data$license_name <- "NOT AVAILABLE"
  risks <- get_risk_analysis(partial_data)
  expect_equal(risks$license, "high")
})


test_that("get_risk_analysis assigns unknown license", {
  withr::local_options(list(risk.assessr.risk_definition = NULL))
  
  partial_data <- mock_data
  partial_data$license_name <- "blablabla"
  risks <- get_risk_analysis(partial_data)
  expect_equal(risks$license, "high")
})


# get_risk_analysis with non standard rules


test_that("get_risk_analysis works with multiple metrics in custom config", {

  multi_config <- list(
    list(
      label = "dependency count",
      id = "dependencies_count",
      key = "dependencies_count",
      thresholds = list(
        list(level = "high", max = 1),
        list(level = "medium", max = 3),
        list(level = "low", max = NULL)
      )
    ),
    list(
      label = "code coverage",
      id = "code_coverage",
      key = "code_coverage",
      thresholds = list(
        list(level = "critical", max = 0.7),
        list(level = "acceptable", max = 0.85),
        list(level = "excellent", max = NULL)
      )
    ),
    list(
      label = "popularity",
      id = "popularity",
      key = "last_month_download",
      thresholds = list(
        list(level = "low", max = 10000),
        list(level = "medium", max = 60000),
        list(level = "high", max = NULL)
      )
    )
  )
  withr::local_options(list(risk.assessr.risk_definition = multi_config))
  
  risks <- get_risk_analysis(mock_data)
  expect_equal(risks$dependencies_count, "high")
  expect_equal(risks$code_coverage, "excellent")
  expect_equal(risks$last_month_download, "medium")
})

test_that("get_risk_analysis handles categorical levels with custom config", {

  custom_license_config <- list(
    list(
      label = "license",
      id = "license",
      key = "license",
      default = "unknown",
      thresholds = list(
        list(level = "bad", values = c("GPL", "AGPL")),
        list(level = "ok", values = c("LGPL")),
        list(level = "good", values = c("MIT", "BSD"))
      )
    )
  )
  
  withr::local_options(list(risk.assessr.risk_definition = custom_license_config))
  risks <- get_risk_analysis(mock_data)
  expect_equal(risks$license, "good")
})

test_that("get_risk_analysis returns HIGH risk when total_download <= 3,500,000", {

  mock_data <- list(
    pkg_name = "mockpkg",
    pkg_version = "1.0.0",
    download = list(
      total_download = 1000000,   # 1,000,000 -> should be 'high'
      last_month_download = 50000
    )
  )

  custom_config <- list(
    list(
      label = "total_download",
      id = "total_download",
      key = "total_download",
      default = "unknown",
      thresholds = list(
        list(level = "high", max = 3500000),
        list(level = "medium", max = 50000000),
        list(level = "low", max = NULL)
      )
    )
  )

  withr::local_options(list(risk.assessr.risk_definition = custom_config))
  risks <- get_risk_analysis(mock_data)
  expect_equal(risks$total_download, "high")
})

test_that("get_risk_analysis returns MEDIUM risk when total_download <= 50,000,000", {
  
  mock_data <- list(
    pkg_name = "mockpkg",
    pkg_version = "1.0.0",
    download = list(
      total_download = 10000000,
      last_month_download = 50000
    )
  )

  custom_config <- list(
    list(
      label = "popularity",
      id = "popularity",
      key = "total_download",
      default = "unknown",
      thresholds = list(
        list(level = "high", max = 3500000),
        list(level = "medium", max = 50000000),
        list(level = "low", max = NULL)
      )
    )
  )

  withr::local_options(list(risk.assessr.risk_definition = custom_config))
  risks <- get_risk_analysis(mock_data)
  expect_equal(risks$total_download, "medium")
})

test_that("get_risk_analysis returns LOW risk when total_download > 50,000,000", {
  mock_data <- list(
    pkg_name = "mockpkg",
    pkg_version = "1.0.0",
    download = list(
      total_download = 100000000,
      last_month_download = 50000
    )
  )

  custom_config <- list(
    list(
      label = "popularity",
      id = "popularity",
      key = "total_download",
      default = "unknown",
      thresholds = list(
        list(level = "high", max = 3500000),
        list(level = "medium", max = 50000000),
        list(level = "low", max = NULL)
      )
    )
  )

  withr::local_options(list(risk.assessr.risk_definition = custom_config))
  risks <- get_risk_analysis(mock_data)
  expect_equal(risks$total_download, "low")
})

test_that("get_risk_analysis returns correct risk levels for different scenarios", {
  
  mock_data <- list(
    has_bug_reports_url = 1,
    has_examples = 1,
    has_maintainer = 1,
    has_source_control = 1,
    has_vignettes = 1,
    has_website = 1,
    has_news = 1
  )
  

  risks <- get_risk_analysis(mock_data)
  expect_equal(risks$documentation_score, "low")
  
  mock_data <- list(
    has_bug_reports_url = 1,
    has_examples = 1,
    has_maintainer = 1,
    has_source_control = 1,
    has_vignettes = 1,
    has_website = NULL,
    has_news = NULL
  )
  
  risks <- get_risk_analysis(mock_data)
  
  expect_equal(risks$documentation_score, "medium")
  
  mock_data <- list(
    has_bug_reports_url = 1
  )
  
  risks <- get_risk_analysis(mock_data)
  expect_equal(risks$documentation_score, "high")
})














