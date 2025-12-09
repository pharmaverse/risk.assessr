
test_that("forbidden notes are reclassified as errors", {
  res_check <- list(
    notes = c(
      "'foo' import not declared from: 'bar'",
      "Namespace in Imports field not imported from: 'baz'",
      "no visible global function definition for 'qux'",
      "some harmless note"
    ),
    warnings = character(0),
    errors = character(0)
  )
  
  updated <- check_forbidden_notes(res_check, pkg_name = "mockpkg")
  
  expect_length(updated$notes, 1)
  expect_match(updated$notes, "some harmless note")
  expect_length(updated$errors, 3)
  expect_true(any(grepl("import not declared", updated$errors)))
  expect_true(any(grepl("Namespace in Imports", updated$errors)))
  expect_true(any(grepl("no visible global", updated$errors)))
})

test_that("no forbidden notes leaves notes and errors unchanged", {
  res_check <- list(
    notes = c("this is a harmless note", "another safe note"),
    warnings = character(0),
    errors = character(0)
  )
  
  updated <- check_forbidden_notes(res_check, pkg_name = "mockpkg")
  
  expect_equal(updated$notes, res_check$notes)
  expect_equal(updated$errors, character(0))
})

test_that("empty notes does not cause errors", {
  res_check <- list(
    notes = character(0),
    warnings = character(0),
    errors = character(0)
  )
  
  updated <- check_forbidden_notes(res_check, pkg_name = "mockpkg")
  
  expect_equal(updated$notes, character(0))
  expect_equal(updated$errors, character(0))
})
