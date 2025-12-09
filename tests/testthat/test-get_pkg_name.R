input_string <- "/home/user/R/x86_64-pc-linux-gnu-library/4.1/package.metric/test-data/here_0.1.0.tar.gz"

input_string <- "/home/user/R/x86_64-pc-linux-gnu-library/4.1/package.metric/test-data/here-0.1.0.tar.gz"


input_string <- "TxDb.Dmelanogaster.UCSC.dm3.ensGene_3.2.2.tar.gz"

input_string <- "here-1.0.1.tar.gz"

input_string <- "here_1.0.1.tar.gz"

test_that("finds package name in file path", {

 pkg_source_path <- "/home/user/R/x86_64-pc-linux-gnu-library/4.1/risk.assessr/test-data/test.package.0001_0.1.0.tar.gz"
 
 pkg_disp <- risk.assessr::get_pkg_name(pkg_source_path)
 
 testthat::expect_true(!is.na(pkg_disp))
 
 testthat::expect_identical(length(pkg_disp), 1L)
 
 testthat::expect_identical(pkg_disp, "test.package.0001")
})

test_that("finds package name in file path", {
  
  pkg_source_path <- "/home/user/R/x86_64-pc-linux-gnu-library/4.1/risk.assessr/test-data/here_0.1.0.tar.gz"
  
  pkg_disp <- risk.assessr::get_pkg_name(pkg_source_path)
  
  testthat::expect_true(!is.na(pkg_disp))
  
  testthat::expect_identical(length(pkg_disp), 1L)
  
  testthat::expect_identical(pkg_disp, "here")
})

test_that("finds package name in file path", {
  
  pkg_source_path <- "/home/user/R/x86_64-pc-linux-gnu-library/4.1/risk.assessr/test-data/here-0.1.0.tar.gz"
  
  pkg_disp <- risk.assessr::get_pkg_name(pkg_source_path)
  
  testthat::expect_true(!is.na(pkg_disp))
  
  testthat::expect_identical(length(pkg_disp), 1L)
  
  testthat::expect_identical(pkg_disp, "here")
})


test_that("finds package name in tar file string", {
  pkg <- "TxDb.Dmelanogaster.UCSC.dm3.ensGene_3.2.2.tar.gz"
  
  pkg_disp <- risk.assessr::get_pkg_name(pkg)
  
  testthat::expect_true(!is.na(pkg_disp))
  
  testthat::expect_identical(length(pkg_disp), 1L)
  
  testthat::expect_identical(pkg_disp, "TxDb.Dmelanogaster.UCSC.dm3.ensGene")

})

test_that("finds package name in tar file string", {
  pkg <- "here_0.1.0.tar.gz"
  
  pkg_disp <- risk.assessr::get_pkg_name(pkg)
  
  testthat::expect_true(!is.na(pkg_disp))
  
  testthat::expect_identical(length(pkg_disp), 1L)
  
  testthat::expect_identical(pkg_disp, "here")
  
})

test_that("finds package name in tar file string", {
  pkg <- "here-0.1.0.tar.gz"
  
  pkg_disp <- risk.assessr::get_pkg_name(pkg)
  
  testthat::expect_true(!is.na(pkg_disp))
  
  testthat::expect_identical(length(pkg_disp), 1L)
  
  testthat::expect_identical(pkg_disp, "here")
  
})
