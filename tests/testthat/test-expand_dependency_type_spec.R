test_that("expand_dependency_type_spec returns correct values for named types", {
  expect_equal(
    expand_dependency_type_spec("strong"),
    c("Depends", "Imports", "LinkingTo")
  )
  
  expect_equal(
    expand_dependency_type_spec("most"),
    c("Depends", "Imports", "LinkingTo", "Suggests")
  )
  
  expect_equal(
    expand_dependency_type_spec("all"),
    c("Depends", "Imports", "LinkingTo", "Suggests", "Enhances")
  )
})

test_that("expand_dependency_type_spec returns custom input unchanged", {
  expect_equal(
    expand_dependency_type_spec(c("Depends", "Suggests")),
    c("Depends", "Suggests")
  )
})
