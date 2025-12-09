test_that("parse deps for tar file works correctly", {
  skip_on_cran()
  
  # Set CRAN repo
  r <- getOption("repos")
  r["CRAN"] <- "http://cran.us.r-project.org"
  options(repos = r)
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz", 
                    package = "risk.assessr")
  
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  # Only proceed if package is installed
  if (package_installed == TRUE) {
    
    mock_revdeps <- c("pkgA", "pkgB", "pkgC")
    mockery::stub(get_reverse_dependencies,"find_reverse_dependencies", mock_revdeps)
    
    revdeps_list <- suppressWarnings(get_reverse_dependencies(pkg_source_path))
    expect_identical(length(revdeps_list), 3L)
    checkmate::assert_character(revdeps_list, any.missing = FALSE)
  }
})