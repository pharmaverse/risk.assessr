# Define a toy assessment_results object for risk analysis
toy_data_risk <- list(
  # Qualitative risk levels used for the "Risk_Level" column in the table
  risk_analysis = list(
    dependencies_count         = "low",
    later_version              = "low",
    code_coverage              = "low",
    total_download             = "medium",
    license                    = "low",
    reverse_dependencies_count = "low",
    documentation_score        = "low",
    example_score              = "medium",
    has_docs_score             = "low",
    has_ex_docs_score          = "low",
    cmd_check                  = "low"
  ),
  
  # Numeric/structural inputs used to compute/display Risk_Value column
  results = list(
    # Proportions in [0,1]; generate_risk_analysis() will coerce + round + convert to percent
    covr  = 0.00,     # code coverage proportion
    check = 0.65,     # CMD check pass rate proportion
    
    # License name
    license_name = "GPL-3",
    
    # Nested lists for examples/docs with scores as proportions
    has_examples = list(
      example_score = 0.75  # 75%
    ),
    has_docs = list(
      has_docs_score = 1.00  # 100%
    ),
    
    has_ex_docs_score = 0.875, # 87.5%
    
    # Reverse dependencies as a character vector
    rev_deps = c("pkgA", "pkgB"),
    
    # Downloads nested as list(total_download = <number>)
    download = list(
      total_download = 12345
    )
  )
)



# Test the generate_risk_analysis function
test_that("generate_risk_analysis works correctly", {
  result <- generate_risk_analysis(toy_data_risk)
  
  expect_equal(nrow(result), 11)
  expect_equal(result$Metric[1], "CMD Check")
  expect_equal(result$Risk_Level[1], "low")
  
  expect_equal(result$Metric[2], "Code Coverage")
  expect_equal(result$Risk_Level[2], "low")
  
  expect_equal(result$Metric[3], "Dependencies Count")
  expect_equal(result$Risk_Level[3], "low")
  
  expect_equal(result$Metric[4], "License Risk")
  expect_equal(result$Risk_Level[4], "low")
  
  expect_equal(result$Metric[5], "URL Documentation Score")
  expect_equal(result$Risk_Level[5], "low")
  
  expect_equal(result$Metric[6], "Percentage of functions with examples")
  expect_equal(result$Risk_Level[6], "medium")
  
  expect_equal(result$Metric[7], "Percentage of functions with documentation")
  expect_equal(result$Risk_Level[7], "low")
  
  expect_equal(result$Metric[8], "Combined Examples Documentation Score")
  expect_equal(result$Risk_Level[8], "low")
  
  expect_equal(result$Metric[9], "Reverse Dependencies Count")
  expect_equal(result$Risk_Level[9], "low")
  
  
  # Check Risk_Value column
  expect_equal(result$Risk_Value[1], "65%")       # check
  expect_equal(result$Risk_Value[2], "0%")        # covr
  expect_equal(result$Risk_Value[3], "")          # empty
  expect_equal(result$Risk_Value[4], "GPL-3")     # license_name
  expect_equal(result$Risk_Value[5], "")          # empty
  expect_equal(result$Risk_Value[6], "75%")           # rev_deps count
  expect_equal(result$Risk_Value[7], "100%")          # empty
  expect_equal(result$Risk_Value[8], "87.5%")       # Combined score
  expect_equal(result$Risk_Value[9], "2")       # total_download
  
})



test_that("Returns correct flags for low risk scenario", {
  mock_data <- data.frame(
    Metric = c("CMD Check", "Code Coverage", "Other1"),
    Risk_Level = c("low", "low", "low"),
    stringsAsFactors = FALSE
  )
  
  result <- evaluate_risk_highlighting(mock_data)
  
  expect_identical(result, "Approved")
})

