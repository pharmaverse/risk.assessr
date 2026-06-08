make_db <- function(pkgs) {
  df <- do.call(rbind, lapply(pkgs, function(x) {
    data.frame(
      Package    = if (is.null(x$Package)) NA_character_ else x$Package,
      Version    = if (is.null(x$Version)) "1.0.0" else x$Version,
      Depends    = if (is.null(x$Depends)) NA_character_ else x$Depends,
      Imports    = if (is.null(x$Imports)) NA_character_ else x$Imports,
      LinkingTo  = if (is.null(x$LinkingTo)) NA_character_ else x$LinkingTo,
      Suggests   = if (is.null(x$Suggests)) NA_character_ else x$Suggests,
      Enhances   = if (is.null(x$Enhances)) NA_character_ else x$Enhances,
      stringsAsFactors = FALSE
    )
  }))
  rownames(df) <- df$Package
  df
}

test_that("bioconductor_reverse_deps returns reverse Imports", {
  # edgeR and DESeq2 import limma
  db <- make_db(list(
    list(Package = "limma"),
    list(Package = "edgeR",  Imports = "limma"),
    list(Package = "DESeq2", Imports = "limma"),
    list(Package = "other")
  ))
  
  res <- bioconductor_reverse_deps("limma", which = "Imports", db = db)
  expect_type(res, "list")
  expect_equal(names(res), "Imports")
  expect_setequal(res$Imports, c("edgeR", "DESeq2"))
})

test_that("bioconductor_reverse_deps handles which = 'all'", {
  db <- make_db(list(
    list(Package = "limma"),
    list(Package = "edgeR",  Imports = "limma"),
    list(Package = "DESeq2", Imports = "limma")
  ))
  
  res <- bioconductor_reverse_deps("limma", which = "all", db = db)
  expect_type(res, "list")
  expect_true(all(c("Depends","Imports","LinkingTo","Suggests","Enhances") %in% names(res)))
  expect_setequal(res$Imports, c("edgeR","DESeq2"))
  # Others should be empty vectors
  expect_length(res$Depends,   0)
  expect_length(res$LinkingTo, 0)
  expect_length(res$Suggests,  0)
  expect_length(res$Enhances,  0)
})

test_that("bioconductor_reverse_deps only.bioc = TRUE filters correctly", {
  # DB has Bioc pkgs edgeR/DESeq2 and a non-Bioc pkg notBioc, all importing limma
  db <- make_db(list(
    list(Package = "limma"),
    list(Package = "edgeR",   Imports = "limma"),
    list(Package = "DESeq2",  Imports = "limma"),
    list(Package = "notBioc", Imports = "limma")
  ))
  
  # biocdb lists only the Bioconductor packages
  biocdb <- make_db(list(
    list(Package = "limma"),
    list(Package = "edgeR"),
    list(Package = "DESeq2")
  ))
  
  res <- bioconductor_reverse_deps("limma", which = "Imports", only.bioc = TRUE, db = db, biocdb = biocdb)
  expect_setequal(res$Imports, c("edgeR","DESeq2"))
  expect_false("notBioc" %in% res$Imports)
})

test_that("bioconductor_reverse_deps returns NULL for invalid which value", {
  db <- make_db(list(list(Package = "limma")))
  res <- bioconductor_reverse_deps("limma", which = "NotARealType", db = db)
  expect_null(res)
})

test_that("bioconductor_reverse_deps returns empty when pkg has no reverse deps", {
  db <- make_db(list(
    list(Package = "limma"),
    list(Package = "edgeR")  # no imports/depends on limma
  ))
  res <- bioconductor_reverse_deps("limma", which = "Imports", db = db)
  expect_equal(res$Imports, character(0))
})

# ---- db = NULL branch (fetched from BiocManager repositories) ----------------
#
# These tests cover the network-bound path where the package database is read
# from PACKAGES{,.gz} indexes. All entry points that would touch the network
# (BiocManager::repositories(), url(), gzcon(), read.dcf()) are stubbed via
# mockery so the tests are deterministic, offline, and CRAN-safe.

test_that("bioconductor_reverse_deps assembles db from BiocManager repositories when db = NULL", {
  # read.dcf() returns a character matrix; emulate one with limma plus two
  # reverse importers so the assembled db drives a non-trivial result.
  fake_dcf <- matrix(
    c(
      "limma",  NA_character_, NA_character_, NA_character_, NA_character_, NA_character_,
      "edgeR",  NA_character_, "limma",        NA_character_, NA_character_, NA_character_,
      "DESeq2", NA_character_, "limma",        NA_character_, NA_character_, NA_character_
    ),
    nrow = 3, byrow = TRUE,
    dimnames = list(NULL, c("Package", "Depends", "Imports",
                            "LinkingTo", "Suggests", "Enhances"))
  )
  
  # url(u, "rb") would normally open a connection eagerly; replace it with an
  # inert placeholder. close() in the on.exit() handler is wrapped in
  # try(.., silent = TRUE) so dispatch failure on the placeholder is harmless.
  fake_con <- list()
  
  mockery::stub(
    bioconductor_reverse_deps, "BiocManager::repositories",
    function(...) c(BioCsoft = "https://example.com/bioc")
  )
  mockery::stub(bioconductor_reverse_deps, "url",   function(...) fake_con)
  mockery::stub(bioconductor_reverse_deps, "gzcon", function(con, ...) con)
  mockery::stub(bioconductor_reverse_deps, "read.dcf", function(...) fake_dcf)
  
  res <- bioconductor_reverse_deps(
    pkg     = "limma",
    which   = "Imports",
    version = "3.20"
  )
  
  expect_type(res, "list")
  expect_equal(names(res), "Imports")
  expect_setequal(res$Imports, c("edgeR", "DESeq2"))
})

