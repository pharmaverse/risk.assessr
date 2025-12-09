#' Untar package and return installation directory
#'
#' @param pkg_tar path to tarball package
#' @param temp_file_name name of `tempfile`
#' @keywords internal
unpack_tarball <- function(pkg_tar, 
                           temp_file_name = "temp_file_"){
  
  pkg_disp <- risk.assessr::get_pkg_name(pkg_tar)
  message(glue::glue("unpacking {pkg_disp} locally"))
  # Create temporary location for package installation
  temp_pkg_dir <- tempfile(temp_file_name)
  if (!dir.create(temp_pkg_dir)) stop("unable to create ", temp_pkg_dir)
  
  source_tar_dir <- file.path(temp_pkg_dir)
  
  # unpack tarball
  # use internal tar from R to ensure untar doesn't crash with 
  # unacceptable tar file
  utils::untar(pkg_tar, exdir = source_tar_dir, tar = "internal")
  
  # unpackaged package path
  pkg_source_path <- fs::dir_ls(source_tar_dir)
  
  # Confirm tar is unpackaged in expected directory
  check1 <- checkmate::check_string(pkg_source_path)
  check2 <- checkmate::check_directory_exists(pkg_source_path)
  
  if (check1 == TRUE & check2 == TRUE) {
    message(glue::glue("unpacked {pkg_disp} locally"))  
  } else {
    message(glue::glue("not able to unpack {pkg_disp} locally")) 
  }
  
  return(pkg_source_path)
}



