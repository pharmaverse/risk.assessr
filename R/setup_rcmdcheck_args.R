#' set up rcmdcheck arguments
#' 
#' @description This sets up rcmdcheck arguments
#' @details {Some packages need to have build vignettes as a 
#' build argument as their vignettes structure is inst/doc or inst/docs} 
#' 
#' @param check_type basic R CMD check type - "1" CRAN R CMD check_type - "2"
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

  