test_that("bioconductor_reverse_deps falls back to plain PACKAGES when PACKAGES.gz is unreadable", {
  # Drive the for() loop in read_packages_index past the .gz URL so the
  # second iteration (plain PACKAGES) is exercised too.
  fake_dcf <- matrix(
    c(
      "limma", NA_character_, NA_character_, NA_character_, NA_character_, NA_character_,
      "edgeR", NA_character_, "limma",        NA_character_, NA_character_, NA_character_
    ),
    nrow = 2, byrow = TRUE,
    dimnames = list(NULL, c("Package", "Depends", "Imports",
                            "LinkingTo", "Suggests", "Enhances"))
  )
  
  fake_con <- list()
  
  read_dcf_stub <- function(con, ...) {
    # First call (PACKAGES.gz path) errors -> tryCatch turns it into NULL;
    # second call (plain PACKAGES) returns the fake matrix.
    if (!isTRUE(read_dcf_stub_state$called)) {
      read_dcf_stub_state$called <<- TRUE
      stop("simulated gz read failure")
    }
    fake_dcf
  }
  read_dcf_stub_state <- new.env()
  read_dcf_stub_state$called <- FALSE
  
  mockery::stub(
    bioconductor_reverse_deps, "BiocManager::repositories",
    function(...) c(BioCsoft = "https://example.com/bioc")
  )
  mockery::stub(bioconductor_reverse_deps, "url",   function(...) fake_con)
  mockery::stub(bioconductor_reverse_deps, "gzcon", function(con, ...) con)
  mockery::stub(bioconductor_reverse_deps, "read.dcf", read_dcf_stub)
  
  res <- bioconductor_reverse_deps(
    pkg     = "limma",
    which   = "Imports",
    version = "3.20"
  )
  
  expect_setequal(res$Imports, "edgeR")
})

test_that("bioconductor_reverse_deps returns NULL with a message when no PACKAGES index can be read", {
  # read.dcf() always throws; the inner tryCatch turns each read into NULL,
  # the outer Filter strips the NULLs, and the function should hit the
  # 'could not read any PACKAGES indexes' branch.
  fake_con <- list()
  
  mockery::stub(
    bioconductor_reverse_deps, "BiocManager::repositories",
    function(...) c(BioCsoft = "https://example.com/bioc")
  )
  mockery::stub(bioconductor_reverse_deps, "url",   function(...) fake_con)
  mockery::stub(bioconductor_reverse_deps, "gzcon", function(con, ...) con)
  mockery::stub(
    bioconductor_reverse_deps, "read.dcf",
    function(...) stop("simulated read failure")
  )
  
  expect_message(
    res <- bioconductor_reverse_deps(
      pkg     = "limma",
      which   = "Imports",
      version = "3.20"
    ),
    "could not read any PACKAGES indexes"
  )
  expect_null(res)
})

test_that("bioconductor_reverse_deps respects only.bioc filtering when db is fetched from repositories", {
  # Same fetched-db path but with only.bioc = TRUE so the biocdb branch
  # (which also calls BiocManager::repositories) is exercised. The mocked
  # PACKAGES contains a non-Bioc reverse importer that must be filtered out.
  fake_dcf <- matrix(
    c(
      "limma",   NA_character_, NA_character_, NA_character_, NA_character_, NA_character_,
      "edgeR",   NA_character_, "limma",        NA_character_, NA_character_, NA_character_,
      "notBioc", NA_character_, "limma",        NA_character_, NA_character_, NA_character_
    ),
    nrow = 3, byrow = TRUE,
    dimnames = list(NULL, c("Package", "Depends", "Imports",
                            "LinkingTo", "Suggests", "Enhances"))
  )
  
  biocdb <- make_db(list(
    list(Package = "limma"),
    list(Package = "edgeR")
  ))
  
  fake_con <- list()
  
  mockery::stub(
    bioconductor_reverse_deps, "BiocManager::repositories",
    function(...) c(BioCsoft = "https://example.com/bioc")
  )
  mockery::stub(bioconductor_reverse_deps, "url",   function(...) fake_con)
  mockery::stub(bioconductor_reverse_deps, "gzcon", function(con, ...) con)
  mockery::stub(bioconductor_reverse_deps, "read.dcf", function(...) fake_dcf)
  
  res <- bioconductor_reverse_deps(
    pkg       = "limma",
    which     = "Imports",
    only.bioc = TRUE,
    version   = "3.20",
    biocdb    = biocdb
  )
  
  expect_setequal(res$Imports, "edgeR")
  expect_false("notBioc" %in% res$Imports)
})
