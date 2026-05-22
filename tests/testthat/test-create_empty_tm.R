test_that("test create_empty_tm ", {
  
  pkg_name <- ""
  
  empty_tm <- create_empty_tm(pkg_name)
  
  expect_identical(length(empty_tm), 4L)
  
  expect_true(checkmate::check_list(empty_tm, all.missing = TRUE))
  
  df <- empty_tm |> 
    as.data.frame()
  
  expect_identical(length(df), 5L)
  
  expect_true(checkmate::check_data_frame(df, all.missing = TRUE))
  
  
})