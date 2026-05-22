#' Untar package and return installation directory
#'
#' @param pkg_tar path to tarball package
#' @param temp_file_name name of `tempfile`
#' @keywords internal
unpack_tarball <- function(pkg_tar,
                           temp_file_name = "temp_file_") {
  
  pkg_disp <- tryCatch(
    get_pkg_name(pkg_tar),
    error = function(e) basename(pkg_tar)
  )
  message(paste0("unpacking ", pkg_disp, " locally"))
  
  # Initialize as a zero-length fs_path (via fs's public constructor) so the
  # return type is consistent across success and every failure branch.
  pkg_source_path <- fs::as_fs_path(character())
  proceed <- TRUE
  
  temp_pkg_dir <- tempfile(temp_file_name)
  if (!dir.create(temp_pkg_dir)) {
    message("Unable to create temp dir for ", pkg_disp, "; returning empty path.")
    proceed <- FALSE
  } else {
    # On any failure path (zero-length pkg_source_path at exit), remove the
    # temp dir we just created so repeated tolerant calls do not accumulate
    # orphan directories under tempdir(). On success the dir is preserved
    # because callers (set_up_pkg, install_package_local) need the contents.
    on.exit(
      if (length(pkg_source_path) == 0L && dir.exists(temp_pkg_dir)) {
        unlink(temp_pkg_dir, recursive = TRUE, force = TRUE)
      },
      add = TRUE
    )
  }
  
  if (proceed) {
    # use internal tar from R to ensure untar doesn't crash with
    # unacceptable tar file. utils::untar() emits warning() (not error())
    # for conditions such as "cannot open compressed file" and benign
    # informational notes such as "skipping pax global extended headers";
    # muffle them here and route through message() so callers (and
    # R CMD check on CRAN) never see a leaked warning.
    proceed <- tryCatch(
      withCallingHandlers(
        {
          utils::untar(pkg_tar, exdir = temp_pkg_dir, tar = "internal")
          TRUE
        },
        warning = function(w) {
          message("untar note for ", pkg_disp, ": ", conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) {
        message("untar failed for ", pkg_disp, ": ", conditionMessage(e))
        FALSE
      }
    )
  }
  
  if (proceed) {
    candidate <- fs::dir_ls(temp_pkg_dir, type = "directory")
    
    if (length(candidate) == 0L) {
      # Empty tarball, or tarball containing only top-level files (no package dir).
      # Distinguish the two for clearer diagnostics.
      any_entries <- fs::dir_ls(temp_pkg_dir)
      if (length(any_entries) == 0L) {
        message(
          "Tarball ", pkg_disp, " is empty (no entries extracted). ",
          "Returning empty path."
        )
      } else {
        message(
          "Tarball ", pkg_disp, " has no top-level directory ",
          "(found ", length(any_entries), " top-level file(s) only). ",
          "Returning empty path."
        )
      }
    } else if (length(candidate) > 1L) {
      message(
        "Tarball ", pkg_disp, " has ", length(candidate),
        " top-level directories; expected exactly one. Returning empty path."
      )
    } else if (!file.exists(file.path(candidate, "DESCRIPTION"))) {
      message("Unpacked directory has no DESCRIPTION: ", candidate)
    } else {
      message(paste0("unpacked ", pkg_disp, " locally"))
      pkg_source_path <- candidate
    }
  }
  
  return(pkg_source_path)
}