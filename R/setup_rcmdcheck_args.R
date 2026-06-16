#' set up rcmdcheck arguments
#' 
#' @description This sets up rcmdcheck arguments
#' @details {Some packages need to have build vignettes as a 
#' build argument as their vignettes structure is inst/doc or inst/docs} 
#' 
#' @param check_type R CMD check mode:
#'   * `"1"` — basic R CMD check (default).
#'   * `"2"` — frugal mode used by [get_frugal_metrics()]: same args as
#'     `"1"` plus `--no-tests`, so the test suite is skipped.
#'   * any other value (e.g. `"3"`) — CRAN-like check (`--as-cran`).
#' @param build_vignettes Logical (T/F). Whether or not to build vignettes
#' 
#' @return - list with rcmdcheck arguments
#' @keywords internal
setup_rcmdcheck_args <- function(check_type = "1", 
                                 build_vignettes) {
  if (check_type == "1") {
    rcmdcheck_args = list(
      timeout = Inf,
      args = c("--no-examples", # don't check examples
               "--ignore-vignettes", # skip all tests on vignettes
               "--no-vignettes", # do not run R code in vignettes nor build outputs
               "--no-manual"), # disable pdf manual rendering
      build_args = if (Sys.info()[["sysname"]] == "Windows") {
        c("--no-build-vignettes", # do not build vignette outputs
          "--no-manual") # disable pdf manual rendering on Windows
      } else {
        c("--no-build-vignettes") # do not build vignette outputs
      },  
      # FORCE_SUGGESTS give an error if suggested packages are not available. 
      # Default: true (but false for CRAN submission checks)
      env = c(`_R_CHECK_FORCE_SUGGESTS_` = "FALSE"),
      quiet = FALSE
    )
  } else if (check_type == "2") {
    # Frugal mode (used by get_frugal_metrics()): same args as the basic
    # check, plus --no-tests so the test suite is skipped. build_args / env /
    # quiet are intentionally identical to the "1" branch — the only
    # difference is the additional --no-tests flag.
    rcmdcheck_args = list(
      timeout = Inf,
      args = c("--no-tests", # don't run the test suite
               "--no-examples", # don't check examples
               "--ignore-vignettes", # skip all tests on vignettes
               "--no-vignettes", # do not run R code in vignettes nor build outputs
               "--no-manual"), # disable pdf manual rendering
      build_args = if (Sys.info()[["sysname"]] == "Windows") {
        c("--no-build-vignettes", # do not build vignette outputs
          "--no-manual") # disable pdf manual rendering on Windows
      } else {
        c("--no-build-vignettes") # do not build vignette outputs
      },
      # FORCE_SUGGESTS give an error if suggested packages are not available.
      # Default: true (but false for CRAN submission checks)
      env = c(`_R_CHECK_FORCE_SUGGESTS_` = "FALSE"),
      quiet = FALSE
    )
  } else { 
    
    if (build_vignettes == FALSE) {
      rcmdcheck_args = list(
        timeout = Inf,
        args = c("--ignore-vignettes", # skip all tests on vignettes
                 "--no-vignettes", # do not run R code in vignettes nor build outputs
                 "--as-cran", # select customizations similar to those used for CRAN incoming checking"
                 "--no-manual"), # disable pdf manual rendering
        build_args = "--no-build-vignettes", # do not build vignette outputs
        # FORCE_SUGGESTS give an error if suggested packages are not available. 
        # Default: true (but false for CRAN submission checks)
        env = c(`_R_CHECK_FORCE_SUGGESTS_` = "FALSE"), 
        quiet = FALSE
      )
    } else {
      rcmdcheck_args = list(
        timeout = Inf,
        args = c("--ignore-vignettes", # skip all tests on vignettes
                 "--no-vignettes", # do not run R code in vignettes nor build outputs
                 "--as-cran", # select customizations similar to those used for CRAN incoming checking"
                 "--no-manual"), # disable pdf manual rendering
        # FORCE_SUGGESTS give an error if suggested packages are not available. 
        # Default: true (but false for CRAN submission checks)
        env = c(`_R_CHECK_FORCE_SUGGESTS_` = "FALSE"),
        quiet = FALSE
      )
    }
  }  
  return(rcmdcheck_args)
}
