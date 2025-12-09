test_that("extract_thresholds_by_id returns correct thresholds", {
  # Mocked risk rule data
  mock_risk_rules <- list(
    list(id = "code_coverage", thresholds = list(
      list(level = "high", max = 90),
      list(level = "medium", max = 75)
    )),
    list(id = "doc_coverage", thresholds = list(
      list(level = "high", max = 85),
      list(level = "medium", max = 70)
    ))
  )
  
  # Direct test of extract_thresholds_by_id
  result <- extract_thresholds_by_id(mock_risk_rules, "code_coverage")
  expect_type(result, "list")
  expect_equal(length(result), 2)
  expect_equal(result[[1]]$level, "high")
  expect_equal(result[[1]]$max, 90)
  expect_equal(result[[2]]$level, "medium")
  expect_equal(result[[2]]$max, 75)
})

test_that("extract_thresholds_by_id returns NULL when id not found", {
  mock_risk_rules <- list(
    list(id = "doc_coverage", thresholds = list(
      list(level = "high", max = 85),
      list(level = "medium", max = 70)
    ))
  )
  
  result <- extract_thresholds_by_id(mock_risk_rules, "code_coverage")
  expect_null(result)
})


test_that("extract_threshold_by_key returns correct thresholds", {
  # Mocked risk rule data
  mock_risk_rules <- list(
    list(
      key = "total_download",
      thresholds = list(
        list(level = "high", max = 3500000),
        list(level = "medium", max = 50000000),
        list(level = "low", max = NULL)
      )
    ),
    list(
      key = "stars",
      thresholds = list(
        list(level = "high", max = 1000),
        list(level = "medium", max = 500)
      )
    )
  )
  
  # Direct test of extract_threshold_by_key
  result <- extract_thresholds_by_key(mock_risk_rules, "total_download")
  expect_type(result, "list")
  expect_equal(length(result), 3)
  expect_equal(result[[1]]$level, "high")
  expect_equal(result[[1]]$max, 3500000)
  expect_equal(result[[3]]$level, "low")
  expect_null(result[[3]]$max)
})

test_that("extract_threshold_by_key returns NULL when key not found", {
  mock_risk_rules <- list(
    list(
      key = "stars",
      thresholds = list(
        list(level = "high", max = 1000),
        list(level = "medium", max = 500)
      )
    )
  )
  
  result <- extract_thresholds_by_key(mock_risk_rules, "total_download")
  expect_null(result)
})