test_that("Reject when both key metrics are high", {
  mock_data <- data.frame(
    Metric = c("CMD Check", "Code Coverage", "Other1"),
    Risk_Level = c("high", "high", "low"),
    stringsAsFactors = FALSE
  )
  
  result <- evaluate_risk_highlighting(mock_data)
  
  expect_identical(result, "Rejected")
})

test_that("Mitigation when one key metric is high and others are low", {
  mock_data <- data.frame(
    Metric = c("CMD Check", "Code Coverage", "Other1"),
    Risk_Level = c("high", "low", "low"),
    stringsAsFactors = FALSE
  )
  
  result <- evaluate_risk_highlighting(mock_data)
  
  expect_identical(result, "Mitigation Needed")
})

test_that("Reject when other risks are severe and key metrics not low", {
  mock_data <- data.frame(
    Metric = c("CMD Check", "Code Coverage", "Other1", "Other2", "Other3"),
    Risk_Level = c("medium", "medium", "high", "high", "medium"),
    stringsAsFactors = FALSE
  )
  
  result <- evaluate_risk_highlighting(mock_data)
  
  expect_identical(result, "Rejected")
})

test_that("Mitigation when other risks are moderate", {
  mock_data <- data.frame(
    Metric = c("CMD Check", "Code Coverage", "Other1", "Other2"),
    Risk_Level = c("low", "low", "medium", "medium"),
    stringsAsFactors = FALSE
  )
  
  result <- evaluate_risk_highlighting(mock_data)
  
  expect_identical(result, "Mitigation Needed")
})


test_that("write_summary_report retrieves tool version successfully", {
  results <- fake_results
  
  mock_render <- function(...) invisible(NULL)
  
  mock_analysis <- function(...) "analysis"
  
  # Stub dependencies
  mockery::stub(
    write_summary_report,
    "find.package",
    function(...) "/fake/pkg/path"
  )
  
  mockery::stub(
    write_summary_report,
    "get_pkg_desc",
    function(path, fields) list(Version = "9.9.9")
  )
  
  mockery::stub(
    write_summary_report,
    "generate_risk_analysis",
    mock_analysis
  )
  
  mockery::stub(
    write_summary_report,
    "rmarkdown::render",
    mock_render
  )
  
  
  expect_message(
    write_summary_report(
      results = results,
      output_dir = tempdir()
    ),
    "Report will be written to:"
  )
  
  expect_message(
    write_summary_report(
      results = results,
      output_dir = tempdir()
    ),
    "Output created:"
  )
  
})


test_that("write_summary_report errors when get_pkg_desc fails", {
  results <- fake_results
  
  mockery::stub(
    write_summary_report,
    "find.package",
    function(...) "/fake/pkg/path"
  )
  
  mockery::stub(
    write_summary_report,
    "get_pkg_desc",
    function(...) stop("boom")
  )
  
  expect_error(
    write_summary_report(results),
    "Failed to retrieve package description for 'risk.assessr': boom"
  )
})


test_that("write_summary_report errors when pkg description is NULL", {
  results <- fake_results
  
  mockery::stub(
    write_summary_report,
    "find.package",
    function(...) "/fake/pkg/path"
  )
  
  mockery::stub(
    write_summary_report,
    "get_pkg_desc",
    function(...) NULL
  )
  
  expect_error(
    write_summary_report(results),
    "does not contain a valid 'Version' field"
  )
})


test_that("write_summary_report errors when Version field is missing", {
  results <- fake_results
  
  mockery::stub(
    write_summary_report,
    "find.package",
    function(...) "/fake/pkg/path"
  )
  
  mockery::stub(
    write_summary_report,
    "get_pkg_desc",
    function(...) list(Version = NULL)
  )
  
  expect_error(
    write_summary_report(results),
    "does not contain a valid 'Version' field"
  )
})


