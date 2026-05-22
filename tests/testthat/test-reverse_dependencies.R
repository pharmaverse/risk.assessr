test_that("parse deps for tar file works correctly", {
  skip_on_cran()
  
  # Keep the existing CRAN repo setup (harmless here)
  r <- getOption("repos")
  r["CRAN"] <- "http://cran.us.r-project.org"
  options(repos = r)
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz", 
                    package = "risk.assessr")
  
  install_list <- set_up_pkg(dp)
  package_installed <- install_list$package_installed
  pkg_source_path   <- install_list$pkg_source_path
  
  if (package_installed == TRUE) {
    # --- derive the package name from the tarball path (no stringr needed)
    pkg_tar   <- basename(pkg_source_path)             # e.g. "here-1.0.1.tar.gz"
    pkg_name0 <- sub("\\.tar\\.gz$", "", pkg_tar)      # "here-1.0.1"
    pkg_name  <- sub("[_|-].*$", "", pkg_name0)        # "here"
    
    # --- fake CRAN index (like utils::available.packages())
    # columns must include dependency fields used by dependsOnPkgs()
    fake <- matrix(
      c(
        "pkgA","here", "",    "",      "",
        "pkgB","",     "here","",      "",
        "pkgC","",     "",    "here",  "",
        "here","R",    "",    "",      ""
      ),
      ncol = 5, byrow = TRUE,
      dimnames = list(NULL, c("Package","Depends","Imports","Suggests","LinkingTo"))
    )
    rownames(fake) <- fake[, "Package"]
    
    # --- call the new API directly; no network, no stubs
    revdeps_list <- cran_revdep(
      pkg_name,
      dependencies = c("Depends","Imports","Suggests","LinkingTo"),
      recursive = FALSE,
      installed = fake
    )
    
    expect_identical(length(revdeps_list), 3L)
    checkmate::assert_character(revdeps_list, any.missing = FALSE)
    expect_setequal(revdeps_list, c("pkgA","pkgB","pkgC"))
  }
})