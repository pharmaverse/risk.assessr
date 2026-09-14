test_that("returns the data frame produced by get_security_vulnerabilities()", {
  mockery::stub(generate_security_vulnerabilities, "get_security_vulnerabilities", function(...) {
    data.frame(id = "RSEC-2023-6", stringsAsFactors = FALSE)
  })
  
  result <- generate_security_vulnerabilities("commonmark", pkg_ver = "1.7")
  
  expect_s3_class(result, "data.frame")
  expect_equal(result$id, "RSEC-2023-6")
})

test_that("passes pkg_name, pkg_ver, and ecosystem to get_security_vulnerabilities()", {
  seen <- new.env(parent = emptyenv())
  
  mockery::stub(generate_security_vulnerabilities, "get_security_vulnerabilities", function(pkg_name, pkg_ver, ecosystem) {
    seen$pkg_name <- pkg_name
    seen$pkg_ver <- pkg_ver
    seen$ecosystem <- ecosystem
    data.frame(id = character(0), stringsAsFactors = FALSE)
  })
  
  generate_security_vulnerabilities("pkgpass", pkg_ver = "9.9.9", ecosystem = "Bioconductor")
  
  expect_equal(seen$pkg_name, "pkgpass")
  expect_equal(seen$pkg_ver, "9.9.9")
  expect_equal(seen$ecosystem, "Bioconductor")
})

test_that("defaults pkg_ver to NULL and ecosystem to 'CRAN'", {
  seen <- new.env(parent = emptyenv())
  
  mockery::stub(generate_security_vulnerabilities, "get_security_vulnerabilities", function(pkg_name, pkg_ver, ecosystem) {
    seen$pkg_ver <- pkg_ver
    seen$ecosystem <- ecosystem
    data.frame(id = character(0), stringsAsFactors = FALSE)
  })
  
  generate_security_vulnerabilities("commonmark")
  
  expect_null(seen$pkg_ver)
  expect_equal(seen$ecosystem, "CRAN")
})

test_that("errors on an invalid pkg_name argument", {
  expect_error(generate_security_vulnerabilities(123))
  expect_error(generate_security_vulnerabilities(""))
})

test_that("errors on an invalid pkg_ver argument", {
  expect_error(generate_security_vulnerabilities("pkgname", pkg_ver = 123))
})

test_that("errors on an invalid ecosystem argument", {
  expect_error(generate_security_vulnerabilities("pkgname", ecosystem = ""))
  expect_error(generate_security_vulnerabilities("pkgname", ecosystem = NA))
})