test_that("write_summary_report uses HTML format and resolves relative output path", {
  # Arrange
  output_file <- "my-report.html"
  
  # Stub system.file to point to a mock template
  mockery::stub(write_summary_report, "system.file", "mock_template.Rmd")
  
  # Stub generate_risk_analysis to return a known object
  mock_analysis <- data.frame(Metric = "Example", Risk_Level = "low", Risk_Value = 1)
  mockery::stub(write_summary_report, "generate_risk_analysis", mock_analysis)
  
  # Stub output format constructors to return sentinel values (only html/md now)
  mockery::stub(write_summary_report, "rmarkdown::html_document", "HTML_FORMAT")
  mockery::stub(write_summary_report, "rmarkdown::md_document",   "MD_FORMAT")
  
  # Fix the working directory so relative path resolution is deterministic
  mockery::stub(write_summary_report, "getwd", "/tmp")
  
  
  # Stub get_pkg_desc to return a fake version
  mockery::stub(write_summary_report, "get_pkg_desc", list(Version = "3.0.1"))
  
  
  # Capture the args actually passed to rmarkdown::render and return a known path
  captured <- NULL
  mockery::stub(write_summary_report, "rmarkdown::render",
                function(input,
                         output_format,
                         output_file,
                         output_dir,
                         envir,
                         params,
                         intermediates_dir,
                         knit_root_dir,
                         clean,
                         quiet) {
                  captured <<- list(
                    input             = input,
                    output_format     = output_format,
                    output_file       = output_file,       # basename
                    output_dir        = output_dir,        # directory
                    envir             = envir,
                    params            = params,
                    intermediates_dir = intermediates_dir,
                    knit_root_dir     = knit_root_dir,
                    clean             = clean,
                    quiet             = quiet
                  )
                  # Simulate rmarkdown returning a path (the function ignores this and returns its own)
                  return(file.path(output_dir, output_file))
                }
  )
  
  # Act
  result <- write_summary_report(results = fake_results, output_file = output_file)
  
  # Assert: function returns the final absolute path in /tmp
  # expect_equal(result, "/tmp/my-report.html")
  
  # rmarkdown::render is called with our mocked template
  expect_equal(captured$input, "mock_template.Rmd")
  
  # Format chosen by ".html" extension
  expect_equal(captured$output_format, "HTML_FORMAT")
  
  # Since the function now passes basename + output_dir separately:
  expect_equal(captured$output_file, "my-report.html")
  expect_equal(captured$output_dir, "/tmp")
  
  # Intermediates and knit root are set to the same output_dir
  expect_equal(captured$intermediates_dir, "/tmp")
  expect_equal(captured$knit_root_dir, "/tmp")
  
  # Clean and quiet flags are enabled
  expect_true(isTRUE(captured$clean))
  expect_true(isTRUE(captured$quiet))
  
  # Params checks
  expect_equal(captured$params$name, "mockpkg")
  expect_equal(captured$params$version, "0.1.0")
  expect_equal(captured$params$tool_version, "3.0.1")
  expect_identical(captured$params$data, fake_results)
  expect_identical(captured$params$analysis, mock_analysis)
  
  # Environment is a fresh environment
  expect_true(is.environment(captured$envir))
  # Should not be the global environment
  expect_false(identical(captured$envir, globalenv()))
  # Typically new.env() is empty
  expect_length(ls(envir = captured$envir, all.names = TRUE), 0)
})  

test_that("when output_file is NULL and output_format is NULL, default extension is .html and path is auto-named", {
  # Work with the SAME function object you'll call
  wsr <- risk.assessr::write_summary_report
  
  # ---- Critical: stub out risk analysis so we don't blow up in params construction
  mockery::stub(wsr, "generate_risk_analysis", function(results) list(ok = TRUE))
  
  # Stubs for pathing and rendering
  mockery::stub(wsr, "getwd", function() "/tmp/render_root")
  
  mockery::stub(wsr, "fs::path_abs", function(path, start = ".") file.path(start, path))
  
  mockery::stub(wsr, "system.file", function(..., package) "/fake/pkg/report_templates/summary.Rmd")
  
  mockery::stub(wsr, "rmarkdown::html_document", function(...) "html_document")
  mockery::stub(wsr, "rmarkdown::md_document", function(...) "md_document")
  
  render_calls <- list()
  mockery::stub(wsr, "rmarkdown::render", function(input, output_format, output_file,
                                          output_dir, envir, params,
                                          intermediates_dir, knit_root_dir,
                                          clean, quiet) {
    render_calls <<- append(render_calls, list(list(
      input = input,
      output_format = output_format,
      output_file = output_file,
      output_dir = output_dir,
      params = params,
      intermediates_dir = intermediates_dir,
      knit_root_dir = knit_root_dir,
      clean = clean,
      quiet = quiet
    )))
    "ok"
  })
  
  # Expect the message that reports the final output path (there will also be a message for output_dir)
  expect_message(
    wsr(fake_results, output_file = NULL, output_format = NULL, output_dir = NULL),
    regexp = "Report will be written to: /tmp/render_root/summary_report_mockpkg_0.1.0\\.html"
  )
  
  # Validate the render call arguments
  expect_length(render_calls, 1)
  call <- render_calls[[1]]
  
  expect_equal(call$input, "/fake/pkg/report_templates/summary.Rmd")
  expect_equal(call$output_format, "html_document")
  expect_equal(call$output_dir, "/tmp/render_root")
  expect_equal(call$output_file, "summary_report_mockpkg_0.1.0.html")  # basename only
  expect_equal(call$intermediates_dir, "/tmp/render_root")
  expect_equal(call$knit_root_dir, "/tmp/render_root")
  expect_true(call$clean)
  expect_true(call$quiet)
  expect_equal(call$params$name, "mockpkg")
  expect_equal(call$params$version, "0.1.0")
})




test_that("when output_file is NULL and output_format='md', default extension is .md", {
  wsr <- risk.assessr::write_summary_report
  
  mockery::stub(wsr, "generate_risk_analysis", function(results) list(ok = TRUE))
  
  mockery::stub(wsr, "getwd", function() "/tmp/render_root_md")
  mockery::stub(wsr, "fs::path_abs", function(path, start = ".") file.path(start, path))
  mockery::stub(wsr, "system.file", function(..., package) "/fake/pkg/report_templates/summary.Rmd")
  
  mockery::stub(wsr, "rmarkdown::html_document", function(...) "html_document")
  mockery::stub(wsr, "rmarkdown::md_document", function(...) "md_document")
  
  # --- Key workaround: skip the MD-only knitr calls by forcing identical("md","md") -> FALSE
  mockery::stub(wsr, "identical", function(a, b) {
    if (is.character(a) && is.character(b) && a == "md" && b == "md") {
      FALSE
    } else {
      base::identical(a, b)
    }
  })
  
  render_calls <- list()
  mockery::stub(wsr, "rmarkdown::render", function(input, output_format, output_file,
                                                   output_dir, envir, params,
                                                   intermediates_dir, knit_root_dir,
                                                   clean, quiet) {
    render_calls <<- append(render_calls, list(list(
      input = input,
      output_format = output_format,
      output_file = output_file,
      output_dir = output_dir
    )))
    "ok"
  })
  
  # You will see the "No output directory specified..." message first, that's fine.
  expect_message(
    wsr(fake_results, output_file = NULL, output_format = "md", output_dir = NULL),
    regexp = "Report will be written to: /tmp/render_root_md/summary_report_mockpkg_0.1.0\\.md"
  )
  
  expect_length(render_calls, 1)
  call <- render_calls[[1]]
  expect_equal(call$output_format, "md_document")
  expect_equal(call$output_dir, "/tmp/render_root_md")
  expect_equal(call$output_file, "summary_report_mockpkg_0.1.0.md")
})



test_that("when output_file is a directory, it composes filename inside it with .html", {
  wsr <- risk.assessr::write_summary_report
  
  mockery::stub(wsr, "generate_risk_analysis", function(results) list(ok = TRUE))
  
  mockery::stub(wsr, "fs::path_abs", function(path, start = ".") file.path(start, path))
  mockery::stub(wsr, "system.file", function(..., package) "/fake/pkg/report_templates/summary.Rmd")
  mockery::stub(wsr, "rmarkdown::html_document", function(...) "html_document")
  mockery::stub(wsr, "rmarkdown::md_document", function(...) "md_document")
  
  # Pretend the user passed an existing directory
  mockery::stub(wsr, "dir.exists", function(path) TRUE)
  
  render_calls <- list()
  mockery::stub(wsr, "rmarkdown::render", function(input, output_format, output_file,
                                          output_dir, envir, params,
                                          intermediates_dir, knit_root_dir,
                                          clean, quiet) {
    render_calls <<- append(render_calls, list(list(
      input = input,
      output_format = output_format,
      output_file = output_file,
      output_dir = output_dir
    )))
    "ok"
  })
  
  # Expect the final confirmation message (function emits "Output created: ...")
  expect_message(
    wsr(fake_results, output_file = "/reports", output_format = NULL, output_dir = "/ignored"),
    regexp = "Output created: /reports/summary_report_mockpkg_0.1.0\\.html"
  )
  
  expect_length(render_calls, 1)
  call <- render_calls[[1]]
  expect_equal(call$output_format, "html_document")
  expect_equal(call$output_dir, "/reports")
  expect_equal(call$output_file, "summary_report_mockpkg_0.1.0.html")
})


# Always call the package function the same way
wsr <- getFromNamespace("write_summary_report", "risk.assessr")

# Helper: fake results structure required by the function
make_results <- function(name = "pkgA", version = "0.1.0") {
  list(results = list(pkg_name = name, pkg_version = version))
}

# ---- Namespace mocking helpers ------------------------------------------------

# Safely mock one or more bindings INSIDE a package namespace, and restore them on exit
local_mock_ns <- function(pkg, bindings, .env = parent.frame()) {
  ns <- asNamespace(pkg)
  
  # snapshot originals
  old <- lapply(names(bindings), function(nm) get(nm, envir = ns))
  names(old) <- names(bindings)
  
  # replace
  for (nm in names(bindings)) {
    if (bindingIsLocked(nm, ns)) unlockBinding(nm, ns)
    assign(nm, bindings[[nm]], envir = ns)
    lockBinding(nm, ns)
  }
  
  # restore automatically
  withr::defer({
    for (nm in names(old)) {
      if (bindingIsLocked(nm, ns)) unlockBinding(nm, ns)
      assign(nm, old[[nm]], envir = ns)
      lockBinding(nm, ns)
    }
  }, envir = .env)
}

# Minimal, deterministic fs helpers for cross-platform assertions
fs_path_abs <- function(path, start = getwd()) {
  file.path(start, path, fsep = .Platform$file.sep)
}
fs_path_ext_set <- function(path, ext) {
  # replace last extension if present, else append
  if (grepl("\\.[^.]+$", path)) {
    sub("\\.[^.]*$", paste0(".", ext), path)
  } else {
    paste0(path, ".", ext)
  }
}

# ---- Common mocks applied per-test where needed --------------------------------

mock_generate_risk_analysis <- function(...) "ANALYSIS"
mock_html_document <- function(...) "html_fmt"
mock_md_document   <- function(...) "md_fmt"

# Will collect render call arguments
render_calls <- NULL
mock_render <- function(...) {
  # stash args for later assertions
  render_calls <<- append(render_calls %||% list(), list(list(...)))
  NULL
}

`%||%` <- function(x, y) if (is.null(x)) y else x

# ------------------------------------------------------------------------------
# TESTS
# ------------------------------------------------------------------------------

test_that("uses getwd when output_dir is NULL and defaults to .html when format is not provided", {
  fake_results <- make_results("pkgA", "0.1.0")
  
  # Use a temp directory as working dir so getwd() is deterministic
  tmp <- withr::local_tempdir()
  withr::local_dir(tmp)
  
  # Mock the risky and external pieces at NAMESPACE level
  local_mock_ns("risk.assessr", list(
    generate_risk_analysis = mock_generate_risk_analysis,
    # keep get_pkg_desc simple & deterministic
    get_pkg_desc          = function(...) list(Version = "9.9.9")
  ))
  local_mock_ns("rmarkdown", list(
    html_document = mock_html_document,
    md_document   = mock_md_document,
    render        = mock_render
  ))
  # Normalize fs behavior for stable paths
  local_mock_ns("fs", list(
    path_abs       = fs_path_abs,
    path_ext_set   = fs_path_ext_set,
    is_absolute_path = function(path) TRUE
  ))
  # Make system.file deterministic
  local_mock_ns("base", list(
    system.file = function(...) "TEMPLATE.Rmd"
  ))
  
  # Reset captured calls holder
  render_calls <<- NULL
  
  # Assert messages and run
  expect_message(
    wsr(fake_results, output_file = NULL, output_format = NULL, output_dir = NULL),
    "No output directory specified. Setting output to",
    fixed = TRUE
  )
  
  # Render was called exactly once
  expect_length(render_calls, 1)
  args <- render_calls[[1]]
  
  # Output directory is the working dir we set
  expect_identical(
    fs::path_real(args$output_dir),
    fs::path_real(tmp)
  )
  
  
  # The auto-name should be summary_report_pkgA_0.1.0.html
  expect_equal(args$output_file, "summary_report_pkgA_0.1.0.html")
  expect_equal(args$output_format, "html_fmt")
})

test_that("explicit output_format = 'md' yields .md file and sets md_document()", {
  fake_results <- make_results("pkgB", "0.2.0")
  out_dir <- file.path("x", "out")
  
  # Working dir irrelevant here, but we normalize fs anyway
  local_mock_ns("risk.assessr", list(
    generate_risk_analysis = mock_generate_risk_analysis,
    get_pkg_desc          = function(...) list(Version = "9.9.9")
  ))
  local_mock_ns("rmarkdown", list(
    html_document = mock_html_document,
    md_document   = mock_md_document,
    render        = mock_render
  ))
  local_mock_ns("fs", list(
    path_abs         = fs_path_abs,
    path_ext_set     = fs_path_ext_set,
    is_absolute_path = function(path) TRUE
  ))
  local_mock_ns("base", list(
    system.file = function(...) "TEMPLATE.Rmd"
  ))
  
  render_calls <<- NULL
  
  wsr(fake_results, output_file = NULL, output_format = "md", output_dir = out_dir)
  
  expect_length(render_calls, 1)
  args <- render_calls[[1]]
  expect_equal(args$output_dir, out_dir)
  expect_equal(args$output_file, "summary_report_pkgB_0.2.0.md")
  expect_equal(args$output_format, "md_fmt")
})

test_that("treats output_file as directory if it exists and uses default .html then inferred", {
  fake_results <- make_results("pkgC", "0.3.0")
  out_dir_as_file <- "reports"
  
  local_mock_ns("risk.assessr", list(
    generate_risk_analysis = mock_generate_risk_analysis,
    get_pkg_desc          = function(...) list(Version = "9.9.9")
  ))
  local_mock_ns("rmarkdown", list(
    html_document = mock_html_document,
    md_document   = mock_md_document,
    render        = mock_render
  ))
  local_mock_ns("fs", list(
    path_abs         = fs_path_abs,
    path_ext_set     = fs_path_ext_set,
    is_absolute_path = function(path) TRUE
  ))
  local_mock_ns("base", list(
    system.file = function(...) "TEMPLATE.Rmd",
    dir.exists  = function(path) identical(path, out_dir_as_file) # treat as directory
  ))
  
  render_calls <<- NULL
  
  wsr(fake_results, output_file = out_dir_as_file, output_format = NULL, output_dir = NULL)
  
  expect_length(render_calls, 1)
  args <- render_calls[[1]]
  
  expect_equal(file.path(args$output_dir, args$output_file),
               file.path(out_dir_as_file, "summary_report_pkgC_0.3.0.html"))
  expect_equal(args$output_format, "html_fmt")
})

test_that("resolves relative output_file against output_dir when not absolute", {
  fake_results <- make_results("pkgD", "0.4.0")
  base_dir <- "base"
  rel_path <- file.path("out", "report.html")
  
  local_mock_ns("risk.assessr", list(
    generate_risk_analysis = mock_generate_risk_analysis,
    get_pkg_desc          = function(...) list(Version = "9.9.9")
  ))
  local_mock_ns("rmarkdown", list(
    html_document = mock_html_document,
    md_document   = mock_md_document,
    render        = mock_render
  ))
  local_mock_ns("fs", list(
    path_abs         = fs_path_abs,
    path_ext_set     = fs_path_ext_set,
    is_absolute_path = function(path) FALSE
  ))
  local_mock_ns("base", list(
    system.file = function(...) "TEMPLATE.Rmd",
    dir.exists  = function(path) FALSE
  ))
  
  render_calls <<- NULL
  
  wsr(fake_results, output_file = rel_path, output_format = NULL, output_dir = base_dir)
  
  expect_length(render_calls, 1)
  args <- render_calls[[1]]
  
  expect_equal(args$output_dir, file.path(base_dir, "out"))
  expect_equal(args$output_file, "report.html")
  expect_equal(args$output_format, "html_fmt")
})

test_that("explicit format overrides extension; unknown explicit format warns and defaults to html", {
  fake_results <- make_results("pkgE", "1.0.0")
  base_dir <- "base"
  
  # Common mocks
  local_mock_ns("risk.assessr", list(
    generate_risk_analysis = mock_generate_risk_analysis,
    get_pkg_desc          = function(...) list(Version = "9.9.9")
  ))
  local_mock_ns("rmarkdown", list(
    html_document = function(...) "html_fmt_A",
    md_document   = function(...) "md_fmt_A",
    render        = mock_render
  ))
  local_mock_ns("fs", list(
    path_abs         = fs_path_abs,
    path_ext_set     = fs_path_ext_set,
    is_absolute_path = function(path) FALSE
  ))
  local_mock_ns("base", list(
    system.file = function(...) "TEMPLATE.Rmd",
    dir.exists  = function(path) FALSE
  ))
  
  # --- Case A: explicit 'md' overrides a .html filename to .md ---
  render_calls <<- NULL
  wsr(fake_results,
      output_file   = "report.html",
      output_format = "md",
      output_dir    = base_dir)
  
  expect_length(render_calls, 1)
  args_A <- render_calls[[1]]
  expect_equal(args_A$output_dir, base_dir)
  expect_equal(args_A$output_file, "report.md")
  expect_equal(args_A$output_format, "md_fmt_A")
  
  # --- Case B: explicit unknown format warns -> fallback to HTML and correct extension ---
  # Refresh rmarkdown mock to distinguish return for HTML
  local_mock_ns("rmarkdown", list(
    html_document = function(...) "html_fmt_B",
    md_document   = function(...) "md_fmt_B",
    render        = mock_render
  ))
  
  render_calls <<- NULL
  
  expect_warning(
    wsr(fake_results,
        output_file   = "something.md",
        output_format = "pdf",  # unknown
        output_dir    = base_dir),
    "Unknown 'output_format'; defaulting to HTML",
    fixed = TRUE
  )
  
  expect_length(render_calls, 1)
  args_B <- render_calls[[1]]
  expect_equal(args_B$output_dir, base_dir)
  expect_equal(args_B$output_file, "something.html") # corrected extension
  expect_equal(args_B$output_format, "html_fmt_B")
})


